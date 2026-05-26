---
title: "Docker Compose Tip #67: Controlling image pulls with pull_policy"
date: 2026-05-25T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "build", "configuration", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Decide when Compose should pull images from a registry with the pull_policy directive"
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

By default, Compose pulls an image when it's missing locally and uses the cached one otherwise. `pull_policy` lets you change that behavior per service.

## The policies

```yaml
services:
  web:
    image: nginx
    pull_policy: always
```

Available values:

- **`missing`** (default when no `build:` is defined): pull only if the image is not present locally. Alias: `if_not_present`. Note: the `latest` tag is always pulled even with this policy.
- **`always`**: pull on every `up`, even if the local image is recent
- **`never`**: don't pull, fail if the image is missing
- **`build`**: build the image, rebuilds even if it's already present locally
- **`daily`**: check the registry if the last pull was more than 24 hours ago
- **`weekly`**: check the registry if the last pull was more than 7 days ago
- **`every_<duration>`**: check the registry if the last pull was older than the given duration. Units: `w`, `d`, `h`, `m`, `s` (or any combination, e.g. `every_12h`, `every_30m`, `every_1d12h`)

## When to use each

**`always`** for development against a fast-moving tag:

```yaml
services:
  api:
    image: myregistry/api:latest
    pull_policy: always
```

Every `docker compose up` checks the registry. Useful when you want to track the latest build of a feature branch image.

**`never`** in CI to catch accidental dependencies on registries:

```yaml
services:
  app:
    image: myregistry/app:${CI_COMMIT_SHA}
    pull_policy: never
```

If the image isn't already on the runner, the build fails fast. This forces explicit `docker compose pull` steps and prevents flaky CI runs caused by registry outages.

**`build`** to force a local build:

```yaml
services:
  app:
    image: myapp:dev      # used for tagging the built image
    build: ./app
    pull_policy: build
```

Without `pull_policy: build`, Compose would pull `myapp:dev` if available and skip the `build:` step. This makes local builds authoritative.

**`daily`**, **`weekly`**, or **`every_<duration>`** for periodic refreshes:

```yaml
services:
  scanner:
    image: security-scanner:latest
    pull_policy: daily

  test-runner:
    image: my-test-suite:main
    pull_policy: every_12h    # twice a day
```

Refreshes without the cost of `always` on every command. `every_<duration>` accepts combinations like `every_2d`, `every_1h30m`, `every_45s` for fine-grained control.

## CLI overrides

The `--pull` flag on `up` overrides the file setting for that run:

```bash
# Force a pull regardless of pull_policy
docker compose up --pull always

# Skip pulls
docker compose up --pull never

# Standalone pull command (respects pull_policy unless --policy given)
docker compose pull
docker compose pull --policy always
```

Handy for one-off behavior changes without editing the file.

## Match the policy to your tag

The right policy depends on how mutable your image tag is:

```yaml
# Immutable: pinned by digest, no point ever re-pulling
image: nginx@sha256:abc123...
pull_policy: missing

# Slow-moving: latest tag, refresh periodically
image: nginx:latest
pull_policy: daily

# Fast-moving: branch tag that changes often, always grab the newest
image: myteam/app:main
pull_policy: always
```

A digest-pinned image never changes, so `missing` is enough. A `:latest` tag moves occasionally, so `daily` or `weekly` keeps you reasonably current without thrashing. A branch tag like `:main` may change every commit, so `always` is the safe default.

## Further reading

- [Compose specification: pull_policy](https://docs.docker.com/reference/compose-file/services/#pull_policy)
- [Docker Compose CLI: pull](https://docs.docker.com/reference/cli/docker/compose/pull/)
