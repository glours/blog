---
title: "Docker Compose Tip #9: Publishing Compose applications as OCI artifacts"
date: 2026-01-15T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "oci", "distribution", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to publish and share Docker Compose applications as OCI artifacts"
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

Package your entire Docker Compose application as an OCI artifact and share it through any container registry. No more complex installation instructions.

## The basics

Publish your Compose configuration as an OCI artifact:

```bash
# Publish your compose.yml to a registry
docker compose publish myusername/myapp:v1.0

# Users run it directly with oci:// prefix
docker compose -f oci://docker.io/myusername/myapp:v1.0 up
```

The compose.yml (and any included files) are stored as an OCI artifact alongside your container images.

## Requirements

- Docker Compose 2.34.0 or later
- OCI-compliant registry (Docker Hub, GitHub Container Registry, etc.)

## Publishing your application

```yaml
# compose.yml
name: voting-app

services:
  vote:
    image: mycompany/vote:latest
    ports:
      - "5000:80"
    depends_on:
      - redis

  redis:
    image: redis:7-alpine

  worker:
    image: mycompany/worker:latest
    depends_on:
      - redis
      - db

  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: postgres
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

Publish it:
```bash
# Simple publish
docker compose publish mycompany/voting-app:v1.0

# With multiple compose files
docker compose -f compose.yml -f compose.prod.yml \
  publish mycompany/voting-app:prod
```

## Advanced publishing options

Pin images to specific digests for reproducibility:

```bash
# Lock all image versions
docker compose publish \
  --resolve-image-digests \
  mycompany/voting-app:v1.0
```

Include environment for fully self-contained app:

```bash
# Bundle environment variables
docker compose publish \
  --with-env \
  mycompany/voting-app:v1.0
```

## Consuming published applications

Users run your app with one command:

```bash
# Pull and run from registry
docker compose -f oci://docker.io/mycompany/voting-app:v1.0 up -d

# Or from GitHub Container Registry
docker compose -f oci://ghcr.io/mycompany/voting-app:latest up

# Check what's running
docker compose -f oci://docker.io/mycompany/voting-app:v1.0 ps
```

## Real example

We distribute sample apps at Docker this way:

```bash
# Publish our example voting app
docker compose publish dockersamples/example-voting-app:latest

# Users run it instantly
docker compose -f oci://docker.io/dockersamples/example-voting-app:latest up
```

No git clone, no README setup, just run.

## Limitations

Cannot publish applications with:
- **Bind mounts** in services (volumes are OK)
- Services with only `build` section (need image specified)
- Local files in `include` directives (remote includes work)

## Security considerations

Compose prompts for confirmation when running OCI artifacts with:
- Variable interpolation
- Environment variables
- Remote includes

Use `-y` flag to skip prompts in automation:

```bash
docker compose -f oci://myregistry/app:v1 up -y
```

## Version management

```bash
# Publish different versions
docker compose publish mycompany/app:v2.0
docker compose publish mycompany/app:v2.1
docker compose publish mycompany/app:latest

# Users choose version
docker compose -f oci://docker.io/mycompany/app:v2.0 up
```

## Pro tip

Perfect for distributing internal tools:

```bash
# Publish development environment
docker compose publish internal-registry.company.com/devenv:latest

# Developers run with one command
docker compose -f oci://internal-registry.company.com/devenv:latest up

# Update? Just publish new version
docker compose publish internal-registry.company.com/devenv:v2
```

OCI artifacts transform how we share Compose applications - from complex READMEs to single commands.

## Further reading

- [Docker Compose OCI artifact documentation](https://docs.docker.com/compose/how-tos/oci-artifact/)
- [OCI Image Specification](https://github.com/opencontainers/image-spec)