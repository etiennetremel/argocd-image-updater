FROM golang:1.20 AS builder

RUN mkdir -p /src/argocd-image-updater
WORKDIR /src/argocd-image-updater
# cache dependencies as a layer for faster rebuilds
COPY go.mod go.sum ./
RUN go mod download
COPY . .

RUN mkdir -p dist && \
	make controller

FROM alpine:latest

RUN apk add --no-cache \
      ca-certificates \
      git \
      openssh-client \
      python3 \
      py3-pip \
      tini \
      aws-cli \
      gcc \
      musl-dev \
      python3-dev \
      libffi-dev \
      openssl-dev \
      cargo \
      make && \
    python3 -m venv .venv && \
    source .venv/bin/activate && \
    python3 -m pip install azure-cli && \
    rm -rf /var/cache/apk/*

RUN mkdir -p /usr/local/bin /app/config
RUN adduser --home "/app" --disabled-password --uid 1000 argocd

COPY --from=builder /src/argocd-image-updater/dist/argocd-image-updater /usr/local/bin/
COPY hack/git-ask-pass.sh /usr/local/bin/git-ask-pass.sh

USER 1000

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/argocd-image-updater"]
