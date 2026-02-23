---
title: "Docker Compose Tip #32: Build contexts and dockerignore patterns"
date: 2026-02-25T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "build", "optimization", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Optimize build performance with proper context management and .dockerignore patterns"
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

Speed up builds and reduce image size by managing build contexts effectively. Don't send unnecessary files to the Docker daemon!

## Understanding build context

The build context is what gets sent to Docker daemon:

```yaml
services:
  app:
    build: .  # Current directory is the context
    # Everything in . gets sent to daemon!
```

Check your context size:
```bash
# See what's being sent
docker build --no-cache . 2>&1 | grep "Sending build context"
# Output: Sending build context to Docker daemon  458.2MB 😱
```

## Custom build contexts

Specify different contexts for different services:

```yaml
services:
  frontend:
    build:
      context: ./frontend  # Only frontend/ directory
      dockerfile: Dockerfile

  backend:
    build:
      context: ./backend   # Only backend/ directory
      dockerfile: Dockerfile

  shared-lib:
    build:
      context: .          # Root for accessing multiple dirs
      dockerfile: ./shared/Dockerfile
```

## The power of .dockerignore

Create `.dockerignore` files to exclude unnecessary files:

```bash
# .dockerignore
# Version control
.git
.gitignore

# Dependencies
node_modules
vendor
__pycache__
*.pyc

# IDE files
.idea
.vscode
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Build artifacts
dist
build
*.o
*.exe

# Local env files
.env
.env.local
*.env

# Logs
*.log
logs/

# Tests
test/
tests/
coverage/
.coverage

# Documentation
docs/
*.md
!README.md  # Exception: include README

# Development files
docker-compose.override.yml
Makefile
```

## Multiple dockerignore patterns

Different contexts can have different `.dockerignore` files:

```yaml
project/
├── .dockerignore           # Root ignore
├── frontend/
│   ├── .dockerignore      # Frontend-specific ignore
│   └── Dockerfile
├── backend/
│   ├── .dockerignore      # Backend-specific ignore
│   └── Dockerfile
└── docker-compose.yml
```

Each service uses its context's `.dockerignore`:

```yaml
services:
  frontend:
    build: ./frontend  # Uses ./frontend/.dockerignore

  backend:
    build: ./backend   # Uses ./backend/.dockerignore
```

## Advanced context with multiple sources

Use bind mounts for selective file inclusion:

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      additional_contexts:
        - shared=../shared-libs
        - configs=./configurations
```

In Dockerfile:
```dockerfile
# Copy from additional contexts
COPY --from=shared . /app/shared
COPY --from=configs . /app/config
```

## Git-based contexts

Build directly from Git repositories:

```yaml
services:
  app:
    build: https://github.com/user/repo.git#branch

  specific-commit:
    build: https://github.com/user/repo.git#v1.0.0

  subdirectory:
    build: https://github.com/user/repo.git#main:subdirectory
```

## Named contexts for reuse

Share contexts between services:

```yaml
x-backend-build: &backend-build
  context: ./backend
  dockerfile: Dockerfile
  args:
    BUILD_ENV: production

services:
  api:
    build: *backend-build

  worker:
    build:
      <<: *backend-build
      target: worker  # Different stage

  scheduler:
    build:
      <<: *backend-build
      target: scheduler
```

## Pro tip

Use BuildKit's cache mounts to speed up builds:

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      cache_from:
        - type=local,src=/tmp/buildcache
      cache_to:
        - type=local,dest=/tmp/buildcache,mode=max
```

And in your Dockerfile:
```dockerfile
# syntax=docker/dockerfile:1
FROM node:18

WORKDIR /app

# Cache package manager downloads
RUN --mount=type=cache,target=/root/.npm \
    npm set cache /root/.npm

# Cache dependencies
COPY package*.json .
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production

# Copy only necessary files (respecting .dockerignore)
COPY . .

RUN npm run build
```

Smaller contexts = faster builds = happier developers!

## Further reading

- [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [BuildKit documentation](https://docs.docker.com/build/buildkit/)