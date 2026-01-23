---
title: "Docker Compose Tip #18: Graceful shutdown with stop_grace_period"
date: 2026-01-28T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to configure graceful shutdown timeouts for containers in Docker Compose"
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

Give your containers time to clean up. Configure grace periods to ensure database connections close, transactions complete, and data saves properly.

## The problem

By default, Docker gives containers 10 seconds to stop before forcefully killing them:

```yaml
services:
  app:
    image: myapp:latest
    # Container gets SIGTERM, then SIGKILL after 10s
```

This can interrupt long-running operations and corrupt data.

## The solution

Use `stop_grace_period` to extend shutdown time:

```yaml
services:
  worker:
    image: myworker:latest
    stop_grace_period: 2m  # 2 minutes to finish current job
    stop_signal: SIGTERM   # Signal to send first (default)
```

## Real-world examples

Different services need different grace periods:

```yaml
services:
  # Web server - quick shutdown
  nginx:
    image: nginx
    stop_grace_period: 30s

  # API - finish active requests
  api:
    image: api:latest
    stop_grace_period: 45s
    environment:
      SHUTDOWN_TIMEOUT: 40  # App-level timeout

  # Background worker - complete current job
  worker:
    image: worker:latest
    stop_grace_period: 5m
    environment:
      WORKER_SHUTDOWN_TIMEOUT: 290  # Slightly less than grace period

  # Database - flush and close properly
  postgres:
    image: postgres:15
    stop_grace_period: 2m
    command: postgres -c max_wal_size=2GB
```

## Handle signals properly

Your application must respond to SIGTERM:

```javascript
// Node.js example
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully...');

  server.close(() => {
    console.log('HTTP server closed');
  });

  // Close database connections
  await db.close();

  // Finish current jobs
  await jobQueue.shutdown();

  process.exit(0);
});
```

## Test graceful shutdown

Verify your grace period works:

```bash
# Start services
docker compose up -d

# Trigger long operation in container
docker compose exec worker trigger-long-job

# Stop with timing
time docker compose stop worker

# Should take close to your grace period
# real    2m3.456s
```

## Compose commands respect grace period

All these commands honor `stop_grace_period`:

```bash
docker compose stop
docker compose down
docker compose restart
docker compose rm -s  # Stop first
```

## Common patterns

**Quick web services**:
```yaml
stop_grace_period: 30s  # Finish HTTP requests
```

**Job processors**:
```yaml
stop_grace_period: 5m   # Complete current job
```

**Databases**:
```yaml
stop_grace_period: 2m   # Flush buffers, close connections
```

**Message consumers**:
```yaml
stop_grace_period: 1m   # Process remaining messages
```

## Pro tip

For critical data operations, combine grace period with health checks:

```yaml
services:
  processor:
    image: processor:latest
    stop_grace_period: 5m
    healthcheck:
      test: ["CMD", "pgrep", "-x", "processor"]
      interval: 30s
      retries: 10  # Keep checking during shutdown
```

This ensures the container stays healthy during graceful shutdown.

## Further reading

- [Compose stop_grace_period](https://docs.docker.com/compose/compose-file/#stop_grace_period)
- [Docker stop documentation](https://docs.docker.com/engine/reference/commandline/stop/)