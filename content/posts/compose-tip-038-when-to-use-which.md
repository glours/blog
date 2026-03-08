---
title: "Docker Compose Tip #38: When to use include vs extends vs overrides"
date: 2026-03-11T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "A practical guide to choosing the right Compose configuration mechanism for each situation"
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

Now that you understand how `include`, `extends`, and override files work, how do you pick the right one? Here's a practical guide.

## Use override files for environment-specific configuration

Override files are the right choice when you need to adapt the same stack to different environments or developer setups:

```yaml
# compose.yml - base definition, committed to git
services:
  app:
    image: myapp:${TAG:-latest}
    environment:
      NODE_ENV: production

# compose.override.yml - local dev tweaks, optionally gitignored
services:
  app:
    build: .           # Build locally instead of pulling image
    environment:
      NODE_ENV: development
    volumes:
      - .:/app         # Mount source for hot reload
```

Good fit for:
- Dev vs prod differences (volumes, build vs image, ports)
- Local developer customizations that shouldn't be committed
- CI-specific overrides (no volumes, specific image tags)

## Use extends for shared service configuration

`extends` shines when multiple services share a common base configuration and you want a single source of truth:

```yaml
# base.yml
services:
  service-base:
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    labels:
      com.company.env: ${ENV:-dev}
      com.company.version: ${VERSION}

# compose.yml
services:
  api:
    extends:
      file: base.yml
      service: service-base
    image: myapp-api

  worker:
    extends:
      file: base.yml
      service: service-base
    image: myapp-worker
```

Good fit for:
- Common restart policies, logging, labels across services
- Shared resource limits or security options
- Base image variants (e.g., a debug version extending a production service)

## Use include for reusable service groups

`include` is the right choice when you have a self-contained group of services that you want to treat as a unit and potentially reuse across multiple projects:

```yaml
# compose.yml
include:
  - path: ./infra/observability.yml   # Prometheus + Grafana stack
  - path: ./infra/database.yml        # Postgres + migrations

services:
  app:
    image: myapp
    depends_on:
      - postgres
      - prometheus
```

Good fit for:
- Shared infrastructure stacks (monitoring, databases, message queues)
- Team-maintained service libraries reused across projects
- Keeping a large compose file split into logical modules

## Quick decision guide

```
Need to adapt existing services per environment?
  → Override files

Multiple services sharing the same base config?
  → extends

Importing a self-contained group of services?
  → include
```

## Further reading

- [Compose documentation: Multiple Compose files](https://docs.docker.com/compose/how-tos/multiple-compose-files/)
- [Watch: Managing multiple Compose files](https://www.youtube.com/watch?v=VOyyGX1MOU0&list=PLkA60AVN3hh_t73mQG7RIvvMRTpm1ompt&index=52) - real-world examples for each approach
