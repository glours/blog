---
title: "Docker Compose Tip #92: Compose now tells you when an attribute does nothing"
date: 2026-10-14T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "debugging"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Compose 5.6.0 warns the moment it loads a schema-valid attribute it has never honored outside Swarm mode, like deploy.update_config or credential_spec, instead of silently ignoring it."
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

`deploy.update_config`, `credential_spec`, `ports[].mode: host`: every one of these is valid against the compose-spec schema, and none of them has ever done anything to a plain `docker compose up`. They're Swarm-only. Before Compose 5.6.0, a file carrying any of them loaded without complaint, and whatever behavior you expected from reading the spec just never showed up, with no hint why.

## What changed

Load a file with one of these attributes now, and Compose says so:

```yaml
services:
  web:
    image: nginx:alpine
    deploy:
      update_config:
        parallelism: 2
    credential_spec:
      file: my-credential-spec.json
```

```
$ docker compose up
WARN[0000] service "web": credential_spec: credential_spec is only supported when running Windows containers under Swarm
WARN[0000] service "web": deploy.update_config: deploy.update_config only applies to rolling updates in Swarm mode
```

The warning fires on `up`, `create`, `config`, `pull`, `build`, `run`, `viz`, `watch`, `publish`, `scale`, `push`, and `bridge convert`. Shell completion skips it on purpose, the same way it skips environment resolution: it only needs service names, and a missing `env_file` or an unsupported attribute shouldn't get in the way of pressing tab.

## The full list

Outside Swarm mode, these are flagged on sight: `deploy.mode`, `deploy.labels`, `deploy.update_config`, `deploy.rollback_config`, `deploy.endpoint_mode`, `deploy.placement`, `credential_spec`, `configs[].labels`, `secrets[].driver_opts`, `secrets[].labels`, `ports[].mode: host` specifically (not every `ports[].mode` value), `volumes[].type: cluster`, and a per-reference `uid`/`gid`/`mode` set directly on a service's `configs:`/`secrets:` entry.

## Why it matters

This is built as an allowlist, not a denylist. Compose walks every attribute path the compose-spec schema declares and flags anything not on the list of what this runtime actually honors. That means an attribute the spec adds tomorrow, one nobody has taught this check about yet, gets a generic warning the moment it shows up in a file, instead of silently doing nothing until someone notices and files an issue. The known cases above get a specific reason; anything new just says it isn't honored outside Swarm mode.

## Pro tip: don't confuse this with a validation error

The warning doesn't block anything. The attribute stays in the file, `up` still runs, and the rest of the service behaves normally. It only tells you that one specific field is dead weight for the runtime you're actually using. If you copy-pasted a `deploy:` block from a Swarm stack file expecting rolling-update behavior from Compose, this is the warning that tells you to look elsewhere (a `restart` policy, a health check, your orchestrator) instead of wondering why `update_config` never seems to trigger.

## Further reading

- [Compose spec: deploy](https://github.com/compose-spec/compose-spec/blob/master/deploy.md)
- Related: [Tip #29, Container capabilities and security options](/posts/compose-tip-029-container-capabilities/)
