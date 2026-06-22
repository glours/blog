---
title: "Docker Compose Tip #81: tty and stdin_open for interactive containers"
date: 2026-06-26T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "development", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Why interactive services in Compose need both tty: true and stdin_open: true — the Compose equivalent of docker run -it."
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

Drop a `bash` or `python` service into a `compose.yaml` and it exits immediately on `up`. The container starts, sees no stdin, prints nothing, and stops. The fix is the Compose equivalent of `docker run -it`: `tty: true` and `stdin_open: true`.

## What each flag does

The two flags map directly to the docker run flags everyone has typed a thousand times:

- `stdin_open: true` ⇔ `docker run -i` — keep STDIN open even when not attached.
- `tty: true` ⇔ `docker run -t` — allocate a pseudo-TTY.

```yaml
services:
  shell:
    image: alpine
    command: sh
    stdin_open: true
    tty: true
```

Set both for an interactive shell. Set only `tty: true` for a process that wants a terminal (for color output, line-buffered logs) but doesn't read from stdin. `stdin_open: true` alone is rare — almost always paired with `tty`.

## The Compose-specific gotcha

Setting these on a service started by `docker compose up` is half the story. By default, `up` attaches all services in a single multiplexed terminal — keystrokes don't go to one specific container. Two things make the interactive flow actually work:

1. Start only the interactive service in the foreground, or
2. Use `docker compose attach <service>` after `up -d`, or
3. Use `docker compose run` ([Tip #79](/posts/compose-tip-079-compose-run-advanced/)) which always attaches.

A reproducible pattern:

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: dev

  psql:
    image: postgres:16
    depends_on: [db]
    command: psql -h db -U postgres
    stdin_open: true
    tty: true
```

```bash
docker compose up -d db
docker compose run --rm psql
```

The `psql` service is shaped to be interactive; `run` is the verb that actually lets you type into it.

## Real use cases

Where `tty: true` + `stdin_open: true` earn their keep:

- **Debug toolboxes**: a service like `image: nicolaka/netshoot` you bring up on demand to poke at the network.
- **Language REPLs**: pinned versions of `python`, `node`, `ghci`, `irb` in a stack so contributors hit the same interpreter.
- **CLI clients**: `redis-cli`, `mongosh`, `mysql` configured against the in-stack database.
- **Migration runners**: an interactive migration tool that asks for confirmation before each step.

A REPL example:

```yaml
services:
  app:
    build: .

  repl:
    build: .
    command: python -i
    depends_on: [app]
    volumes:
      - ./:/app
    stdin_open: true
    tty: true
```

```bash
docker compose run --rm repl
```

You're dropped into a Python REPL inside an image that already has your app's dependencies installed.

## When you need only one

- **Only `tty: true`**: a daemon that detects a TTY and switches its logging format (color, progress bars). Common with CLIs that wrap a long-running process.
- **Only `stdin_open: true`**: a service that reads piped input from stdin without needing a terminal — `command: ["sh", "-c", "cat | wc -l"]` fed from a CI step.

The everyday case is both. Tools that detect "am I running interactively" check the TTY, so set them together unless you have a specific reason not to.

## Pair with attach for hands-off scenarios

If the interactive service isn't where the action is, set `attach: false` ([Tip #75](/posts/compose-tip-075-attach-false/)) to keep its logs out of `up`. Bring it forward only when you want it:

```yaml
services:
  repl:
    image: python
    command: python -i
    stdin_open: true
    tty: true
    attach: false      # hidden during normal `up`
```

```bash
docker compose attach repl   # surface it on demand
```

## Pro tip: docker run -it muscle memory

If your fingers still type `docker run -it`, the Compose equivalent of each letter is worth memorising once:

- `-i` → `stdin_open: true`
- `-t` → `tty: true`

The reverse cheat works too: when reading a `compose.yaml` with both flags set, picture it as `-it` and the intent of the service becomes obvious.

## Further reading

- [Compose specification: tty](https://docs.docker.com/reference/compose-file/services/#tty)
- [Compose specification: stdin_open](https://docs.docker.com/reference/compose-file/services/#stdin_open)
- Related: [Tip #79, docker compose run advanced flags](/posts/compose-tip-079-compose-run-advanced/)
- Related: [Tip #75, Silencing noisy services with attach: false](/posts/compose-tip-075-attach-false/)
- Related: [Tip #34, Debugging with docker compose exec vs run](/posts/compose-tip-034-exec-vs-run/)
