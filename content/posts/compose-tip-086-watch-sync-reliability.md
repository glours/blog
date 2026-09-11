---
title: "Docker Compose Tip #86: Three sync bugs that made watch unpredictable"
date: 2026-09-16T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "development", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Three separate compose watch sync bugs fixed in 5.5.1: files silently skipped on initial_sync, Dockerfiles leaking into containers, and symlinked targets aborting the whole sync."
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

[Tip #11](/posts/compose-tip-011-docker-compose-watch/) covered `sync` and `rebuild`. One `watch` attribute it didn't cover: `initial_sync`, which re-syncs a path into containers that already exist, for when you reattach `watch` to a stack that's still running.

```yaml
services:
  web:
    build: .
    develop:
      watch:
        - path: ./src
          target: /app/src
          action: sync
          initial_sync: true
```

Three separate bugs in that sync path, and one in sync generally, got fixed in 5.5.1.

## initial_sync skipped most of your files

`initial_sync` compared each host file's modification time against the image's creation time and skipped anything older. That's backwards for most real projects: source code checked out from git is almost always older than the image built from it, so the files `initial_sync` exists to catch up were exactly the ones it silently left behind. 5.5.1 removes the mtime check entirely: everything not ignored or bind-mounted now syncs, regardless of when it was last touched.

## initial_sync could leak your Dockerfile into the container

`initial_sync`'s own doc comment promised the `Dockerfile` and compose files themselves would never be copied in. A January 2025 refactor dropped the filter enforcing that and left only a `// FIXME .dockerignore` comment behind. If a watch rule's `path` included the project root, `initial_sync` would happily copy `Dockerfile` and `compose.yaml` into the running container. 5.5.1 reintroduces a dedicated matcher for both.

One scope worth knowing: the fix only covers `initial_sync`. The continuous watch loop that reacts to file changes afterward never carried this exclusion either way, and still doesn't. That's a separate change if it ever lands.

## A symlinked sync target could abort the whole batch

This one isn't specific to `initial_sync`. It hits any `sync` action:

```yaml
services:
  app:
    image: alpine
    command: sh -c 'mkdir -p /app/data /var/sub && ln -s /var/sub /app/data/sub && sleep infinity'
    develop:
      watch:
        - action: sync
          path: ./data
          target: /app/data
```

Drop a file under `./data/sub/` on the host, and the container resolves `/app/data/sub` through the symlink to `/var/sub`. The archive Compose built for the sync carried a directory header for `/app/data/sub` too, and the engine refuses to extract a directory header over a path it already knows as a symlink, so it rejected the entire batch, not just that one entry:

```
Error handling changed files: copying files to <id>: Error response from daemon:
cannot overwrite non-directory "/app/data/sub" with directory "/"
```

5.5.1 retries a rejected copy without the directory headers that its own file entries already imply, letting the engine create those directories itself and resolve them through the symlink as expected. One case is still unresolved: creating a bare *empty* directory directly on a symlinked path still fails, since there's no file entry there to imply it and nothing in the sync tells Compose the container resolves that path through a symlink.

## Pro tip

If a stack has directories that resolve through a symlink inside the container, an empty one landing exactly on that path is still worth testing by hand after upgrading. Everything else in this post you get for free.

## Further reading

- [Compose specification: develop.watch.initial_sync](https://docs.docker.com/reference/compose-file/develop/#initial_sync)
- [Use Compose Watch](https://docs.docker.com/compose/file-watch/)
- Related: [Tip #11, Mastering docker compose up --watch for hot reload](/posts/compose-tip-011-docker-compose-watch/)
