---
title: "Docker Compose Tip #75: Silencing noisy services with attach: false"
date: 2026-06-12T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "logging", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Hide noisy service logs from docker compose up without losing access to them, using attach in the Compose file or attach flags on the CLI."
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

`docker compose up` streams logs from every service in a single terminal. That works fine for two or three services. With a stack that includes a chatty proxy, a healthcheck loop, or a model server printing tokenizer warnings every second, the signal-to-noise ratio drops fast. `attach: false` tells Compose to keep the service running but stop streaming its logs to the foreground.

## Per-service in the Compose file

Mark the noisy service:

```yaml
services:
  web:
    image: myapp

  reverse-proxy:
    image: nginx
    attach: false      # logs hidden from `docker compose up`

  metrics:
    image: prom/prometheus
    attach: false
```

The reverse proxy and the metrics collector still start, still run, still serve traffic. They simply do not pollute the terminal.

The logs are not lost — `docker compose logs reverse-proxy` and `docker compose logs -f metrics` work as usual.

## Override from the CLI

`--no-attach` and `--attach` flip the decision at runtime without touching the file:

```bash
# Bring everything up but hide the proxy logs
docker compose up --no-attach reverse-proxy

# The opposite: only show logs for the API
docker compose up --attach api
```

Both flags accept the flag multiple times for several services:

```bash
docker compose up --no-attach proxy --no-attach metrics
```

`--attach` is whitelisting (only these services); `--no-attach` is blacklisting (everything except these). Pick whichever shorter list fits.

## When this matters

A few real cases where `attach: false` earns its keep:

- **Sidecars and proxies**: Envoy, Nginx, Traefik — their access logs are useful but rarely the thing you're debugging right now.
- **Model servers**: `docker/model-runner` and similar print loading progress, tokenizer warnings, and the occasional benchmark line. Hide it during application development; check it explicitly when investigating the model.
- **Background workers with verbose tracebacks** that aren't the focus of the current debugging session.
- **Healthcheck loops** that exec a probe every two seconds and dump output to stdout.

## What `attach: false` does not do

- It does not stop the service. Use `profiles` ([#24](/posts/compose-tip-024-profiles/)) or `docker compose up <list-of-services>` for that.
- It does not silence the service permanently. `docker compose logs` still streams.
- It does not affect `docker compose up -d` (detached mode) — that already returns immediately and never streams logs.

## Pair it with selective `up`

For an even tighter feedback loop, combine `attach: false` with starting only the services you're actively touching:

```bash
docker compose up api worker
```

Compose still pulls in dependencies (`depends_on`), but the foreground only attaches to `api` and `worker`. Add `--no-attach worker` if the worker also gets noisy.

## Pro tip: keep the YAML clean

Set `attach: false` in the file for services that are *always* background noise (proxies, metrics, log shippers). Use the CLI flags for one-off cases. Mixing both is fine: a service marked `attach: false` in the file can still be brought to the foreground with `--attach <name>` for one run.

## Further reading

- [Compose specification: attach](https://docs.docker.com/reference/compose-file/services/#attach)
- Related: [Using `docker compose logs` effectively](/posts/compose-tip-020-docker-compose-logs/)
- Related: [Logging drivers and options](/posts/compose-tip-033-logging-drivers/)
- Related: [Organize optional services with profiles](/posts/compose-tip-024-profiles/)
