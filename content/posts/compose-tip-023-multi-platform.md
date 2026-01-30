---
title: "Docker Compose Tip #23: Multi-platform builds with platforms"
date: 2026-02-04T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "build", "cross-platform", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Build Docker images for multiple CPU architectures with one command"
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

Build once, run everywhere! Create images that work on ARM Macs, Intel servers, and Raspberry Pi with a single build command.

## Configure multi-arch builder

Docker Desktop handles this by default. For other Docker installations, set up buildx:

```bash
# Only needed if not using Docker Desktop
# Create and use a new builder
docker buildx create --name multiarch --use

# Verify available platforms
docker buildx ls
```

## Configure platforms

Specify target architectures in your compose file:

```yaml
services:
  app:
    build:
      context: .
      platforms:
        - linux/amd64     # Intel/AMD 64-bit
        - linux/arm64     # ARM 64-bit (M1/M2 Macs, AWS Graviton)
        - linux/arm/v7    # ARM 32-bit (Raspberry Pi)
    image: myapp:latest
```

## Build and push

Build for all platforms and push to registry:

```bash
# Build for all platforms
docker compose build

# Build and push to registry
docker compose build --push

# Specific service
docker compose build --push app
```

## Platform-specific Dockerfiles

Handle platform differences in your Dockerfile:

```dockerfile
FROM --platform=$BUILDPLATFORM node:20 AS builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN echo "Building on $BUILDPLATFORM for $TARGETPLATFORM"

# Platform-specific commands
RUN if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
      echo "ARM v7 specific setup"; \
    fi

WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:20-alpine
COPY --from=builder /app /app
CMD ["node", "app.js"]
```

## Development workflow

Different platforms for dev and production:

```yaml
services:
  app:
    build:
      context: .
      platforms:
        - ${DOCKER_DEFAULT_PLATFORM:-linux/amd64}

  # Production build
  app-prod:
    build:
      context: .
      platforms:
        - linux/amd64
        - linux/arm64
    profiles: ["prod"]
```

Local development:
```bash
# Build for current platform only
docker compose build app

# Production multi-platform build
docker compose --profile prod build --push app-prod
```

## Check image platforms

Verify multi-platform support:

```bash
# Inspect manifest
docker buildx imagetools inspect myapp:latest

# Output shows:
# MediaType: application/vnd.docker.distribution.manifest.list.v2+json
# Manifests:
#   linux/amd64
#   linux/arm64
#   linux/arm/v7
```

## CI/CD integration

GitHub Actions example:

```yaml
- name: Set up QEMU
  uses: docker/setup-qemu-action@v3

- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Build and push
  run: |
    docker compose build --push
```

## Performance tips

Building for multiple platforms takes longer:

```yaml
services:
  # Development - single platform
  dev:
    build:
      context: .
      platforms:
        - linux/arm64  # Just for M1 Mac
    profiles: ["dev"]

  # CI/CD - all platforms
  prod:
    build:
      context: .
      cache_from:
        - type=registry,ref=myapp:buildcache
      cache_to:
        - type=registry,ref=myapp:buildcache
      platforms:
        - linux/amd64
        - linux/arm64
```

## Common platform combinations

```yaml
# Modern cloud (AWS, GCP, Azure)
platforms:
  - linux/amd64
  - linux/arm64

# IoT and edge
platforms:
  - linux/arm64
  - linux/arm/v7
  - linux/arm/v6

# Maximum compatibility
platforms:
  - linux/amd64
  - linux/arm64
  - linux/arm/v7
  - linux/386
```

## Pro tip

Docker automatically selects the correct variant of multi-arch images:

```dockerfile
# This automatically uses the right platform variant
FROM node:20-alpine

# You can also use platform variables in your Dockerfile
ARG TARGETPLATFORM
RUN echo "Building for $TARGETPLATFORM"
```

For platform-specific optimization, build separately:
```bash
# Build only for ARM64 with specific optimizations
docker compose build --platform linux/arm64

# Build only for AMD64
docker compose build --platform linux/amd64
```

## Further reading

- [Docker buildx documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Multi-platform images](https://docs.docker.com/build/building/multi-platform/)