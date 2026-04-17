---
title: "Docker Compose Tip #55: docker compose config advanced usage"
date: 2026-04-27T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "debugging", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Go beyond validation with docker compose config, list services, hash, resolve digests, and filter output"
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

Most people know `docker compose config` as "the validate command". It's much more than that. The same command can list resources, output JSON, hash services for change detection, and pin image digests for reproducibility.

## Listing resources

Ask Compose what's actually in your project, after all overrides and interpolation:

```bash
# List all services
docker compose config --services

# List all volumes
docker compose config --volumes

# List all images used
docker compose config --images

# List all defined profiles
docker compose config --profiles
```

These are great in scripts when you need to loop over each service:

```bash
for svc in $(docker compose config --services); do
  echo "=== Logs for $svc ==="
  docker compose logs "$svc" | tail -20
done
```

## Filtering to a specific service

Show only the resolved configuration for one service:

```bash
docker compose config web
```

Useful when your Compose file is large and you only care about one piece.

## Output formats

By default the resolved configuration comes back as YAML. Switch to JSON for programmatic use:

```bash
# Default YAML
docker compose config

# JSON for jq and friends
docker compose config --format json

# Extract just the environment of a service
docker compose config --format json | jq '.services.web.environment'
```

## Hashing for change detection

`--hash` gives you a reproducible hash of a service's configuration. Perfect for CI caching or detecting whether a service needs to be rebuilt:

```bash
# Hash every service
docker compose config --hash='*'
# web: 8f4e2a1b...
# db:  3c7d9e5f...

# Hash specific services
docker compose config --hash=web,api
```

If the hash doesn't change, the service configuration is identical and you can skip expensive operations like rebuilding.

## Pinning image digests

`--resolve-image-digests` replaces image tags with their current digests:

```yaml
# Input: compose.yml
services:
  web:
    image: nginx:latest
```

```bash
docker compose config --resolve-image-digests
```

```yaml
# Output
services:
  web:
    image: nginx:latest@sha256:a1b2c3...
```

Great for generating a production-ready, reproducible version of your Compose file.

## Raw vs resolved

By default, Compose interpolates all `${VAR}` references. Sometimes you want to see the file *before* substitution:

```bash
# Resolved (default)
docker compose config

# Raw, no interpolation
docker compose config --no-interpolate
```

This helps debug which variables are being substituted vs left as-is.

## Combining with other commands

Pipe the resolved config to other tools:

```bash
# Save a resolved copy for production
docker compose config --resolve-image-digests > compose.resolved.yml

# Validate environment without starting services
docker compose config > /dev/null && echo "Config OK"

# See the full rendered config with overrides applied
docker compose -f compose.yml -f compose.prod.yml config
```

## Further reading

- [Docker Compose CLI: config](https://docs.docker.com/reference/cli/docker/compose/config/)
- Related: [Tip #1, Debug your configuration with config](/posts/compose-tip-001-validate-config/)
