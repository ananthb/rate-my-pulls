# Copyright 2020, Ananth Bhaskararaman
#
# This file is part of Rate My Pulls.
#
# Rate My Pulls is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, version 3 of the License.
#
# Rate My Pulls is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Rate My Pulls.  If not, see
# <https://www.gnu.org/licenses/>.

FROM docker.io/library/node:16 as node_build
WORKDIR /app
COPY web .
RUN yarn install
RUN yarn build

FROM docker.io/library/haskell:9-buster as haskell_build
RUN cabal update
WORKDIR /app
COPY ./rate-my-pulls.cabal .
RUN cabal build --only-dependencies -j4
COPY . .
RUN cabal install

FROM docker.io/library/debian:buster-slim
COPY --from=node_build /app/public /public
COPY --from=haskell_build /root/.cabal/bin/rmp /rmp
ENTRYPOINT [ "/rmp" ]
