---
title: "Docker Compose Tip #47: Sidecar container patterns"
date: 2026-04-01T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "advanced", "architecture"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Use sidecar containers to add capabilities without modifying your main application"
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

A sidecar is a helper container that runs alongside your main application, adding capabilities without modifying the application itself. Compose has specific features to make sidecars work seamlessly.

## Shared network namespace with network_mode

Use `network_mode: service:<name>` to share the network stack with another container, they share the same IP address and can communicate over `localhost`:

```yaml
services:
  app:
    image: myapp
    # No ports needed — proxy handles public traffic

  proxy:
    image: nginx
    network_mode: service:app
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
```

Since both containers share the same network namespace, nginx can proxy to `localhost:3000` without any DNS resolution. The app doesn't need to know about TLS at all, the proxy sidecar handles it.

## Sharing volumes with volumes_from

Use `volumes_from` to mount all volumes from another service, no need to declare shared named volumes manually:

```yaml
services:
  app:
    image: myapp
    volumes:
      - /var/log/app
      - /app/data

  log-forwarder:
    image: fluent/fluent-bit
    volumes_from:
      - app:ro
    depends_on:
      - app
```

The `log-forwarder` gets read-only access to all of `app`'s volumes. This is simpler than declaring named volumes when the sidecar just needs to see everything the main container writes.

## Combining both for a pod-like pattern

Use `network_mode` and `volumes_from` together to create a Kubernetes pod-like setup where containers are tightly coupled:

```yaml
services:
  app:
    image: myapp
    ports:
      - "8080:8080"
    volumes:
      - /var/log/app

  log-shipper:
    image: fluent/fluent-bit
    network_mode: service:app
    volumes_from:
      - app:ro
    depends_on:
      - app
```

The log shipper shares the app's network (can scrape `localhost` metrics endpoints) and filesystem (can read log files) — just like containers in the same Kubernetes pod.

## Sidecar with depends_on and healthcheck

Ensure sidecars wait for the main service to be ready:

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 10s

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter
    environment:
      DATA_SOURCE_NAME: "postgresql://postgres:${DB_PASSWORD}@postgres:5432/postgres?sslmode=disable"
    ports:
      - "9187:9187"
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  db-data:
```

## When to use sidecars

Sidecars are a good fit when:
- You can't or don't want to modify the main application image
- The concern (logging, metrics, debugging) is orthogonal to the app
- You want to reuse the same sidecar across multiple projects
- You need to share network or filesystem context tightly between containers

## Further reading

- [Compose specification: network_mode](https://docs.docker.com/reference/compose-file/services/#network_mode)
- [Compose specification: volumes_from](https://docs.docker.com/reference/compose-file/services/#volumes_from)
- [Compose specification: depends_on](https://docs.docker.com/reference/compose-file/services/#depends_on)
