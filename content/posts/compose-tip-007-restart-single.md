---
title: "Docker Compose Tip #7: Restarting single services without stopping the stack"
date: 2026-01-13T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "productivity", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to restart individual services in Docker Compose without bringing down your entire stack"
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

Stop doing `docker compose down && docker compose up` for every code change. Docker Compose lets you restart individual services while keeping the rest running.

## The solution

Restart just what changed:

```bash
# Restart only the web service
docker compose up -d web

# Your database, cache, and queue keep running!
```

This simple command saves minutes per restart. Your database keeps its data, Redis maintains its cache, message queues preserve their state.

## Common patterns

**Basic restart after code changes:**
```bash
# Make your changes, then:
docker compose up -d api
```

**Force recreate when config changed:**
```bash
# When you've changed environment variables or volumes
docker compose up -d --force-recreate web
```

**Rebuild and restart for local builds:**
```bash
# After changing code in a service you build
docker compose up -d --build api
```

**Pull latest image and restart:**
```bash
docker compose pull web
docker compose up -d web
```

## Real production example

Here's our typical development workflow:

```yaml
services:
  api:
    build: ./api
    volumes:
      - ./api:/app  # Code mounted for development
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    volumes:
      - pgdata:/var/lib/postgresql/data  # Persistent data

  redis:
    image: redis:7-alpine
```

Development session:
```bash
# Start everything
docker compose up -d

# Make API changes, restart just the API
docker compose up -d api

# Database and Redis stay running with all your test data!
```

## Check what's running

See the impact:
```bash
# Before restart
docker compose ps
```

Output:
```
NAME                STATUS          PORTS
myapp-api-1        Up 2 hours      0.0.0.0:3000->3000/tcp
myapp-postgres-1   Up 2 hours      5432/tcp
myapp-redis-1      Up 2 hours      6379/tcp
```

After `docker compose up -d api`:
```
NAME                STATUS          PORTS
myapp-api-1        Up 5 seconds    0.0.0.0:3000->3000/tcp
myapp-postgres-1   Up 2 hours      5432/tcp        # Still running!
myapp-redis-1      Up 2 hours      6379/tcp        # Still running!
```

## Multiple services at once

Restart several services together:
```bash
docker compose up -d web api worker
```

## Common pitfall

**Dependencies won't start automatically with `--no-deps`:**
```bash
# This won't start postgres if it's not running
docker compose up -d --no-deps web

# This ensures dependencies are running
docker compose up -d web
```

## Pro tip

During development, an even faster solution exists - use `docker compose up --watch` for automatic hot reloading:

```bash
# Instead of manually restarting services
docker compose up --watch

# Files change → services automatically reload!
```

This enables hot reloading when your code changes. We'll cover this powerful feature in detail in an upcoming post.

## Performance impact

In our Docker Desktop development:
- Full restart (`down && up`): ~45 seconds, loses all state
- Single service restart: ~3 seconds, preserves everything

That's 15x faster, plus no data loss or cache warming.

Stop restarting everything. Restart what changed. Your development speed will thank you.

## Further reading

- [Docker Compose up reference](https://docs.docker.com/engine/reference/commandline/compose_up/)
- [Docker Compose Watch](https://docs.docker.com/compose/file-watch/)
- Related tip: [Service dependencies with health checks](/posts/compose-tip-003-depends-on-healthcheck/)