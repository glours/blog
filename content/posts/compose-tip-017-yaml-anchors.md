---
title: "Docker Compose Tip #17: YAML anchors to reduce duplication"
date: 2026-01-27T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to use YAML anchors and aliases to eliminate duplication in Compose files"
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

Stop copy-pasting the same configuration. YAML anchors let you define once and reuse everywhere in your Compose files.

## The basics

Define an anchor with `&` and reference it with `*`:

```yaml
services:
  web: &default-app
    image: myapp:latest
    environment:
      NODE_ENV: production
      LOG_LEVEL: info
    networks:
      - app-network

  worker:
    <<: *default-app  # Inherit all settings from web
    command: npm run worker
```

The `worker` service inherits everything from `web`, then overrides the command.

## Common logging configuration

Share logging setup across all services:

```yaml
x-logging: &default-logging
  logging:
    driver: "json-file"
    options:
      max-size: "10m"
      max-file: "3"

services:
  web:
    image: nginx
    <<: *default-logging

  api:
    image: myapi:latest
    <<: *default-logging

  worker:
    image: myworker:latest
    <<: *default-logging
```

## Shared environment variables

Perfect for microservices with common config:

```yaml
x-common-variables: &common-variables
  REDIS_URL: redis://redis:6379
  POSTGRES_HOST: postgres
  POSTGRES_PORT: 5432
  LOG_LEVEL: ${LOG_LEVEL:-info}

services:
  api:
    image: api:latest
    environment:
      <<: *common-variables
      SERVICE_NAME: api
      PORT: 8080

  worker:
    image: worker:latest
    environment:
      <<: *common-variables
      SERVICE_NAME: worker
      WORKER_CONCURRENCY: 10
```

## Network and volume patterns

Reuse complex configurations:

```yaml
x-app-service: &app-defaults
  networks:
    - frontend
    - backend
  volumes:
    - ./shared:/app/shared:ro
    - logs:/app/logs
  restart: unless-stopped
  deploy:
    resources:
      limits:
        memory: 512M

services:
  web:
    <<: *app-defaults
    image: web:latest
    ports:
      - "3000:3000"

  api:
    <<: *app-defaults
    image: api:latest
    ports:
      - "8080:8080"

networks:
  frontend:
  backend:

volumes:
  logs:
```

## Build configuration reuse

Share build settings across services:

```yaml
x-build-args: &build-args
  NODE_VERSION: "20"
  NPM_TOKEN: ${NPM_TOKEN}

services:
  app:
    build:
      context: ./app
      args:
        <<: *build-args

  worker:
    build:
      context: ./worker
      args:
        <<: *build-args
        WORKER_MODE: "true"
```

## View expanded configuration

Check how anchors expand:

```bash
docker compose config
```

This shows the final configuration with all anchors resolved.

## Pro tip

Use the `x-` prefix for anchor-only blocks - Compose ignores top-level keys starting with `x-`:

```yaml
x-healthcheck: &healthcheck
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost/health"]
    interval: 30s
    timeout: 3s
    retries: 3

services:
  web:
    image: web:latest
    <<: *healthcheck
```

The `x-healthcheck` block exists only for the anchor, not as a service.

## Further reading

- [YAML anchors specification](https://yaml.org/spec/1.2/spec.html#id2765878)
- [Compose extension fields](https://docs.docker.com/compose/compose-file/#extension)