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

FROM docker.io/library/golang:1.16 as go_build
WORKDIR /go/src/app
COPY . .
RUN go get -d -v ./...
RUN go install ./...

FROM docker.io/library/node:16 as node_build
WORKDIR /app
COPY web .
RUN yarn install
RUN yarn build

FROM gcr.io/distroless/base
COPY --from=go_build /go/bin/rmp /rmp
COPY --from=node_build /app/public /public
ENTRYPOINT [ "/rmp" ]
