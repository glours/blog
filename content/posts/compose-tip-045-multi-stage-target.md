---
title: "Docker Compose Tip #45: Multi-stage builds with target"
date: 2026-03-27T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "build", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Use the target option to build specific stages from multi-stage Dockerfiles"
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

Multi-stage Dockerfiles let you define multiple build stages. With the `target` option in Compose, you can choose which stage to build — giving you different images from the same Dockerfile.

## A multi-stage Dockerfile

```dockerfile
# Stage 1: dependencies
FROM node:20-slim AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Stage 2: development (with dev dependencies and tools)
FROM deps AS dev
RUN npm install --include=dev
COPY . .
CMD ["npm", "run", "dev"]

# Stage 3: build
FROM deps AS build
COPY . .
RUN npm run build

# Stage 4: production (minimal)
FROM node:20-slim AS production
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=deps /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

## Targeting stages in Compose

Use `target` to pick which stage to build:

```yaml
services:
  app:
    build:
      context: .
      target: dev
    volumes:
      - .:/app
    ports:
      - "3000:3000"
```

## Different targets per environment

This is where `target` really shines — use override files to build different stages:

```yaml
# compose.yml
services:
  app:
    build:
      context: .
      target: production
    ports:
      - "3000:3000"

# compose.override.yml (local dev)
services:
  app:
    build:
      target: dev
    volumes:
      - .:/app
```

Running `docker compose up` locally builds the `dev` stage with source mounting. In CI or production, `docker compose -f compose.yml up` builds the `production` stage.

## Multiple services from one Dockerfile

Use `target` to build different services from the same Dockerfile:

```yaml
services:
  api:
    build:
      context: .
      target: production
    command: ["node", "dist/api.js"]

  worker:
    build:
      context: .
      target: production
    command: ["node", "dist/worker.js"]

  tests:
    build:
      context: .
      target: dev
    command: ["npm", "test"]
    profiles: ["test"]
```

The `api` and `worker` share the same production image, while `tests` uses the dev stage with test dependencies included.

## Combining target with build args

Use build args to further customize stages:

```yaml
services:
  app:
    build:
      context: .
      target: production
      args:
        NODE_ENV: production
        VERSION: ${VERSION:-dev}
```

## Pro tip

Use `docker compose build --progress=plain` to see which stages are built and which are cached:

```bash
# See full build output including cache hits
docker compose build --progress=plain

# Build a specific service
docker compose build --progress=plain app
```

Stages that aren't needed for the target are skipped entirely — multi-stage builds are efficient by design.

## Further reading

- [Compose specification: build target](https://docs.docker.com/reference/compose-file/build/#target)
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
