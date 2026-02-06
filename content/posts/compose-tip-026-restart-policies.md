---
title: "Docker Compose Tip #26: Using restart policies effectively"
date: 2026-02-09T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "restart", "runtime", "reliability", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Configure automatic container restarts for resilient applications"
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

Keep your services running! Restart policies ensure containers recover from crashes automatically.

## Available restart policies

Docker Compose offers four restart options:

```yaml
services:
  # Never restart (default)
  dev-tool:
    image: debug-tools
    restart: "no"

  # Restart only on failure (non-zero exit)
  api:
    image: api:latest
    restart: on-failure

  # Always restart unless manually stopped
  web:
    image: nginx
    restart: unless-stopped

  # Always restart, even after Docker daemon restarts
  database:
    image: postgres:15
    restart: always
```

## Choosing the right policy

**Development services:**
```yaml
services:
  # One-off tasks
  migrator:
    image: migrate/migrate
    restart: "no"
    command: -path=/migrations -database=$DB_URL up

  # Development tools
  adminer:
    image: adminer
    restart: unless-stopped  # Survives crashes, not Docker restarts
```

**Production services:**
```yaml
services:
  # Critical services
  app:
    image: myapp:prod
    restart: always

  redis:
    image: redis:alpine
    restart: always

  # Less critical
  metrics:
    image: prom/node-exporter
    restart: unless-stopped
```

## Restart with limits

Control restart behavior with on-failure:

```yaml
services:
  worker:
    image: worker:latest
    restart: on-failure:5  # Max 5 restart attempts

  flaky-service:
    image: unstable-api
    restart: on-failure:3
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      retries: 3
```

The counter resets after 10 minutes of successful running.

## Restart and depends_on

Restart policies work independently of dependencies:

```yaml
services:
  db:
    image: postgres
    restart: always

  app:
    image: myapp
    restart: always
    depends_on:
      - db
    # App restarts even if db is down
```

Better approach with health checks:
```yaml
services:
  db:
    image: postgres
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    image: myapp
    restart: always
    depends_on:
      db:
        condition: service_healthy
```

## Testing restart behavior

Simulate failures to test policies:

```bash
# Force container to exit with error
docker compose exec app kill -TERM 1

# Check restart count
docker compose ps
# NAME       STATUS         RESTARTS
# app-1      Up 2 seconds   1

# View restart events
docker compose events --since 5m | grep restart

# Force immediate restart
docker compose restart app
```

## Common patterns

**Database with init scripts:**
```yaml
services:
  postgres:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_DB: mydb
    volumes:
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    # Restarts don't re-run init scripts
```

**Queue workers:**
```yaml
services:
  worker:
    image: worker
    restart: on-failure:10
    deploy:
      replicas: 3
    # Each replica has independent restart counter
```

Choose policies that match your availability requirements!

## Further reading

- [Restart policies documentation](https://docs.docker.com/compose/compose-file/05-services/#restart)
- [Docker restart policies](https://docs.docker.com/config/containers/start-containers-automatically/)