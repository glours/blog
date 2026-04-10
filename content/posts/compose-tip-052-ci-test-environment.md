---
title: "Docker Compose Tip #52: Setting up a CI test environment"
date: 2026-04-13T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "devops", "ci-cd", "testing", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Use Compose override files to create a dedicated CI environment with seeded database and automated tests"
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

Your development Compose file isn't your CI Compose file. A dedicated CI configuration ensures tests run against a clean, seeded database with no leftover state.

## The development stack

Take a typical full-stack project like [dockersamples/sbx-quickstart](https://github.com/dockersamples/sbx-quickstart) — a FastAPI backend with a Next.js frontend and PostgreSQL:

```yaml
# compose.yml
services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db:5432/devboard
    depends_on:
      db:
        condition: service_healthy

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"

  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: devboard
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 5s
      retries: 5

volumes:
  db-data:
```

## Adding a CI override

Create a `compose.ci.yml` that adapts the stack for testing:

```yaml
# compose.ci.yml
services:
  db:
    # No persistent volume in CI — fresh database every run
    volumes:
      - ./backend/tests/seed.sql:/docker-entrypoint-initdb.d/seed.sql:ro

  backend:
    # No port exposure needed — tests run inside the network
    ports: !reset []
    environment:
      TESTING: "true"

  frontend:
    # Not needed for API tests
    profiles: ["frontend"]

  tests:
    build: ./backend
    command: pytest tests/ -v --tb=short
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db:5432/devboard
    depends_on:
      backend:
        condition: service_started
      db:
        condition: service_healthy
```

Key decisions:
- **Database seeding**: mount a SQL file into `/docker-entrypoint-initdb.d/` — Postgres runs it automatically on init
- **No volumes**: the `db-data` volume from the base file is not mounted, so every run starts fresh
- **Frontend disabled**: moved to a profile so it's not started during API tests
- **Test service added**: runs pytest against the backend through the Compose network

## The seed file

```sql
-- backend/tests/seed.sql
INSERT INTO users (username, email) VALUES
  ('testuser1', 'test1@example.com'),
  ('testuser2', 'test2@example.com');

INSERT INTO projects (name, owner_id) VALUES
  ('Test Project', 1);
```

## Running in CI

```bash
# Start stack, wait for health, run tests, return test exit code
docker compose -f compose.yml -f compose.ci.yml up \
  --build \
  --exit-code-from tests

# Clean teardown — remove volumes for a fresh next run
docker compose -f compose.yml -f compose.ci.yml down --volumes
```

The `--exit-code-from tests` flag makes the command return the exit code of the `tests` service — so your CI pipeline fails if tests fail.

## Using --wait for multi-step workflows

If you need to run different test suites sequentially, use `--wait` ([Tip #51](/posts/compose-tip-051-up-wait/)) to start the stack first, then run tests separately:

```bash
# Start and wait for everything to be healthy
docker compose -f compose.yml -f compose.ci.yml up -d --build --wait --wait-timeout 120

# Run API tests
docker compose -f compose.yml -f compose.ci.yml exec backend pytest tests/api/ -v

# Run integration tests
docker compose -f compose.yml -f compose.ci.yml exec backend pytest tests/integration/ -v

# Clean up
docker compose -f compose.yml -f compose.ci.yml down --volumes
```

## Pro tip

Use `--project-name` to isolate parallel CI runs on the same host:

```bash
docker compose -p "ci-${BUILD_ID}" -f compose.yml -f compose.ci.yml up \
  --build --exit-code-from tests

docker compose -p "ci-${BUILD_ID}" -f compose.yml -f compose.ci.yml down --volumes
```

Each pipeline run gets its own networks and containers — no conflicts.

## Further reading

- [Compose documentation: Multiple Compose files](https://docs.docker.com/compose/how-tos/multiple-compose-files/)
- [dockersamples/sbx-quickstart](https://github.com/dockersamples/sbx-quickstart) — the example project used in this post
