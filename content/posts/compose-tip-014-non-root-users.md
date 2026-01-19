---
title: "Docker Compose Tip #14: Running containers as non-root users"
date: 2026-01-22T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "security", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to run containers with non-root users for improved security"
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

Running containers as root is a security risk. Configure your services to use non-root users for defense in depth.

## The problem

By default, many containers run as root:

```yaml
services:
  app:
    image: nginx
    # Runs as root user (uid 0) - security risk!
```

If compromised, attackers have root privileges inside the container.

## The solution

Set the user in compose.yml:

```yaml
services:
  app:
    image: node:20
    user: "1000:1000"  # Run as uid:gid 1000
    working_dir: /app
    volumes:
      - ./app:/app
```

Or use the image's built-in user:

```yaml
services:
  nginx:
    image: nginx:alpine
    user: "nginx"  # Use nginx user from image
```

## Creating users in Dockerfile

Best practice: create a dedicated user in your image:

```dockerfile
FROM node:20-alpine

# Create app user and group
RUN addgroup -g 1001 -S appuser && \
    adduser -u 1001 -S appuser -G appuser

# Create app directory with correct ownership
RUN mkdir -p /app && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

WORKDIR /app
COPY --chown=appuser:appuser package*.json ./
RUN npm ci --only=production
COPY --chown=appuser:appuser . .

CMD ["node", "server.js"]
```

Use it in compose.yml:

```yaml
services:
  api:
    build: .
    # Already runs as appuser from Dockerfile
    ports:
      - "3000:3000"
```

## Handling file permissions

When using volumes with non-root users:

```yaml
services:
  app:
    image: node:20
    user: "1000:1000"
    volumes:
      - ./data:/data  # Must be writable by uid 1000
    # Fix permissions on startup
    entrypoint: |
      sh -c 'chown -R 1000:1000 /data 2>/dev/null || true && npm start'
```

Better approach - use init container:

```yaml
services:
  # Fix permissions before app starts
  init-permissions:
    image: busybox
    user: root
    volumes:
      - ./data:/data
    command: chown -R 1000:1000 /data

  app:
    image: node:20
    user: "1000:1000"
    volumes:
      - ./data:/data
    depends_on:
      init-permissions:
        condition: service_completed_successfully
```

## Common issues and solutions

**Port binding below 1024:**
```yaml
services:
  web:
    image: nginx
    user: "nginx"
    ports:
      - "8080:8080"  # Use high ports for non-root
    # Configure nginx to listen on 8080 instead of 80
```

**Reading secrets:**
```yaml
services:
  app:
    image: myapp
    user: "1000:1000"
    secrets:
      - source: db_password
        uid: "1000"  # Make secret readable by user
        mode: 0400

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

## Verify user

Check which user is running:

```bash
docker compose exec app whoami
# Should output: appuser (not root)

docker compose exec app id
# uid=1000(appuser) gid=1000(appuser)
```

## Further reading

- [Docker security best practices](https://docs.docker.com/develop/security-best-practices/)
- [USER instruction in Dockerfile](https://docs.docker.com/engine/reference/builder/#user)