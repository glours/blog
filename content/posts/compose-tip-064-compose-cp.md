---
title: "Docker Compose Tip #64: Copying files with docker compose cp"
date: 2026-05-18T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "cli", "debugging", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Copy files in and out of containers without bind mounts or volumes using docker compose cp"
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

Need to grab a log file out of a container? Push a quick config change for a one-off test? Don't redeploy with a bind mount, just use `docker compose cp`.

## Basic usage

The syntax mirrors `docker cp` but resolves service names instead of container IDs:

```bash
# Copy from container to host
docker compose cp <service>:<container-path> <host-path>

# Copy from host to container
docker compose cp <host-path> <service>:<container-path>
```

The direction is determined by which side has the `service:` prefix.

## Copy from container to host

Grab a log file produced inside a container:

```bash
docker compose cp app:/var/log/app/error.log ./error.log
```

Useful for:
- Extracting logs when the service can't be debugged interactively
- Pulling generated reports or build artifacts
- Saving a coredump or stack trace for offline analysis

## Copy from host to container

Push a file in without rebuilding the image or restarting the service:

```bash
# Quick config tweak for testing
docker compose cp ./nginx-debug.conf web:/etc/nginx/nginx.conf
docker compose exec web nginx -s reload

# Seed test data into a running database container
docker compose cp ./test-fixtures.sql db:/tmp/fixtures.sql
docker compose exec db psql -U postgres -f /tmp/fixtures.sql
```

This is ideal for short-lived experiments. For permanent file sharing, use volumes or `configs` ([Tip #58](/posts/compose-tip-058-configs/)).

## Copying directories

Add the directory path and Compose handles the recursion:

```bash
# Copy a whole directory from container
docker compose cp app:/var/log/app ./logs/

# Copy a directory into container
docker compose cp ./static-assets web:/usr/share/nginx/html/
```

## Targeting a specific replica

For scaled services, use `--index` to target one container ([Tip #48](/posts/compose-tip-048-network-debugging-port/)):

```bash
docker compose up -d --scale worker=3

# Copy log from a specific worker replica
docker compose cp --index=2 worker:/var/log/worker.log ./worker-2.log
```

Without `--index`, Compose uses the first replica.

## When to use cp vs alternatives

| Goal | Use |
|---|---|
| One-off file extraction | `docker compose cp` |
| Persistent file sharing | Bind mount or volume |
| Read-only config files | `configs` (Tip #58) |
| Secrets | `secrets` (Tip #22) |
| Live source code in dev | `docker compose watch` (Tip #11) |

`cp` is the right tool when you need a snapshot in time, not ongoing sync.

## Further reading

- [Docker Compose CLI: cp](https://docs.docker.com/reference/cli/docker/compose/cp/)
- Related: [Tip #48, Network debugging with docker compose port](/posts/compose-tip-048-network-debugging-port/)
- Related: [Tip #58, Using configs for config files](/posts/compose-tip-058-configs/)
