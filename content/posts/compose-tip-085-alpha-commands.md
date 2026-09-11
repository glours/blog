---
title: "Docker Compose Tip #85: What docker compose alpha actually means"
date: 2026-09-14T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "cli", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "docker compose alpha is where new commands land before they're stable. What that label actually commits to, and what's there today."
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

Run `docker compose alpha --help` and Compose is upfront about what that word means:

```
EXPERIMENTAL:
  docker compose alpha is an experimental feature.
  Experimental features provide early access to product functionality.
  These features may change between releases without warning, or can be
  removed from a future release.
```

Not a beta, not a preview with a stable target date. A command under `alpha` can change its flags, its output format, or disappear entirely in the next release, with no deprecation notice. Build a script around one and a routine `docker compose` upgrade can break it silently.

## Alpha is a real graduation path, not just a label

The biggest proof: `docker compose watch` ([Tip #11](/posts/compose-tip-011-docker-compose-watch/), and this week's [Tip #86](/posts/compose-tip-086-watch-sync-reliability/)) started life as `docker compose alpha watch` in January 2023. It moved to the top level as plain `docker compose watch` that September, and the `alpha watch` alias itself wasn't removed until January 2024, four months later. One of Compose's most-used features spent a full year under `alpha` before the label came off for good.

`docker compose publish` ([Tip #9](/posts/compose-tip-009-oci-artifacts/)) took the same path out of `alpha`:

```bash
docker compose publish mycompany/app:v1.0        # the stable, documented command
docker compose alpha publish mycompany/app:v1.0  # still runs today, under its old name
```

The same move `watch` made. Don't read stability into a command still answering under `alpha`. Read the `--help` output instead.

## What's under alpha right now

Two commands currently live there:

```bash
docker compose alpha viz
docker compose alpha generate [containers...]
```

`viz` reads a Compose file and prints a Graphviz graph of the service dependency graph, useful the moment a stack grows past a handful of services and `depends_on` stops being readable at a glance:

```
digraph "myapp" {
	"db" [style="filled" label=<<font point-size="15">db</font>>];
	"api" [style="filled" label=<<font point-size="15">api</font>>];
	"api" -> "db";
}
```

`generate` runs the other direction: point it at already-running containers and it writes back a Compose file, useful for adopting Compose on a stack that only ever existed as a pile of `docker run` commands ([Tip #28](/posts/compose-tip-028-docker-run-to-compose/) has a worked example). Both deserve their own tip; this one's just the map.

## Pro tip: check the list, it changes

`docker compose alpha --help` is the source of truth for what's in there this release, not this post. Commands move out (like `publish` did) and new ones move in. `generate` also takes `--format json` today if you'd rather pipe its output into JSON-based tooling than YAML. Read the disclaimer once, then treat the `--help` output as current.

## Further reading

- [Docker experimental features](https://docs.docker.com/go/experimental/)
- Related: [Tip #9, Publishing Compose applications as OCI artifacts](/posts/compose-tip-009-oci-artifacts/)
- Related: [Tip #11, Mastering docker compose up --watch for hot reload](/posts/compose-tip-011-docker-compose-watch/)
- Related: [Tip #28, Converting docker run commands to Compose](/posts/compose-tip-028-docker-run-to-compose/)
- Related: [Tip #86, Three sync bugs that made watch unpredictable](/posts/compose-tip-086-watch-sync-reliability/)
