---
title: "Docker Compose Tip #41: Container lifecycle hooks"
date: 2026-03-18T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Run commands at specific points in a container's lifecycle with post_start and pre_stop hooks"
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

Docker Compose supports lifecycle hooks that let you run commands at specific points in a container's lifecycle, right after it starts and just before it stops.

## post_start hook

Run a command inside the container right after it starts — perfect for initialization tasks like database migrations:

```yaml
services:
  api:
    image: myapp-api
    post_start:
      - command: /app/migrate.sh
    depends_on:
      postgres:
        condition: service_healthy
```

Or warming up caches so the service is ready to handle traffic:

```yaml
services:
  web:
    image: myapp-web
    post_start:
      - command: /bin/sh -c "curl -sf http://localhost:3000/warmup"
```

## pre_stop hook

Run a command just before the container receives the stop signal — useful for draining connections gracefully:

```yaml
services:
  api:
    image: myapp-api
    pre_stop:
      - command: /bin/sh -c "curl -sf -X POST http://localhost:8080/drain"
    stop_grace_period: 30s
```

Or notifying other services that this one is going away:

```yaml
services:
  worker:
    image: myapp-worker
    pre_stop:
      - command: /bin/sh -c "curl -sf -X POST http://api:8080/workers/deregister?id=$HOSTNAME"
    stop_grace_period: 15s
```

## Combining both hooks

```yaml
services:
  api:
    image: myapp-api
    post_start:
      - command: /bin/sh -c "curl -sf http://localhost:8080/ready || exit 1"
    pre_stop:
      - command: /bin/sh -c "curl -sf -X POST http://localhost:8080/drain"
    stop_grace_period: 30s
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
```

## Hook behavior

A few things to keep in mind:

- `post_start` runs **inside the container**, not on the host
- `pre_stop` runs **before** the stop signal is sent to the main process
- If a `post_start` hook fails, the container is marked as unhealthy
- Hooks run sequentially if you define multiple commands:

```yaml
services:
  app:
    image: myapp
    post_start:
      - command: /app/migrate.sh
      - command: /app/seed.sh
      - command: /app/warm-cache.sh
```

## Hooks vs entrypoint

Don't confuse hooks with `entrypoint` or `command`:

- **entrypoint/command**: the main process — it IS the container
- **post_start**: runs alongside the main process, after the container starts
- **pre_stop**: runs before the main process receives the stop signal

Hooks are for side tasks; the main process should still be defined by the image.

## Further reading

- [Compose specification: post_start](https://docs.docker.com/reference/compose-file/services/#post_start)
- [Compose specification: pre_stop](https://docs.docker.com/reference/compose-file/services/#pre_stop)
