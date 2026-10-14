---
title: "Docker Compose Tip #93: The ambassador pattern for environment-specific dependencies"
date: 2026-10-16T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "advanced", "networking"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Have an app always connect to localhost regardless of where a dependency actually lives, by putting a thin proxy sidecar in its network namespace instead of wiring environment logic into the app itself."
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

An app connects to Redis at `localhost:6379` in every environment, but Redis never actually lives at the same place twice: a local container in dev, a managed instance in staging, a different managed instance in prod. Something has to resolve that difference, and the easiest place to put it is scattered `if ENV == "prod"` branches in the app's own config. The ambassador pattern puts it in one disposable container instead.

## The setup

An ambassador is a proxy sidecar that shares the app's network namespace and forwards a fixed local address to wherever the real dependency actually is:

```yaml
services:
  app:
    build: .
    network_mode: "service:db-ambassador"
    depends_on:
      - db-ambassador
    environment:
      - REDIS_HOST=localhost
      - REDIS_PORT=6379

  db-ambassador:
    image: haproxy:3.0
    configs:
      - source: ambassador_cfg
        target: /usr/local/etc/haproxy/haproxy.cfg

configs:
  ambassador_cfg:
    content: |
      defaults
        mode tcp
        timeout connect 5s
        timeout client 1m
        timeout server 1m
      frontend redis_in
        bind *:6379
        default_backend redis_out
      backend redis_out
        server redis1 ${REDIS_REMOTE_HOST:?set me}:${REDIS_REMOTE_PORT:-6379}
```

`network_mode: "service:db-ambassador"` puts `app` in `db-ambassador`'s network namespace, so `app` sees `localhost:6379` as if Redis were running right next to it. `REDIS_REMOTE_HOST`/`REDIS_REMOTE_PORT` come from a `.env` file or the shell, Compose's own variable substitution, not the container's `environment:` block, and it applies just as well inside an inline `configs:` block's `content:`, so switching targets is a value in `.env`, not a line of app code:

```
# .env.staging
REDIS_REMOTE_HOST=redis.staging.internal
REDIS_REMOTE_PORT=6379
```

## Why it's not just another sidecar

[Tip #47](/posts/compose-tip-047-sidecar-patterns/) covered the sidecar pattern broadly: any helper container handling a concern the main service shouldn't carry itself (log shipping, a local cache, a metrics exporter). An ambassador is the specific flavor that only ever does one thing, stand in for a remote dependency on the local network, so the app never has to know, or care, where that dependency physically lives. The app's code stays identical across dev, staging, and prod; only the ambassador's target changes.

## Why it matters

Environment-specific connection logic (retries, TLS, service discovery, failover) lives in one small, replaceable container instead of being re-implemented or re-configured inside every service that needs the same dependency. HAProxy's own config already covers TLS termination and backend health checks, so adding either is a change to `haproxy.cfg`, not new code in every dependent service.

## Pro tip: one ambassador per namespace

`network_mode: "service:x"` shares the *entire* network namespace, not just one forwarded port. A container can only join one other container's namespace at a time, so if `app` needs ambassadors for both Redis and Postgres, that's two separate proxies, each needing its own sidecar relationship, not one ambassador juggling both. Plan for one dependency per ambassador, and expose only the ports that dependency actually needs.

## Further reading

- Related: [Tip #47, Sidecar container patterns](/posts/compose-tip-047-sidecar-patterns/)
- Related: [Tip #58, Using configs for config files](/posts/compose-tip-058-configs/)
- Related: [Tip #13, Using external networks to connect multiple projects](/posts/compose-tip-013-external-networks/)
