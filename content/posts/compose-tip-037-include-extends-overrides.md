---
title: "Docker Compose Tip #37: Understanding include, extends, and override files"
date: 2026-03-09T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Three different mechanisms to split and reuse Compose configurations, each working very differently"
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

Docker Compose gives you three ways to split and reuse configurations. They look similar but work at different levels and serve different purposes.

## Override files: project-level merge

Override files are merged with your main `compose.yml` at the project level. `compose.override.yml` is loaded automatically; additional files require the `-f` flag:

```bash
# compose.override.yml is loaded automatically
docker compose up

# Explicit merge
docker compose -f compose.yml -f compose.prod.yml up
```

Mappings are merged (override wins), arrays are concatenated:

```yaml
# compose.yml
services:
  app:
    image: myapp
    environment:
      LOG_LEVEL: debug
    ports:
      - "3000:3000"

# compose.override.yml
services:
  app:
    environment:
      LOG_LEVEL: info   # Overrides debug
    ports:
      - "9229:9229"     # Appended, not replaced
```

Result: `app` gets `LOG_LEVEL=info` and both ports exposed.

## extends: service-level inheritance

`extends` lets a service inherit configuration from another service definition, in the same file or another file:

```yaml
# base.yml
services:
  base:
    image: myapp
    environment:
      LOG_FORMAT: json
      METRICS_ENABLED: "true"
    labels:
      com.company.team: platform

# compose.yml
services:
  api:
    extends:
      file: base.yml
      service: base
    environment:
      PORT: "8080"    # Added on top of inherited env vars

  worker:
    extends:
      file: base.yml
      service: base
    environment:
      PORT: "8081"
```

`api` and `worker` both get the base environment and labels, each adding their own `PORT`.

> **Note:** `extends` does not inherit `depends_on`, `links`, or `volumes_from` — you need to redeclare those in each service.

## include: isolated sub-projects

`include` pulls in another Compose file as a self-contained unit. Unlike override files, the included file is parsed in isolation with its own working directory and its own `.env` file:

```yaml
# compose.yml
include:
  - path: ./monitoring/compose.yml
  - path: ./database/compose.yml

services:
  app:
    image: myapp
    depends_on:
      - postgres   # Service defined in database/compose.yml
```

The included file's services are merged into the project, but the included file cannot see or override services in the parent. It's a one-way import.

## Key differences at a glance

| Mechanism | Scope | Context |
|-----------|-------|---------|
| Override files | Project (all services) | Shared |
| `extends` | Single service | Shared |
| `include` | Full sub-project | Isolated |

## Further reading

- [Compose documentation: Merge and override](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/)
- [Compose documentation: extend](https://docs.docker.com/compose/how-tos/multiple-compose-files/extends/)
- [Compose documentation: include](https://docs.docker.com/compose/how-tos/multiple-compose-files/include/)
- [Watch: Managing multiple Compose files](https://www.youtube.com/watch?v=VOyyGX1MOU0&list=PLkA60AVN3hh_t73mQG7RIvvMRTpm1ompt&index=52) - a deep dive into all three approaches
