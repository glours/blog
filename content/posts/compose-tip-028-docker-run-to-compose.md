---
title: "Docker Compose Tip #28: Converting docker run commands to Compose"
date: 2026-02-11T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "migration", "conversion", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Transform complex docker run commands into clean Compose configurations"
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

Stop managing long docker run commands! Convert them to maintainable Compose files.

## Basic conversions

Common flag mappings:

```bash
# Docker run command
docker run -d \
  --name myapp \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e API_KEY=secret123 \
  -v $(pwd)/data:/app/data \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --restart unless-stopped \
  myapp:latest
```

Becomes:

```yaml
services:
  myapp:
    image: myapp:latest
    container_name: myapp
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      API_KEY: secret123
    volumes:
      - ./data:/app/data
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
```

## Network configurations

```bash
# Host network
docker run --network host nginx

# Custom network
docker run --network mynet --ip 172.20.0.5 app

# Network alias
docker run --network mynet --network-alias db postgres
```

Compose equivalent:

```yaml
services:
  nginx:
    image: nginx
    network_mode: host

  app:
    image: app
    networks:
      mynet:
        ipv4_address: 172.20.0.5

  postgres:
    image: postgres
    networks:
      mynet:
        aliases:
          - db

networks:
  mynet:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## Resource limits

```bash
docker run -d \
  --memory="2g" \
  --memory-swap="4g" \
  --cpus="1.5" \
  --cpu-shares="512" \
  myapp
```

Becomes:

```yaml
services:
  myapp:
    image: myapp
    deploy:
      resources:
        limits:
          cpus: "1.5"
          memory: 2G
        reservations:
          cpus: "0.5"
          memory: 1G
    mem_swappiness: 60
    cpu_shares: 512
```

## User and working directory

```bash
docker run \
  --user 1000:1000 \
  --workdir /app \
  --entrypoint /custom-entrypoint.sh \
  myapp npm start
```

Becomes:

```yaml
services:
  myapp:
    image: myapp
    user: "1000:1000"
    working_dir: /app
    entrypoint: /custom-entrypoint.sh
    command: npm start
```

## Advanced security options

```bash
docker run \
  --privileged \
  --cap-add SYS_ADMIN \
  --cap-drop ALL \
  --security-opt apparmor=unconfined \
  --read-only \
  --tmpfs /tmp:size=100M \
  myapp
```

Becomes:

```yaml
services:
  myapp:
    image: myapp
    privileged: true
    cap_add:
      - SYS_ADMIN
    cap_drop:
      - ALL
    security_opt:
      - apparmor:unconfined
    read_only: true
    tmpfs:
      - /tmp:size=100M
```

## Complex real-world example

Converting a database with initialization:

```bash
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=admin \
  -v postgres_data:/var/lib/postgresql/data \
  -v $(pwd)/init.sql:/docker-entrypoint-initdb.d/init.sql \
  -p 5432:5432 \
  --health-cmd "pg_isready -U admin" \
  --health-interval 10s \
  --health-timeout 5s \
  --health-retries 5 \
  --restart always \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  postgres:15
```

Becomes:

```yaml
services:
  postgres:
    image: postgres:15
    container_name: postgres
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: mydb
      POSTGRES_USER: admin
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U admin"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: always
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  postgres_data:
```

## Common gotchas

```yaml
# WRONG: Using command for everything
services:
  app:
    image: ubuntu
    command: /bin/bash -c "apt update && apt install -y curl && curl http://example.com"

# RIGHT: Use entrypoint for shell, command for args
services:
  app:
    image: ubuntu
    entrypoint: ["/bin/bash", "-c"]
    command: ["apt update && apt install -y curl && curl http://example.com"]

# BETTER: Use custom image
services:
  app:
    build: .
    command: ["curl", "http://example.com"]
```

## Pro tip

Use Docker Compose's built-in conversion tool:

```bash
# Convert a running container to Compose format
docker compose alpha generate [container-name-or-id]

# Example: Convert a running container
docker run -d --name myapp -p 3000:3000 -e NODE_ENV=production myapp:latest
docker compose alpha generate myapp > compose.yml

# Generate from multiple containers
docker compose alpha generate web db cache > stack.yml

# With project name
docker compose alpha generate --name myproject web db > compose.yml
```

This experimental command automatically converts running containers to Compose format!

Clean, maintainable, and version-controlled!

## Further reading

- [Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Docker run reference](https://docs.docker.com/engine/reference/run/)