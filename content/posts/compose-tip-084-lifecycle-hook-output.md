---
title: "Docker Compose Tip #84: Lifecycle hooks now show you why they failed"
date: 2026-09-11T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "debugging", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Since Compose 5.5.1, a failing post_start, pre_stop, or pre_start hook includes its own output in the error message."
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

A failing lifecycle hook, [`post_start`, `pre_stop`](/posts/compose-tip-041-lifecycle-hooks/), or the new [`pre_start`](/posts/compose-tip-082-pre-start-init-containers/), used to report only its exit code:

```
db hook exited with status 1
```

What the hook actually printed depended on how it ran. Under a plain `docker compose up`, the output streamed live to the terminal, mixed into the rest of `up`'s output, but was never carried into the error message itself. Under `restart`, `run`, or any tool driving Compose as a library, there was no listener attached at all, so Compose didn't even request stdout or stderr from the daemon, and there was nothing to read afterward, live or otherwise. Since Compose 5.5.1, both cases keep a tail of the output and fold it straight into the error on failure.

## What you see now

```yaml
services:
  api:
    build: .
    post_start:
      - command: ./migrate.sh
```

If `migrate.sh` exits non-zero, the error now reads something like:

```
db hook exited with status 1: SQLSTATE[42S02]: Base table or view not found
```

The reason travels with the failure instead of requiring a manual `docker compose exec` into the container to re-run the script and see what actually broke.

## What's kept, and when

- Compose keeps the last **10 lines or 2 KiB** of stdout and of stderr, tracked separately, whichever limit hits first for each. The error prefers stderr when it has content and falls back to stdout otherwise, so a chatty hook can't grow either buffer without bound.
- The tail is attached to the error **only on a non-zero exit**. A passing hook behaves exactly as before: nothing extra is printed or returned.
- This applies whether or not you're watching a listener (a plain `docker compose up` or a tool driving Compose as a library), output is captured either way now.

## Gotcha: hook output can carry secrets

A hook that fails mid-migration might echo a connection string, a stack trace with a credential in it, or a query with sensitive parameters, and that text now lands in the error message rather than being silently dropped. If a hook can print something sensitive on failure, make it fail without echoing that value, the same way you'd treat any other error path.

## Further reading

- Related: [Tip #41, Container lifecycle hooks](/posts/compose-tip-041-lifecycle-hooks/)
- Related: [Tip #82, pre_start hooks and native init containers](/posts/compose-tip-082-pre-start-init-containers/)
