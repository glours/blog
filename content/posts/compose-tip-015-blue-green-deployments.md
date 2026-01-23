---
title: "Docker Compose Tip #15: Blue-green deployments with Traefik"
date: 2026-01-23T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "deployment", "traefik", "advanced"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to implement zero-downtime blue-green deployments with Docker Compose and Traefik"
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

Deploy with zero downtime using Traefik's dynamic routing. Switch traffic between blue and green deployments by updating environment variables, with automatic health checks.

## The setup

Traefik automatically discovers services and routes traffic based on labels:

```yaml
# compose.yml
services:
  traefik:
    image: traefik:v3.0
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
    ports:
      - "80:80"
      - "8080:8080"  # Traefik dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - web

  app-blue:
    image: myapp:${BLUE_VERSION:-v1.0}
    labels:
      - "traefik.enable=${BLUE_ENABLED:-true}"
      - "traefik.http.routers.app-blue.rule=Host(`app.localhost`)"
      - "traefik.http.routers.app-blue.priority=1"
      - "traefik.http.services.app-blue.loadbalancer.server.port=3000"
    networks:
      - web
    environment:
      VERSION: blue

  app-green:
    image: myapp:${GREEN_VERSION:-v2.0}
    labels:
      - "traefik.enable=${GREEN_ENABLED:-false}"  # Start disabled
      - "traefik.http.routers.app-green.rule=Host(`app.localhost`)"
      - "traefik.http.routers.app-green.priority=2"  # Higher priority when enabled
      - "traefik.http.services.app-green.loadbalancer.server.port=3000"
    networks:
      - web
    environment:
      VERSION: green

networks:
  web:
    driver: bridge
```

## Deployment workflow

Switch traffic by recreating containers with updated labels:

```bash
# 1. Deploy with blue active
docker compose up -d

# 2. Update green to new version
GREEN_VERSION=v2.0 docker compose up -d app-green

# 3. Switch traffic to green (recreate with new labels)
BLUE_ENABLED=false GREEN_ENABLED=true docker compose up -d

# Traefik detects the change and switches routing instantly!
```

For this to work, update your compose file:
```yaml
services:
  app-blue:
    labels:
      - "traefik.enable=${BLUE_ENABLED:-true}"

  app-green:
    labels:
      - "traefik.enable=${GREEN_ENABLED:-false}"
```

## Weighted canary deployment

Gradually shift traffic from blue to green:

```yaml
services:
  app-blue:
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.app.loadbalancer.server.port=3000"
      - "traefik.http.services.app.loadbalancer.sticky=true"
      - "traefik.http.services.app.loadbalancer.weight=90"  # 90% traffic

  app-green:
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.app.loadbalancer.server.port=3000"
      - "traefik.http.services.app.loadbalancer.weight=10"  # 10% traffic
```

Adjust weights to gradually migrate:
```bash
# Shift to 50/50
BLUE_WEIGHT=50 GREEN_WEIGHT=50 docker compose up -d

# Full migration to green
BLUE_WEIGHT=0 GREEN_WEIGHT=100 docker compose up -d
```

Update your compose file to use variables:
```yaml
services:
  app-blue:
    labels:
      - "traefik.http.services.app.loadbalancer.weight=${BLUE_WEIGHT:-90}"
  app-green:
    labels:
      - "traefik.http.services.app.loadbalancer.weight=${GREEN_WEIGHT:-10}"
```

## Health-check based routing

Traefik only routes to healthy services:

```yaml
services:
  app-green:
    image: myapp:v2.0
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 10s
      timeout: 3s
      retries: 3
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.app-green.loadbalancer.healthcheck.path=/health"
      - "traefik.http.services.app-green.loadbalancer.healthcheck.interval=10s"
```

## Instant rollback

```bash
# Revert to blue immediately
BLUE_ENABLED=true GREEN_ENABLED=false docker compose up -d

# Containers recreate quickly and Traefik switches routing!
```

## Pro tip

Monitor deployments via Traefik dashboard at http://localhost:8080. You can see:
- Active services and their health
- Current routing rules
- Real-time traffic distribution
- Response times and error rates

## Further reading

- [Traefik Docker provider](https://doc.traefik.io/traefik/providers/docker/)
- [Docker Compose profiles](https://docs.docker.com/compose/profiles/)