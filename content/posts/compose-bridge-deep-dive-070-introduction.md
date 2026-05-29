---
title: "Compose Bridge Deep Dive #70 — Part 1: From Compose to Kubernetes"
date: 2026-06-01T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "compose-bridge", "kubernetes", "deep-dive", "intermediate"]
categories: ["Compose Deep Dive"]
author: "Guillaume Lours"
showToc: true
TocOpen: false
hidemeta: false
comments: false
description: "What Compose Bridge is, how its transformer images work, and how to generate Kubernetes manifests directly from a Compose file."
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

Compose excels at local development. Production usually runs on Kubernetes. Maintaining two parallel descriptions of the same application is where drift, bugs, and "works on my laptop" stories come from. Compose Bridge bridges that gap by turning a Compose file into a deployable Kubernetes artifact, without asking you to maintain a second source of truth.

This is the first part of a three-post deep dive on Compose Bridge. Part 1 covers what it is and how it works. [Part 2](/posts/compose-bridge-deep-dive-071-custom-transformers/) goes into custom transformers and enterprise customization. [Part 3](/posts/compose-bridge-deep-dive-072-model-runner/) shows how to deploy an AI application with Docker Model Runner to Kubernetes.

## What Compose Bridge is

`docker compose bridge` is a sub-command that converts a Compose model into platform-specific manifests. Out of the box it targets Kubernetes with a Kustomize-style layout, and a second official transformer produces a Helm chart. The same Compose file feeds both.

The simplest invocation, in a directory with a `compose.yaml`:

```bash
docker compose bridge convert
```

That writes generated files under `./out/`. Apply them to any cluster with:

```bash
kubectl apply -k out/overlays/desktop/
```

No new file format to learn, no second YAML tree to maintain.

## How it actually works: transformer images

Compose Bridge does not have a hard-coded mapping from Compose to Kubernetes. The conversion logic lives in a *transformer image*: a regular Docker image that follows a small contract.

The contract is intentionally minimal:

- **Input**: the resolved Compose model is mounted at `/in/compose.yaml`
- **Output**: the transformer writes platform manifests under `/out/`

Whatever the image does in between is its own business. The default transformers ship Go templates plus a tiny Go binary that walks the Compose model and renders the templates, but a transformer could be written in any language and use any templating engine.

Two official transformer images cover the common cases:

- `docker/compose-bridge-kubernetes` — produces a base + overlays Kustomize layout (this is the default)
- `docker/compose-bridge-helm` — produces a Helm chart

Pick a transformer explicitly with `--transformation`:

```bash
docker compose bridge convert --transformation docker/compose-bridge-helm
```

## A first end-to-end run

Take a small Compose file:

```yaml
services:
  web:
    image: nginx:1.27
    ports:
      - "8080:80"
    environment:
      WELCOME: "hello from compose"

  cache:
    image: redis:7-alpine
```

Run the default conversion:

```bash
docker compose bridge convert
```

The resulting tree:

```
out/
├── base/
│   ├── kustomization.yaml
│   ├── web-deployment.yaml
│   ├── web-service.yaml
│   ├── cache-deployment.yaml
│   └── cache-service.yaml
└── overlays/
    └── desktop/
        ├── kustomization.yaml
        └── web-service.yaml      # overrides Service type to LoadBalancer
```

The `base/` directory holds the platform-agnostic manifests. The `overlays/` directory carries context-specific patches, with `desktop/` being a starter overlay that suits Docker Desktop's embedded Kubernetes cluster.

To deploy:

```bash
kubectl apply -k out/overlays/desktop/
```

Kustomize merges base and overlay, then `kubectl` posts the result to the cluster.

## What gets generated for which Compose constructs

The default Kubernetes transformer follows predictable mappings. A short cheat sheet:

| Compose construct | Kubernetes output |
|---|---|
| `services:` entry | `Deployment` + `Service` |
| `ports:` | `Service` `ports` (ClusterIP by default, LoadBalancer in desktop overlay) |
| `environment:` | `env` entries on the container |
| `volumes:` named volume | `PersistentVolumeClaim` + `volumeMounts` |
| `configs:` (Tip [#58](/posts/compose-tip-058-configs/)) | `ConfigMap` |
| `secrets:` | `Secret` (placeholder, you provide the values) |
| `healthcheck:` | `livenessProbe` and `readinessProbe` |
| `depends_on:` | startup ordering hints (init containers for the simple cases) |
| `deploy.replicas` | `replicas` on the `Deployment` |
| `deploy.resources` | container `resources.requests` / `resources.limits` |

Some things do not have a literal Kubernetes equivalent and are handled with reasonable defaults or simply omitted (for example, `develop.watch` is a local-dev concept). The next post in this series shows how to override any of these mappings with a custom transformer.

## Helm output

Swap the transformer to produce a Helm chart instead:

```bash
docker compose bridge convert --transformation docker/compose-bridge-helm
```

The output is a complete chart, ready to install:

```bash
helm install myapp ./out
```

Values are extracted into `values.yaml`, so non-developers can tune replicas, images, or environment variables without touching the templates.

## Where Compose Bridge fits in your workflow

A few patterns that work well in practice:

- **Local first, production second**: write the Compose file, develop with `docker compose up --watch`, then `docker compose bridge convert` when it's time to ship a manifest. The Compose file stays canonical.
- **CI generates the manifests**: keep `compose.yaml` in the repo, generate the `out/` tree on every PR, and let CI validate or even apply the result.
- **Combine with Compose Bridge in Docker Desktop**: Docker Desktop integrates the same transformer pipeline, so you can push a stack to the embedded Kubernetes cluster from the UI.

## Pro tip: keep extension fields in your Compose file

Extension fields ([Tip #27](/posts/compose-tip-027-extension-metadata/)) flow through the transformation unchanged. Anything you stash under `x-*` is available to a custom transformer, which is exactly how organisations encode their own conventions on top of the defaults. Part 2 of this series leans on that mechanism.

## Further reading

- [Compose Bridge documentation](https://docs.docker.com/compose/bridge/)
- [Default transformer templates on GitHub](https://github.com/docker/compose-bridge-transformer)
- Related: [Compose `configs` for config files](/posts/compose-tip-058-configs/)
- Related: [Extension fields as metadata](/posts/compose-tip-027-extension-metadata/)
- Next: [Compose Bridge Deep Dive — Part 2: Custom transformers and `x-*` extensions](/posts/compose-bridge-deep-dive-071-custom-transformers/)
