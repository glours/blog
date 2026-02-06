---
title: "Docker Compose Tip #27: Extension fields as metadata for tools and platforms"
date: 2026-02-10T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "metadata", "kubernetes", "compose-bridge", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Use extension fields to store metadata for tools, platforms, and deployment environments"
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

Extension fields aren't just for YAML reusability - they're powerful metadata carriers that tools can leverage for platform-specific configurations!

## Extension fields as metadata

Any key starting with `x-` is ignored by Compose but preserved in the configuration:

```yaml
# Top-level metadata
x-project-version: "2.1.0"
x-team: "platform-engineering"
x-environment: "production"
x-region: "us-east-1"

services:
  api:
    image: myapi:latest
    # Service-level metadata
    x-tier: "frontend"
    x-cost-center: "engineering"
    x-sla: "99.9"
    x-owner: "api-team@company.com"
```

## Compose Bridge and Kubernetes integration

Extension fields can provide hints for Kubernetes deployment:

```yaml
# Kubernetes-specific metadata
x-kubernetes:
  namespace: production
  ingress-class: nginx
  storage-class: fast-ssd

services:
  web:
    image: webapp:v2
    x-kubernetes:
      replicas: 3
      node-selector:
        zone: us-east-1a
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
    x-deploy:
      update-strategy: "RollingUpdate"
      max-surge: 1
      max-unavailable: 0
```

## Platform-specific configurations

Different deployment platforms can read their own extension fields:

```yaml
# Multi-platform metadata
services:
  database:
    image: postgres:15

    # AWS-specific
    x-aws:
      instance-type: "db.r5.large"
      backup-retention: 7
      multi-az: true

    # Azure-specific
    x-azure:
      sku: "GP_Gen5_4"
      backup-redundancy: "Geo"

    # GCP-specific
    x-gcp:
      machine-type: "db-n1-standard-4"
      backup-location: "us-central1"
      high-availability: true
```

## Tool integration examples

**CI/CD pipelines:**
```yaml
services:
  app:
    build: .
    x-ci:
      test-command: "npm test"
      coverage-threshold: 80
      deploy-branch: "main"
      rollback-on-failure: true
```

**Monitoring and observability:**
```yaml
services:
  api:
    image: api:latest
    x-monitoring:
      alert-threshold-cpu: 80
      alert-threshold-memory: 90
      dashboard-url: "https://grafana.company.com/d/api-metrics"
      slo-target: 99.95
```

**Cost tracking:**
```yaml
services:
  worker:
    image: worker:latest
    x-cost:
      center: "CC-1234"
      project: "data-processing"
      environment: "production"
      estimated-monthly: 450
```

## Using extension fields programmatically

Read and process metadata in your tools:

```bash
#!/bin/bash
# extract-metadata.sh

# Get service owner
docker compose config | yq '.services.api["x-owner"]'

# List all services with their tier
docker compose config | yq '.services | to_entries | .[] |
  select(.value["x-tier"]) |
  {service: .key, tier: .value["x-tier"]}'

# Extract Kubernetes annotations
docker compose config | yq '.services.web["x-kubernetes"].annotations'
```

## Compose Bridge example

When using Compose Bridge to deploy to Kubernetes:

```yaml
x-default-resources: &resources
  limits:
    cpu: "1"
    memory: "512Mi"
  requests:
    cpu: "0.5"
    memory: "256Mi"

services:
  frontend:
    image: frontend:v1
    x-kubernetes:
      service-type: "LoadBalancer"
      ingress:
        enabled: true
        host: "app.example.com"
        tls: true
    deploy:
      resources:
        <<: *resources

  backend:
    image: backend:v1
    x-kubernetes:
      service-type: "ClusterIP"
      pod-annotations:
        linkerd.io/inject: enabled
    deploy:
      replicas: 3
```

## Validation and schemas

Define schemas for your extension fields:

```yaml
# compose-schema.yml
x-schema:
  required-fields:
    - x-owner
    - x-environment
  environments:
    - development
    - staging
    - production

services:
  app:
    image: app:latest
    x-owner: "platform-team"
    x-environment: "production"
    x-compliance:
      gdpr: true
      pci-dss: false
      sox: true
```

## Pro tip: Automated documentation

Generate documentation from extension fields:

```python
#!/usr/bin/env python3
# generate-docs.py

import yaml
import json

def extract_service_metadata(compose_file):
    with open(compose_file, 'r') as f:
        config = yaml.safe_load(f)

    docs = {
        "project": {
            "version": config.get('x-project-version', 'unknown'),
            "team": config.get('x-team', 'unknown'),
            "environment": config.get('x-environment', 'unknown')
        },
        "services": {}
    }

    for name, service in config.get('services', {}).items():
        metadata = {k: v for k, v in service.items() if k.startswith('x-')}
        if metadata:
            docs['services'][name] = metadata

    return docs

# Generate markdown documentation
metadata = extract_service_metadata('compose.yml')
print(f"# Service Catalog\n")
print(f"**Version:** {metadata['project']['version']}")
print(f"**Team:** {metadata['project']['team']}")
print(f"**Environment:** {metadata['project']['environment']}\n")

for service, data in metadata['services'].items():
    print(f"## {service}")
    for key, value in data.items():
        print(f"- **{key[2:]}:** {value}")
```

Extension fields: Your bridge between Compose and the wider ecosystem!

## Further reading

- [Compose specification - Extension](https://github.com/compose-spec/compose-spec/blob/master/spec.md#extension)
- [Compose Bridge documentation](https://github.com/docker/compose-bridge)