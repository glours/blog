---
title: "Docker Compose Tip #76: docker compose down and its options"
date: 2026-06-15T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "cli", "debugging", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "What docker compose down actually removes, and the flags that decide whether you keep your data, your images, and your sibling services."
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

`docker compose down` looks like a tidy shutdown command. It is, but the flags around it decide whether you walk away with your data intact, with a clean image store, or with a database wiped because you typed `-v` out of habit.

## The default behavior

Without any flag, `down` stops and removes:

- Every container in the project
- The default network Compose created for the project
- Anonymous volumes that the stack was using

It does **not** remove:

- Named volumes (your data is safe)
- Images
- External networks declared with `external: true`
- Containers for services that exist outside the current Compose file

```bash
docker compose down
```

Run it in the same directory as the `compose.yaml` and the project name is inferred from the directory (or from `name:` / `-p`). Run it from elsewhere with `docker compose -p <project> down` to target a specific stack.

## -v / --volumes — the footgun

`-v` removes named volumes declared in the file *and* anonymous volumes attached to containers:

```bash
docker compose down -v
```

This is the right command after a failed migration test or when you want a truly clean slate. It is the wrong command on a stack with a Postgres named volume you've spent the morning populating. There is no confirmation prompt.

A safer habit: type the full long form `--volumes` when you actually mean it, and never alias `down` to `down -v`.

## --rmi local / all — also remove images

`--rmi` deletes images associated with the project:

```bash
# Only images built by this Compose project (no tag, or tagged with the project name)
docker compose down --rmi local

# Every image referenced by the project, including pulled ones
docker compose down --rmi all
```

`local` is the one you usually want for a teardown: it removes the images this project produced without nuking shared base images other stacks rely on.

## --remove-orphans

If services have been renamed or removed from the file, the old containers stick around. `--remove-orphans` cleans them up:

```bash
docker compose down --remove-orphans
```

Same idea applies on `up`: if Compose detects orphan containers it warns you, and `up --remove-orphans` (or the `COMPOSE_REMOVE_ORPHANS=true` env var) removes them automatically.

## -t / --timeout

How long Compose waits for containers to stop gracefully before sending SIGKILL:

```bash
docker compose down -t 60
```

Default is `10` seconds — fine for stateless services, often too short for databases. Pair it with `stop_grace_period` in the file ([Tip #18](/posts/compose-tip-018-graceful-shutdown/)) for per-service tuning.

## Targeting specific services

`down` is project-scoped — you cannot pass service names to it. To stop a single service, use `stop` and `rm`:

```bash
docker compose stop api
docker compose rm -f api
```

Or, for an in-place restart of just one service, `docker compose up <service>` ([Tip #7](/posts/compose-tip-007-restart-single/)).

## A teardown playbook

For a one-shot demo, finishing a workshop, or wiping a local dev environment:

```bash
# 1. Stop and remove everything, including data
docker compose down -v --remove-orphans

# 2. Remove the images you built locally too
docker compose down -v --remove-orphans --rmi local

# 3. Confirm nothing is left behind
docker compose ls --all
docker volume ls | grep $(basename $PWD)
```

For day-to-day work, plain `docker compose down` is almost always what you want — keep your named volumes, restart fresh tomorrow.

## Pro tip: dry-run before destructive operations

`--dry-run` ([Tip #54](/posts/compose-tip-054-dry-run/)) works on `down` too. Before the all-flags-on teardown:

```bash
docker compose down -v --rmi all --remove-orphans --dry-run
```

The output lists every container, volume, network, and image Compose intends to remove. Reading that list once is cheaper than restoring from backup.

## Further reading

- [Compose CLI: down](https://docs.docker.com/reference/cli/docker/compose/down/)
- Related: [Tip #18, Graceful shutdown with stop_grace_period](/posts/compose-tip-018-graceful-shutdown/)
- Related: [Tip #54, docker compose --dry-run to preview changes](/posts/compose-tip-054-dry-run/)
- Related: [Tip #74, docker compose ls and cross-project visibility](/posts/compose-tip-074-compose-ls/)
