---
title: "Docker Compose Tip #33: Using logging drivers and options"
date: 2026-02-27T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "logging", "monitoring", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Configure logging drivers for better log management and analysis"
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

Take control of your container logs! Configure different logging drivers for better management, rotation, and analysis.

## Default logging: json-file

By default, Docker uses the json-file driver:

```yaml
services:
  app:
    image: myapp
    logging:
      driver: json-file
      options:
        max-size: "10m"    # Rotate after 10MB
        max-file: "3"      # Keep 3 rotated files
        compress: "true"   # Compress rotated files
```

Without rotation, logs can fill your disk!

## Common logging drivers

### 1. Local driver (efficient storage)

Optimized for performance and disk usage:

```yaml
services:
  app:
    image: myapp
    logging:
      driver: local
      options:
        max-size: "20m"
        max-file: "5"
        compress: "true"
```

### 2. Syslog (centralized logging)

Send logs to syslog server:

```yaml
services:
  app:
    image: myapp
    logging:
      driver: syslog
      options:
        syslog-address: "tcp://192.168.1.100:514"
        syslog-format: "rfc5424"
        tag: "{{.ImageName}}/{{.Name}}/{{.ID}}"
```

### 3. Journald (systemd integration)

For systemd-based systems:

```yaml
services:
  app:
    image: myapp
    logging:
      driver: journald
      options:
        tag: "compose-{{.Name}}"
        labels: "env,version"
```

View with: `journalctl -u docker.service -f`

### 4. Fluentd (log aggregation)

Forward to Fluentd collector:

```yaml
services:
  app:
    image: myapp
    logging:
      driver: fluentd
      options:
        fluentd-address: "localhost:24224"
        tag: "app.{{.Name}}"
        fluentd-async: "true"
        fluentd-buffer-limit: "1MB"
```

### 5. AWS CloudWatch

Direct to CloudWatch:

```yaml
services:
  app:
    image: myapp
    logging:
      driver: awslogs
      options:
        awslogs-region: "us-east-1"
        awslogs-group: "myapp-logs"
        awslogs-stream: "{{.FullID}}"
        awslogs-create-group: "true"
```

## No logging

Disable logging entirely:

```yaml
services:
  noisy-service:
    image: chatty-app
    logging:
      driver: none
```

## Mixed logging strategies

Different drivers per service:

```yaml
services:
  # Critical service - centralized logging
  api:
    image: api
    logging:
      driver: syslog
      options:
        syslog-address: "tcp://log-server:514"
        tag: "api/{{.ID}}"

  # High-volume service - local with rotation
  worker:
    image: worker
    logging:
      driver: local
      options:
        max-size: "100m"
        max-file: "10"

  # Debug service - json for easy reading
  debug:
    image: debug-tool
    logging:
      driver: json-file
      options:
        max-size: "5m"
        max-file: "2"
        labels: "service_name,version"
        env: "NODE_ENV,LOG_LEVEL"

  # Metrics collector - no logs needed
  metrics:
    image: prometheus
    logging:
      driver: none
```

## Log labels and metadata

Add metadata to logs:

```yaml
services:
  app:
    image: myapp
    labels:
      - "com.example.version=1.0"
      - "com.example.environment=production"
    environment:
      - LOG_LEVEL=info
    logging:
      driver: json-file
      options:
        labels: "com.example.version,com.example.environment"
        env: "LOG_LEVEL,NODE_ENV"
        env-regex: "^LOG_"
```

Logs will include these labels and env vars!

## Complete example: ELK stack integration

```yaml
services:
  # Application with structured logging
  app:
    image: myapp
    depends_on:
      - elasticsearch
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
        labels: "service,version,environment"
    labels:
      service: "api"
      version: "2.0"
      environment: "production"

  # Log shipper
  filebeat:
    image: elastic/filebeat:8.11.0
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
    depends_on:
      - elasticsearch
      - kibana

  # Log storage
  elasticsearch:
    image: elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    logging:
      driver: local  # Don't log ES to itself
      options:
        max-size: "50m"

  # Log visualization
  kibana:
    image: kibana:8.11.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    logging:
      driver: local
      options:
        max-size: "10m"
```

## Global logging configuration

Set defaults for all services:

```yaml
# docker-compose.yml
x-logging: &default-logging
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
    compress: "true"

services:
  app1:
    image: app1
    logging: *default-logging

  app2:
    image: app2
    logging: *default-logging

  app3:
    image: app3
    logging:
      <<: *default-logging
      options:
        max-size: "20m"  # Override size for this service
```

## Pro tip

View logs with filters and formatting:

```bash
# Follow logs with timestamps
docker compose logs -f --timestamps

# Last 100 lines from specific services
docker compose logs --tail=100 web worker

# Logs since specific time
docker compose logs --since="2024-01-01T10:00:00"

# Logs until specific time
docker compose logs --until="2024-01-01T11:00:00"

# No log prefix (service names)
docker compose logs --no-log-prefix

# Export logs for analysis
docker compose logs --no-color > logs.txt
```

Proper logging is crucial for production debugging!

## Further reading

- [Configure logging drivers](https://docs.docker.com/config/containers/logging/configure/)
- [Logging driver details](https://docs.docker.com/config/containers/logging/)