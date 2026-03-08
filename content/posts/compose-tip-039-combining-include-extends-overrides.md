---
title: "Docker Compose Tip #39: Combining include, extends, and overrides"
date: 2026-03-13T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "advanced"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Use include, extends, and override files together for a clean and flexible multi-environment setup"
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

The real power comes from using all three mechanisms together, each doing what it does best.

## The scenario

A team maintaining a web application with:
- Shared infrastructure (database, monitoring) reused across projects
- Common service configuration (logging, labels) applied to all services
- Different settings for local development vs CI vs production

## Project structure

```
my-project/
├── compose.yml              # Main entry point
├── compose.override.yml     # Local dev overrides
├── compose.ci.yml           # CI-specific overrides
├── base/
│   └── service-base.yml     # Shared service config (extends)
└── infra/
    ├── database.yml         # Postgres stack (include)
    └── monitoring.yml       # Prometheus + Grafana (include)
```

## Step 1: Shared service config with extends

Define common configuration once:

```yaml
# base/service-base.yml
services:
  base:
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    labels:
      com.company.project: ${COMPOSE_PROJECT_NAME}
      com.company.env: ${ENV:-dev}
```

## Step 2: Modular infrastructure with include

Self-contained stacks that can be reused across projects:

```yaml
# infra/database.yml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 10s

volumes:
  db-data:
```

## Step 3: Main compose file

Bring it all together:

```yaml
# compose.yml
include:
  - path: ./infra/database.yml
  - path: ./infra/monitoring.yml

services:
  api:
    extends:
      file: ./base/service-base.yml
      service: base
    image: myapp-api:${TAG:-latest}
    environment:
      DATABASE_URL: postgres://postgres:${DB_PASSWORD}@postgres/myapp
    depends_on:
      postgres:
        condition: service_healthy

  worker:
    extends:
      file: ./base/service-base.yml
      service: base
    image: myapp-worker:${TAG:-latest}
    environment:
      DATABASE_URL: postgres://postgres:${DB_PASSWORD}@postgres/myapp
```

## Step 4: Environment-specific overrides

```yaml
# compose.override.yml (local dev - auto-loaded)
services:
  api:
    build: ./api       # Build locally
    volumes:
      - ./api:/app     # Hot reload
    environment:
      DEBUG: "true"

# compose.ci.yml (CI - explicit: docker compose -f compose.yml -f compose.ci.yml up)
services:
  api:
    image: myapp-api:${CI_COMMIT_SHA}
  worker:
    image: myapp-worker:${CI_COMMIT_SHA}
```

## The result

Each mechanism handles its concern independently:
- `include`: infrastructure stacks are isolated and reusable
- `extends`: service config is DRY and consistent
- Override files: environment differences are explicit and targeted

Changing the logging config? Update `base/service-base.yml` once. Swapping the database stack? Replace one `include` line. Adjusting dev ports? Edit `compose.override.yml` without touching anything else.

## Further reading

- [Compose documentation: Multiple Compose files](https://docs.docker.com/compose/how-tos/multiple-compose-files/)
- [Watch: Managing multiple Compose files](https://www.youtube.com/watch?v=VOyyGX1MOU0&list=PLkA60AVN3hh_t73mQG7RIvvMRTpm1ompt&index=52) - a complete walkthrough of these patterns in practice
