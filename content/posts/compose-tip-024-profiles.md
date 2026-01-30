---
title: "Docker Compose Tip #24: Using profiles to organize optional services"
date: 2026-02-05T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "profiles", "development", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Control which services start with profiles for dev, test, and production scenarios"
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

Keep your Compose stack flexible! Profiles let you include or exclude services based on your current needs.

## Basic profiles

Define optional services with profiles:

```yaml
services:
  app:
    image: myapp:latest
    ports:
      - "3000:3000"
    # No profile - always starts

  debug:
    image: debug-tools
    profiles:
      - debug
    # Only starts with --profile debug

  test-db:
    image: postgres:15
    profiles:
      - test
    environment:
      POSTGRES_DB: test_db
```

## Starting with profiles

Choose which services to include:

```bash
# Start only core services (no profiles)
docker compose up

# Include debug tools
docker compose --profile debug up

# Run tests with test database
docker compose --profile test up

# Multiple profiles
docker compose --profile debug --profile test up
```

## Common use cases

**Development tools:**
```yaml
services:
  app:
    image: node:20
    volumes:
      - .:/app

  adminer:
    image: adminer
    profiles: ["debug", "dev"]
    ports:
      - "8080:8080"

  mailhog:
    image: mailhog/mailhog
    profiles: ["dev"]
    ports:
      - "8025:8025"
```

**Testing services:**
```yaml
services:
  tests:
    image: test-runner
    profiles: ["test"]
    depends_on:
      - app
      - test-db
    command: pytest

  test-db:
    image: postgres:15
    profiles: ["test"]
    environment:
      POSTGRES_DB: test
```

## Monitoring stack

Enable monitoring on demand:

```yaml
services:
  app:
    image: myapp
    labels:
      - "prometheus.io/scrape=true"

  prometheus:
    image: prom/prometheus
    profiles: ["monitoring"]
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana
    profiles: ["monitoring"]
    ports:
      - "3001:3000"
    depends_on:
      - prometheus

  node-exporter:
    image: prom/node-exporter
    profiles: ["monitoring", "metrics"]
    ports:
      - "9100:9100"
```

Usage:
```bash
# Dev without monitoring
docker compose up

# Full monitoring stack
docker compose --profile monitoring up

# Just metrics collection
docker compose --profile metrics up
```

## Profile combinations

Mix profiles for different scenarios:

```yaml
services:
  api:
    image: api:latest

  frontend:
    image: frontend:latest
    profiles: ["full", "ui"]

  backend-tools:
    image: debug-tools
    profiles: ["debug", "full"]

  load-test:
    image: k6
    profiles: ["test", "performance"]
```

```bash
# API only
docker compose up

# Full stack
docker compose --profile full up

# Performance testing
docker compose --profile performance up
```

## Environment-based profiles

Use environment variables to control profiles:

```bash
# .env
COMPOSE_PROFILES=dev,debug

# Or via command line
export COMPOSE_PROFILES=production,monitoring
docker compose up
```

## Pro tip

View active services for each profile:

```bash
# See what would start with a specific profile
docker compose --profile debug config --services

# Check all profiles at once
docker compose --profile="*" config --services

# Check each profile one by one
for profile in dev test debug monitoring; do
  echo "Profile: $profile"
  docker compose --profile $profile config --services
done
```

Profiles keep your stack lean and flexible!

## Further reading

- [Using profiles with Compose](https://docs.docker.com/compose/profiles/)
- [Compose specification - profiles](https://github.com/compose-spec/compose-spec/blob/master/spec.md#profiles)