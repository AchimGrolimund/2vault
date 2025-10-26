# Obtain certs for final stage
FROM alpine:latest as authority
RUN mkdir /user && \
    echo 'appuser:x:1000:1000:appuser:/:' > /user/passwd && \
    echo 'appgroup:x:1000:' > /user/group
RUN apk --no-cache add ca-certificates

# Build app binary for final stage
FROM golang:latest AS builder

# Some build arguments
ARG GIT_VERSION=unspecified
LABEL git_version=$GIT_VERSION
ARG GIT_BUILD=unspecified
LABEL git_build=$GIT_BUILD

WORKDIR /app
COPY . .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-w -s -X main.Version=${GIT_VERSION} -X main.Build=${GIT_BUILD}" -a -installsuffix cgo -o /main .

# Final stage
FROM scratch
COPY --from=authority /user/group /user/passwd /etc/
COPY --from=authority /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /main ./
USER appuser:appgroup
EXPOSE 8080
ENTRYPOINT ["./main"]