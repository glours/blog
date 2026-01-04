---
title: "Docker Compose Tip #5: Writing Compose files for AI tools"
date: 2026-01-10T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "ai", "documentation", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to structure Compose files so AI tools understand them better"
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

AI tools work better when they understand the setup. Here's how to document Compose files effectively.

## Add context with comments

Comments help AI understand what each service does:

```yaml
services:
  # Primary web application serving React frontend
  # Handles user authentication and API gateway
  web:
    image: myapp:latest
    ports:
      - "3000:3000"  # Public facing port - update in .env for production
    environment:
      # Connection string to PostgreSQL - format: postgresql://user:pass@host:5432/db
      DATABASE_URL: ${DATABASE_URL}
      # JWT secret for auth - must be at least 256 bits
      JWT_SECRET: ${JWT_SECRET}
    depends_on:
      db:
        condition: service_healthy
    # Development only - remove for production
    volumes:
      - ./src:/app/src  # Hot reload for development

  # PostgreSQL 15 database with PostGIS extension
  # Stores user data and geographic information
  db:
    image: postgis/postgis:15-3.3
    environment:
      POSTGRES_DB: myapp
      POSTGRES_PASSWORD: ${DB_PASSWORD}  # Never commit actual password
    volumes:
      # Initial schema and seed data
      - ./init.sql:/docker-entrypoint-initdb.d/01-init.sql
      # Persistent data storage
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
    # Named volume for database persistence across container restarts
```

## File headers

For bigger projects, add a header:

```yaml
# Application: E-commerce Platform
# Environment: Development
# Required: Docker 24.0+, Compose v2.20+
#
# Services:
# - web: Next.js frontend (port 3000)
# - api: Node.js backend (port 4000)
# - db: PostgreSQL database
# - redis: Session cache
#
# Quick Start:
# 1. cp .env.example .env
# 2. docker compose up -d
# 3. Visit http://localhost:3000

name: ecommerce-dev

services:
  # ... services
```

## Document environment variables

```yaml
services:
  api:
    environment:
      # Required: External service credentials
      STRIPE_API_KEY: ${STRIPE_API_KEY:?Missing STRIPE_API_KEY}

      # Optional: Defaults provided
      LOG_LEVEL: ${LOG_LEVEL:-info}  # Options: debug, info, warn, error

      # Feature flags
      ENABLE_BETA_FEATURES: ${ENABLE_BETA:-false}  # Set to true for beta testing
```

## Useful patterns

Describe relationships:
```yaml
worker:
  # Processes background jobs from Redis queue
  # Depends on: api (for job creation), redis (for queue)
```

Explain your choices:
```yaml
nginx:
  image: nginx:alpine  # Alpine: 5MB vs 142MB regular
```

Mark the tricky parts:
```yaml
volumes:
  - ./data:/data  # WARNING: Check ownership (1000:1000)
```

## What AI can do with this

When your files are documented, AI tools can:
- Write health checks that make sense
- Spot security issues
- Generate CI/CD configs
- Create test setups
- Suggest performance improvements

## Example prompt

"Generate a production version of this Compose file with security improvements"

The AI uses your comments to understand what needs protecting and what to remove.

## Extra tip

Create an `AI-CONTEXT.md` file:
```markdown
# Project Context for AI

## Architecture
- Microservices with REST APIs
- PostgreSQL for persistent data
- Redis for caching
- nginx for reverse proxy

## Conventions
- Port 3xxx for frontend services
- Port 4xxx for backend services
- All services run as non-root
```

Then reference it:
```yaml
# See AI-CONTEXT.md for project details
services:
  # ...
```