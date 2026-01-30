---
title: "Docker Compose Tip #21: Understanding bridge vs host networking modes"
date: 2026-02-02T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "networking", "security", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "When to use bridge vs host networking modes and their security implications"
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

Choose the right networking mode for your containers. Understand when isolation matters and when performance is key.

## Bridge mode (default)

The default and most secure option - containers get their own network namespace:

```yaml
services:
  web:
    image: nginx
    ports:
      - "8080:80"  # Port mapping required
    networks:
      - app_network

  db:
    image: postgres:15
    networks:
      - app_network

networks:
  app_network:
    driver: bridge
```

Containers can communicate using service names (web, db) within the network.

## Host mode

Container shares the host's network stack - no network isolation:

```yaml
services:
  monitoring:
    image: prometheus/node-exporter
    network_mode: host
    # No port mapping needed - uses host ports directly
```

The container can access all host network interfaces directly.

## Key differences

| Feature | Bridge | Host |
|---------|--------|------|
| **Port mapping** | Required (8080:80) | Not needed |
| **Network isolation** | Yes | No |
| **Container DNS** | Service names work | Use localhost/IPs |
| **Performance** | Small overhead | Native speed |
| **Security** | Better isolation | Less secure |

## When to use each

**Use Bridge for:**
```yaml
services:
  # Application services
  api:
    networks: [app]

  # Databases
  postgres:
    networks: [app]

  # Web servers
  nginx:
    networks: [app]
```

**Use Host for:**
```yaml
services:
  # System monitoring
  node-exporter:
    network_mode: host

  # Network tools
  tcpdump:
    network_mode: host

  # Performance-critical
  game-server:
    network_mode: host
```

## Security considerations

Bridge mode provides better security:

```yaml
services:
  # Isolated database
  database:
    image: postgres
    networks:
      - backend
    # Not exposed to host network

  # Only web is exposed
  web:
    image: nginx
    networks:
      - backend
    ports:
      - "443:443"  # Controlled exposure
```

Host mode risks:
- Container can access all host ports
- Can see all network traffic
- No network-level isolation

## Mixing modes

You can mix both in one project:

```yaml
services:
  app:
    image: myapp
    networks:
      - isolated
    ports:
      - "3000:3000"

  monitoring:
    image: netdata/netdata
    network_mode: host
    # Can monitor host system and services on host ports

networks:
  isolated:
    driver: bridge
```

## Pro tip

Test network isolation:

```bash
# Bridge mode - can't access host services directly
docker compose exec web curl localhost:5432  # Fails

# Host mode - full access
docker compose exec monitoring curl localhost:5432  # Works
```

Choose bridge for security, host for system-level tools.

## Further reading

- [Docker networking overview](https://docs.docker.com/network/)
- [Bridge network driver](https://docs.docker.com/network/drivers/bridge/)