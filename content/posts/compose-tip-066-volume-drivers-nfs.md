---
title: "Docker Compose Tip #66: Volume drivers with NFS"
date: 2026-05-22T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "storage", "networking", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Mount NFS shares as Compose volumes for shared storage across hosts using the built-in local driver"
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

Compose volumes default to local disk on the host running the container. When you need storage shared across hosts, a volume driver does the job. The built-in `local` driver already supports NFS through its options.

## Basic NFS mount

Declare a volume that points to an NFS export:

```yaml
volumes:
  shared:
    driver: local
    driver_opts:
      type: nfs
      o: "addr=nfs-server.example.com,rw,nfsvers=4"
      device: ":/exports/shared"

services:
  app:
    image: myapp
    volumes:
      - shared:/data
```

The `app` service mounts `/exports/shared` from the NFS server at `/data` inside the container. Multiple containers (or even multiple Compose stacks on different hosts) can mount the same volume to share data.

## Breaking down the options

- `type`: the filesystem type, `nfs` for NFSv3/v4
- `o`: mount options passed to the kernel — at minimum the server address (`addr=`) and read/write mode (`rw` or `ro`)
- `device`: the remote export path, prefixed with `:` for NFS

Common `o` options:

- `addr=<server>` — required, the NFS server address
- `rw` / `ro` — read-write or read-only
- `nfsvers=4` — force NFSv4 (often more reliable than v3)
- `soft` / `hard` — how to handle server unavailability
- `timeo=N` — timeout in tenths of a second
- `nolock` — disable client-side locking (useful when locking causes issues)

## Read-only shared assets

A common pattern: static assets read from a shared NFS server:

```yaml
volumes:
  assets:
    driver: local
    driver_opts:
      type: nfs
      o: "addr=nfs.example.com,ro,nfsvers=4"
      device: ":/exports/static-assets"

services:
  web:
    image: nginx
    volumes:
      - assets:/usr/share/nginx/html:ro
    ports:
      - "80:80"
```

Multiple web servers across hosts serve the same content from a single NFS source.

## NFS for backups

Mount a backup target so containers can write archives off the host:

```yaml
volumes:
  backups:
    driver: local
    driver_opts:
      type: nfs
      o: "addr=backup.example.com,rw,nfsvers=4,hard"
      device: ":/backups/postgres"

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db-data:/var/lib/postgresql/data
      - backups:/backups

volumes:
  db-data:
  backups:
    driver: local
    driver_opts:
      type: nfs
      o: "addr=backup.example.com,rw,nfsvers=4,hard"
      device: ":/backups/postgres"
```

A scheduled backup job inside the postgres container writes to `/backups`, which lands on the NFS server.

## Other volume drivers

`type: nfs` works with the built-in `local` driver. For cloud-managed storage (AWS EBS/EFS, Azure Disk, GCP Persistent Disk) or distributed filesystems (Ceph, GlusterFS), install the corresponding plugin and use it as the `driver`:

```yaml
volumes:
  cloud-storage:
    driver: rexray/ebs
    driver_opts:
      size: "20"
      volumetype: "gp3"
```

Each plugin defines its own options. Check the plugin's docs.

## Troubleshooting

If the volume fails to mount, check:

```bash
# Validate the mount options syntax
docker compose config

# Try mounting manually from the host
sudo mount -t nfs -o "vers=4" nfs-server.example.com:/exports/shared /mnt/test

# Inspect the volume to see what Docker resolved
docker volume inspect <project>_shared
```

The most common issues are firewall rules blocking the NFS ports (2049, plus portmapper) and missing `nfs-common` / `nfs-utils` packages on the host.

## Further reading

- [Compose specification: volumes](https://docs.docker.com/reference/compose-file/volumes/)
- [Docker volumes overview](https://docs.docker.com/engine/storage/volumes/)
- Related: [Tip #35, Using tmpfs for ephemeral storage](/posts/compose-tip-035-tmpfs-storage/)
