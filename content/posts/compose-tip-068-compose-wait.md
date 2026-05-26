---
title: "Docker Compose Tip #68: Waiting for service exit with docker compose wait"
date: 2026-05-27T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "cli", "devops", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Block until a service exits and propagate its exit code, perfect for migration containers and CI jobs"
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

`docker compose up --wait` ([Tip #51](/posts/compose-tip-051-up-wait/)) waits for services to become *healthy*. `docker compose wait` does something different: it waits for services to *exit*, and returns their exit code.

## Basic usage

```bash
docker compose wait <service>
```

The command blocks until the specified service stops, then prints the exit code. If you echo `$?` after, it's the same value.

This is perfect for one-shot services: migrations, batch jobs, test runners, anything that runs and exits.

## A migration example

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 5s

  migrate:
    image: myapp-migrate
    command: ["./run-migrations.sh"]
    depends_on:
      db:
        condition: service_healthy

  app:
    image: myapp
    depends_on:
      db:
        condition: service_healthy
      migrate:
        condition: service_completed_successfully
```

Run the migration explicitly and only proceed if it succeeds:

```bash
docker compose up -d migrate
docker compose wait migrate

if [ $? -ne 0 ]; then
  echo "Migration failed"
  docker compose down
  exit 1
fi

docker compose up -d app
```

## wait vs up --wait

The two commands solve different problems:

| Goal | Command |
|---|---|
| Wait for services to be **ready to serve** (healthy) | `docker compose up --wait` |
| Wait for a service to **finish its work** (exit) | `docker compose wait` |

Use both together in a CI pipeline:

```bash
# Bring up the stack and wait for everything to be healthy
docker compose up -d --wait --wait-timeout 60

# Run the test suite
docker compose up -d tests

# Wait for tests to finish, propagate exit code
docker compose wait tests
TESTS_EXIT=$?

docker compose down --volumes
exit $TESTS_EXIT
```

## Waiting for multiple services

You can wait on more than one service:

```bash
docker compose wait migrate seeder
```

The command returns once **all** named services have exited. If any of them fail, the exit code reflects the failure.

## Pairing with --exit-code-from

`docker compose up --exit-code-from <service>` ([Tip #52](/posts/compose-tip-052-ci-test-environment/)) is the all-in-one alternative: start everything, wait for the named service to exit, return its exit code. `wait` gives you the same result with more control — you can start the stack first, then wait at the right moment in your script.

For simple one-step pipelines, `--exit-code-from` is cleaner. For multi-step scripts where you orchestrate services individually, `wait` is more flexible.

## Further reading

- [Docker Compose CLI: wait](https://docs.docker.com/reference/cli/docker/compose/wait/)
- Related: [Tip #51, docker compose up --wait for scripting and CI](/posts/compose-tip-051-up-wait/)
- Related: [Tip #52, Setting up a CI test environment](/posts/compose-tip-052-ci-test-environment/)
