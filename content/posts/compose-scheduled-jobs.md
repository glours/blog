---
title: "Docker Compose v5.8.0: Scheduled Jobs"
date: 2026-11-17T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "docker-engine", "jobs", "cron", "backup", "postgres", "new-feature"]
categories: ["Docker Compose"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Docker Compose v5.8.0 adds a top-level jobs element: containers that run to completion, on demand or on a cron schedule. A nightly PostgreSQL backup declared next to the database, with no host cron."
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

Docker Compose v5.8.0 adds a top-level `jobs:` element: containers that run to completion, on demand or on a schedule, declared next to the services they work with. A nightly database backup no longer needs a cron entry on the host or a container running `crond`. It lives in the Compose file, and the Docker Engine fires it.

Because the engine owns the schedule, a job keeps firing after the `docker compose` command has exited, and also when the project targets a remote engine. Each execution is recorded with its state and exit code.

Jobs are experimental: the Compose file syntax and the behavior may change between releases. Scheduling needs Docker Engine 29.10 or later with the jobs extension enabled, which is off by default. Jobs that are only run on demand work without it.

## Enable the extension

```bash
dockerd --extension-enable org.mobyproject.jobs.v0
```

Or in `daemon.json`:

```json
{
  "extensions": {
    "enable": ["org.mobyproject.jobs.v0"]
  }
}
```

The nested form is required. A flat `"extension-enable"` key in `daemon.json` is rejected at startup.

## A nightly backup

This project runs PostgreSQL and dumps the database every day at 03:00 Paris time:

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_PASSWORD: example
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
    volumes:
      - db-data:/var/lib/postgresql/data
      - backups:/backups:ro

jobs:
  backup:
    image: postgres:17
    depends_on:
      db:
        condition: service_healthy
    environment:
      PGHOST: db
      PGUSER: postgres
      PGPASSWORD: example
    command: sh -c 'pg_dump --format=custom --file=/backups/shop-$$(date +%Y%m%d-%H%M%S).dump postgres'
    volumes:
      - backups:/backups
    triggers:
      schedule:
        - cron: "0 3 * * *"
          timezone: Europe/Paris

volumes:
  db-data:
  backups:
```

A job takes the same container attributes as a service: image, command, environment, volumes, networks, `depends_on`. What it adds is `triggers`, which is required. Here the job joins the project network, so it reaches the database as `db`, and the dumps land in the `backups` volume. That volume is also mounted read-only on `db`, so the files can be listed from there with `docker compose exec db ls /backups`.

## Register, run, remove

`docker compose up` registers the job with the engine, which then fires it on its own clock:

```console
$ docker compose up -d
 Container shop-db-1 Started
 Job backup Creating
 Job backup Created
```

Running `up` again on an unchanged project does nothing. If the job definition changed, `up` refuses and says what to do: `job "backup" has changed: run docker compose down to remove it, then up again`. `docker compose down` removes the registered job.

A job can also run right now:

```console
$ docker compose run backup
```

The dependencies start first, and the command waits for `db` to be healthy. The job's logs are streamed and its exit code is returned, which makes this the way to take a dump before a migration. A succeeded run returns `0`, a failed one the container's exit code, a timeout `124` and a cancellation `130`.

A scheduled job runs exactly as it was registered, so `docker compose run` refuses options that would change it, such as `-e`, `-v` or `--user`.

## Triggers

`schedule` is a list, and each entry is either a cron string or an object:

- `cron`: a five-field expression.
- `timezone`: an IANA timezone such as `Europe/Paris`, used to evaluate the expression. Without it, the engine uses UTC.
- `concurrency`: `forbid` (default) skips a fire while the previous run is still going, `queue` defers it until the run ends.
- `missed_fires`: `one` (default) starts a single catch-up run after the engine was down across fires, `skip` drops them.

Setting `manual: false` under `triggers` forbids `docker compose run` for a job that should only run on its schedule.

## Pro tip

A few behaviors are worth knowing before relying on a backup job:

- **Pipes hide failures.** `pg_dump | gzip > file` exits with the status of `gzip`. With the database stopped, the run still ended as `succeeded`. Writing with `pg_dump --file`, as above, makes a failed dump a failed run.
- **Successful runs leave no container.** Compose registers jobs so that the container of a succeeded run is removed, which is why the example writes to a volume. The container of a failed run is kept and listed by `docker compose ps -a` with its `Exited (1)` status. Its output is still there: `docker logs <container>`. It lives as long as the run record, and Compose keeps the last 5 runs of a job. `docker compose down` leaves these containers, and `docker compose down --remove-orphans` removes them.
- **Dependencies are not started on a schedule.** `depends_on` is honored by `docker compose run`. When the engine fires the job at 03:00, `db` has to be running already.
- **Deleting a job from the file does not unregister it.** The engine keeps the registered job and it keeps firing. `docker compose up` warns about it, and `docker compose up --remove-orphans` removes it.
- **Not for work a service waits on.** A service cannot `depends_on` a job. A migration that must finish before the application starts belongs in an [init container](/posts/compose-tip-082-pre-start-init-containers/).
- **Without the extension, `up` refuses.** A project with a scheduled job is rejected before anything is created, with a message that points at the `--extension-enable` flag. `docker compose run` on a job falls back to a one-off container.

## What's next: the docker job commands

A succeeded scheduled run leaves no container, so Compose has nothing to list for it. A `docker job` command group is in review in [docker/cli#7503](https://github.com/docker/cli/pull/7503) to list jobs and their runs. It is not part of Docker 29.10, and the UX is not final: names, flags and output may change before it is merged. With a build of that pull request, the jobs registered by Compose appear as `<project>.<job>`:

```console
$ docker job runs shop.backup
ITERATION  STATE      EXIT  TRIGGER   STARTED             FINISHED            CONTAINER
32         succeeded  0     schedule  37 seconds ago      37 seconds ago      73bf25b1c5c5
31         succeeded  0     schedule  About a minute ago  About a minute ago  8bd82df7de80
30         succeeded  0     schedule  2 minutes ago       2 minutes ago       2376894b965e
```

## Further reading

- [Run jobs in Compose](https://docs.docker.com/compose/how-tos/jobs/)
- [The jobs element in the Compose file reference](https://docs.docker.com/reference/compose-file/jobs/)
- [Manage jobs in Docker Engine](https://docs.docker.com/engine/daemon/jobs/)
- [Compose v5.8.0 release](https://github.com/docker/compose/releases/tag/v5.8.0)
- [Pull request #14155: jobs support in Compose](https://github.com/docker/compose/pull/14155)
- [Docker Engine 29.10.0 release](https://github.com/moby/moby/releases/tag/docker-v29.10.0)
- [Pull request docker/cli#7503: the docker job commands](https://github.com/docker/cli/pull/7503)
