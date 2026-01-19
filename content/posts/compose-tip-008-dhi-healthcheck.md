---
title: "Docker Compose Tip #8: Healthchecks with Docker Hardened Images"
date: 2026-01-14T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "security", "healthcheck", "advanced"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to add healthchecks using sidecar pattern with Docker Hardened Images"
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

Docker Hardened Images (DHI) maximize security by removing shells and package managers. But how do you add healthchecks? Use a secure sidecar with shared network namespace.

## The problem

Your hardened Node.js application:
```yaml
services:
  app:
    image: dhi.io/node:25-debian13-sfw-ent-dev
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      # FAILS: No curl in hardened image!
```

## The solution: Network namespace sidecar

Use a hardened curl image that shares the app's network:

```yaml
services:
  app:
    image: dhi.io/node:25-debian13-sfw-ent-dev
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production

  app-health:
    image: dhi.io/curl:8-debian13-dev
    entrypoint: ["sleep", "infinity"]
    network_mode: "service:app"  # Shares app's network namespace!
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s
```

The `network_mode: "service:app"` allows the sidecar to access `localhost:3000` directly - they share the same network stack!

## How it works

1. Main app runs with DHI Node.js image (no shell, minimal attack surface)
2. Sidecar runs with DHI curl image sharing the app's network namespace
3. Sidecar can reach app on `localhost` (same network stack)
4. Other services depend on the app itself or app-health

## Real production example

A real example with a secure Node.js image:

```yaml
services:
  # API using hardened Node.js
  api:
    image: dhi.io/node:25-debian13-sfw-ent-dev
    ports:
      - "8080:8080"
    environment:
      NODE_ENV: production
      PORT: 8080

  # Hardened curl sidecar for healthchecks
  api-health:
    image: dhi.io/curl:8-debian13-dev
    network_mode: "service:api"  # Critical: shares api's network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/healthz"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 45s
    entrypoint: ["sleep", "infinity"]  
    deploy:
      resources:
        limits:
          memory: 32M  # Minimal resource usage

  # Worker depends on API being healthy
  worker:
    image: dhi.io/node:25-debian13-sfw-ent-dev
    depends_on:
      api-health:
        condition: service_healthy
    environment:
      API_URL: http://api:8080  # Uses service name for cross-container
```

## Verify health status

```bash
docker compose ps
```

Output shows both containers:
```
NAME           STATUS                    PORTS
api            Up 5 minutes              0.0.0.0:8080->8080/tcp
api-health     Up 5 minutes (healthy)
worker         Up 4 minutes
```

Check the network namespace:
```bash
# Both containers share the same network
docker compose exec api-health curl http://localhost:8080/healthz
# Works! They share the network stack
```

## Multiple services pattern

Scale this pattern for multiple services:

```yaml
services:
  frontend:
    image: dhi.io/node:25-debian13-sfw-ent-dev
    ports:
      - "3000:3000"

  frontend-health:
    image: dhi.io/curl:8-debian13-dev
    network_mode: "service:frontend"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/"]

  backend:
    image: dhi.io/node:25-debian13-sfw-ent-dev
    ports:
      - "8080:8080"

  backend-health:
    image: dhi.io/curl:8-debian13-dev
    network_mode: "service:backend"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/health"]

  # Services that need everything healthy
  e2e-tests:
    image: test-runner
    depends_on:
      frontend-health:
        condition: service_healthy
      backend-health:
        condition: service_healthy
```

## Why `network_mode` matters

With `network_mode: "service:app"`:
- Sidecar sees the same network as app
- Can use `localhost` to reach app's ports
- No inter-container networking needed
- Perfect isolation from other services

Without it:
- Would need to use service names
- Requires app to bind to 0.0.0.0 (not just localhost)
- Less secure network isolation

## Security benefits

- **Zero shell access** in production containers
- **No package managers** to exploit
- **Minimal attack surface** - only required binaries
- **Network isolation** - sidecar only sees app's network
- **DHI throughout** - even healthcheck containers are hardened

Maximum security with full observability - DHI sidecars with shared networking.

## Further reading

- [Docker Hardened Images](https://hub.docker.com/hardened-images/catalog)
- [Docker Compose networking](https://docs.docker.com/compose/networking/)
- Related tip: [Service dependencies with health checks](/posts/compose-tip-003-depends-on-healthcheck/)