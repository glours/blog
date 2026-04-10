---
title: "Docker Compose Tip #53: Compose project name and working directory"
date: 2026-04-15T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Control project naming and working directory to avoid conflicts and organize multi-environment setups"
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

Every Compose stack gets a project name. It prefixes all resource names such as containers, networks, volumes. Understanding how it works avoids naming conflicts and makes multi-environment setups cleaner.

## Default behavior

By default, the project name is the directory name where your `compose.yml` lives:

```
my-app/
  compose.yml
```

```bash
docker compose up -d
# Creates: my-app-web-1, my-app-db-1, my-app_default network
```

## Setting the project name

Three ways to set it, in order of precedence:

```bash
# 1. CLI flag (highest precedence)
docker compose -p myproject up

# 2. Environment variable
COMPOSE_PROJECT_NAME=myproject docker compose up

# 3. In the Compose file itself
```

```yaml
# compose.yml
name: myproject

services:
  web:
    image: nginx
```

The `name` key in the Compose file is the recommended approach, it's versioned with your code and everyone on the team gets the same project name.

## Why it matters

Without an explicit name, the project name depends on the directory. This causes problems:

```bash
# Two developers clone to different paths
/home/alice/projects/app/   → project name: "app"
/home/bob/work/app/         → project name: "app"  ✅ same

# But...
/home/alice/projects/my-app/ → project name: "my-app"
/home/bob/work/app/          → project name: "app"  ❌ different
```

Different project names mean different volumes — so `docker compose down --volumes` on one won't clean up the other's data.

## Running multiple instances

Use `-p` to run the same stack multiple times on the same host:

```bash
# Staging environment
docker compose -p staging up -d

# Production environment
docker compose -p production up -d

# Both running simultaneously with isolated networks and volumes
docker compose -p staging ps
docker compose -p production ps
```

## Changing the working directory

Use `--project-directory` to tell Compose where to resolve relative paths:

```bash
# Run from anywhere, resolve paths relative to ./deploy
docker compose --project-directory ./deploy up
```

This is useful when your Compose file is not in the project root, or when you want to run Compose from a CI script that's in a different directory.

## Listing all projects

See all running Compose projects on the host:

```bash
docker compose ls
```

```
NAME        STATUS      CONFIG FILES
myapp       running(3)  /home/user/myapp/compose.yml
staging     running(3)  /home/user/myapp/compose.yml
production  running(3)  /home/user/myapp/compose.yml
```

## Pro tip

Combine `name` with variable substitution for flexible naming:

```yaml
name: myapp-${ENV:-dev}

services:
  web:
    image: nginx
```

```bash
ENV=staging docker compose up -d  # project: myapp-staging
ENV=prod docker compose up -d     # project: myapp-prod
docker compose up -d              # project: myapp-dev (default)
```

## Further reading

- [Compose specification: name](https://docs.docker.com/reference/compose-file/version-and-name/#name-top-level-element)
- [Compose environment variables: COMPOSE_PROJECT_NAME](https://docs.docker.com/compose/how-tos/environment-variables/envvars/)
