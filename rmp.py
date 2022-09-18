"""rmp.py

   Copyright 2022, Ananth <rate-my-pulls@kedi.dev>

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

"""
from pathlib import Path

from aiohttp_oauthlib import OAuth2Session  # type: ignore
from fastapi import FastAPI
from fastapi.requests import Request
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from gql import Client, gql
from gql.transport.aiohttp import AIOHTTPTransport
from starlette.config import Config
from starlette.datastructures import Secret
from starlette_cramjam.middleware import CompressionMiddleware  # type: ignore
from starlette_prometheus import PrometheusMiddleware, metrics
from starsessions import SessionAutoloadMiddleware, SessionMiddleware
from starsessions.stores.redis import RedisStore

# CONFIG
config = Config()

HOST = config("HOST", cast=str, default="127.0.0.1")
PORT = config("PORT", cast=int, default=8000)
WEB_DIR = config("WEB_DIR", cast=Path, default=Path("web"))
FLY_APP_NAME = config("FLY_APP_NAME", cast=str)
REDIS_URL = config("REDIS_URL", cast=str, default="redis://localhost:6379")
GITHUB_APP_ID = config("GITHUB_APP_ID", cast=str)
GITHUB_WEBHOOK_SECRET = config("GITHUB_WEBHOOK_SECRET", cast=Secret)
GITHUB_APP_PRIVATE_KEY = config("GITHUB_APP_PRIVATE_KEY", cast=Secret)
GITHUB_OAUTH_CLIENT_ID = config("GITHUB_OAUTH_CLIENT_ID", cast=str)
GITHUB_OAUTH_CLIENT_SECRET = config("GITHUB_OAUTH_CLIENT_SECRET", cast=Secret)
GITHUB_OAUTH_BASE_URL = "https://github.com/login/oauth/authorize"
GITHUB_OAUTH_TOKEN_URL = "https://github.com/login/oauth/access_token"


# GITHUB CLIENT
transport = AIOHTTPTransport(url="https://countries.trevorblades.com/")
github = Client(transport=transport, fetch_schema_from_transport=True)

# APP
app = FastAPI()
app.add_middleware(PrometheusMiddleware, filter_unhandled_paths=True)
app.add_middleware(CompressionMiddleware)
app.add_middleware(SessionMiddleware, store=RedisStore(REDIS_URL))
app.add_middleware(SessionAutoloadMiddleware)

## HANDLERS

app.add_route("/metrics", metrics)


@app.get("/health")
def health() -> str:
    """health check"""
    return "ok"


# STATIC FILES
app.mount(
    "/",
    StaticFiles(directory=WEB_DIR, html=True),
    name="web",
)


@app.post("/auth", response_class=RedirectResponse)
def auth(request: Request) -> RedirectResponse:
    """auth starts the GitHub OAuth flow"""
    gh_session = OAuth2Session(
        client_id=GITHUB_OAUTH_CLIENT_ID,
        scope=["user:email"],
        redirect_uri=f"https://{FLY_APP_NAME}.fly.dev/auth/callback",
    )
    authorization_url, state = gh_session.authorization_url(GITHUB_OAUTH_BASE_URL)
    request.session["oauth_state"] = state
    return RedirectResponse(authorization_url)


@app.post("/auth/callback", response_class=RedirectResponse)
async def auth_callback(request: Request) -> RedirectResponse:
    """auth_callback handles the callback from GitHub OAuth"""
    gh_session = OAuth2Session(
        client_id=GITHUB_OAUTH_CLIENT_ID,
        state=request.session["oauth_state"],
    )
    token = await gh_session.fetch_token(
        GITHUB_OAUTH_TOKEN_URL,
        client_secret=str(GITHUB_OAUTH_CLIENT_SECRET),
        authorization_response=request.url,
    )
    del request.session["oauth_state"]
    request.session["token"] = token
    return RedirectResponse("/")


@app.post("/auth/clear")
def auth_clear(request: Request) -> RedirectResponse:
    """clears user session"""
    request.session.clear()
    return RedirectResponse("/")


@app.get("/cards")
def get_cards():
    query = gql(
        """
{
  viewer {
    followers(first: 100) {
      edges {
        node {
          id
          name
          pullRequests(first: 100) {
            totalCount
            nodes {
              createdAt
              number
              title
              repository {
                id
                nameWithOwner
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      }
    }
  }
}
"""
    )
    result = github.execute(query)
    return result


def main() -> None:
    import uvicorn  # type: ignore

    uvicorn.run(app, host=HOST, port=PORT)


if __name__ == "__main__":
    main()
