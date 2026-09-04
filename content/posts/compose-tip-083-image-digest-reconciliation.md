---
title: "Docker Compose Tip #83: Why up recreated containers that never changed"
date: 2026-09-09T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "build", "runtime", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Compose 5.5.0 fixes a bug class where up recreated containers with no real change behind it, because image identity was computed differently depending on how the image arrived."
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

A service recreates on every single `docker compose up`. No file change, no rebuild, nothing actually different about the image. Before Compose 5.5.0, that wasn't a flaky environment, it was a real bug class in how Compose decided an image had changed.

## One image, three ways to name its digest

Compose decides whether to recreate a container by comparing the image's current identity against a label it recorded last time, `com.docker.compose.image`. Before 5.5.0, that identity was computed differently depending on how the image got there:

- `docker compose pull` recorded one kind of digest
- the classic builder recorded another
- `buildx bake`, which Compose uses internally for builds, recorded another still
- inspecting an image already present locally produced yet another

Depending on the engine's image store (the classic graphdriver versus containerd) and the daemon's API version, that could be a top-level multi-platform index digest, a single-platform manifest digest, or an image config digest. Three different values, all describing the exact same image. Compare a freshly recorded one against an older one computed a different way, and Compose reads "changed" even when nothing was.

## Where this actually showed up

The fix's own bug list reads like a tour of the different code paths: a locally built image with build provenance attestations enabled (the default in recent BuildKit) got a digest that changed on every rebuild even when the image content didn't; a platform-pinned service could get resolved against the host's platform instead of its own; pulling the same tag for different platforms concurrently could record whichever pull happened to finish last; a `type: image` volume's mount source, built from that same digest value, could stop resolving outright once the value's shape changed. Different code paths, different root causes, the same symptom: `up` treating an unchanged image as a new one.

## The fix

5.5.0 introduces one canonical content-digest producer used by every path: pull, bake, the classic builder, and local inspect all resolve an image's identity the same way now. Only one function writes the label (`ensureImagesExists`), and a platform-pinned service gets the digest matching its own platform's manifest instead of whichever one happened to be resolved last. A dedicated end-to-end suite now runs specifically against the containerd image store, where the different digest kinds actually diverge, and locks the invariant that two consecutive `up` runs with no change recreate nothing.

## A related regression: `type: image` volumes

```yaml
services:
  api:
    build: .
    volumes:
      - type: image
        source: config-bundle:latest
        target: /etc/config
```

Mounting a volume backed by an image ([Tip #77](/posts/compose-tip-077-volume-subpath/) covers the mechanics) used to set the mount's source directly to that image's digest value. Once the digest producer started returning a per-platform manifest digest instead of a plain image ID, the daemon could no longer resolve that value as a mount source at all, breaking the volume outright (tracked as [#14005](https://github.com/docker/compose/issues/14005)). 5.5.0 keeps the mount source as the image's resolvable name and tracks its digest separately, in a label of its own, so a changed source image is still detected without the mount depending on a value it might not be able to resolve.

## Pro tip

If a service has been recreating on every `up` for no visible reason, upgrading to 5.5.0 or later is the fix, not a change to the Compose file. Expect one recreate on the very first `up` after upgrading, since the label format itself changes, then it settles.

## Further reading

- [Docker Compose v5.5.0 release notes](https://github.com/docker/compose/releases/tag/v5.5.0)
- Related: [Tip #67, Controlling image pulls with pull_policy](/posts/compose-tip-067-pull-policy/)
- Related: [Tip #77, Volume subpath](/posts/compose-tip-077-volume-subpath/)
