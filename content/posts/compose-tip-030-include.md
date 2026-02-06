---
title: "Docker Compose Tip #30: Compose include for modular configurations"
date: 2026-02-13T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "include", "configuration", "modular", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Build modular, reusable Compose configurations with the include directive"
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

Keep configurations DRY! The `include` directive enables modular, reusable Compose setups.

## Basic include usage

Split configurations into logical modules:

```yaml
# compose.yml
include:
  - path: ./services/database.yml
  - path: ./services/cache.yml
  - path: ./services/monitoring.yml

services:
  app:
    image: myapp:latest
    depends_on:
      - postgres
      - redis
```

```yaml
# services/database.yml
services:
  postgres:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## Project-wide organization

Structure complex projects:

```
project/
├── compose.yml           # Main entry point
├── common/
│   ├── networks.yml     # Shared networks
│   └── volumes.yml      # Shared volumes
├── services/
│   ├── frontend.yml     # Frontend services
│   ├── backend.yml      # Backend services
│   └── database.yml     # Data layer
└── environments/
    ├── dev.yml          # Development overrides
    └── prod.yml         # Production config
```

```yaml
# compose.yml
include:
  - path: ./common/networks.yml
  - path: ./common/volumes.yml
  - path: ./services/frontend.yml
  - path: ./services/backend.yml
  - path: ./services/database.yml
  - path: ${COMPOSE_ENV:-./environments/dev.yml}
```

## Conditional includes

Include files based on environment:

```yaml
# compose.yml
include:
  - path: ./base.yml
  - path: ./monitoring.yml
    env_file: .env.monitoring  # Only if file exists
  - path: ${EXTRA_SERVICES:-/dev/null}
    required: false  # Don't fail if missing

services:
  app:
    image: myapp
```

Run with optional services:
```bash
# Basic setup
docker compose up

# With monitoring
touch .env.monitoring
docker compose up

# With extra services
EXTRA_SERVICES=./debug.yml docker compose up
```

## Team collaboration

Share common configurations:

```yaml
# team/shared.yml
x-default-logging: &default-logging
  logging:
    driver: json-file
    options:
      max-size: "10m"
      max-file: "3"

services:
  shared-db:
    image: postgres:15
    <<: *default-logging
    volumes:
      - shared_data:/var/lib/postgresql/data

volumes:
  shared_data:
```

```yaml
# compose.yml
include:
  - path: ./team/shared.yml

services:
  app:
    image: myapp
    depends_on:
      - shared-db
```

## Service libraries

Create reusable service definitions:

```yaml
# lib/elasticsearch.yml
services:
  elasticsearch:
    image: elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    volumes:
      - es_data:/usr/share/elasticsearch/data

volumes:
  es_data:
```

```yaml
# lib/kibana.yml
services:
  kibana:
    image: kibana:8.11.0
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
    depends_on:
      - elasticsearch
    ports:
      - "5601:5601"
    profiles: ["monitoring"]  # Service-level profile
```

```yaml
# compose.yml
include:
  - path: ./lib/elasticsearch.yml
  - path: ./lib/kibana.yml

services:
  app:
    image: myapp
    environment:
      ES_HOST: elasticsearch
```

## Override with includes

Layer configurations:

```yaml
# base.yml
services:
  app:
    image: myapp:latest
    environment:
      LOG_LEVEL: info
```

```yaml
# dev-overrides.yml
services:
  app:
    environment:
      LOG_LEVEL: debug
    volumes:
      - .:/app
```

```yaml
# compose.yml
include:
  - path: ./base.yml
  - path: ./dev-overrides.yml  # Merges with base

# Result: app has LOG_LEVEL=debug and volume mount
```

## Include with variables

Parameterize included paths:

```yaml
# compose.yml
include:
  - path: ./services/${SERVICE_SET:-standard}.yml
  - path: ./configs/${REGION:-us-east}.yml

services:
  app:
    image: myapp:${VERSION:-latest}
```

Usage:
```bash
# Default configuration
docker compose up

# Custom service set and region
SERVICE_SET=premium REGION=eu-west docker compose up
```

## Pro tip

Validate complex include structures:

```bash
#!/bin/bash
# validate-compose.sh

echo "Validating Compose configuration..."

# Check all included files exist
for file in $(grep -E '^\s*- path:' compose.yml | awk '{print $3}'); do
  if [ ! -f "$file" ]; then
    echo "❌ Missing include: $file"
    exit 1
  fi
  echo "✓ Found: $file"
done

# Validate final configuration
if docker compose config > /dev/null 2>&1; then
  echo "✅ Configuration valid"

  # Show final service list
  echo "Services configured:"
  docker compose config --services | sed 's/^/  - /'
else
  echo "❌ Configuration invalid"
  docker compose config
  exit 1
fi
```

Modular configurations scale with your project!

## Further reading

- [Compose include specification](https://docs.docker.com/compose/compose-file/14-include/)
- [Compose file merging](https://docs.docker.com/compose/multiple-compose-files/merge/)