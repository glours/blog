---
title: "Docker Compose Tip #74: docker compose ls and cross-project visibility"
date: 2026-06-10T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "cli", "debugging", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Inspect every Compose stack running on the host with docker compose ls, filter by name, and script around the output with json + jq."
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

`docker compose ps` shows the services inside the current project. `docker compose ls` zooms out: every Compose stack running anywhere on the host, regardless of which directory you happen to be standing in.

## The basics

Run it from any directory:

```bash
docker compose ls
```

Sample output:

```
NAME                STATUS              CONFIG FILES
api-platform        running(4)          /home/dev/api-platform/compose.yaml
data-pipeline       running(2)          /home/dev/data-pipeline/compose.yaml
old-prototype       exited(3)           /tmp/prototype/compose.yaml
```

Three columns: the project name, how many services are up, and the path to the Compose file that started it. No need to `cd` into the project to see what's running.

## Show stopped stacks too

By default, `ls` only shows running projects. Stopped ones (services exited but still defined in Docker's records) need `--all`:

```bash
docker compose ls --all
```

Useful right after a `docker compose down --remove-orphans` chase, or to find a project you forgot to clean up.

## Filtering by name

`--filter name=` narrows the listing to projects matching the given name:

```bash
docker compose ls --filter name=api
```

Status filtering isn't available on `ls`; use `--format json` and `jq` to slice by status (see below).

## Output formats for scripting

The default human table is good for eyeballing. `--format` accepts two values: `table` (default) and `json`. There is no Go-template form — passing `'{{.Name}}'` fails with a parse error.

For just the project names, `-q` / `--quiet` is the shortest path:

```bash
docker compose ls -q
```

For anything more structured, JSON piped through `jq` is the way:

```bash
# All project names
docker compose ls --format json | jq -r '.[].Name'

# Only stopped (exited) projects
docker compose ls --all --format json \
  | jq -r '.[] | select(.Status | startswith("exited")) | .Name'

# Project name and config file as a CSV
docker compose ls --format json \
  | jq -r '.[] | [.Name, .ConfigFiles] | @csv'
```

## The "who's holding port 5432" workflow

A common pain point: an unrelated stack is still running, holding a port, and nothing in your current project's `docker compose ps` mentions it. Quick diagnosis:

```bash
# 1. Find every running stack.
docker compose ls

# 2. Inspect a suspect one without entering its directory.
docker compose -f /home/dev/old-prototype/compose.yaml ps

# 3. Bring it down.
docker compose -f /home/dev/old-prototype/compose.yaml down
```

`-f <path>` works from anywhere, so you never need to `cd` into the project.

## Stopping a specific project by name

If you know the project name but not its file, point Compose at it by name:

```bash
docker compose -p old-prototype down
```

`-p <name>` selects the project; Compose will use whatever it has on record for that project.

## Pro tip: clean up the zombies

Find every stopped Compose project on the host:

```bash
docker compose ls --all --format json \
  | jq -r '.[] | select(.Status | startswith("exited")) | .Name'
```

Pipe that into `xargs -I{} docker compose -p {} down --volumes` to clean them up in one shot. Keep that incantation a few terminals away from production hosts.

## Further reading

- [Compose CLI reference: ls](https://docs.docker.com/reference/cli/docker/compose/ls/)
- Related: [docker compose cp for file transfer](/posts/compose-tip-064-compose-cp/)
- Related: [Compose project name and working directory](/posts/compose-tip-053-project-name-workdir/)
