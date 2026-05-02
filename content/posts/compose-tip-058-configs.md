---
title: "Docker Compose Tip #58: Using configs for config files"
date: 2026-05-04T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Mount config files into containers declaratively with the configs top-level key, no volumes required"
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

You've used `secrets` for sensitive data ([Tip #22](/posts/compose-tip-022-secrets/)). For non-sensitive config files like `nginx.conf` or `prometheus.yml`, there's a parallel feature: `configs`.

## Basic usage

Define a config at the top level, reference it in a service:

```yaml
configs:
  nginx_conf:
    file: ./nginx.conf

services:
  web:
    image: nginx
    configs:
      - source: nginx_conf
        target: /etc/nginx/nginx.conf
```

The file is mounted read-only inside the container at the target path. No need to declare a volume mount manually.

## Inline content

Skip the external file and define content inline:

```yaml
configs:
  prometheus_conf:
    content: |
      global:
        scrape_interval: 15s
      scrape_configs:
        - job_name: 'app'
          static_configs:
            - targets: ['app:8080']

services:
  prometheus:
    image: prom/prometheus
    configs:
      - source: prometheus_conf
        target: /etc/prometheus/prometheus.yml
```

Great for short configs that don't need a separate file.

## Setting permissions and ownership

Control file mode, owner, and group when mounting:

```yaml
configs:
  app_conf:
    file: ./app.conf

services:
  app:
    image: myapp
    configs:
      - source: app_conf
        target: /etc/app/app.conf
        uid: "1000"
        gid: "1000"
        mode: 0440
```

## Variable interpolation in inline content

Inline `content:` supports interpolation just like other Compose values:

```yaml
configs:
  app_conf:
    content: |
      log_level=${LOG_LEVEL:-info}
      api_url=${API_URL:?API_URL is required}
      env=${ENV:-dev}

services:
  app:
    image: myapp
    configs:
      - source: app_conf
        target: /etc/app/app.conf
```

## External configs

Reference a config that already exists outside the Compose project (created with `docker config create`):

```yaml
configs:
  shared_conf:
    external: true
    name: company-shared-config

services:
  app:
    image: myapp
    configs:
      - shared_conf
```

Useful in Swarm or when multiple Compose projects share the same config.

## configs vs volumes

Both put files in containers, but they're not the same:

| | `configs` | Volume mounts |
|---|---|---|
| **Source of truth** | Declared in compose file | External directory |
| **Read-only** | Yes (always) | Configurable |
| **Inline content** | Supported | Not supported |
| **Best for** | Config files, small text data | Persistent data, large files, dev source code |

If a file rarely changes and is part of the application config, use `configs`. If it's data that changes at runtime or large files, use a volume.

## Further reading

- [Compose specification: configs](https://docs.docker.com/reference/compose-file/configs/)
- Related: [Tip #22, Using secrets in Compose files](/posts/compose-tip-022-secrets/)
