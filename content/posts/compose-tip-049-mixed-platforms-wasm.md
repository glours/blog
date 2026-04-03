---
title: "Docker Compose Tip #49: Mixed platforms with Linux containers and Wasm"
date: 2026-04-06T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "advanced", "wasm", "platform"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Run Linux containers and WebAssembly modules side by side in the same Compose stack"
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

Compose can orchestrate more than just Linux containers. By combining `platform` and `runtime`, you can run traditional containers alongside WebAssembly (Wasm) modules in the same stack.

## The platform key

The `platform` key at service level tells Docker which platform the service targets:

```yaml
services:
  # Regular Linux container (default)
  web:
    image: nginx
    platform: linux/amd64

  # WebAssembly module
  api:
    image: wasmedge/example-wasi-http
    runtime: io.containerd.wasmedge.v1
```

## Mixing Linux and Wasm services

Here's a practical stack where a traditional nginx reverse proxy sits in front of a Wasm-based API:

```yaml
services:
  # Standard Linux container — reverse proxy
  nginx:
    image: nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - api

  # Wasm module — lightweight HTTP echo server
  api:
    image: wasmedge/example-wasi-http
    runtime: io.containerd.wasmedge.v1
    expose:
      - "1234"

  # Standard Linux container — database
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

The `nginx` and `postgres` services run as regular Linux containers. The `api` service runs as a Wasm module using the WasmEdge runtime — much lighter and with a smaller attack surface. The [`wasmedge/example-wasi-http`](https://hub.docker.com/r/wasmedge/example-wasi-http) image is a simple HTTP echo server listening on port 1234.

## The runtime key

The `runtime` key specifies which OCI runtime executes the container. For Wasm workloads, you need a Wasm-compatible runtime:

```yaml
services:
  # Using Wasmtime
  app-wasmtime:
    image: myapp:latest
    platform: wasi/wasm
    runtime: io.containerd.wasmtime.v1

  # Using WasmEdge
  app-wasmedge:
    image: myapp:latest
    platform: wasi/wasm
    runtime: io.containerd.wasmedge.v1

  # Using Spin
  app-spin:
    image: myapp:latest
    platform: wasi/wasm
    runtime: io.containerd.spin.v2
```

## Why mix platforms?

Wasm services offer some advantages over traditional containers:
- **Cold start in milliseconds** — great for event-driven workloads
- **Smaller images** — Wasm binaries are typically much smaller
- **Sandboxed by default** — no filesystem or network access unless explicitly granted
- **Cross-platform** — the same Wasm binary runs anywhere

But not everything can run as Wasm today. Databases, reverse proxies, and many existing tools still need traditional Linux containers. Compose lets you mix both seamlessly.

## Prerequisites

To run Wasm workloads with Docker Desktop, enable the Wasm integration in Settings > Features in development > Enable Wasm.

## Further reading

- [Compose specification: platform](https://docs.docker.com/reference/compose-file/services/#platform)
- [Compose specification: runtime](https://docs.docker.com/reference/compose-file/services/#runtime)
- [Docker and Wasm](https://docs.docker.com/wasm/)
