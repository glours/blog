---
title: "Docker Compose Tip #10: Using init for proper PID 1 handling"
date: 2026-01-16T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "processes", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Why and how to use init in Docker Compose for proper signal handling and zombie reaping"
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

Zombie processes in your containers? Slow shutdowns? Your app shouldn't run as PID 1. Here's the simple fix.

## The problem

When your app runs as PID 1, it has special responsibilities:
- Handle system signals (SIGTERM, SIGINT)
- Reap zombie processes
- Forward signals to child processes

Most apps (especially Node.js, Python) don't handle these well.

## The solution

Add `init: true` to your service:

```yaml
services:
  app:
    image: node:20
    init: true  # Adds Tini as PID 1
    command: node server.js
```

Docker automatically injects a tiny init system (Tini) that handles PID 1 responsibilities properly.

## What it fixes

**Before (without init):**
```yaml
services:
  app:
    image: node:20
    command: node server.js
```

Problems:
- `docker compose stop` takes 10 seconds (waiting for SIGKILL)
- Zombie processes accumulate
- Ctrl+C doesn't stop the container cleanly

**After (with init):**
```yaml
services:
  app:
    image: node:20
    init: true
    command: node server.js
```

Fixed:
- Instant graceful shutdown
- No zombie processes
- Signals handled correctly

## Real example

Our Node.js API that spawns child processes:

```yaml
services:
  api:
    image: node:20-alpine
    init: true
    command: node index.js
    stop_grace_period: 5s  # Now actually works!

  worker:
    image: python:3.11-slim
    init: true
    command: python worker.py

  # Even shells benefit
  debug:
    image: alpine
    init: true
    command: sh -c "while true; do echo working; sleep 10; done"
```

## Verify it's working

Check process tree:
```bash
docker compose exec app ps aux
```

Without init:
```
PID   USER     COMMAND
1     node     node server.js    # App is PID 1 - problematic!
15    node     /usr/bin/worker   # Child process
```

With init:
```
PID   USER     COMMAND
1     root     /sbin/docker-init  # Tini is PID 1
7     node     node server.js     # App is child of init
22    node     /usr/bin/worker    # Grandchild process
```

## Test graceful shutdown

```bash
# Time how long stop takes
time docker compose stop

# Without init: ~10 seconds
# With init: ~1 second
```

## When you need it most

Essential for:
- **Node.js apps** - Doesn't handle SIGTERM by default
- **Python scripts** - Poor signal handling
- **Shell scripts** - No zombie reaping
- **Apps spawning subprocesses** - Prevents zombie accumulation
- **Kubernetes** - Critical for pod termination

## Production impact

In our production Kubernetes clusters:
- 95% faster pod terminations
- Zero zombie processes after 30 days uptime
- Clean connection draining during deployments

## Pro tip

Some images include their own init:
```yaml
services:
  # These handle PID 1 properly already
  nginx:
    image: nginx:alpine  # Has its own signal handling

  postgres:
    image: postgres:15   # Database handles signals well

  # These need init
  node-app:
    image: node:20
    init: true          # Add init for Node.js

  python-app:
    image: python:3.11
    init: true          # Add init for Python
```

One line of config prevents entire classes of production issues. Always use `init: true` for interpreted languages.

## Further reading

- [Tini - A tiny but valid init](https://github.com/krallin/tini)
- [Docker run --init documentation](https://docs.docker.com/engine/reference/run/#specify-an-init-process)