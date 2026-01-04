---
title: "Docker Compose Tip #3: Service dependencies with health checks"
date: 2025-01-08T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to make services wait for dependencies to be actually ready"
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

"Connection refused" errors? The app starts before the database is ready. Here's the fix.

## What doesn't work

This only waits for the container to start, not for it to be ready:
```yaml
services:
  app:
    depends_on:
      - db  # Container starts, but database isn't ready yet
```

## What actually works

Add health checks:

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  app:
    image: myapp
    depends_on:
      db:
        condition: service_healthy  # Now it actually waits for the database
```

## Common health checks

**PostgreSQL:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-postgres}"]
```

**MySQL:**
```yaml
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
```

**Redis:**
```yaml
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
```

**HTTP Service:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  # Or wget if curl isn't available
  test: ["CMD-SHELL", "wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1"]
```

## What the options mean

- `interval`: How often to run the check
- `timeout`: How long to wait for a response
- `retries`: Failures before marking unhealthy
- `start_period`: Grace period for slow services

## Multiple dependencies

```yaml
services:
  app:
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started  # Mix different conditions
      migration:
        condition: service_completed_successfully  # Waits for migrations to finish
```

## Development tip

Add restart logic for local dev:
```yaml
services:
  app:
    depends_on:
      db:
        condition: service_healthy
        restart: true  # Restarts app when db restarts
```

The app will reconnect when the database restarts.

## Debugging

```bash
# Check health status
docker compose ps

# See health check output
docker inspect --format='{{json .State.Health}}' <container_name> | jq
```