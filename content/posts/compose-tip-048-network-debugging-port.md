---
title: "Docker Compose Tip #48: Network debugging with docker compose port"
date: 2026-04-03T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "debugging", "networking", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Find out which host port maps to a container port with docker compose port"
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

When using dynamic port mapping or multiple services, it's not always obvious which host port maps to which container port. `docker compose port` tells you exactly.

## Basic usage

```bash
# Which host port maps to container port 80 on the web service?
docker compose port web 80
# Output: 0.0.0.0:8080
```

## Why dynamic ports matter

When you let Docker assign ports automatically, the host port changes on every `docker compose up`:

```yaml
services:
  web:
    image: nginx
    ports:
      - "80"   # Dynamic host port, container port 80
```

```bash
docker compose port web 80
# Output: 0.0.0.0:55432  (assigned dynamically)
```

This is common in CI or when running multiple instances of the same project.

## Scaled services with --index

When you scale a service, each replica gets its own dynamic port. Use `--index` to query a specific replica:

```yaml
services:
  web:
    image: nginx
    ports:
      - "80"   # Dynamic host port for each replica
```

```bash
# Scale to 3 replicas
docker compose up -d --scale web=3

# Get the port for each replica
docker compose port --index=1 web 80
# Output: 0.0.0.0:55001

docker compose port --index=2 web 80
# Output: 0.0.0.0:55002

docker compose port --index=3 web 80
# Output: 0.0.0.0:55003
```

Without `--index`, the command returns the port for the first replica.

## Specifying protocol

By default, `docker compose port` looks for TCP mappings. If a service exposes both TCP and UDP on the same port, use `--protocol` to pick the right one:

```bash
# TCP (default)
docker compose port myservice 53

# UDP
docker compose port --protocol=udp myservice 53
```

## Combining with other debug commands

`docker compose port` is one of several useful commands for network debugging:

```bash
# List all port mappings for all services
docker compose ps --format "table {{.Name}}\t{{.Ports}}"

# Get port mappings as JSON for a specific service
docker compose ps web --format json | jq '.[].Ports'

# Check connectivity from one container to another
docker compose exec app wget -qO- http://web:80/health
```

## Further reading

- [Docker Compose CLI: port](https://docs.docker.com/reference/cli/docker/compose/port/)
- [Compose specification: ports](https://docs.docker.com/reference/compose-file/services/#ports)
