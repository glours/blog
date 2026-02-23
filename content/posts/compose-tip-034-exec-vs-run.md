---
title: "Docker Compose Tip #34: Debugging with exec vs run"
date: 2026-03-02T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "debugging", "cli", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Understanding when to use docker compose exec vs run for debugging"
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

Know the difference between `exec` and `run`! Each has its place in your debugging toolkit.

## The key difference

- **`exec`**: Runs commands in an **existing** container
- **`run`**: Creates a **new** container

```bash
# Exec: enters running container
docker compose exec web bash

# Run: starts new container
docker compose run web bash
```

## When to use `exec`

Use `exec` for debugging running services:

```bash
# Debug a running web server
docker compose exec web bash

# Check logs inside container
docker compose exec web tail -f /var/log/app.log

# Run database queries
docker compose exec db psql -U postgres

# Check process list
docker compose exec web ps aux

# Test connectivity from inside
docker compose exec web curl http://api:3000/health
```

**Important**: Container must be running!
```bash
# This fails if web is stopped
docker compose exec web bash
# Error: No container found for web_1
```

## When to use `run`

Use `run` for one-off tasks:

```bash
# Run database migrations
docker compose run migrate npm run migrate:up

# Run tests
docker compose run --rm test npm test

# Execute scripts
docker compose run --rm app python manage.py createsuperuser

# Start interactive session with overrides
docker compose run --rm -e DEBUG=true web bash
```

## Key differences

### 1. Container lifecycle

```bash
# exec: uses existing container
docker compose up -d web
docker compose exec web echo "Existing PID: $$"
# Output: Existing PID: 1

# run: creates new container
docker compose run web echo "New PID: $$"
# Output: New PID: 1 (different container!)
```

### 2. Port mapping

```yaml
services:
  web:
    image: nginx
    ports:
      - "8080:80"
```

```bash
# exec: uses existing port mapping
docker compose exec web curl localhost:80  # Works

# run: NO port mapping by default
docker compose run web curl localhost:80   # Works
# But from host: curl localhost:8080       # Doesn't work!

# run with ports:
docker compose run --service-ports web     # Now ports are mapped
```

### 3. Dependencies

```yaml
services:
  web:
    image: myapp
    depends_on:
      - db
      - redis
```

```bash
# exec: dependencies already running
docker compose exec web bash  # db and redis are up

# run: doesn't start dependencies by default
docker compose run web bash   # db and redis NOT started!

# run with dependencies:
docker compose run --deps web bash  # Starts db and redis first
```

## Useful flags

### For `exec`:

```bash
# Run as different user
docker compose exec -u root web bash
docker compose exec -u 1000 web bash

# Set working directory
docker compose exec -w /app web ls

# Set environment variable
docker compose exec -e DEBUG=true web npm start

# Disable TTY
docker compose exec -T web cat /etc/hosts > hosts.txt

# Run in detached mode
docker compose exec -d web long-running-script.sh
```

### For `run`:

```bash
# Remove container after exit
docker compose run --rm web bash

# Run with service ports
docker compose run --service-ports web

# Run with dependencies
docker compose run --deps web bash

# Override entrypoint
docker compose run --entrypoint /bin/sh web

# Set name
docker compose run --name my-debug-container web bash

# Run in detached mode
docker compose run -d web background-job.sh
```

## Real-world debugging scenarios

### Scenario 1: Debug production issue

```bash
# 1. Check running containers
docker compose ps

# 2. Enter the problematic container
docker compose exec web bash

# 3. Inside container: check processes
ps aux | grep node

# 4. Check environment
env | grep NODE_

# 5. Test internal connectivity
curl http://api:3000/health

# 6. Review logs
tail -f /app/logs/error.log
```

### Scenario 2: Run maintenance tasks

```bash
# Database backup (new container)
docker compose run --rm db pg_dump -U postgres mydb > backup.sql

# Clear cache (existing container)
docker compose exec redis redis-cli FLUSHALL

# Run migrations (new container with cleanup)
docker compose run --rm migrate npm run migrate:up

# Seed database (new container)
docker compose run --rm --env SEED_USERS=100 seeder
```

Choose wisely: `exec` for running containers, `run` for fresh starts!

## Further reading

- [docker compose exec reference](https://docs.docker.com/compose/reference/exec/)
- [docker compose run reference](https://docs.docker.com/compose/reference/run/)