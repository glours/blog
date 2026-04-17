---
title: "Docker Compose Tip #56: env_file advanced patterns"
date: 2026-04-29T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Go beyond a single .env file, multiple files, optional loading, formats, and precedence rules"
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

The `env_file` key looks simple but has surprisingly rich behavior, you can load multiple files, mark some as optional, and control how they're parsed.

## The two flavors of .env

There are two completely different things called ".env" in Compose:

- **The project `.env` file** at the same level as `compose.yml`, used for **interpolation** of `${VAR}` in the Compose file itself (see [Tip #42](/posts/compose-tip-042-variable-substitution/))
- **`env_file:` at service level**, loaded as **runtime environment variables** inside the container

This post is about the second one.

## Single file (basic form)

```yaml
services:
  app:
    image: myapp
    env_file: .env.app
```

```ini
# .env.app
DATABASE_URL=postgres://db:5432/mydb
LOG_LEVEL=info
```

All key-value pairs end up as environment variables in the container.

## Multiple files with priority

Chain multiple env files, later files override earlier ones:

```yaml
services:
  app:
    image: myapp
    env_file:
      - .env.common         # Shared defaults
      - .env.${ENV:-dev}    # Environment-specific overrides
      - .env.local          # Local developer tweaks (gitignored)
```

Result for a missing key: nothing, as expected. For a key defined in `.env.common` and `.env.local`: the `.env.local` value wins.

## Optional files

By default, a missing env file causes Compose to fail. Use `required: false` to make it optional:

```yaml
services:
  app:
    image: myapp
    env_file:
      - path: .env.common
        required: true    # Default
      - path: .env.local
        required: false   # Skip if missing
```

Great for `.env.local` files that each developer may or may not have.

## Format option

The default format treats each line as `KEY=VALUE`. For more complex values (multi-line, JSON blobs, strings with special characters), use `format: raw` to parse the file differently, or just stick to the default format and quote your values:

```yaml
services:
  app:
    env_file:
      - path: .env.app
        format: raw
```

For most cases, the default format is what you want.

## Interpolation inside env files

Env files support `${VAR}` substitution, pulling from the host environment or the project `.env`:

```ini
# .env.app
DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
API_KEY=${API_KEY}
```

As long as `DB_USER`, `DB_PASSWORD`, etc. are available on the host (or in the project `.env`), Compose resolves them before passing to the container.

## Precedence: env_file vs environment

When both `env_file` and `environment` define the same variable, `environment` wins:

```yaml
services:
  app:
    env_file:
      - .env.app            # LOG_LEVEL=info
    environment:
      LOG_LEVEL: debug      # ← this wins
```

The running container sees `LOG_LEVEL=debug`. Useful for one-off overrides without editing the env file.

## A practical multi-environment setup

```
my-app/
├── compose.yml
├── .env.common
├── .env.dev
├── .env.staging
├── .env.prod
└── .env.local      # gitignored
```

```yaml
services:
  app:
    image: myapp
    env_file:
      - .env.common
      - path: .env.${ENV:-dev}
        required: true
      - path: .env.local
        required: false
```

```bash
docker compose up                  # uses .env.dev
ENV=staging docker compose up      # uses .env.staging
ENV=prod docker compose up         # uses .env.prod
```

## Further reading

- [Compose specification: env_file](https://docs.docker.com/reference/compose-file/services/#env_file)
- [Environment variables precedence](https://docs.docker.com/compose/how-tos/environment-variables/envvars-precedence/)
- Related: [Tip #2, Using --env-file for different environments](/posts/compose-tip-002-env-files/)
- Related: [Tip #42, Variable substitution and defaults](/posts/compose-tip-042-variable-substitution/)
