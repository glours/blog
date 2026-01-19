---
title: "Docker Compose Tip #11: Mastering docker compose up --watch for hot reload"
date: 2026-01-19T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "development", "productivity", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to use docker compose watch for automatic hot reloading during development"
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

Stop manually restarting containers when code changes. Docker Compose Watch automatically syncs files and reloads services - zero interruption development.

## The basics

Enable watch mode with:

```bash
docker compose up --watch
# If you don't want mixed logs, you can run it in a dedicated process, you need to have your stack started on its own process
docker compose watch
```

Then configure watching in your `compose.yml`:

```yaml
services:
  web:
    image: node:20
    command: npm start
    develop:
      watch:
        - path: ./src
          target: /app/src
          action: sync
        - path: package.json
          action: rebuild
```

Files in `./src` sync instantly. Changes to `package.json` trigger a rebuild.

## Watch actions explained

Three actions control what happens when files change:

**`sync`** - Updates files in the container instantly:
```yaml
watch:
  - path: ./src
    target: /app/src
    action: sync
```

**`rebuild`** - Rebuilds image and restarts container:
```yaml
watch:
  - path: ./Dockerfile
    action: rebuild
```

**`sync+restart`** - Syncs files then restarts container:
```yaml
watch:
  - path: ./config
    target: /app/config
    action: sync+restart
```

## Real development example

Full stack app with hot reloading:

```yaml
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    develop:
      watch:
        # React/Vue/Angular source files - instant sync
        - path: ./frontend/src
          target: /app/src
          action: sync
        # Config changes need restart
        - path: ./frontend/.env
          target: /app/.env
          action: sync+restart
        # Dependencies need rebuild
        - path: ./frontend/package*.json
          action: rebuild

  backend:
    build: ./backend
    ports:
      - "8080:8080"
    develop:
      watch:
        # Python/Node source - sync for hot reload
        - path: ./backend/app
          target: /app
          action: sync
          ignore:
            - __pycache__/
            - "*.pyc"
        # Requirements change = rebuild
        - path: ./backend/requirements.txt
          action: rebuild
```

## Ignore patterns

Exclude files that shouldn't trigger updates:

```yaml
watch:
  - path: ./src
    target: /app/src
    action: sync
    ignore:
      - node_modules/
      - "*.test.js"
      - ".git/"
      - "**/*.log"
```

## Check watch status

See what's being watched:

```bash
docker compose watch --no-up
```

Output shows all watched paths:
```
web Watching:
  - ./src → /app/src (sync)
  - package.json (rebuild)
backend Watching:
  - ./backend/app → /app (sync)
```

## Common patterns

**Frontend development** (React/Vue/Angular):
```yaml
develop:
  watch:
    - path: ./src
      target: /app/src
      action: sync  # Webpack/Vite handles reload
```

**Backend with nodemon/Flask debug**:
```yaml
develop:
  watch:
    - path: ./app
      target: /app
      action: sync  # App framework handles reload
```

**Static sites** (Hugo/Jekyll):
```yaml
develop:
  watch:
    - path: ./content
      action: sync+restart  # Regenerate site
```

## Further reading

- [Docker Compose Watch documentation](https://docs.docker.com/compose/file-watch/)
- [Compose specification - develop section](https://github.com/compose-spec/compose-spec/blob/master/develop.md)
- Related: [Restarting single services](/posts/compose-tip-007-restart-single/)