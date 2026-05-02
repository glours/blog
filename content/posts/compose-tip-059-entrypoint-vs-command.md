---
title: "Docker Compose Tip #59: entrypoint vs command"
date: 2026-05-06T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Understand the subtle but important difference between entrypoint and command, and when to use each"
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

Both `entrypoint` and `command` define what runs when a container starts. They look similar, but they play different roles, and confusing them leads to surprising behavior.

## The mental model

When a container starts, Docker runs:

```
<entrypoint> <command>
```

- `entrypoint` is the executable
- `command` is the default arguments passed to it

If the image's Dockerfile has `ENTRYPOINT ["python"]` and `CMD ["app.py"]`, the container runs `python app.py`.

## Overriding from Compose

Both can be overridden in Compose:

```yaml
services:
  app:
    image: python:3.12
    entrypoint: ["python"]
    command: ["app.py", "--debug"]
```

This runs `python app.py --debug` regardless of what the image's Dockerfile defined.

## When you typically only set command

Most of the time, you just want to run a different command on an image:

```yaml
services:
  # Run tests instead of the default app
  tests:
    image: myapp
    command: ["pytest", "tests/"]

  # Run a one-off migration
  migrate:
    image: myapp
    command: ["./migrate.sh"]
```

The image's `ENTRYPOINT` (often `python`, `node`, or `/entrypoint.sh`) handles the executable, and you just pass different arguments.

## When you set entrypoint

Override `entrypoint` when you want to bypass the image's default executable:

```yaml
services:
  # Image normally starts the app, but here we want a shell
  debug:
    image: myapp
    entrypoint: ["/bin/sh"]
    command: ["-c", "env && tail -f /dev/null"]
```

To completely disable the image's entrypoint and run a fresh command:

```yaml
services:
  app:
    image: myapp
    entrypoint: []
    command: ["echo", "hello from compose"]
```

## Exec form vs shell form

There are two syntaxes:

```yaml
# Exec form (recommended) — array, runs directly
command: ["python", "app.py"]

# Shell form — string, runs through /bin/sh -c
command: python app.py
```

Exec form is preferred because:
- Signals (SIGTERM, etc.) reach your process directly ([Tip #44](/posts/compose-tip-044-signal-handling/))
- No shell expansion gotchas
- Faster startup (one less process)

Use shell form only when you need shell features:

```yaml
command: bash -c "wait-for-db && python app.py"
```

## Override at runtime

`docker compose run` lets you override both at runtime:

```bash
# Override command
docker compose run --rm app pytest tests/

# Override entrypoint with --entrypoint
docker compose run --rm --entrypoint /bin/sh app
```

This is the cleanest way to debug a misbehaving service ([Tip #34](/posts/compose-tip-034-exec-vs-run/)).

## A common gotcha

If you define `command:` in Compose but the image already has an `ENTRYPOINT` that doesn't expect arguments, things break:

```dockerfile
# Dockerfile
ENTRYPOINT ["/start.sh"]
```

```yaml
# compose.yml
services:
  app:
    image: myapp
    command: ["bash"]   # Becomes: /start.sh bash — probably not what you want
```

Either set `entrypoint: []` to clear the image's entrypoint, or use the existing entrypoint as designed.

## Further reading

- [Compose specification: entrypoint](https://docs.docker.com/reference/compose-file/services/#entrypoint)
- [Compose specification: command](https://docs.docker.com/reference/compose-file/services/#command)
- Related: [Tip #34, Debugging with exec vs run](/posts/compose-tip-034-exec-vs-run/)
- Related: [Tip #44, Signal handling in containers](/posts/compose-tip-044-signal-handling/)
