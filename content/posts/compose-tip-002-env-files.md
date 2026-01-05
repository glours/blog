---
title: "Docker Compose Tip #2: Using --env-file for different environments"
date: 2026-01-06T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to manage dev, staging, and production configurations with env files"
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

Same compose.yml, different environments. Here's the cleanest approach.

## Basic setup

Create different env files for each environment:

**.env.dev**
```bash
DATABASE_URL=postgresql://localhost:5432/dev_db
API_KEY=dev_key_12345
LOG_LEVEL=debug
REPLICAS=1
```

**.env.prod**
```bash
DATABASE_URL=postgresql://prod-db.example.com:5432/prod_db
API_KEY=${SECURE_API_KEY}  # From CI/CD secrets
LOG_LEVEL=error
REPLICAS=3
```

## How to use them

```bash
# Development
docker compose --env-file .env.dev up

# Production
docker compose --env-file .env.prod up

# Override specific vars
API_KEY=test_key docker compose --env-file .env.dev up
```

## Layering configs

You can use multiple env files:

```bash
# Base + environment-specific
docker compose \
  --env-file .env.base \
  --env-file .env.prod \
  up
```

Note: Later files override earlier ones.

## Recommended project structure

This works well:
```
project/
├── compose.yml
├── .env              # Git-ignored, local overrides
├── .env.example      # Committed, template for team
└── environments/
    ├── .env.dev      # Development defaults
    ├── .env.staging  # Staging config
    └── .env.prod     # Production (maybe in CI/CD)
```

## Debugging

```bash
# See what Compose is using
docker compose --env-file .env.prod config

# Check specific variable
docker compose run --rm web printenv DATABASE_URL
```

## Git strategy

What I ignore:
```
.env
.env.local
.env.*.local
```

What I commit:
```
.env.example
.env.dev
```

New team members just run `cp .env.example .env` and they're ready.