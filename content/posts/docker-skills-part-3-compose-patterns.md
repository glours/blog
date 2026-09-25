---
title: "Docker Skills, Part 3: docker-compose-patterns in Depth"
date: 2026-10-02T09:00:00+02:00
draft: false
tags: ["docker-skills", "docker-compose", "ai-agents", "docker", "healthcheck"]
categories: ["Docker Skills"]
author: "Guillaume Lours"
showToc: true
TocOpen: false
hidemeta: false
comments: false
description: "A close read of docker-compose-patterns, the Docker Skills guide for wiring Compose services: health-check sidecars for distroless images, depends_on readiness rules, Compose Watch action types, and the destructive-command guardrails it bakes in."
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

`depends_on` only guarantees a container has started. It says nothing about whether the process inside is actually ready to take traffic, and a database container that's up but still replaying its init scripts will happily accept a connection from a service that then fails on its first query. `docker-compose-patterns`, the skill that fires when the task is service wiring rather than image builds, spends a good part of its rules closing that exact gap.

[Part 1](/posts/docker-skills-part-1-overview/) covered what Docker Skills is and how to install it, and [Part 2](/posts/docker-skills-part-2-build-and-foundations/) went deep on the Build family. This skill's own scope is explicit about its boundary: it activates for a new `compose.yaml`, adding or modifying services, `compose.override.yaml` setups, or debugging startup ordering and connectivity. It steps aside when there's no Docker setup at all yet (that's `docker-project-foundations`), or when the work is really about Dockerfile internals (`docker-build-strategies`).

## The rules read like a Compose file review checklist

Most of `docker-compose-patterns`' "Core guidance" section is what an experienced reviewer would already flag on a pull request: use `compose.yaml`, not the legacy `docker-compose.yml`/`docker-compose.yaml` names. Pin every image tag; never `latest`. Give services lowercase, role-based names (`web`, `db`, `cache`), and skip `container_name` unless an external tool genuinely needs a predictable one. Use named volumes for anything that must survive a container recreation, bind mounts only for development-time source syncing, and never mount the Docker socket unless the service truly requires it.

None of that is exotic, but it's exactly the kind of detail that gets skipped when an agent is focused on making a stack merely *run*.

## Readiness, not just "started"

The skill is precise about a distinction that's easy to gloss over: `depends_on` on its own only guarantees a container has *started*, not that whatever it's serving is *ready*. Its rule is to pair `depends_on` with `condition: service_healthy`, and to require that every service named that way actually has a `healthcheck` defined. For the check itself, it prefers the service's own native client tool: `pg_isready` for Postgres, `redis-cli ping` for Redis, `mysqladmin ping` for MySQL. As a starting point for timing, it suggests `interval: 5s`, `timeout: 3s`, `retries: 3`, `start_period: 10s`.

## Health checks when the image has no shell

The one genuinely non-obvious pattern in the skill is what to do when the service image is distroless, scratch-based, or otherwise hardened: no shell, no `curl`, no `wget` to run a check with. The skill's rule is explicit: don't bake diagnostic tools into a hardened image just to satisfy a healthcheck, since that defeats the point of using it. Instead, run the check from a tiny sidecar that shares the target container's network namespace:

```yaml
services:
  api:
    build:
      context: .
      target: runtime          # distroless / hardened image
    ports:
      - "8080:8080"
    # No healthcheck here — the image has no tools to run one

  api-health:
    image: curlimages/curl:8
    network_mode: "service:api"   # shares api's localhost
    entrypoint: ["sleep", "infinity"]  # keep sidecar alive for healthcheck
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 45s
    deploy:
      resources:
        limits:
          memory: 32M
```

The mechanics worth noting: `network_mode: "service:api"` makes `localhost` inside `api-health` resolve to `api`'s own loopback, so no extra networking is needed to reach it. The sidecar needs an `entrypoint` that keeps it alive (`sleep infinity`) purely so Compose has a running container to execute the healthcheck inside. And anything downstream that needs to wait on `api` being ready has to depend on the sidecar, not on `api` directly, since `api` itself carries no healthcheck:

```yaml
  worker:
    depends_on:
      api-health:
        condition: service_healthy
```

It's a small pattern, but it's the kind of thing that's easy to get subtly wrong without a reference: forgetting the `entrypoint`, forgetting which service the downstream dependency should actually point at, or reaching for a shell-based check that silently fails on an image that has none.

## Compose Watch, mapped to action types

For development workflows, the skill prefers `develop.watch` over hand-rolled bind mounts, and it maps the three watch actions to concrete file categories rather than leaving the choice to guesswork: `action: sync` for source files that should just be copied in, `action: rebuild` for dependency manifests like `package.json` or `requirements.txt` that require a full image rebuild, and `action: sync+restart` for configuration files that need the process restarted but not the whole image rebuilt.

## Destructive commands get their own guardrail

Compose has several commands that delete data with no undo, and the skill treats them as a distinct category rather than folding them into general advice: `docker compose down -v` (or `--volumes`), `docker compose rm -v`, and `docker volume rm`/`prune` run against a Compose project's volumes. The rule is to state exactly what will be deleted and get explicit confirmation before running any of them, and never as a side effect of "just restarting" or "cleaning up" a stack. If the actual goal is reclaiming containers and networks, `docker compose down` without `-v`, or `docker compose restart`, leaves named volumes untouched. Volumes declared `external: true` get a specific callout too: they aren't managed by the Compose project, so `down -v` won't touch them, but that also means they need the same explicit-confirmation treatment as a standalone `docker volume rm`, which is the domain of the cross-product `docker-destructive-guardrails` skill covered later in this series.

## Verifying without leaking secrets

The skill ships a small script, `scripts/verify-compose.sh`, that validates a Compose file with `docker compose config --quiet` rather than plain `docker compose config`. The distinction matters: the non-quiet form prints the fully resolved configuration, which can include interpolated variables and `env_file` values, so it's a bad default for anything an agent might echo into a chat transcript or a CI log.

## What's next

Week 2 of this series moves past the Build and Compose families: `docker-sandboxes-lifecycle` and `docker-sandboxes-network-credentials` for running agents in isolated microVMs with Docker Sandboxes' `sbx` CLI, `docker-agent-config`/`docker-agent-run`/`docker-agent-deploy` for authoring and shipping agents with Docker Agent, and a closing look at `docker-destructive-guardrails`, the cross-product policy referenced throughout this post and the last one.

## Further reading

- [Docker Compose documentation](https://docs.docker.com/compose/)
- [`docker/skills` on GitHub](https://github.com/docker/skills)
- Previous: [Docker Skills, Part 2: docker-build-strategies and docker-project-foundations](/posts/docker-skills-part-2-build-and-foundations/)
