---
title: "Docker Compose Tip #57: Container resource monitoring"
date: 2026-05-01T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "debugging", "monitoring", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Monitor CPU, memory, and processes in your Compose stack with docker compose top and docker compose stats"
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

A container is running but your app feels sluggish. Is it CPU-bound? Leaking memory? Stuck on a runaway process? Compose gives you two essential commands to find out: `docker compose top` and `docker compose stats`.

## docker compose top

Show running processes inside each service's container:

```bash
docker compose top
```

```
myapp-web-1
UID      PID     PPID    C    STIME   TTY   TIME       CMD
root     12345   12320   0    09:15   ?     00:00:02   nginx: master process
nobody   12400   12345   0    09:15   ?     00:00:00   nginx: worker process

myapp-api-1
UID      PID     PPID    C    STIME   TTY   TIME       CMD
node     12500   12480   2    09:15   ?     00:01:45   node server.js
node     12600   12500   0    09:15   ?     00:00:12   node worker.js
```

You see every process running inside each container with their CPU usage (C column) and CPU time. Perfect for spotting runaway workers or unexpected child processes.

Target a specific service if you don't want the full list:

```bash
docker compose top api
```

## docker compose stats

Real-time CPU, memory, network, and disk I/O for services in your Compose project, scoped automatically to the current project:

```bash
# Live view, updates every second
docker compose stats

# One-shot snapshot instead of live view
docker compose stats --no-stream

# Focus on specific services
docker compose stats api db
```

Output:

```
CONTAINER ID   NAME              CPU %    MEM USAGE / LIMIT     MEM %    NET I/O          BLOCK I/O
a1b2c3d4e5f6   myapp-api-1       45.23%   312.5MiB / 512MiB     61.04%   1.2MB / 3.4MB    0B / 0B
b2c3d4e5f6a7   myapp-web-1       0.12%    8.3MiB / 256MiB       3.24%    524kB / 1.1MB    0B / 0B
c3d4e5f6a7b8   myapp-db-1        2.50%    98.4MiB / 1GiB        9.61%    245kB / 892kB    12MB / 45MB
```

This tells you at a glance which service is hot. In the example above, `api` is using 45% CPU and near its memory limit, a good place to start investigating.

Unlike `docker stats` (which shows every container on the host), `docker compose stats` shows only the containers in your current Compose project, no need to filter manually.

## Custom format

Narrow down to just the columns you care about:

```bash
docker compose stats --no-stream \
  --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemPerc}}"
```

```
NAME            CPU %    MEM %
myapp-api-1     45.23%   61.04%
myapp-web-1     0.12%    3.24%
myapp-db-1      2.50%    9.61%
```

## Combining with resource limits

These monitoring commands pair naturally with [Tip #16 (resource limits)](/posts/compose-tip-016-resource-limits/). Set limits, then watch to see if services are hitting them:

```yaml
services:
  api:
    image: myapp-api
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
```

```bash
# Watch the container approach its limits
docker compose stats api
```

A service consistently at 95%+ of its limits is a hint you need to either raise the limit or optimize the code.

## Quick debugging workflow

When something feels off:

```bash
# 1. See what's running
docker compose ps

# 2. Check resource usage
docker compose stats --no-stream

# 3. Drill into the hot service
docker compose top api

# 4. Check recent events for restarts or OOM kills
docker compose events --since 5m
```

This four-command sequence covers 80% of "my stack feels slow" investigations.

## Further reading

- [Docker Compose CLI: top](https://docs.docker.com/reference/cli/docker/compose/top/)
- [Docker Compose CLI: stats](https://docs.docker.com/reference/cli/docker/compose/stats/)
- Related: [Tip #16, Setting resource limits](/posts/compose-tip-016-resource-limits/)
- Related: [Tip #25, Using docker compose events](/posts/compose-tip-025-events/)
