---
title: "Docker Compose Tip #35: Using tmpfs for ephemeral storage"
date: 2026-03-04T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "performance", "storage", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Boost performance with in-memory tmpfs mounts for temporary data"
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

Speed up I/O operations and enhance security by using tmpfs for temporary data. RAM-based storage that vanishes on restart!

## What is tmpfs?

Tmpfs is a temporary filesystem that resides in memory:
- ⚡ Ultra-fast (RAM speed)
- 🔒 Secure (data doesn't persist)
- 🧹 Self-cleaning (cleared on restart)

## Basic tmpfs usage

Simple tmpfs mount:

```yaml
services:
  app:
    image: myapp
    tmpfs:
      - /tmp
      - /app/cache
      - /var/run
```

With size limits:

```yaml
services:
  app:
    image: myapp
    tmpfs:
      - /tmp:size=100M
      - /app/cache:size=500M
      - /var/run:size=10M
```

## Advanced tmpfs options

Fine-tuned configuration:

```yaml
services:
  app:
    image: myapp
    tmpfs:
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 100M          # Size limit
          mode: 1770          # File permissions
          uid: 1000           # User ID
          gid: 1000           # Group ID
```

Using volumes syntax:

```yaml
services:
  app:
    image: myapp
    volumes:
      - type: tmpfs
        target: /app/temp
        tmpfs:
          size: 200000000     # 200MB in bytes
```

## Common use cases

### 1. Build cache

Speed up compilation:

```yaml
services:
  builder:
    image: node:18
    working_dir: /app
    volumes:
      - .:/app
      - type: tmpfs
        target: /app/.cache
        tmpfs:
          size: 1G
    command: npm run build
```

### 2. Session storage

Fast session management:

```yaml
services:
  web:
    image: nginx
    tmpfs:
      - /var/cache/nginx:size=100M
      - /var/run:size=10M

  app:
    image: myapp
    tmpfs:
      - /app/sessions:size=500M,mode=1770
    environment:
      SESSION_STORE: /app/sessions
```

### 3. Temporary uploads

Process files in memory:

```yaml
services:
  upload-processor:
    image: processor
    tmpfs:
      - /tmp/uploads:size=2G
    environment:
      UPLOAD_DIR: /tmp/uploads
      MAX_UPLOAD_SIZE: 100M
```

## Read-only root with tmpfs

Secure pattern with writable temp areas:

```yaml
services:
  secure-app:
    image: myapp
    read_only: true     # Entire filesystem read-only
    tmpfs:
      - /tmp:size=100M  # Writable temp
      - /var/run:size=10M
      - /app/cache:size=50M
    volumes:
      - app_logs:/var/log:rw  # Persistent logs
```

## Database with tmpfs

Speed up test databases:

```yaml
services:
  # Test database (data doesn't persist!)
  test-db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: test
    tmpfs:
      - /var/lib/postgresql/data:size=1G
    profiles: ["test"]

  # Production database (persistent)
  prod-db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    profiles: ["prod"]

volumes:
  postgres_data:
```

## Performance comparison

Test I/O performance:

```yaml
services:
  benchmark:
    image: alpine
    command: |
      sh -c "
        echo '=== Tmpfs Performance ==='
        time dd if=/dev/zero of=/tmp/test bs=1M count=100
        echo
        echo '=== Volume Performance ==='
        time dd if=/dev/zero of=/data/test bs=1M count=100
      "
    tmpfs:
      - /tmp:size=200M
    volumes:
      - benchmark_data:/data

volumes:
  benchmark_data:
```

## Complete example: CI runner

```yaml
services:
  runner:
    image: gitlab-runner
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner_config:/etc/gitlab-runner
    tmpfs:
      # Build artifacts (temporary)
      - /builds:size=5G
      # Package caches
      - /cache:size=2G
      # Docker layer cache
      - /var/lib/docker:size=10G

  # Test environment
  test-runner:
    image: node:18
    working_dir: /app
    volumes:
      - .:/app:ro  # Source code (read-only)
    tmpfs:
      # Dependencies
      - /app/node_modules:size=1G
      # Test output
      - /app/coverage:size=100M
      # Build output
      - /app/dist:size=500M
    command: |
      sh -c "
        cp -r /app /tmp/app-copy
        cd /tmp/app-copy
        npm ci
        npm test
        npm run build
      "
```

## Monitoring tmpfs usage

Check memory usage:

```bash
# Check tmpfs usage in a specific container
docker compose exec app df -h | grep tmpfs

# Monitor all containers' tmpfs usage
docker compose ps -q | xargs -I {} docker exec {} df -h 2>/dev/null | grep tmpfs

# Check system memory to see tmpfs impact
docker stats --no-stream
```

## Pro tip

Dynamic tmpfs sizing based on available memory:

```yaml
services:
  app:
    image: myapp
    environment:
      TMPFS_SIZE: ${TMPFS_SIZE:-100M}
    tmpfs:
      - /tmp:size=${TMPFS_SIZE:-100M}
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

And set size based on environment:
```bash
# .env.development
TMPFS_SIZE=500M

# .env.production
TMPFS_SIZE=2G

# .env.test
TMPFS_SIZE=100M
```

Fast, secure, and self-cleaning - tmpfs for the win!

## Further reading

- [tmpfs documentation](https://docs.docker.com/storage/tmpfs/)
- [Storage drivers overview](https://docs.docker.com/storage/storagedriver/)