---
title: "Docker Compose Tip #54: Preview changes with --dry-run"
date: 2026-04-17T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "debugging", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Use --dry-run to see what Compose will do before it actually does it"
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

Not sure what `docker compose up` will actually do? Add `--dry-run` to preview every action without executing anything.

## Basic usage

```bash
docker compose up --dry-run
```

Compose shows exactly what it *would* do:

```
DRY-RUN MODE -  Container myapp-db-1  Creating
DRY-RUN MODE -  Container myapp-db-1  Created
DRY-RUN MODE -  Container myapp-web-1  Creating
DRY-RUN MODE -  Container myapp-web-1  Created
DRY-RUN MODE -  Container myapp-db-1  Starting
DRY-RUN MODE -  Container myapp-db-1  Started
DRY-RUN MODE -  Container myapp-web-1  Starting
DRY-RUN MODE -  Container myapp-web-1  Started
```

Nothing is created, started, or modified. You just see the plan.

## Works with most commands

`--dry-run` isn't limited to `up`. It works with many Compose commands:

```bash
# What would be stopped?
docker compose down --dry-run

# What would be removed?
docker compose rm --dry-run

# What would be pulled?
docker compose pull --dry-run

# What would be restarted?
docker compose restart --dry-run
```

## Catching unexpected changes

Dry-run is especially useful when you've modified a Compose file and want to see what changed before applying:

```bash
# You just edited compose.yml — what will happen?
docker compose up -d --dry-run
```

```
DRY-RUN MODE -  Container myapp-db-1  Running
DRY-RUN MODE -  Container myapp-web-1  Recreating
DRY-RUN MODE -  Container myapp-web-1  Recreated
DRY-RUN MODE -  Container myapp-web-1  Starting
DRY-RUN MODE -  Container myapp-web-1  Started
```

You can see that only `web` will be recreated — `db` stays running. No surprises.

## Validating override files

When stacking multiple Compose files, dry-run helps verify the result before applying:

```bash
# What does the CI override actually change?
docker compose -f compose.yml -f compose.ci.yml up --dry-run

# What does the production override do?
docker compose -f compose.yml -f compose.prod.yml up --dry-run
```

This is a great safety check before running overrides in unfamiliar environments.

## Combining with --verbose

For even more detail, combine `--dry-run` with the `--verbose` flag on the docker compose command:

```bash
docker compose --verbose up --dry-run
```

## Dry-run vs config

Both are useful for debugging, but they serve different purposes:

- **`docker compose config`** — shows the resolved Compose file after interpolation and merging. It answers: "what does my configuration look like?"
- **`docker compose up --dry-run`** — shows what actions Compose would take given the current state. It answers: "what will actually happen if I run this?"

Use `config` to debug your YAML. Use `--dry-run` to debug the execution plan.

## Further reading

- [Docker Compose CLI: --dry-run](https://docs.docker.com/reference/cli/docker/compose/#use---dry-run-flag-to-test-your-command)
