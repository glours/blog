---
title: "Docker Compose Tip #42: Variable substitution and defaults"
date: 2026-03-20T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Use variable substitution with defaults, required values, and error messages in Compose files"
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

Docker Compose supports shell-style variable substitution in your Compose files. Combined with defaults and error messages, it makes your configurations flexible and safe.

## Basic substitution

Reference environment variables or `.env` file values:

```yaml
services:
  app:
    image: myapp:${TAG}
    environment:
      DATABASE_URL: postgres://${DB_USER}:${DB_PASS}@db/${DB_NAME}
```

```bash
# .env
TAG=2.1.0
DB_USER=admin
DB_PASS=secret
DB_NAME=myapp
```

## Default values

Provide fallback values when a variable is unset or empty:

```yaml
services:
  app:
    image: myapp:${TAG:-latest}
    environment:
      LOG_LEVEL: ${LOG_LEVEL:-info}
      PORT: ${PORT:-3000}
    deploy:
      replicas: ${REPLICAS:-1}
```

Two syntaxes with a subtle difference:

```yaml
# ${VAR:-default} - use default if VAR is unset OR empty
image: myapp:${TAG:-latest}

# ${VAR-default} - use default only if VAR is unset (empty string is kept)
image: myapp:${TAG-latest}
```

Most of the time, `:-` (with colon) is what you want.

## Required values with error messages

Force a variable to be set, with a clear error if it's missing:

```yaml
services:
  app:
    image: myapp:${TAG:?TAG must be set to deploy}
    environment:
      DATABASE_URL: ${DATABASE_URL:?Missing DATABASE_URL - check your .env file}
      API_KEY: ${API_KEY:?API_KEY is required}
```

Running without `TAG` set will produce:

```
invalid interpolation format for services.app.image.
required variable TAG is missing a value: TAG must be set to deploy
```

## Combining patterns

Use defaults for development, require values in production:

```yaml
# compose.yml - development defaults
services:
  app:
    image: myapp:${TAG:-latest}
    environment:
      DB_HOST: ${DB_HOST:-localhost}
      DB_PORT: ${DB_PORT:-5432}
      LOG_LEVEL: ${LOG_LEVEL:-debug}

# compose.prod.yml - strict requirements
services:
  app:
    image: myapp:${TAG:?TAG is required for production}
    environment:
      DB_HOST: ${DB_HOST:?DB_HOST must be set}
      DB_PORT: ${DB_PORT:-5432}
      LOG_LEVEL: ${LOG_LEVEL:-warn}
```

## Escaping dollar signs

If you need a literal `$` in your Compose file, use `$$`:

```yaml
services:
  app:
    image: myapp
    environment:
      # Literal dollar sign (not interpolated)
      PRICE: "$$9.99"
    command: /bin/sh -c "echo $$HOME"
```

## Variable substitution scope

Variables are substituted in the Compose file itself, not inside containers. These are different:

```yaml
services:
  app:
    image: myapp
    environment:
      # Substituted by Compose at parse time (from .env or host env)
      DB_HOST: ${DB_HOST:-localhost}

      # NOT substituted by Compose - passed as-is to the container
      PATH: "/usr/local/bin:/usr/bin"
```

## Pro tip

Use `docker compose config` to see the resolved values after substitution:

```bash
# See what Compose resolves
docker compose config

# Check a specific service
docker compose config --format json | jq '.services.app.environment'
```

This is especially useful for debugging when you're not sure which `.env` file or environment variable is being picked up.

When using variables from multiple sources (`.env` file, host environment, `environment` key, `env_file`), keep in mind that Compose follows a specific [precedence order](https://docs.docker.com/compose/how-tos/environment-variables/envvars-precedence/) — host environment variables always override `.env` file values, for example. Check the documentation for the full priority chain.

## Further reading

- [Compose specification: interpolation](https://docs.docker.com/reference/compose-file/interpolation/)
- [Compose environment variables](https://docs.docker.com/compose/how-tos/environment-variables/)
- [Environment variables precedence](https://docs.docker.com/compose/how-tos/environment-variables/envvars-precedence/)
