---
title: "Docker Compose Tip #63: Tuning containers with ulimits and shm_size"
date: 2026-05-15T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "performance", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Adjust kernel resource limits and shared memory size for containers that need more than the defaults"
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

CPU and memory limits ([Tip #16](/posts/compose-tip-016-resource-limits/)) cover the obvious resources. Two more options solve specific problems: `ulimits` for kernel limits and `shm_size` for shared memory.

## ulimits: kernel resource limits

`ulimits` controls per-container limits the Linux kernel enforces: open file descriptors, processes, locked memory, and others.

```yaml
services:
  api:
    image: myapi
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
      nproc: 4096
```

`soft` is the default, `hard` is the maximum the process can raise itself to. For most simple cases, set them equal.

You can also use the short form when soft and hard match:

```yaml
ulimits:
  nofile: 65536
  nproc: 4096
```

## When you need higher nofile

The default `nofile` limit (often 1024) is fine for most apps but breaks high-concurrency servers. Symptoms:

- `Too many open files` errors
- Connections randomly dropped under load
- nginx, HAProxy, or Node.js servers refusing new connections at the limit

```yaml
services:
  nginx:
    image: nginx
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    ports:
      - "80:80"
```

## shm_size: shared memory

`/dev/shm` is a tmpfs used for inter-process shared memory. Default is 64MB, which trips up several common workloads.

```yaml
services:
  app:
    image: myapp
    shm_size: 256mb
```

Accepts `b`, `k`, `m`, `g` suffixes (e.g., `256mb`, `2gb`).

## When you need bigger shm

Three classic cases:

**Chrome / Puppeteer**: each tab uses shared memory; Chrome crashes with the default 64MB.

```yaml
services:
  scraper:
    image: chrome-headless
    shm_size: 2gb
```

**PyTorch DataLoader workers**: workers use shared memory to pass tensors. Default fails with `RuntimeError: DataLoader worker (pid X) is killed by signal: Bus error`.

```yaml
services:
  training:
    image: pytorch/pytorch
    shm_size: 8gb
```

**Databases with shared buffers**: PostgreSQL on heavy workloads benefits from larger shm.

```yaml
services:
  postgres:
    image: postgres:16
    shm_size: 1gb
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
```

## A combined example

A Puppeteer-based scraper with all the right limits:

```yaml
services:
  scraper:
    image: chrome-headless
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    shm_size: 2gb
    deploy:
      resources:
        limits:
          cpus: "2.0"
          memory: 4G
```

CPU and memory limits cap the resources Docker hands out. `ulimits` and `shm_size` configure how the container uses them internally. You typically need both.

## Debugging

Check the limits actually applied:

```bash
# File descriptor limit inside the container
docker compose exec scraper sh -c "ulimit -n"

# /dev/shm size
docker compose exec scraper df -h /dev/shm
```

If your settings don't show up, the host kernel may impose stricter caps that override container requests.

## Further reading

- [Compose specification: ulimits](https://docs.docker.com/reference/compose-file/services/#ulimits)
- [Compose specification: shm_size](https://docs.docker.com/reference/compose-file/services/#shm_size)
- Related: [Tip #16, Setting resource limits with deploy.resources](/posts/compose-tip-016-resource-limits/)
