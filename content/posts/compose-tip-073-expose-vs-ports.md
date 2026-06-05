---
title: "Docker Compose Tip #73: expose vs ports — what actually gets published"
date: 2026-06-08T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "networking", "security", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Understand the difference between expose and ports in Compose: one documents intent, the other actually publishes a port to the host."
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

Two directives that look similar but do completely different things. Confusing `expose` with `ports` is a classic way to either break inter-service communication or accidentally publish a database to the public internet.

## What each one does

`ports` publishes a container port to the host. The outside world (and anything on the host) can reach it.

```yaml
services:
  web:
    image: nginx
    ports:
      - "8080:80"     # host:container
```

`expose` declares that a container listens on a port. It does **not** publish anything to the host. The directive is documentation of intent for tooling and humans.

```yaml
services:
  db:
    image: postgres:16
    expose:
      - "5432"
```

The Postgres container listens on `5432`. Other services on the same Compose network can reach it as `db:5432`. The host cannot.

## Inter-service traffic does not need `expose`

A common misconception: `expose` is required for services to talk to each other. It is not. Two services on the same network reach each other on any port the listener is actually bound to, whether or not `expose` is set.

```yaml
services:
  api:
    image: my-api    # listens on 3000

  worker:
    image: my-worker
    environment:
      API_URL: http://api:3000    # works, even without `expose: [3000]`
```

Use `expose` for *documentation*: making it explicit which ports are part of the service contract.

## Short vs long syntax for `ports`

The short syntax covers most cases:

```yaml
ports:
  - "8080:80"          # host:container, TCP
  - "127.0.0.1:8080:80"  # bind to localhost only
  - "8080:80/udp"      # UDP
```

The long syntax exposes the full set of options:

```yaml
ports:
  - target: 80
    published: "8080"
    protocol: tcp
    mode: host
    app_protocol: http
```

- `target`: container port (required)
- `published`: host port (omit to let Docker pick one)
- `protocol`: `tcp` (default) or `udp`
- `mode`: `ingress` (default, load-balanced when in swarm) or `host` (bypass routing mesh)
- `app_protocol`: a hint for tools (e.g., `http`, `grpc`)

## The security angle

`ports: "5432:5432"` on a database service is a frequent footgun. With a default Docker daemon, this binds to `0.0.0.0:5432` — reachable from anywhere the host is. Many cloud VMs end up with their database accidentally on the internet this way.

Two safer patterns:

```yaml
# 1. Don't publish at all. Other services reach it on the network.
services:
  db:
    image: postgres:16
    expose:
      - "5432"
```

```yaml
# 2. Publish only to localhost.
services:
  db:
    image: postgres:16
    ports:
      - "127.0.0.1:5432:5432"
```

The first pattern is the default for any service that does not need to be reached from outside the Compose stack.

## And what about `EXPOSE` in the Dockerfile?

A `Dockerfile` `EXPOSE 80` does the same job as `expose: ["80"]` in Compose: it documents the listening port. If the image already declares `EXPOSE`, repeating it in Compose is redundant. Neither makes the port reachable from the host.

## Pro tip: use `expose` as a contract

Treat `expose` as the service's public contract on the Compose network. Reviewers can scan a `compose.yaml` and immediately know which ports each service intends to be reached on. Tools that read Compose files — service meshes, manifest generators, the Compose Bridge transformers ([#70](/posts/compose-bridge-deep-dive-070-introduction/)) — can rely on that intent.

## Further reading

- [Compose specification: ports](https://docs.docker.com/reference/compose-file/services/#ports)
- [Compose specification: expose](https://docs.docker.com/reference/compose-file/services/#expose)
- Related: [Bridge vs host networking](/posts/compose-tip-021-bridge-vs-host/)
- Related: [Service discovery and internal DNS](/posts/compose-tip-006-service-discovery/)
