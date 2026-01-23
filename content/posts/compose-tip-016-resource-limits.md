---
title: "Docker Compose Tip #16: Setting resource limits with deploy.resources"
date: 2026-01-26T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "performance", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to set CPU and memory limits for containers in Docker Compose"
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

Prevent containers from consuming all available resources. Set CPU and memory limits to ensure stable multi-service deployments.

## The basics

Resource limits protect your system from runaway containers:

```yaml
services:
  api:
    image: node:20
    deploy:
      resources:
        limits:
          cpus: '0.5'     # Half a CPU core
          memory: 512M    # 512 megabytes
        reservations:
          cpus: '0.25'    # Minimum guaranteed
          memory: 256M
```

The container can use up to 512MB memory and 50% of one CPU core.

## Real-world example

Production stack with proper resource allocation:

```yaml
services:
  nginx:
    image: nginx:alpine
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          memory: 128M

  app:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '2.0'     # 2 full cores
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

  postgres:
    image: postgres:15
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          memory: 512M
```

## Monitor resource usage

Check actual resource consumption:

```bash
# Real-time resource usage for all services
docker compose stats

# Monitor specific service
docker compose stats app

# One-time snapshot
docker compose stats --no-stream
```

Output shows:
```
NAME     CPU %   MEM USAGE / LIMIT   MEM %
app      45.2%   892MiB / 2GiB       43.5%
nginx    0.1%    12MiB / 256MiB      4.7%
postgres 12.3%   467MiB / 1GiB       45.6%
```

## Development vs production

Use environment variables for different environments:

```yaml
services:
  app:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '${CPU_LIMIT:-2.0}'
          memory: '${MEMORY_LIMIT:-2G}'
```

```bash
# Development (relaxed limits)
CPU_LIMIT=4.0 MEMORY_LIMIT=4G docker compose up

# Production (strict limits)
CPU_LIMIT=1.0 MEMORY_LIMIT=1G docker compose up
```

## Common issues

**Container killed (exit code 137)**:
```yaml
# Out of memory - increase limit
deploy:
  resources:
    limits:
      memory: 1G  # Was 512M
```

**Slow performance**:
```yaml
# CPU throttling - increase CPU limit
deploy:
  resources:
    limits:
      cpus: '2.0'  # Was 0.5
```

## Pro tip

Test your limits under load before production:

```bash
# Stress test with limited resources
docker compose up -d
docker exec app stress --cpu 4 --vm 2 --vm-bytes 256M --timeout 30s

# Check if limits hold
docker compose stats --no-stream
```

This ensures your limits are realistic for actual workload.

## Further reading

- [Deploy specification](https://docs.docker.com/compose/compose-file/deploy/)
- [Runtime options with Memory, CPUs](https://docs.docker.com/config/containers/resource_constraints/)