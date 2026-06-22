---
title: "Docker Compose Tip #78: The COMPOSE_* environment variables"
date: 2026-06-19T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "cli", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Set defaults for Compose CLI flags via COMPOSE_FILE, COMPOSE_PROJECT_NAME, COMPOSE_PROFILES, and a handful of other variables that follow you across shells and CI."
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

Almost every Compose CLI flag has an environment-variable counterpart. Setting them once in a project `.env` file, in your shell, or in CI removes the need to retype the same flags on every command — and makes the configuration of a stack visible to anything that reads the environment.

## The core set

The variables you reach for most often:

| Variable | What it sets | CLI equivalent |
|---|---|---|
| `COMPOSE_FILE` | Path(s) to the Compose file(s) | `-f`, `--file` |
| `COMPOSE_PATH_SEPARATOR` | Separator when listing multiple files | (in `COMPOSE_FILE`) |
| `COMPOSE_PROJECT_NAME` | Project name | `-p`, `--project-name` |
| `COMPOSE_PROFILES` | Profiles to enable | `--profile` |
| `COMPOSE_ENV_FILES` | Project-level env files | `--env-file` |
| `COMPOSE_PARALLEL_LIMIT` | Max parallel operations | `--parallel` (on some subcommands) |
| `COMPOSE_IGNORE_ORPHANS` | Don't warn about orphan containers | (no flag) |
| `COMPOSE_REMOVE_ORPHANS` | Always remove orphans on `up`/`down` | `--remove-orphans` |
| `COMPOSE_ANSI` | Control ANSI output (`auto`, `never`, `always`) | `--ansi` |
| `COMPOSE_PROGRESS` | Progress style (`auto`, `tty`, `plain`, `json`, `quiet`) | `--progress` |
| `COMPOSE_STATUS_STDOUT` | Send status messages to stdout instead of stderr | (no flag) |
| `COMPOSE_MENU` | Disable the interactive Docker Desktop menu | (no flag) |

The full list lives in the [Compose docs](https://docs.docker.com/compose/how-tos/environment-variables/envvars/). The table above covers the ones that show up in real workflows.

## COMPOSE_FILE with multiple files

The most useful pairing. Combine several Compose files into one stack without retyping `-f` every time:

```bash
export COMPOSE_FILE=compose.yaml:compose.override.yaml:compose.local.yaml
docker compose up
# Same as: docker compose -f compose.yaml -f compose.override.yaml -f compose.local.yaml up
```

The default separator is `:` on Linux/macOS and `;` on Windows. Override it explicitly if you need to:

```bash
export COMPOSE_PATH_SEPARATOR=,
export COMPOSE_FILE=compose.yaml,compose.prod.yaml
```

## Per-project defaults with `.env`

The cleanest place to pin per-project defaults is the project `.env` file. Compose loads it automatically before parsing `compose.yaml`, and the COMPOSE_* control variables it finds are honored just like shell-exported ones:

```ini
# .env (loaded by Compose itself)
COMPOSE_FILE=compose.yaml:compose.dev.yaml
COMPOSE_PROJECT_NAME=myapp-dev
COMPOSE_PROFILES=full
```

```bash
docker compose config
# name: myapp-dev — both files merged, profile "full" enabled
```

No shell setup, no third-party tool, nothing to source. Switch to another worktree and the defaults change automatically because the `.env` is local to the directory.

A few caveats:

- The values stay scoped to Compose. They're not exported to your shell, so tools other than `docker compose` (e.g., a wrapper script) won't see them. If you need that, set them in the shell or use a tool like [direnv](https://direnv.net/) on top.
- The format is `KEY=VALUE`, no `export`, no shell logic.
- This is the same `.env` used for `${VAR}` interpolation in `compose.yaml` ([Tip #42](/posts/compose-tip-042-variable-substitution/)), so keep it readable.

## Pinning for deterministic CI runs

In a CI job, you want every `docker compose` call to behave the same way regardless of who triggers it. Set the variables once at the top of the job and forget about per-step flags:

```yaml
# GitHub Actions snippet
env:
  COMPOSE_FILE: compose.yaml:compose.ci.yaml
  COMPOSE_PROJECT_NAME: ${{ github.run_id }}
  COMPOSE_PROGRESS: plain
  COMPOSE_REMOVE_ORPHANS: "true"
  COMPOSE_IGNORE_ORPHANS: "false"

jobs:
  test:
    steps:
      - uses: actions/checkout@v4
      - run: docker compose up --wait
      - run: docker compose exec api npm test
      - run: docker compose down -v
        if: always()
```

`COMPOSE_PROJECT_NAME` set to the run ID isolates each CI build, so two concurrent runs on the same runner don't fight over the same project name.

`COMPOSE_PROGRESS=plain` (or `json`) keeps the log output readable in CI; the default TTY-aware progress bar is for humans.

## Profiles via environment

`COMPOSE_PROFILES` works the same as `--profile`, with a comma-separated list:

```bash
COMPOSE_PROFILES=dev,observability docker compose up
```

Useful when the choice of profiles depends on context (local vs CI, dev vs demo) and you don't want every script to remember which profiles to pass.

## Precedence

Order of precedence, from lowest to highest:

1. Defaults defined in Compose itself
2. Values from the project `.env`
3. Values from `COMPOSE_*` env vars set in the shell
4. Explicit CLI flags

So a `--file compose.alt.yaml` on the command line always beats `COMPOSE_FILE` in the environment. The env vars are *defaults*, not overrides.

## Pro tip: keep them visible

A small `make print-compose-env` (or shell alias) that dumps the active variables is invaluable when "it works on my machine" strikes:

```bash
env | grep ^COMPOSE_
```

Stick that in the troubleshooting section of your README. Half the support requests on Compose stacks end up being "you have `COMPOSE_FILE` set to something unexpected".

## Further reading

- [Compose environment variables reference](https://docs.docker.com/compose/how-tos/environment-variables/envvars/)
- [Environment variables precedence](https://docs.docker.com/compose/how-tos/environment-variables/envvars-precedence/)
- Related: [Tip #2, Using --env-file for different environments](/posts/compose-tip-002-env-files/)
- Related: [Tip #53, Compose project name and working directory control](/posts/compose-tip-053-project-name-workdir/)
- Related: [Tip #56, env_file advanced patterns](/posts/compose-tip-056-env-file-advanced/)
