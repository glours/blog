---
title: "Docker Compose Tip #51: docker compose up --wait for scripting and CI"
date: 2026-04-10T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "devops", "ci-cd", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Wait for all services to be healthy before proceeding, perfect for CI pipelines and scripts"
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

`docker compose up -d` starts services in the background, but it returns immediately — before services are actually ready. `--wait` solves this by blocking until all services are healthy.

## The problem

Without `--wait`, you often end up with fragile sleep-based scripts:

```bash
# Fragile: how long is enough?
docker compose up -d
sleep 10
npm test
```

## The solution

```bash
docker compose up --wait
npm test
```

`--wait` starts services in detached mode and blocks until every service with a healthcheck reports healthy. If a service fails to become healthy, the command exits with a non-zero status.

## It requires healthchecks

`--wait` relies on healthchecks to know when services are ready. Services without healthchecks are considered ready immediately after starting:

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:7
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  app:
    image: myapp
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000/health"]
      interval: 5s
      timeout: 3s
      retries: 5
```

```bash
# Blocks until postgres, redis, AND app are all healthy
docker compose up --wait
```

## Setting a timeout

Use `--wait-timeout` to avoid waiting forever if something goes wrong:

```bash
# Wait up to 60 seconds, then fail
docker compose up --wait --wait-timeout 60
```

This is essential in CI where you don't want a broken service to hang the pipeline indefinitely.

## CI pipeline example

A typical CI workflow:

```bash
# Start the full stack and wait for health
docker compose up --wait --wait-timeout 120

# Run tests against the healthy stack
docker compose exec app npm test

# Tear down
docker compose down
```

No sleep, no polling, no flaky timing issues. The stack is guaranteed to be healthy before tests run.

## Combining with --exit-code-from

For test services that should run and exit, combine with `--exit-code-from`:

```yaml
services:
  postgres:
    image: postgres:16
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 5s

  tests:
    image: myapp-tests
    depends_on:
      postgres:
        condition: service_healthy
    command: npm test
```

```bash
# Start postgres, wait for health, run tests, return test exit code
docker compose up --exit-code-from tests
echo $?  # 0 if tests passed, non-zero otherwise
```

## Further reading

- [Docker Compose CLI: up](https://docs.docker.com/reference/cli/docker/compose/up/)
- [Compose specification: healthcheck](https://docs.docker.com/reference/compose-file/services/#healthcheck)
