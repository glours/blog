---
title: "Docker Compose Tip #19: Override files for local development"
date: 2026-01-29T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "development", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to use compose.override.yml for seamless local development configurations"
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

Keep production and development configs separate. Docker Compose automatically merges `compose.override.yml` for local development tweaks.

## The magic

Compose automatically loads two files:
1. `compose.yml` (base configuration)
2. `compose.override.yml` (local overrides)

```bash
# These are equivalent:
docker compose up
docker compose -f compose.yml -f compose.override.yml up
```

## Basic setup

**compose.yml** (production-ready):
```yaml
services:
  web:
    image: myapp:latest
    ports:
      - "80:80"
    environment:
      NODE_ENV: production
      LOG_LEVEL: warn
```

**compose.override.yml** (developer-friendly):
```yaml
services:
  web:
    build: .  # Build locally instead of using image
    ports:
      - "3000:80"  # Different port for development
    volumes:
      - .:/app  # Mount source code
    environment:
      NODE_ENV: development
      LOG_LEVEL: debug
      DEBUG: "true"
```

## Real development example

**compose.yml**:
```yaml
services:
  frontend:
    image: frontend:${VERSION:-latest}
    depends_on:
      - api

  api:
    image: api:${VERSION:-latest}
    environment:
      DATABASE_URL: ${DATABASE_URL}
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
```

**compose.override.yml**:
```yaml
services:
  frontend:
    build: ./frontend
    volumes:
      - ./frontend:/app
      - /app/node_modules
    command: npm run dev
    ports:
      - "3000:3000"

  api:
    build: ./api
    volumes:
      - ./api:/app
    environment:
      DATABASE_URL: postgres://postgres:localpass@postgres/devdb
      FLASK_DEBUG: "1"
    ports:
      - "5000:5000"

  postgres:
    environment:
      POSTGRES_PASSWORD: localpass
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev:/var/lib/postgresql/data

volumes:
  postgres_dev:
```

## Exclude override in production

Deploy without override file:

```bash
# Production deployment - override.yml ignored
docker compose -f compose.yml up -d

# Or explicitly with production override
docker compose -f compose.yml -f compose.prod.yml up -d
```

## Multiple override files

Chain multiple configurations:

```bash
# Base + override + additional testing setup
docker compose \
  -f compose.yml \
  -f compose.override.yml \
  -f compose.test.yml \
  up
```

## Check merged configuration

See the final result:

```bash
# View merged configuration (both files)
docker compose config

# View with explicit files
docker compose -f compose.yml -f compose.override.yml config

# Production config without override
docker compose -f compose.yml config

# Save merged config
docker compose config > composed.yml
```

## Common patterns

**Enable debugging tools**:
```yaml
# compose.override.yml
services:
  web:
    command: npm run dev
    environment:
      DEBUG: "*"
    ports:
      - "9229:9229"  # Node debugger
```

**Add development services**:
```yaml
# compose.override.yml
services:
  mailhog:  # Email testing
    image: mailhog/mailhog
    ports:
      - "8025:8025"
```

## Pro tip

Add `compose.override.yml` to `.gitignore` for personal settings:

```bash
echo "compose.override.yml" >> .gitignore

# Provide a template
cp compose.override.yml compose.override.yml.example
git add compose.override.yml.example
```

Developers copy the example and customize locally without affecting others.

## Further reading

- [Compose file merging](https://docs.docker.com/compose/multiple-compose-files/merge/)
- [Override and extend](https://docs.docker.com/compose/multiple-compose-files/)