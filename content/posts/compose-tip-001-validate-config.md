---
title: "Docker Compose Tip #1: Debug your configuration with config"
date: 2026-01-06T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How docker compose config helps debug complex configurations and profiles"
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

When your Compose setup gets complex, `docker compose config` becomes your best debugging tool. Especially with profiles.

## The basics

```bash
docker compose config
```

This shows you the **actual configuration** that Docker Compose will run:
- Environment variables are replaced with their values
- Relative paths become absolute
- Default values are applied
- Multiple compose files are merged
- YAML anchors are resolved

What you write:
```yaml
services:
  web:
    image: myapp:${VERSION:-latest}
    volumes:
      - ./data:/app/data
    environment:
      DATABASE_URL: ${DATABASE_URL}
```

What `docker compose config` shows you:
```yaml
services:
  web:
    image: myapp:1.2.3  # VERSION was set to 1.2.3
    volumes:
      - /home/user/project/data:/app/data  # Absolute path
    environment:
      DATABASE_URL: postgresql://localhost:5432/mydb  # Actual value
```

## Understanding variable resolution

See exactly how your variables expand:

```bash
# Show resolved values
docker compose config

# Keep variables as-is
docker compose config --no-interpolate

# Check what services will run
docker compose config --services
```

## Complex merge scenarios

When using multiple files and overrides:
```bash
docker compose -f compose.yml -f compose.dev.yml -f compose.override.yml config
```

This shows the final merged result. It's invaluable for debugging why a service isn't configured as expected.

## CI/CD validation

```bash
# Validate all profiles
for profile in dev staging prod; do
  docker compose --profile $profile config --quiet || exit 1
done
```

This catches issues where profiles break due to missing dependencies or circular references.

## The real power: debugging profiles

Profiles can be tricky. Services get pulled in through dependencies even without having the profile:

```yaml
services:
  web:
    image: nginx
    profiles: ["frontend"]
    depends_on:
      - api

  api:
    image: myapi
    profiles: ["frontend"]
    depends_on:
      - db

  db:
    image: postgres
    # No profile - always runs

  cache:
    image: redis
    profiles: ["backend"]

  worker:
    image: worker
    profiles: ["backend"]
    depends_on:
      - db
      - cache
```

What happens with `--profile backend`?
```bash
docker compose --profile backend config --services
```

You get: `db`, `cache`, AND `worker`. But here's the trick - `db` runs even without the profile because it has no profile defined. Services without profiles are always started.

Even trickier - dependencies across profiles will fail:

```yaml
services:
  test-runner:
    image: test-runner
    profiles: ["test"]
    depends_on:
      - web
      - db

  web:
    image: nginx
    profiles: ["frontend"]

  db:
    image: postgres
    # No profile - always runs
```

Running `docker compose --profile test config` errors out:
```
service "test-runner" depends on undefined service "web": invalid compose project
```

The `web` service isn't available because the `frontend` profile isn't active. You need BOTH profiles:
```bash
docker compose --profile test --profile frontend config --services
# Now you get: db, web, test-runner
```

This is why `docker compose config` is invaluable - it catches these dependency issues before runtime.