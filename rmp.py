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
from typing import Union

from fastapi import FastAPI
from pydantic import BaseSettings
from starlette_cramjam.middleware import CompressionMiddleware
from starlette_prometheus import metrics, PrometheusMiddleware


class Settings(BaseSettings):
    host: str = "127.0.0.1"
    port: int = 8000


settings = Settings()
app = FastAPI()
app.add_middleware(PrometheusMiddleware, filter_unhandled_paths=True)
app.add_middleware(CompressionMiddleware)

## HANDLERS

app.add_route("/metrics", metrics)


@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: Union[str, None] = None):
    return {"item_id": item_id, "q": q}


def main() -> None:
    import uvicorn  # type: ignore

    uvicorn.run(app, host=settings.host, port=settings.port)
