/* Copyright 2020, Ananth Bhaskararaman

   This file is part of Rate My Pulls.

   Rate My Pulls is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License as
	 published by the Free Software Foundation, either version 3 of
	 the License, or any later version.

   Rate My Pulls is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public
	 License along with Foobar.  If not, see
	 <https://www.gnu.org/licenses/>.
*/

package main

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"net/http/httputil"
	"os"

	"github.com/go-redis/redis/v8"
	"github.com/gorilla/sessions"
	"github.com/rbcervilla/redisstore/v8"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/github"
)

const (
	sessionName   = "auth"
	oauthTokenKey = "oauth_token"
	oauthStateKey = "oauth_state"
)

var (
	oauthConf = &oauth2.Config{
		ClientID:     os.Getenv("RMP_GITHUB_CLIENT_ID"),
		ClientSecret: os.Getenv("RMP_GITHUB_CLIENT_SECRET"),
		Endpoint:     github.Endpoint,
		Scopes:       []string{"user:email", "repo"},
	}
	sessionStore sessions.Store

	// errors
	mismatchedStateErr = errors.New("state does not match saved value from session")
	stateMissingErr    = errors.New("no state value in session")
	stateDecodeErr     = errors.New("error decoding state from session")
)

func randomState(n int) string {
	data := make([]byte, n)
	if _, err := io.ReadFull(rand.Reader, data); err != nil {
		panic(err)
	}
	return base64.StdEncoding.EncodeToString(data)
}

func auth(w http.ResponseWriter, r *http.Request) {
	session, err := sessionStore.New(r, sessionName)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	session.Options = &sessions.Options{
		Path:     "/",
		MaxAge:   86400 * 7,
		Secure:   true,
		HttpOnly: true,
	}

	state := randomState(32)
	session.Values[oauthStateKey] = state
	if err := session.Save(r, w); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	url := oauthConf.AuthCodeURL(state, oauth2.AccessTypeOnline)
	http.Redirect(w, r, url, http.StatusTemporaryRedirect)
}

func authCallback(w http.ResponseWriter, r *http.Request) {
	session, err := sessionStore.Get(r, sessionName)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	var savedState string
	if rawState, ok := session.Values[oauthStateKey]; !ok {
		http.Error(w, stateMissingErr.Error(), http.StatusInternalServerError)
		return
	} else {
		if savedState, ok = rawState.(string); !ok {
			http.Error(w, stateDecodeErr.Error(), http.StatusInternalServerError)
			return
		}
	}

	state := r.URL.Query().Get("state")
	if state != savedState {
		http.Error(w, mismatchedStateErr.Error(), http.StatusForbidden)
		return
	}

	code := r.URL.Query().Get("code")
	token, err := oauthConf.Exchange(context.Background(), code)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	session.Values[oauthTokenKey] = token
	delete(session.Values, oauthStateKey)
	if err := session.Save(r, w); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/", http.StatusTemporaryRedirect)
}

func apiDirector(r *http.Request) {
	session, err := sessionStore.Get(r, sessionName)
	if err != nil {
		log.Fatalln(err)
	}
	if rawToken, ok := session.Values[oauthTokenKey]; ok {
		if rawTokenBytes, err := json.Marshal(rawToken); err == nil {
			var token oauth2.Token
			if err := json.Unmarshal(rawTokenBytes, &token); err == nil {
				token.SetAuthHeader(r)
			}
		}
	}
	const host = "api.github.com"
	r.Host = host
	r.URL.Host = host
	r.URL.Scheme = "https"
	r.URL.Path = "/graphql"
}

func main() {
	opts, err := redis.ParseURL(os.Getenv("FLY_REDIS_CACHE_URL"))
	if err != nil {
		log.Fatal("failed to parse redis url: ", err)
	}
	client := redis.NewClient(opts)

	if sessionStore, err = redisstore.NewRedisStore(context.Background(), client); err != nil {
		log.Fatal("failed to create redis session store: ", err)
	}

	// url handlers
	http.HandleFunc("/auth", auth)
	http.HandleFunc("/auth/callback", authCallback)
	http.Handle("/api", &httputil.ReverseProxy{
		Director: apiDirector,
	})

	var address string
	if port := os.Getenv("PORT"); port == "" {
		address = "localhost:8080"
	} else {
		address = ":" + port
	}

	log.Println("starting the server on: ", address)
	log.Fatal(http.ListenAndServe(address, nil))
}
