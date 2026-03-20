---
title: "Docker Compose Tip #43: Read-only root filesystems"
date: 2026-03-23T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "security", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Harden your containers by making the root filesystem read-only"
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

Making a container's root filesystem read-only is one of the simplest and most effective hardening measures. If an attacker gets in, they can't modify binaries or drop malicious files.

## Basic usage

```yaml
services:
  app:
    image: myapp
    read_only: true
```

That's it. The container's filesystem is now immutable. But most applications need to write *somewhere* — logs, temp files, caches. That's where `tmpfs` comes in.

## Read-only with tmpfs for writable directories

Combine `read_only` with `tmpfs` to allow writes only where needed:

```yaml
services:
  app:
    image: myapp
    read_only: true
    tmpfs:
      - /tmp:size=50M
      - /var/run:size=10M
```

A web server typically needs a few writable paths:

```yaml
services:
  nginx:
    image: nginx
    read_only: true
    tmpfs:
      - /tmp
      - /var/cache/nginx
      - /var/run
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
```

## Common writable paths by application

Different applications need different writable directories:

```yaml
services:
  # Node.js application
  node-app:
    image: node:20-slim
    read_only: true
    tmpfs:
      - /tmp

  # Python application
  python-app:
    image: python:3.12-slim
    read_only: true
    tmpfs:
      - /tmp
      - /root/.cache

  # PostgreSQL (data on volume, rest read-only)
  postgres:
    image: postgres:16
    read_only: true
    tmpfs:
      - /tmp
      - /var/run/postgresql
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

## Full hardening pattern

Combine `read_only` with other security options for defense in depth:

```yaml
services:
  web:
    image: dhi.io/nginx:1.28-alpine3.23  # Docker Hardened Image
    read_only: true
    tmpfs:
      - /tmp
      - /var/cache/nginx
      - /var/run
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    ports:
      - "8080:8080"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
```

This combines [Docker Hardened Images](https://docs.docker.com/dhi/) (minimal attack surface, no shell, fewer CVEs), read-only filesystem, capability dropping ([Tip #29](/posts/compose-tip-029-container-capabilities/)), and an unprivileged image that runs as non-root by default — multiple layers of protection.

## Debugging read-only issues

When switching to read-only, you might see errors like:

```
Read-only file system: '/var/log/app.log'
```

Use `docker compose exec` to find which paths need to be writable:

```bash
# Check which files the process tries to write
docker compose exec app find / -writable 2>/dev/null

# Or run with read_only disabled temporarily and monitor writes
docker compose exec app sh -c "inotifywait -mr / 2>&1 | grep -i 'create\|modify'"
```

Then add only those paths as `tmpfs` mounts.

## Further reading

- [Compose specification: read_only](https://docs.docker.com/reference/compose-file/services/#read_only)
- [Docker security best practices](https://docs.docker.com/build/building/best-practices/#security)
