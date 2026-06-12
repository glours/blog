---
title: "Docker Compose Tip #77: Volume subpath for mounting a sub-directory"
date: 2026-06-17T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "storage", "configuration", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Use volume.subpath to mount a sub-directory of a named volume into a container, instead of the whole volume root."
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

Named volumes are great for keeping data alive across container restarts. The default behavior mounts the entire volume root at the container target. Sometimes you want to mount only a sub-directory — for instance, a single service among many sharing the same named volume, each scoped to its own directory. The `subpath` option does exactly that.

## The basic shape

```yaml
services:
  app:
    image: myapp
    volumes:
      - type: volume
        source: shared-data
        target: /app/data
        volume:
          subpath: app

volumes:
  shared-data:
```

The named volume `shared-data` exists once on the host. The `app` container sees only the `app/` directory of it mounted at `/app/data`. Other directories in `shared-data` are invisible to `app`.

## A multi-service example

Several services share a single named volume and each one lives in its own corner:

```yaml
services:
  api:
    image: myapi
    volumes:
      - type: volume
        source: app-data
        target: /var/data
        volume:
          subpath: api

  worker:
    image: myworker
    volumes:
      - type: volume
        source: app-data
        target: /var/data
        volume:
          subpath: worker

  backup:
    image: alpine
    command: tar -czf /backup/snapshot.tgz /source
    volumes:
      - type: volume
        source: app-data
        target: /source
        # No subpath, sees the whole volume

volumes:
  app-data:
```

`api` and `worker` see their own scoped directory. `backup` mounts the volume root and can archive everything in one shot. One named volume, one backup target, clear isolation between services.

## Why not just use multiple volumes?

Three reasons `subpath` is preferable to N separate named volumes when the data is conceptually one dataset:

- **Single backup unit**: one volume, one snapshot, one restore.
- **Shared driver options**: NFS settings ([Tip #66](/posts/compose-tip-066-volume-drivers-nfs/)), encryption, performance tuning — declared once, inherited by every consumer.
- **Atomic migration**: moving the underlying storage moves all sub-paths at once.

When the data is genuinely unrelated, prefer separate volumes. `subpath` is for the case where the directories naturally belong together.

## The first-mount creates the directory

If the sub-directory does not exist when a container starts, Compose creates it. The first container to mount `subpath: foo` will see an empty directory at the target. Subsequent containers see whatever is in there.

This matters for permissions: the directory is created with the running container's UID. If different services run as different users, set the ownership explicitly in an init container or with the `user:` directive ([Tip #14](/posts/compose-tip-014-non-root-users/)).

## Read-only sub-paths

`subpath` combines with `read_only` for a config-style mount where the producer writes once and consumers read:

```yaml
services:
  config-writer:
    image: my-config-builder
    volumes:
      - type: volume
        source: shared
        target: /out
        volume:
          subpath: config

  reader:
    image: myapp
    volumes:
      - type: volume
        source: shared
        target: /etc/myapp
        read_only: true
        volume:
          subpath: config

volumes:
  shared:
```

The `config-writer` populates `/out` (the `config` subpath); `reader` mounts the same directory read-only at `/etc/myapp`.

## Image-backed volumes (Compose 2.35+)

A close cousin of `volume.subpath` is `image.subpath`, available since [Compose v2.35.0](https://github.com/docker/compose/releases/tag/v2.35.0). It mounts a directory from an OCI image as a volume, scoped to one sub-path:

```yaml
services:
  app:
    image: myapp
    volumes:
      - type: image
        source: my-assets:v1
        target: /assets
        image:
          subpath: web/static
```

Use it for read-only datasets packaged as container images — model weights, static sites, sample data — when you only need part of the image's filesystem.

## What `subpath` does not do

- It does not let you mount a path outside the volume root (no `../escape`).
- It does not work with bind mounts — for bind mounts, just adjust the host path itself.
- It does not change permissions, ownership, or read/write mode — those still come from `read_only`, `user`, or the volume driver.

## Pro tip: name the sub-paths the same as the services

A small naming convention pays off in larger stacks:

```yaml
volume:
  subpath: ${SERVICE_NAME}    # or hardcode to match the service key
```

When you later run `docker volume inspect <project>_shared` and walk the directory tree, the structure mirrors your `compose.yaml` and you can map files back to their owners in one glance.

## Further reading

- [Compose specification: volumes (long syntax)](https://docs.docker.com/reference/compose-file/services/#long-syntax-5)
- [Compose specification: volumes top-level](https://docs.docker.com/reference/compose-file/volumes/)
- Related: [Tip #66, Volume drivers with NFS](/posts/compose-tip-066-volume-drivers-nfs/)
- Related: [Tip #35, Using tmpfs for ephemeral storage](/posts/compose-tip-035-tmpfs-storage/)
