---
title: "Docker Compose Tip #46: Build args vs environment variables"
date: 2026-03-30T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "build", "configuration", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Understand the difference between build-time args and runtime environment variables"
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

Build args and environment variables both pass values to your containers, but they work at different times and serve different purposes. Mixing them up is a common source of confusion.

## Build args: build-time only

Build args are available during `docker build` and are not present in the running container:

```yaml
services:
  app:
    build:
      context: .
      args:
        NODE_VERSION: "20"
        APP_VERSION: "2.1.0"
```

In the Dockerfile, they're consumed with `ARG`:

```dockerfile
ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-slim

ARG APP_VERSION
RUN echo "Building version ${APP_VERSION}"
```

After the build, these values are gone — they don't exist in the running container.

## Environment variables: runtime only

Environment variables are set in the running container but are not available during the build:

```yaml
services:
  app:
    image: myapp
    environment:
      DATABASE_URL: postgres://db:5432/myapp
      LOG_LEVEL: info
      NODE_ENV: production
```

## When you need both

Sometimes you need a value at both build-time and runtime. Pass it as a build arg, then convert it to an environment variable in the Dockerfile:

```dockerfile
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
```

```yaml
services:
  app:
    build:
      context: .
      args:
        NODE_ENV: production
    environment:
      NODE_ENV: production
```

## Build args from the host environment

Build args can reference host environment variables, just like other Compose values:

```yaml
services:
  app:
    build:
      context: .
      args:
        # From host environment or .env file
        GIT_COMMIT: ${GIT_COMMIT:-unknown}
        BUILD_DATE: ${BUILD_DATE:-}
```

## Where does interpolation fit in?

There's a third level that's easy to confuse with the other two: Compose interpolation. When you write `${VAR}` in a Compose file, Compose resolves it from your host environment or `.env` file **at parse time**, before any build or container starts:

```yaml
services:
  app:
    image: myapp:${TAG:-latest}        # Interpolation: resolved before anything runs
    build:
      args:
        VERSION: ${VERSION}            # Interpolation → then passed as build arg
    environment:
      DATABASE_URL: ${DB_URL}          # Interpolation → then passed as container env var
      STATIC_VALUE: "hello"            # No interpolation, just a runtime value
```

The subtle part: `DATABASE_URL: ${DB_URL}` involves **both** interpolation and a container env var. Compose resolves `${DB_URL}` from the host, then passes the result to the container. The container never sees the `${DB_URL}` syntax — only the resolved value.

This means `${HOME}` in `environment:` uses the **host's** `$HOME`, not the container's. Use `$$HOME` if you want the literal string `$HOME` passed to the container for shell expansion at runtime.

For more on interpolation syntax and precedence, see [Tip #42](/posts/compose-tip-042-variable-substitution/).

## Security considerations

Build args are visible in the image history:

```bash
docker history myapp
```

Never pass secrets as build args — they'll be baked into image layers. Use secrets or mounted files instead:

```yaml
services:
  app:
    build:
      context: .
      secrets:
        - npm_token
    environment:
      # Runtime secrets are fine here
      API_KEY: ${API_KEY}

secrets:
  npm_token:
    file: ./secrets/npm_token.txt
```

## Quick reference

| | Build args | Environment variables |
|---|---|---|
| **When** | Build time | Runtime |
| **Dockerfile** | `ARG` | `ENV` |
| **Compose** | `build.args` | `environment` |
| **In container** | No | Yes |
| **In image layers** | Yes (visible!) | No |
| **Use for** | Base image version, build config | App config, credentials |

## Further reading

- [Compose specification: build args](https://docs.docker.com/reference/compose-file/build/#args)
- [Compose specification: environment](https://docs.docker.com/reference/compose-file/services/#environment)
- [Dockerfile ARG vs ENV](https://docs.docker.com/reference/dockerfile/#arg)
