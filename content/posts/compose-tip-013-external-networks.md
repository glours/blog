---
title: "Docker Compose Tip #13: Using external networks to connect multiple projects"
date: 2026-01-21T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "networking", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to connect containers from different Compose projects using external networks"
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

Need your frontend project to talk to a backend in another Compose project? External networks let you connect containers across different stacks.

## The problem

Two separate Compose projects need to communicate:
- `frontend/compose.yml` - React app
- `backend/compose.yml` - API service

By default, each creates its own isolated network.

## The solution

Create a shared external network:

```bash
# Create the network once
docker network create shared-network
```

Then reference it in both projects:

**backend/compose.yml:**
```yaml
services:
  api:
    image: myapi:latest
    networks:
      - shared  # Connect to external network
      - default # Keep internal network too

networks:
  shared:
    external: true
    name: shared-network
```

**frontend/compose.yml:**
```yaml
services:
  web:
    image: myfrontend:latest
    environment:
      API_URL: http://api:8080  # Use service name!
    networks:
      - shared

networks:
  shared:
    external: true
    name: shared-network
```

Now `web` can reach `api` by name across projects!

## Real microservices example

```yaml
# shared/compose.yml
services:
  postgres:
    image: postgres:15
    networks: [backbone]

  redis:
    image: redis:7-alpine
    networks: [backbone]

networks:
  backbone:
    external: true
    name: company-backbone

---
# api/compose.yml
services:
  api:
    image: company/api:latest
    networks:
      - backbone  # Access shared services
      - internal  # Private network
    environment:
      DATABASE_URL: postgres://postgres:5432/api
      REDIS_URL: redis://redis:6379

networks:
  backbone:
    external: true
    name: company-backbone
  internal: {}  # Project-specific
```

## Service discovery

Services on the same external network can reach each other by name:

```bash
# From frontend container
docker compose -f frontend/compose.yml exec web sh
$ curl http://api:8080/health  # Works!
```

## Hybrid networking

Keep sensitive services isolated:

```yaml
services:
  public-api:
    networks:
      - shared     # External access
      - internal   # Internal only

  database:
    networks:
      - internal   # Not on shared network!

networks:
  shared:
    external: true
    name: shared-network
  internal:
    # Project-specific, isolated
```


## Troubleshooting

```bash
# "Network not found" error? Create it first:
docker network create shared-network

# Can't connect? Verify both services are on same network:
docker network inspect shared-network
```

## Pro tip

Create the external network first, or your stack won't start:

```bash
# Always create before using
docker network create shared-network
docker compose up -d
```

## Further reading

- [Docker networking overview](https://docs.docker.com/network/)
- [Compose networking](https://docs.docker.com/compose/networking/)