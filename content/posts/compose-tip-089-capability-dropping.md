---
title: "Docker Compose Tip #89: What cap_drop actually takes away from root"
date: 2026-09-23T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "security", "capabilities", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "cap_drop: ALL restricts root itself, not just non-root users, and the capability you'd reach for to prove it might already be a no-op on your host."
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

Run this from a container whose process is `uid 0`:

```yaml
services:
  hardened:
    image: alpine
    cap_drop:
      - ALL
    command: sh -c "touch /tmp/f && chown 2000:2000 /tmp/f && echo OK"
```

```bash
docker compose run --rm hardened
```

```
chown: /tmp/f: Operation not permitted
```

[Tip #29](/posts/compose-tip-029-container-capabilities/) listed which `cap_add` values pair with which workload. This is the part worth sitting with: `cap_drop: ALL` just took a privilege away from `uid 0`, not from some non-root user it was supposedly protecting against.

## Root without capabilities isn't root

Add `CHOWN` back and the same command succeeds:

```yaml
    cap_add:
      - CHOWN
```

```bash
docker compose run --rm hardened
```

```
OK
```

Capabilities aren't a non-root safeguard bolted on top of the UID check, they gate root's own privileges. `CAP_CHOWN`, `CAP_SYS_MODULE`, `CAP_NET_ADMIN`, and the rest are each a specific slice of what root traditionally could do. Drop all of them and a process running as `uid 0` inside the container can't change file ownership, load a kernel module, or touch host networking, no matter what it runs as.

## Why it matters

If something inside that container ever gets to run arbitrary code, that code inherits whatever capabilities the container has, root or not. An attacker who lands as root in a container with `cap_drop: ALL` and only `CHOWN` added back still can't reconfigure `iptables`, mount a filesystem, or load a module. The image's own `USER` directive stops mattering as much once the capability list is this short.

## Pro tip: the classic NET_RAW demo might not prove anything on your host

The default reach for a "watch this get blocked" demo is dropping `NET_RAW` and showing `ping` fail. Try it:

```bash
docker run --rm --cap-drop=ALL alpine ping -c1 1.1.1.1
```

On a host where `net.ipv4.ping_group_range` covers your container's group (`0 2147483647` is the wide-open default on several distros, including Docker Desktop's VM), that `ping` succeeds anyway. Modern `ping` opens an unprivileged `SOCK_DGRAM` socket that never needed `CAP_NET_RAW` in the first place, and the capability drop has nothing to do with it. Same story for `CAP_NET_BIND_SERVICE`, binding to port 80 as a non-root user can succeed without it if `net.ipv4.ip_unprivileged_port_start` is set to `0`.

Check both before you build a demo, a test, or a security argument on either capability:

```bash
docker run --rm alpine cat /proc/sys/net/ipv4/ping_group_range
docker run --rm alpine cat /proc/sys/net/ipv4/ip_unprivileged_port_start
```

`CAP_CHOWN` has no equivalent escape hatch, which is why it's the one that reliably shows the drop taking effect.

## Further reading

- Related: [Tip #29, Container capabilities and security options](/posts/compose-tip-029-container-capabilities/)
- Related: [Tip #14, Running as non-root users in containers](/posts/compose-tip-014-non-root-users/)
- [Linux capabilities man page](https://man7.org/linux/man-pages/man7/capabilities.7.html)
