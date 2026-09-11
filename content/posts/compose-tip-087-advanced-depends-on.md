---
title: "Docker Compose Tip #87: The depends_on options tip #3 didn't cover"
date: 2026-09-18T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "runtime", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "service_completed_successfully, restart: true, and required: false: three depends_on options beyond condition: service_healthy."
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

[Tip #3](/posts/compose-tip-003-depends-on-healthcheck/) stopped at `condition: service_healthy`. The long-form `depends_on` syntax has three more fields, each solving a different problem:

```yaml
services:
  api:
    build: .
    depends_on:
      migrate:
        condition: service_completed_successfully
      cache:
        condition: service_started
        restart: true
      metrics:
        condition: service_started
        required: false
```

## service_completed_successfully: wait for a one-shot to finish

`service_healthy` waits for a long-running service to become ready. `service_completed_successfully` waits for a service to *exit*, and only starts the dependent if it exited zero:

```yaml
services:
  migrate:
    build: .
    command: ["./migrate.sh"]

  api:
    build: .
    depends_on:
      migrate:
        condition: service_completed_successfully
```

If `migrate` exits non-zero, `api` never starts and the error names exactly which dependency failed: `service "migrate" didn't complete successfully: exit 1`.

## restart: true: only means something to docker compose restart

This one is easy to misread as "restart me if the dependency container restarts." It doesn't do that. It only fires on an explicit `docker compose restart`: run `docker compose restart cache`, and every service that declared `cache` as a dependency with `restart: true` restarts right after it. A `restart: always` policy killing and reviving `cache` on its own, or `docker compose up` recreating it, doesn't trigger anything here. `restart: true` is scoped to the one CLI command.

## required: false: warn instead of block

By default a missing or failing dependency blocks the dependent, and `required` defaults to `true`. Set it to `false` and Compose downgrades a hard failure to a warning, then proceeds anyway:

```yaml
services:
  metrics:
    image: prom/statsd-exporter

  api:
    build: .
    depends_on:
      metrics:
        condition: service_started
        required: false
```

No `metrics` container at all: `api` still starts. Compose just logs `api is missing dependency metrics`. Combine it with `service_completed_successfully` for a seed or migration step you want to attempt but never block local dev on: a failed optional run logs `optional dependency "migrate" didn't complete successfully: exit 1` and `api` starts anyway.

## Pro tip

`required: false` changes what happens when Compose gives up, not whether it waits first. If `metrics` has a container running, Compose polls its condition every 500ms exactly like a required dependency. `required` only decides whether a failed or timed-out wait becomes a hard error or a warning. It's only when there's no `metrics` container running at all that Compose skips straight to that decision, since there's nothing left to poll.

## Further reading

- [Compose specification: depends_on](https://docs.docker.com/reference/compose-file/services/#depends_on)
- Related: [Tip #3, Service dependencies with health checks](/posts/compose-tip-003-depends-on-healthcheck/)
