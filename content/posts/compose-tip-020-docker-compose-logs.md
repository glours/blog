---
title: "Docker Compose Tip #20: Using docker compose logs effectively"
date: 2026-01-30T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "debugging", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Master docker compose logs to debug issues quickly and monitor your applications"
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

Stop scrolling through endless output. Master `docker compose logs` options to find issues fast and monitor services effectively.

## Basic commands

```bash
# All service logs
docker compose logs

# Single service
docker compose logs web

# Multiple services
docker compose logs web worker
```

## Follow logs in real-time

Watch logs as they happen:

```bash
# Follow all services
docker compose logs -f

# Follow specific service
docker compose logs -f api

# Start fresh and follow
docker compose logs -f --since 1m
```

## Tail recent logs

Get last N lines:

```bash
# Last 100 lines per service
docker compose logs --tail 100

# Last 50 lines of api service
docker compose logs --tail 50 api

# Just show last line
docker compose logs --tail 1
```

## Filter by time

Focus on recent issues:

```bash
# Last 5 minutes
docker compose logs --since 5m

# Last hour
docker compose logs --since 1h

# Since specific time
docker compose logs --since "2024-01-30T10:00:00"

# Between times
docker compose logs --since "2024-01-30T10:00:00" --until "2024-01-30T11:00:00"
```

## Add helpful context

Include timestamps and service details:

```bash
# Add timestamps
docker compose logs -t

# No service name prefix (cleaner output)
docker compose logs --no-log-prefix

# Combine for debugging
docker compose logs -t --tail 50 -f api
```

## Search logs effectively

Find specific errors or patterns:

```bash
# Search for errors
docker compose logs | grep -i error

# Find specific request ID
docker compose logs api | grep "req-12345"

# Count occurrences
docker compose logs | grep -c "connection refused"

# Show context around matches
docker compose logs | grep -B 2 -A 2 "panic"
```

## Monitor multiple services

Split terminal approach:

```bash
# Terminal 1: Frontend logs
docker compose logs -f frontend

# Terminal 2: Backend logs
docker compose logs -f api

# Terminal 3: Database logs
docker compose logs -f postgres
```

## Save logs for analysis

```bash
# Save all logs
docker compose logs > logs.txt

# Save with timestamps
docker compose logs -t > logs-$(date +%Y%m%d).txt

# Service-specific logs
docker compose logs api > api-debug.log
```

## Common debugging patterns

**Application won't start:**
```bash
docker compose logs --tail 100 app | grep -E "error|fatal|panic"
```

**Connection issues:**
```bash
docker compose logs --since 5m | grep -i "connection\|refused\|timeout"
```

**Memory problems:**
```bash
docker compose logs | grep -i "memory\|oom\|heap"
```

## Pro tip

Create log aliases for common tasks:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias dcl='docker compose logs'
alias dclf='docker compose logs -f'
alias dclt='docker compose logs --tail 100'
alias dcle='docker compose logs | grep -i error'

# Usage
dcl api         # Quick logs
dclf web        # Follow web logs
dcle            # Find all errors
```

## Further reading

- [Docker Compose logs reference](https://docs.docker.com/compose/reference/logs/)
- [Docker logging drivers](https://docs.docker.com/config/containers/logging/)