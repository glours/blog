---
title: "Docker Compose Tip #62: Network aliases for service routing"
date: 2026-05-13T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "networking", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Give a service multiple hostnames on a network with aliases, useful for migrations and legacy hostnames"
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

By default, services in Compose are reachable by their service name. With `aliases`, you can give a service additional hostnames on a network, no extra DNS config required.

## Basic usage

Add aliases under the network attachment:

```yaml
services:
  primary:
    image: postgres
    networks:
      app-net:
        aliases:
          - db
          - database
          - postgres-primary

networks:
  app-net:
```

From any other container on `app-net`, you can reach the service as `primary`, `db`, `database`, or `postgres-primary`. All four hostnames resolve to the same container.

## Why this is useful

The most common use case is migrating from one service name to another without breaking existing clients:

```yaml
services:
  # New name, but old clients still expect "auth-service"
  identity:
    image: identity:v2
    networks:
      app-net:
        aliases:
          - auth-service   # Old name kept as alias
```

Existing services hardcoded to `auth-service` keep working while new services use the cleaner `identity` name. You can drop the alias once everything is migrated.

## Aliases per network

A service connected to multiple networks can have different aliases on each:

```yaml
services:
  api:
    image: myapi
    networks:
      public:
        aliases:
          - api.example.com
          - www.api.example.com
      internal:
        aliases:
          - api-internal
          - backend

networks:
  public:
  internal:
```

External traffic on `public` reaches the API via its public hostnames, while internal services on `internal` use shorter, internal-only names.

## Service discovery patterns

Aliases shine when implementing routing patterns:

```yaml
services:
  # Multiple replicas pretending to be different services
  worker-image:
    image: worker
    networks:
      app-net:
        aliases:
          - email-worker
          - notification-worker
          - queue-worker

  scheduler:
    image: scheduler
    networks:
      - app-net
    # Can route to different "worker" types via different aliases
    environment:
      EMAIL_WORKER: email-worker
      NOTIFICATION_WORKER: notification-worker
```

The same image serves all three worker roles, but the scheduler addresses them by purpose-specific names.

## Aliases vs extra_hosts

These two are easy to confuse:

- **`aliases`** ([Tip #62, this one]): adds hostnames *for a service* that other containers can reach. Same network, multiple names.
- **`extra_hosts`** ([Tip #36](/posts/compose-tip-036-extra-hosts/)): adds entries to a container's `/etc/hosts` for *external* hostnames. Different containers, custom DNS entries.

Use `aliases` for in-network service routing. Use `extra_hosts` when you need to resolve external hostnames or override DNS.

## Pro tip

Combine aliases with [profiles (Tip #24)](/posts/compose-tip-024-profiles/) to swap implementations:

```yaml
services:
  postgres-real:
    image: postgres
    profiles: ["prod"]
    networks:
      app-net:
        aliases:
          - postgres

  postgres-mock:
    image: mock-postgres
    profiles: ["test"]
    networks:
      app-net:
        aliases:
          - postgres
```

Apps connect to `postgres` and get the real DB in prod or the mock in test, with no code changes.

## Further reading

- [Compose specification: aliases](https://docs.docker.com/reference/compose-file/services/#aliases)
- Related: [Tip #36, Using extra_hosts for custom DNS entries](/posts/compose-tip-036-extra-hosts/)
- Related: [Tip #6, Service discovery and internal DNS](/posts/compose-tip-006-service-discovery/)
