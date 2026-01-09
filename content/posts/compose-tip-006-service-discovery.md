---
title: "Docker Compose Tip #6: Service discovery and internal DNS"
date: 2026-01-12T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "networking", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How Docker Compose handles service discovery between containers"
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

Hardcoding IP addresses in your containers? Docker Compose provides automatic DNS-based service discovery. Each service can reach another using just the service name.

## How it works

Docker Compose creates a default network and registers each container with an internal DNS server. The DNS name matches the service name in your `compose.yml`.

```yaml
services:
  web:
    image: nginx
    environment:
      # Just use the service name!
      API_URL: http://api:3000
      DB_HOST: postgres

  api:
    image: myapi
    environment:
      DATABASE_URL: postgres://user:pass@postgres:5432/mydb

  postgres:
    image: postgres:15
```

No configuration needed. The `web` service connects to `api` using `http://api:3000`, and `api` connects to `postgres` using the hostname `postgres`.

## Verify DNS resolution

Check what's actually happening:

```bash
# See what IP 'postgres' resolves to
docker compose exec web nslookup postgres
```

Output:
```
Server:    127.0.0.11
Address:   127.0.0.11#53

Name:      postgres
Address:   172.18.0.3
```

Test connectivity:
```bash
docker compose exec web ping -c 2 api
```

## Multiple instances

When scaling, DNS returns all container IPs:

```yaml
services:
  worker:
    image: myworker
    deploy:
      replicas: 3
```

```bash
docker compose up -d --scale worker=3
docker compose exec web nslookup worker
# Returns 3 IP addresses for round-robin
```

## Common gotchas

**Using container names instead of service names:**
```yaml
services:
  web:
    container_name: my-web-container  # Don't use this name for connections!
    # ...
```
Always use the service name (`web`), not the container name.

**Services on different networks:**
Services must be on the same network to resolve each other. By default, Compose creates one network for all services.

## Real production example

Here's how we use this at Docker:

```yaml
services:
  api:
    image: docker/api:latest
    environment:
      # Service names for all connections
      CACHE_URL: redis://cache:6379
      SEARCH_URL: http://search:9200
      METRICS_URL: http://metrics:9090

  cache:
    image: redis:7-alpine

  search:
    image: elasticsearch:8.11

  metrics:
    image: prom/prometheus
```

Each service finds the others by name. When containers restart and get new IPs, the DNS automatically updates.

## Pro tip

For debugging network issues between services:

```bash
# Run a debug container on the same network
docker compose run --rm alpine sh
# Inside the container:
apk add curl bind-tools
nslookup api
curl http://api:3000/health
```

Service discovery through DNS eliminates configuration complexity. No more managing IP addresses or host files - Compose handles it all automatically.

## Further reading

- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [Compose Specification - Networks](https://github.com/compose-spec/compose-spec/blob/master/spec.md#networks)