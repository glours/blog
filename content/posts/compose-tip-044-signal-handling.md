---
title: "Docker Compose Tip #44: Signal handling in containers"
date: 2026-03-25T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Control how your containers receive and handle stop signals for graceful shutdowns"
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

When you run `docker compose down` or `docker compose stop`, Compose sends a signal to your containers. Understanding which signal is sent and how your application handles it is key to graceful shutdowns.

## Default behavior

By default, Compose sends `SIGTERM` to the main process (PID 1), waits 10 seconds, then sends `SIGKILL`:

```yaml
services:
  app:
    image: myapp
    # Default: SIGTERM, 10s grace period, then SIGKILL
```

## Changing the stop signal

Some applications expect a different signal. Nginx, for example, uses `SIGQUIT` for graceful shutdown:

```yaml
services:
  nginx:
    image: nginx
    stop_signal: SIGQUIT
    stop_grace_period: 30s
```

Common signals and their typical use:

```yaml
services:
  # SIGTERM (default) - most applications
  app:
    image: myapp
    stop_signal: SIGTERM

  # SIGQUIT - nginx graceful shutdown
  web:
    image: nginx
    stop_signal: SIGQUIT

  # SIGINT - same as Ctrl+C, useful for dev tools
  dev:
    image: node:20
    stop_signal: SIGINT

  # SIGUSR1 - custom reload/shutdown in some apps
  custom:
    image: custom-app
    stop_signal: SIGUSR1
```

## Adjusting the grace period

The `stop_grace_period` controls how long Compose waits before sending `SIGKILL`:

```yaml
services:
  # Quick shutdown for stateless services
  cache:
    image: redis
    stop_grace_period: 5s

  # More time for database connections to drain
  api:
    image: myapp-api
    stop_grace_period: 30s

  # Long-running jobs need more time
  worker:
    image: myapp-worker
    stop_grace_period: 120s
```

## The PID 1 problem

If your container runs a shell script as entrypoint, the shell (PID 1) may not forward signals to your application:

```dockerfile
# Bad: shell doesn't forward signals
ENTRYPOINT /start.sh

# Good: exec replaces shell with your process
ENTRYPOINT ["/start.sh"]
```

Or use `init: true` in Compose to add a proper init process that handles signal forwarding:

```yaml
services:
  app:
    image: myapp
    init: true   # Adds tini as PID 1
    stop_signal: SIGTERM
    stop_grace_period: 30s
```

The `init` process (tini) becomes PID 1, properly forwards signals to your application, and reaps zombie processes.

## Combining with lifecycle hooks

For maximum control, combine `stop_signal` with `pre_stop` hooks ([Tip #41](/posts/compose-tip-041-lifecycle-hooks/)):

```yaml
services:
  api:
    image: myapp-api
    pre_stop:
      - command: /bin/sh -c "curl -sf -X POST http://localhost:8080/drain"
    stop_signal: SIGTERM
    stop_grace_period: 30s
```

The sequence is: `pre_stop` runs first, then `stop_signal` is sent, then `stop_grace_period` countdown, then `SIGKILL` if still running.

## Pro tip

Use `docker compose stop -t` to override the grace period at runtime:

```bash
# Quick stop with 5 second timeout
docker compose stop -t 5

# Patient stop for long-running tasks
docker compose stop -t 300
```

## Further reading

- [Compose specification: stop_signal](https://docs.docker.com/reference/compose-file/services/#stop_signal)
- [Compose specification: stop_grace_period](https://docs.docker.com/reference/compose-file/services/#stop_grace_period)
- [Compose specification: init](https://docs.docker.com/reference/compose-file/services/#init)
