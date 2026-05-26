---
title: "Docker Compose Tip #69: Sharing namespaces with pid and ipc"
date: 2026-05-29T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "debugging", "advanced"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Share process and IPC namespaces between containers for debugging, profiling, and shared memory workloads"
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

Linux isolates containers using kernel namespaces. Sometimes you need the opposite: two containers that can see each other's processes or share memory. The `pid` and `ipc` directives give you that escape hatch.

## Sharing a PID namespace

`pid: service:<name>` lets a container see and act on processes inside another service:

```yaml
services:
  app:
    image: myapp

  debugger:
    image: alpine
    pid: service:app
    cap_add:
      - SYS_PTRACE
    command: sleep infinity
```

The `debugger` container's `ps`, `strace`, and `/proc` all reflect `app`'s processes. Combined with `cap_add: SYS_PTRACE`, you can attach strace or gdb to a running production-style container without baking debug tools into its image.

```bash
docker compose exec debugger ps -ef
docker compose exec debugger strace -p <pid>
```

This is the cleanest way to debug a misbehaving service without modifying its image or running as `host`.

## Sharing an IPC namespace

`ipc: service:<name>` shares System V IPC and POSIX shared memory (`/dev/shm`), but the donor service must opt in with `ipc: shareable` first:

```yaml
services:
  producer:
    image: alpine
    ipc: shareable           # required: opt in to allow sharing
    command: sh -c "echo hello > /dev/shm/message && sleep 60"

  consumer:
    image: alpine
    ipc: service:producer    # join producer's IPC namespace
    command: sh -c "cat /dev/shm/message"
```

Run it:

```bash
docker compose up
# consumer-1  | hello
```

The `consumer` reads the file that `producer` wrote to `/dev/shm`. Drop the two `ipc:` lines and the same setup fails with `cat: can't open '/dev/shm/message': No such file or directory`, because each container has its own private `/dev/shm` by default.

Without `ipc: shareable` on the donor, the consumer fails to start with a `non-shareable IPC` error.

This is useful for any pair of services that explicitly use shared memory primitives (`shm_open`, `shmget`, etc.) to communicate, common in scientific computing, simulation pipelines, and some database tooling.

## Other modes

Both directives accept a few special values:

- **`host`**: share the host's namespace. Powerful but eliminates isolation, use carefully.
- **`container:<id>`**: share with a specific container by ID. Rarely needed in Compose.
- **`shareable`** (`ipc` only): create an IPC namespace that other containers can join. Required on the donor service before another service can use `ipc: service:<name>` to join it.
- **`none`** (`ipc` only): no IPC namespace at all, maximum isolation.

```yaml
services:
  # Monitoring tool that needs to see all host processes
  monitor:
    image: monitoring-agent
    pid: host

  # Strict isolation for untrusted code
  sandbox:
    image: untrusted-task
    ipc: none
```

## Compared to other sharing mechanisms

| Want to share... | Directive |
|---|---|
| Network namespace (same IP) | `network_mode: service:<name>` ([Tip #47](/posts/compose-tip-047-sidecar-patterns/)) |
| Volumes / files | `volumes_from: <service>` (Tip #47) or shared volumes |
| Processes (`/proc`, `ps`, signals) | `pid: service:<name>` (this tip) |
| Shared memory / System V IPC | `ipc: service:<name>` (this tip) |

Combining these gives you Kubernetes pod-like behavior: tightly coupled containers that share network, processes, and memory.

## Security considerations

Sharing namespaces removes isolation:

- `pid: service:<name>` lets the helper container see and send signals to the main container's processes. Don't use with untrusted images.
- `ipc: host` lets the container access any shared memory on the host. Almost never appropriate.
- `pid: host` is similar but for processes, used by some monitoring agents.

Pair namespace sharing with read-only filesystems ([Tip #43](/posts/compose-tip-043-read-only-rootfs/)) and capability dropping ([Tip #29](/posts/compose-tip-029-container-capabilities/)) when the helper container doesn't need elevated access.

## Further reading

- [Compose specification: pid](https://docs.docker.com/reference/compose-file/services/#pid)
- [Compose specification: ipc](https://docs.docker.com/reference/compose-file/services/#ipc)
- Related: [Tip #47, Sidecar container patterns](/posts/compose-tip-047-sidecar-patterns/)
