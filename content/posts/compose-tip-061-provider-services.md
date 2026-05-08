---
title: "Docker Compose Tip #61: Provider services for non-container dependencies"
date: 2026-05-11T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "configuration", "advanced", "kubernetes"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Manage external dependencies like Kubernetes intercepts, managed databases, and VPN tunnels declaratively with the provider directive"
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

Not everything in your stack is a container. Managed databases, SaaS APIs, VPN tunnels, Kubernetes intercepts, all sit outside Docker but still need to be wired into your local environment. Compose 2.36 introduced `provider` services to declare and manage these alongside your containers.

## The syntax

A `provider` service replaces `image:` with a `provider:` block:

```yaml
services:
  api:
    image: my-api:latest

  tunnel:
    provider:
      type: telepresence
      options:
        namespace: avatars
        service: api
        port: 5732:api-80
```

Two parts:

- `provider.type`: the name of a binary in your `$PATH` that implements the provider protocol (here, `compose-telepresence`)
- `provider.options`: configuration specific to that provider, defined by the plugin author

When you run `docker compose up`, Compose locates the binary, calls it with the options as flags, and lets it manage the external resource. `docker compose down` calls the same binary to clean up.

## A real example: Kubernetes traffic intercept

The [compose-telepresence-plugin](https://github.com/glours/compose-telepresence-plugin) lets you route traffic from a remote Kubernetes service to a local container, useful for debugging a microservice against the rest of a real cluster.

The plugin:

1. On `up`, installs the Telepresence traffic manager in your cluster (if needed) and creates an intercept routing traffic destined for the cluster's `api` service to your local `api` container
2. On `down`, removes the intercept and cleans up

The local `api` container runs as usual; the `tunnel` provider service handles all the Kubernetes plumbing through the Compose lifecycle.

## Other use cases

The same pattern works for any external dependency:

- **Managed databases**: provision an RDS instance for the duration of `compose up`
- **SaaS APIs**: configure access tokens or service accounts before the app starts
- **VPN tunnels**: bring up a wireguard or OpenVPN connection
- **Message queues**: connect to a managed queue with auth handled by the provider
- **Custom internal platforms**: integrate company-specific tools without shell scripts

If you want a plugin to exist, you can write one.

## How providers talk to dependent services

Providers communicate with Compose through structured JSON messages over stdout:

- `info:` — status updates shown in the Compose log
- `error:` — error messages displayed on failure
- `setenv:` — environment variables exposed to dependent services
- `debug:` — verbose-only debug output

Through `setenv:`, a provider can publish whatever values dependent services need (a generated endpoint URL, a connection string, an API key) without you having to wire anything in the Compose file.

## Writing your own provider

A provider is just a binary that:

1. Lives in your `$PATH`
2. Responds to a `compose` subcommand with `up` and `down` actions
3. Parses provider options as command-line flags
4. Writes JSON messages to stdout

The [Telepresence plugin](https://github.com/glours/compose-telepresence-plugin) is a working reference implementation in Go, and the [protocol spec](https://github.com/docker/compose/blob/main/docs/extension.md) lives in the Compose repository.

## Further reading

- [Docker blog: Compose with Provider Services](https://www.docker.com/blog/docker-compose-with-provider-services/)
- [Compose extension protocol](https://github.com/docker/compose/blob/main/docs/extension.md)
- [compose-telepresence-plugin](https://github.com/glours/compose-telepresence-plugin), reference implementation
