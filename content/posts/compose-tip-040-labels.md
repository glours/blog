---
title: "Docker Compose Tip #40: Using labels for service organization and monitoring"
date: 2026-03-16T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "monitoring", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Organize, filter, and integrate services with labels"
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

Labels are key-value metadata attached to containers. They cost nothing at runtime but unlock powerful filtering, organization, and tool integrations.

## Adding labels to services

```yaml
services:
  api:
    image: myapp-api
    labels:
      com.example.team: "backend"
      com.example.env: "production"
      com.example.version: "2.1.0"

  worker:
    image: myapp-worker
    labels:
      com.example.team: "backend"
      com.example.env: "production"
      com.example.role: "async-processing"
```

You can also use the list syntax:

```yaml
services:
  api:
    image: myapp-api
    labels:
      - "com.example.team=backend"
      - "com.example.env=production"
```

## Filtering with labels

Labels become powerful with `docker compose ps`:

```bash
# Find all containers from the backend team
docker compose ps --filter "label=com.example.team=backend"

# Find all production containers
docker compose ps --filter "label=com.example.env=production"

# Combine filters
docker compose ps --filter "label=com.example.team=backend" --filter "label=com.example.env=production"
```

## Traefik integration

Traefik uses labels for automatic routing configuration:

```yaml
services:
  web:
    image: myapp
    labels:
      traefik.enable: "true"
      traefik.http.routers.web.rule: "Host(`app.example.com`)"
      traefik.http.routers.web.tls: "true"
      traefik.http.services.web.loadbalancer.server.port: "3000"

  traefik:
    image: traefik:v3
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

## Prometheus integration

Prometheus can discover targets using container labels:

```yaml
services:
  api:
    image: myapp-api
    labels:
      prometheus.scrape: "true"
      prometheus.port: "9090"
      prometheus.path: "/metrics"

  worker:
    image: myapp-worker
    labels:
      prometheus.scrape: "true"
      prometheus.port: "9091"
```

## Organization patterns

Use a consistent naming convention across your team:

```yaml
services:
  api:
    image: myapp-api
    labels:
      # Ownership
      com.example.team: "platform"
      com.example.contact: "platform-team@example.com"

      # Environment
      com.example.env: "${ENV:-dev}"
      com.example.version: "${VERSION:-latest}"

      # Operational
      com.example.backup: "true"
      com.example.log-level: "info"
```

## Pro tip

Labels on containers are different from labels on networks and volumes:

```yaml
services:
  app:
    image: myapp
    labels:
      app.tier: "frontend"     # Container label

networks:
  frontend:
    labels:
      network.purpose: "public-facing"  # Network label

volumes:
  data:
    labels:
      volume.backup: "daily"   # Volume label
```

Each resource type has its own labels, and you can filter each independently.

## Further reading

- [Compose specification: labels](https://docs.docker.com/reference/compose-file/services/#labels)
- [Docker object labels](https://docs.docker.com/engine/manage-resources/labels/)
