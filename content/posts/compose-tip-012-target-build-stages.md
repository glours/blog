---
title: "Docker Compose Tip #12: Using target to specify build stages"
date: 2026-01-20T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "build", "optimization", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to use target to build specific stages from multi-stage Dockerfiles"
disableShare: false
disableHLJS: false
hideSummary: false
searchHidden: false
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: false
UseHugoToc: false
---

One Dockerfile, multiple environments. Use `target` to build only the stage you need - faster builds, smaller images, cleaner separation.

## The basics

Multi-stage Dockerfile:
```dockerfile
# Development stage
FROM node:20-alpine AS development
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["npm", "run", "dev"]

# Production stage
FROM node:20-alpine AS production
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
CMD ["npm", "start"]
```

Target specific stages in compose.yml:
```yaml
services:
  app-dev:
    build:
      context: .
      target: development  # Stops at development stage
    volumes:
      - .:/app

  app-prod:
    build:
      context: .
      target: production  # Builds to production stage
```

## Real example

Go application with test and production stages:

```dockerfile
# Dockerfile
FROM golang:1.21-alpine AS base
WORKDIR /app
COPY go.* ./
RUN go mod download

FROM base AS test
COPY . .
RUN go test -v ./...

FROM base AS builder
COPY . .
RUN CGO_ENABLED=0 go build -o server

FROM alpine:3.19 AS production
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/server /server
CMD ["/server"]
```

```yaml
# compose.yml
services:
  app:
    build:
      context: .
      target: ${BUILD_TARGET:-production}
    ports:
      - "8080:8080"

  test:
    build:
      context: .
      target: test
    profiles: ["test"]
```

## Running different targets

```bash
# Development
BUILD_TARGET=development docker compose up

# Run tests
docker compose --profile test build

# Production
BUILD_TARGET=production docker compose build
```

## Size comparison

```bash
# Development image (includes all tools)
docker compose build --no-cache app-dev
# Image size: 450MB

# Production image (optimized)
docker compose build --no-cache app-prod
# Image size: 12MB
```

That's 37x smaller for production!

## CI pattern

Run tests without building production:

```yaml
services:
  ci-test:
    build:
      context: .
      target: test
```

```bash
# CI fails fast if tests don't pass
docker compose build ci-test || exit 1
```

## Pro tip

Use environment variables for flexible target selection:

```bash
# Development by default
export BUILD_TARGET=development

# Switch to production for deployment
BUILD_TARGET=production docker compose up -d
```

One compose file, multiple environments!

## Further reading

- [Docker multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Compose build specification](https://docs.docker.com/compose/compose-file/build/)