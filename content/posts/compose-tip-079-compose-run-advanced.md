---
title: "Docker Compose Tip #79: docker compose run advanced flags"
date: 2026-06-22T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "cli", "development", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Beyond docker compose run service cmd: the flags that turn it into a precise one-shot tool — --rm, --service-ports, --entrypoint, --build, --no-deps."
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

`docker compose run` creates a fresh container for a service and attaches your terminal to it. Compared to `exec` ([Tip #34](/posts/compose-tip-034-exec-vs-run/)), which jumps into a *running* container, `run` is for one-shot tasks — migrations, ad-hoc scripts, REPLs, smoke tests. The flags around it decide what gets started, what gets cleaned up, and whether ports are published.

## --rm — clean up after exit

By default, the container created by `run` stays around (stopped) after the command finishes. That accumulates dead containers fast in a dev loop. `--rm` removes the container as soon as it exits:

```bash
docker compose run --rm api npm test
```

Use it on every interactive or short-lived invocation. The only reason not to is when you need to inspect logs or filesystem state afterwards.

## --service-ports — actually publish the ports

A surprise for newcomers: `run` does **not** publish the ports declared in the service definition by default. Compose avoids clashing with whatever might already be running from `up`.

```yaml
services:
  web:
    image: myweb
    ports:
      - "8080:80"
```

```bash
docker compose run --rm web                # 8080 is NOT bound
docker compose run --rm --service-ports web  # 8080 IS bound
```

Reach for `--service-ports` when running the service interactively (e.g., a dev server you want to hit from your browser).

## -e / --env — ad-hoc environment variables

Override or add env vars for a single invocation, without editing the file:

```bash
docker compose run --rm \
  -e LOG_LEVEL=debug \
  -e FEATURE_FLAG=experimental \
  api ./bin/run-once.sh
```

Useful for debugging a specific run, toggling a flag, or injecting a test secret without polluting the environment of `up`.

## --entrypoint — override the entrypoint

`run` lets you replace the image's entrypoint for the duration of the command:

```bash
# The image's entrypoint is /app/start.sh — bypass it to get a shell
docker compose run --rm --entrypoint sh api
```

Combined with `--rm`, this is the canonical "give me a shell in a freshly built image" command.

## --build — rebuild before running

If the service has a `build:` section, `--build` rebuilds the image before starting the container:

```bash
docker compose run --rm --build api ./tests.sh
```

Equivalent to `docker compose build api && docker compose run --rm api ./tests.sh`, just shorter. Reach for it when you're iterating on the Dockerfile and want each `run` to pick up the latest layers.

## --no-deps — skip the dependency graph

By default, `run service` also starts every service in `depends_on`. For a quick command that doesn't need them, that's wasted setup:

```bash
# Spin up db + redis + their deps, then run
docker compose run --rm api ./check-config.py

# Just run, ignore depends_on
docker compose run --rm --no-deps api ./check-config.py
```

If `up` is already running the stack, `--no-deps` is also the right flag — Compose won't try to start them again.

## -v / --volume — one-off bind mount

Inject a host path into the container for a single run:

```bash
docker compose run --rm \
  -v "$(pwd)/seed.sql:/tmp/seed.sql:ro" \
  db psql -U postgres -f /tmp/seed.sql
```

Handy for one-time seeding, dumping data out to the host, or testing a script that lives outside the build context.

## --name — pin the container name

`run`-created containers default to `<project>-<service>-run-<hash>`. Give it a memorable name when you want to attach later or reference it in logs:

```bash
docker compose run --rm --name api-debug api sh
# In another terminal: docker logs api-debug
```

## A common combo: shell inside a built image

The flag combo you reach for most often when poking at a misbehaving build:

```bash
docker compose run --rm \
  --no-deps \
  --entrypoint sh \
  --build \
  api
```

Rebuilds the image, drops you into a shell, doesn't bring up dependencies, and cleans up when you exit.

## Pro tip: aliases for the long forms

The flag set quickly becomes muscle memory, but the typing isn't. A pair of aliases pays off:

```bash
alias dcr='docker compose run --rm'
alias dcrsh='docker compose run --rm --no-deps --entrypoint sh'
```

Then `dcrsh api` opens a clean shell in the API image without spinning up the rest of the stack.

## Further reading

- [Compose CLI: run](https://docs.docker.com/reference/cli/docker/compose/run/)
- Related: [Tip #34, Debugging with docker compose exec vs run](/posts/compose-tip-034-exec-vs-run/)
- Related: [Tip #76, docker compose down and its options](/posts/compose-tip-076-compose-down-options/)
- Related: [Tip #59, entrypoint vs command](/posts/compose-tip-059-entrypoint-vs-command/)
