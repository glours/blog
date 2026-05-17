---
title: "Docker Compose Tip #65: Custom DNS configuration with dns and dns_search"
date: 2026-05-20T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "networking", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Control which DNS servers a container uses, configure search domains, and tune the resolver"
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

By default, containers inherit DNS configuration from the Docker daemon. When you need to override that, three directives give you full control: `dns:`, `dns_search:`, and `dns_opt:`.

## Setting custom DNS servers

`dns:` overrides which resolvers the container queries:

```yaml
services:
  app:
    image: myapp
    dns:
      - 1.1.1.1
      - 8.8.8.8
```

The container now uses Cloudflare and Google DNS instead of whatever the host provides. Useful when:

- The host DNS is slow or unreliable for your use case
- You need a specific public DNS for content filtering (Pi-hole, NextDNS)
- A development environment must reach internal services through a corporate DNS server

## Search domains

`dns_search:` adds search domains so short names resolve against them:

```yaml
services:
  app:
    image: myapp
    dns_search:
      - corp.example.com
      - internal.example.com
```

Now `app` can resolve `database` as `database.corp.example.com` (or `database.internal.example.com`) without using a fully qualified name. Convenient when working with internal services that share a parent domain.

## Resolver options

`dns_opt:` passes options to the resolver library:

```yaml
services:
  app:
    image: myapp
    dns_opt:
      - "ndots:2"
      - "timeout:1"
      - "attempts:2"
```

Common options:

- `ndots:N` — names with fewer than N dots are looked up using search domains first
- `timeout:N` — seconds to wait for a DNS response
- `attempts:N` — how many retries before giving up
- `rotate` — round-robin through the configured nameservers

## A practical example

A development container that needs to resolve internal hostnames through a VPN's DNS:

```yaml
services:
  dev-app:
    image: myapp
    dns:
      - 10.0.0.1            # Corporate DNS reached over VPN
      - 1.1.1.1             # Public fallback
    dns_search:
      - corp.example.com
    dns_opt:
      - "ndots:1"
      - "timeout:2"
```

`api`, `auth`, and other internal hostnames resolve through corporate DNS via the search domain, while public DNS handles everything else.

## dns vs extra_hosts

Easy to confuse, but very different:

- **`dns:`** ([Tip #65, this one]): tells the container which DNS server(s) to query. Affects *how* names are resolved.
- **`extra_hosts:`** ([Tip #36](/posts/compose-tip-036-extra-hosts/)): adds static entries to `/etc/hosts`. Bypasses DNS entirely for those specific names.

Use `dns:` when you want to change the resolver. Use `extra_hosts` when you want to pin a specific hostname to a specific IP regardless of DNS.

## Verifying the configuration

Check what's actually configured inside the container:

```bash
# See the resolved /etc/resolv.conf
docker compose exec app cat /etc/resolv.conf

# Test name resolution
docker compose exec app getent hosts api.corp.example.com
```

If your settings don't appear, the Docker daemon's default DNS may take precedence, or the image's entrypoint may be rewriting `/etc/resolv.conf`.

## Further reading

- [Compose specification: dns](https://docs.docker.com/reference/compose-file/services/#dns)
- [Compose specification: dns_search](https://docs.docker.com/reference/compose-file/services/#dns_search)
- [Compose specification: dns_opt](https://docs.docker.com/reference/compose-file/services/#dns_opt)
- Related: [Tip #36, Using extra_hosts for custom DNS entries](/posts/compose-tip-036-extra-hosts/)
