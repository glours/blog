---
title: "Docker Compose Tip #88: Reversing a Compose file with docker compose alpha generate"
date: 2026-09-21T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "cli", "open-source", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "docker compose alpha generate reverses a Compose file from running containers. It's also a working example of what alpha code actually looks like, rough edges included."
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

```bash
docker compose alpha generate mycontainer --name myapp
```

Point that at a container that's already running and it inspects it, then writes back the Compose file you'd otherwise have to write by hand. [Tip #28](/posts/compose-tip-028-docker-run-to-compose/) covered that translation manually; `generate` does it straight from what's actually running.

## What it produces

Run it against a container started with `docker run -p 127.0.0.1:8080:80 nginx:alpine`:

```yaml
services:
  mycontainer:
    scale: 1
    image: nginx:alpine
    environment:
      PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
      NGINX_VERSION: "1.31.5"
    labels:
      maintainer: "NGINX Docker Maintainers <docker-maint@nginx.com>"
    ports:
      - host_ip: "127.0.0.1"
        target: 80
        published: "8080"
        protocol: tcp
```

It reads networks, volumes, and healthchecks the same way, and `--format json` swaps the output format if you'd rather feed it into other tooling. Note the environment and labels above: they include everything baked into the image, not just what you passed on the command line. Useful for capturing what a container actually runs with, but expect to trim the output before committing it.

## Why it matters

`generate` is listed [alongside `viz`](/posts/compose-tip-085-alpha-commands/) as one of the two commands currently under `docker compose alpha`, which means Compose is upfront that it's still being built: flags, output shape, and behavior can all change release to release, no deprecation notice required.

That's worth reading as an opportunity rather than a warning. Alpha commands are small, self-contained, and still taking shape, exactly the kind of code a first-time contributor can read start to finish and reason about. Trying one against a real stack and comparing the output to what you expected is the fastest way to find something worth reporting.

## Pro tip: alpha bugs are normal, and they're your ticket in

The example above pins a host IP, which is why `host_ip` comes out clean. Skip that (`docker run -p 8080:80`, bound to every interface, the more common case) and `generate` writes `host_ip: invalid IP` into the port entry instead of defaulting to `0.0.0.0`:

```yaml
ports:
  - host_ip: invalid IP
    target: 80
    published: "8080"
    protocol: tcp
```

The [line responsible](https://github.com/docker/compose/blob/v5.5.1/pkg/compose/generate.go#L137) calls `.String()` on Go's `netip.Addr`, and the zero value of that type stringifies to literally `"invalid IP"` rather than an empty string. It reproduces on the current release, not just an in-progress build, and there's no open issue for it yet.

That's the whole point of poking at alpha commands: bugs like this are expected, not embarrassing, and small enough to fully understand from the code alone. [`CONTRIBUTING.md`](https://github.com/docker/compose/blob/main/CONTRIBUTING.md) covers the process, commits need a `git commit -s` sign-off, and `docker compose alpha --help` stays the source of truth for what's currently in there to try.

## Further reading

- [Docker experimental features](https://docs.docker.com/go/experimental/)
- Related: [Tip #28, Converting docker run commands to Compose](/posts/compose-tip-028-docker-run-to-compose/)
- Related: [Tip #85, What docker compose alpha actually means](/posts/compose-tip-085-alpha-commands/)
