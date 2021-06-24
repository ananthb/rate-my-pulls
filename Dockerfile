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
