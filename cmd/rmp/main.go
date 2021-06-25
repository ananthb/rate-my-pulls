/* Copyright 2020, Ananth Bhaskararaman

   This file is part of Rate My Pulls.

   Rate My Pulls is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License as
	 published by the Free Software Foundation, version 3 of the License.

   Rate My Pulls is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public
	 License along with Rate My Pulls.  If not, see
	 <https://www.gnu.org/licenses/>.
*/

package main

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/gob"
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

	savedState, ok := session.Values[oauthStateKey].(string)
	if !ok {
		http.Error(w, "no saved state present in session", http.StatusConflict)
		return
	}

	state := r.URL.Query().Get("state")
	if state != savedState {
		http.Error(w, "state does not matched saved value", http.StatusForbidden)
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

func githubGraphQLAPI(w http.ResponseWriter, r *http.Request) {
	session, err := sessionStore.Get(r, sessionName)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	token, ok := session.Values[oauthTokenKey].(*oauth2.Token)
	if !ok {
		http.Error(w, "authentication token not found", http.StatusUnauthorized)
		return
	}

	token.SetAuthHeader(r)

	proxy := httputil.ReverseProxy{
		Director: func(r *http.Request) {
			const host = "api.github.com"
			r.Host = host
			r.URL.Host = host
			r.URL.Scheme = "https"
			r.URL.Path = "/graphql"
		},
	}

	proxy.ServeHTTP(w, r)
}

func main() {
	// register types that will be serialized in sessions
	gob.Register(&oauth2.Token{})

	redis_url := os.Getenv("FLY_REDIS_CACHE_URL")
	if redis_url == "" {
		redis_url = "redis://127.0.0.1:6379"
	}
	opts, err := redis.ParseURL(redis_url)
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
	http.HandleFunc("/api", githubGraphQLAPI)

	var address string
	if port := os.Getenv("PORT"); port == "" {
		address = "localhost:8080"
	} else {
		address = ":" + port
	}

	log.Println("starting the server on: ", address)
	log.Fatal(http.ListenAndServe(address, nil))
}
