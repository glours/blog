---
title: "Docker Compose Tip #82: pre_start hooks and native init containers"
date: 2026-09-07T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "configuration", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Compose 5.3 adds pre_start, a lifecycle hook that runs as its own ephemeral init container before the service starts."
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

Tips are back after the summer break, and there are three months of Compose releases to catch up on, v5.2.0 through v5.5.1 shipped while the series was paused. The biggest addition: native init containers, through a new `pre_start` lifecycle hook.

## What pre_start does

[Tip #41](/posts/compose-tip-041-lifecycle-hooks/) covered `post_start` and `pre_stop`, which run a command inside the already-running service container. `pre_start` is different: each step runs in its own ephemeral container, created after the service container exists but before it starts. It also waits on the service's own `depends_on` conditions first, so a step can talk to those dependencies exactly like the main service command does.

```yaml
services:
  db:
    image: postgres:17
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]

  api:
    build: .
    depends_on:
      db:
        condition: service_healthy
    pre_start:
      - image: myapp-migrate
        command: ["./migrate.sh", "up"]
```

The migration runs to completion in its own container, using its own image, before `api` ever starts. A non-zero exit blocks the service, and anything depending on it.

## A step, not just a command

Each `pre_start` entry takes the same fields as `post_start`: `command`, `user`, `privileged`, `working_dir`, `environment`, plus two more: `image` and `per_replica` (covered below). Omit `image` and the step reuses the service's own image (including one built by `build:`), which is enough for most migration or seed scripts. Set it when the init logic needs different tooling than the service image itself.

The step joins the service's networks and shares its declared volumes, so it can reach `depends_on` services and read or write files the service will need.

## Steps run in order

`pre_start` takes a list, not a single entry, and runs each step sequentially in declared order. It's the same idiom as chaining `post_start` commands: a non-zero exit from any step stops the whole sequence there, exactly like a failing `post_start` command skips the ones declared after it:

```yaml
services:
  api:
    build: .
    pre_start:
      - image: myapp-migrate
        command: ["./wait-for-schema.sh"]
      - image: myapp-migrate
        command: ["./migrate.sh", "up"]
```

The first step exiting cleanly is what lets the second one run at all. Each step's output streams alongside the rest of `up`, tagged `api pre_start[0] ->` and `api pre_start[1] ->`, so you can tell which one printed what.

## A failed step stays around for inspection

Since 5.5.1, a failing step isn't cleaned up. The error names the container and keeps it, output tail included:

```
service "api" pre_start[1] exited with code 1: pg_dump: error: connection to server failed (hook container 3f9a2b1c4d5e retained for inspection)
```

`docker logs 3f9a2b1c4d5e` or `docker inspect` picks up from there. Compose removes it automatically the next time the step runs, whether that run succeeds or fails again.

## Ctrl-C during a step doesn't leave one behind

Retention only happens on a genuine hook failure. Interrupting `up` with Ctrl-C while a `pre_start` step is still running, unrelated to whether it would have succeeded, is a different code path entirely: Compose kills and removes that container right away and reports a plain cancellation instead of a status-code error.

## Runs once, not per replica

By default, `pre_start` runs once for the service as a whole, before the first replica starts, not once per replica. The spec also defines `per_replica: true` for per-instance init work, but the Compose CLI doesn't implement it yet; setting it fails at `up`, not at `config`. Stick to the default until that lands.

## When it runs, and when it's skipped

The gate is simpler than a specific list of triggers: `pre_start` runs whenever no replica of the service is currently running. The first `docker compose up` hits that case, and so do a previous attempt that failed, a changed `pre_start` definition, `--force-recreate`, or a plain `docker compose stop` followed by `up` or `start` again. Run `up` again with a replica already running and nothing changed, and it's skipped.

Scaling a service up creates a new container too, but the guard requires *every* replica to be non-running first, so the already-running ones exempt the new one. A container restarting under its own `restart` policy is a different case entirely: that happens inside the engine, bypassing Compose's start flow, so `pre_start` never even gets asked.

## Pro tip: pick the hook by timing, not habit

Default to `post_start`, it's simpler and needs no extra image. Reach for `pre_start` only when the task must finish *before* traffic hits the service, or needs tooling the service image shouldn't ship.

## Further reading

- [Compose specification: pre_start](https://docs.docker.com/reference/compose-file/services/#pre_start)
- [Docker Compose: Using init containers](https://docs.docker.com/compose/how-tos/init-containers/)
- Related: [Tip #41, Container lifecycle hooks](/posts/compose-tip-041-lifecycle-hooks/)
