---
title: "Docker Compose Tip #31: Network isolation between services"
date: 2026-02-23T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "networking", "security", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Isolate services with custom networks for enhanced security"
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

Secure your application architecture by isolating services in separate networks. Not every service needs to talk to every other service!

## Default behavior: All connected

By default, all services share the same network:

```yaml
# All services can communicate
services:
  web:
    image: nginx

  api:
    image: myapi

  database:
    image: postgres
```

Problem: `web` can directly access `database` - potential security risk!

## Network isolation pattern

Create separate networks for different tiers:

```yaml
services:
  # Frontend tier
  web:
    image: nginx
    networks:
      - frontend
      - backend
    depends_on:
      - api

  # Application tier
  api:
    image: myapi
    networks:
      - backend
      - database
    environment:
      DB_HOST: postgres

  # Data tier
  postgres:
    image: postgres
    networks:
      - database
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}

networks:
  frontend:
    name: frontend-network
  backend:
    name: backend-network
  database:
    name: database-network
```

Now:
- `web` can reach `api` (via backend network)
- `api` can reach `postgres` (via database network)
- `web` CANNOT reach `postgres` directly ✅

## Internal networks

Use internal networks to isolate from host network interfaces:

```yaml
services:
  cache:
    image: redis
    networks:
      - internal

  worker:
    image: worker
    networks:
      - internal
      - public

networks:
  internal:
    internal: true  # No connection to host network interfaces
  public:
    # Regular network connected to host
```

The `internal: true` flag creates a network without a connection to the host's network interfaces - it has no default gateway for external connectivity. Containers can still reach the internet if they're also connected to other non-internal networks (like the `worker` service above via the `public` network).

## Service discovery

Services can only discover each other on shared networks:

```yaml
services:
  api1:
    image: api:v1
    networks:
      - api-network
    # Can ping: api2
    # Cannot ping: db1, db2

  api2:
    image: api:v2
    networks:
      - api-network
    # Can ping: api1
    # Cannot ping: db1, db2

  db1:
    image: postgres
    networks:
      - db-network
    # Can ping: db2
    # Cannot ping: api1, api2

  db2:
    image: postgres
    networks:
      - db-network
    # Can ping: db1
    # Cannot ping: api1, api2

networks:
  api-network:
  db-network:
```

## Complete example: Microservices

```yaml
services:
  # Public-facing services
  nginx:
    image: nginx
    ports:
      - "80:80"
    networks:
      - dmz
      - application
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro

  # Application services
  user-service:
    image: user-service
    networks:
      - application
      - user-db

  order-service:
    image: order-service
    networks:
      - application
      - order-db
      - messaging

  # Databases (isolated)
  user-db:
    image: postgres
    networks:
      - user-db
    volumes:
      - user-data:/var/lib/postgresql/data

  order-db:
    image: postgres
    networks:
      - order-db
    volumes:
      - order-data:/var/lib/postgresql/data

  # Message queue
  rabbitmq:
    image: rabbitmq:management
    networks:
      - messaging

  # Monitoring (observes all)
  prometheus:
    image: prom/prometheus
    networks:
      - application
      - user-db
      - order-db
      - messaging
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

networks:
  dmz:
    name: dmz-network
  application:
    name: app-network
  user-db:
    name: user-db-network
    internal: true
  order-db:
    name: order-db-network
    internal: true
  messaging:
    name: messaging-network
    internal: true

volumes:
  user-data:
  order-data:
```

## Pro tip

Use `docker network inspect` to verify isolation:

```bash
# List all networks used by your compose project
docker compose ps --format json | jq -r '.[].Networks | keys[]' | sort -u

# Inspect which services share a network
docker network inspect <network-name> --format '{{json .Containers}}' | jq

# Quick connectivity test between services
docker compose exec web ping api -c 1  # Should work if on same network
docker compose exec web ping postgres -c 1  # Should fail if isolated
```

Defense in depth starts with network segmentation!

## Further reading

- [Docker networking overview](https://docs.docker.com/network/)
- [Compose networking](https://docs.docker.com/compose/networking/)