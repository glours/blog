---
title: "Docker Compose Tip #36: Using extra_hosts for custom DNS entries"
date: 2026-03-06T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "networking", "dns", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Add custom hostname mappings without modifying system hosts file"
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

Need custom DNS resolution in containers? Use `extra_hosts` to add hostname mappings without touching system files!

## Basic extra_hosts usage

Add custom host entries to containers:

```yaml
services:
  app:
    image: myapp
    extra_hosts:
      - "api.local:192.168.1.100"
      - "db.local:192.168.1.101"
      - "cache.local:192.168.1.102"
```

Inside the container:
```bash
docker compose exec app cat /etc/hosts
# 127.0.0.1       localhost
# 192.168.1.100   api.local
# 192.168.1.101   db.local
# 192.168.1.102   cache.local
```

## Dynamic host resolution

Use host machine's IP dynamically:

```yaml
services:
  app:
    image: myapp
    extra_hosts:
      - "host.docker.internal:host-gateway"  # Magic value!
```

This maps to:
- On Linux: Host's IP on default bridge
- On Mac/Windows: Special DNS name to host

## Environment-based hosts

Different hosts per environment:

```yaml
services:
  app:
    image: myapp
    extra_hosts:
      - "api.service:${API_HOST:-127.0.0.1}"
      - "auth.service:${AUTH_HOST:-127.0.0.1}"
      - "cdn.service:${CDN_HOST:-127.0.0.1}"
```

`.env.development`:
```bash
API_HOST=localhost
AUTH_HOST=localhost
CDN_HOST=localhost
```

`.env.production`:
```bash
API_HOST=10.0.1.50
AUTH_HOST=10.0.1.51
CDN_HOST=cdn.example.com
```

## Testing against production APIs

Route specific domains to local/mock services:

```yaml
services:
  app:
    image: myapp
    extra_hosts:
      # Override production APIs
      - "api.example.com:127.0.0.1"
      - "auth.example.com:127.0.0.1"
    ports:
      - "3000:3000"

  # Mock API server
  mock-api:
    image: mockserver
    extra_hosts:
      - "api.example.com:127.0.0.1"
    ports:
      - "80:8080"
```

## Multiple service aliases

Create multiple hostnames for the same IP:

```yaml
services:
  web:
    image: nginx
    extra_hosts:
      # All pointing to the same service
      - "app.local:172.20.0.5"
      - "www.local:172.20.0.5"
      - "admin.local:172.20.0.5"
      - "api.local:172.20.0.5"

  app:
    image: myapp
    networks:
      default:
        ipv4_address: 172.20.0.5

networks:
  default:
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## Development with external services

Connect to services outside Docker:

```yaml
services:
  frontend:
    image: node:18
    working_dir: /app
    volumes:
      - .:/app
    extra_hosts:
      # Local development servers
      - "backend.local:host-gateway"     # Your host machine
      - "database.local:192.168.1.50"    # Another machine
      - "redis.local:192.168.1.51"       # Another machine
    command: npm run dev
    environment:
      API_URL: http://backend.local:8080
      DB_HOST: database.local
      REDIS_HOST: redis.local
```

## Complete example: Microservices testing

```yaml
services:
  # API Gateway
  gateway:
    image: nginx
    ports:
      - "80:80"
    extra_hosts:
      - "users.service:172.25.0.10"
      - "orders.service:172.25.0.11"
      - "inventory.service:172.25.0.12"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - users
      - orders
      - inventory

  # Microservices
  users:
    image: users-service
    extra_hosts:
      - "auth.provider:${AUTH_SERVER:-host-gateway}"
      - "email.service:${EMAIL_SERVER:-host-gateway}"
    networks:
      default:
        ipv4_address: 172.25.0.10

  orders:
    image: orders-service
    extra_hosts:
      - "users.service:172.25.0.10"
      - "inventory.service:172.25.0.12"
      - "payment.gateway:${PAYMENT_HOST:-sandbox.paypal.com}"
    networks:
      default:
        ipv4_address: 172.25.0.11

  inventory:
    image: inventory-service
    extra_hosts:
      - "warehouse.api:${WAREHOUSE_HOST:-mock-warehouse}"
    networks:
      default:
        ipv4_address: 172.25.0.12

  # Mock external service
  mock-warehouse:
    image: mockserver
    container_name: mock-warehouse

networks:
  default:
    ipam:
      config:
        - subnet: 172.25.0.0/16
```

## Debugging DNS resolution

Test hostname resolution:

```yaml
services:
  dns-debug:
    image: alpine
    extra_hosts:
      - "test1.local:1.2.3.4"
      - "test2.local:5.6.7.8"
      - "host.machine:host-gateway"
    command: |
      sh -c "
        echo '=== /etc/hosts ==='
        cat /etc/hosts
        echo
        echo '=== DNS Resolution ==='
        nslookup test1.local || echo 'nslookup not available'
        echo
        echo '=== Ping Tests ==='
        ping -c 1 test1.local || true
        ping -c 1 host.machine || true
      "
```

## YAML anchors for shared hosts

Reuse common host mappings:

```yaml
x-common-hosts: &common-hosts
  - "auth.local:10.0.0.1"
  - "cache.local:10.0.0.2"
  - "db.local:10.0.0.3"

services:
  app1:
    image: app1
    extra_hosts: *common-hosts

  app2:
    image: app2
    extra_hosts:
      <<: *common-hosts
      - "special.local:10.0.0.4"  # Additional host

  app3:
    image: app3
    extra_hosts: *common-hosts
```


## Further reading

- [Docker networking documentation](https://docs.docker.com/network/)
- [Compose networking](https://docs.docker.com/compose/networking/)