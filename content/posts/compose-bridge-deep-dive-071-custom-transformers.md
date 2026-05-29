---
title: "Compose Bridge Deep Dive #71 — Part 2: Custom transformers and x-* extensions"
date: 2026-06-03T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "compose-bridge", "kubernetes", "deep-dive", "customization", "advanced"]
categories: ["Compose Deep Dive"]
author: "Guillaume Lours"
showToc: true
TocOpen: false
hidemeta: false
comments: false
description: "Bootstrap a custom Compose Bridge transformer, fold organisation-specific rules into the templates, and use x-* extension fields to drive the output."
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

The defaults shipped with Compose Bridge produce sensible Kubernetes manifests, but every organisation has its own rules: which labels are required, which ingress class to use, which `securityContext` is mandatory, which Pod Security Standard applies. Hard-coding all of that in every Compose file gets old fast. The clean way to bake those rules in is a custom transformer.

This is the second post of the [Compose Bridge Deep Dive](/posts/compose-bridge-deep-dive-070-introduction/) series. Part 1 explained the transformer concept. This post shows how to fork the default templates, plug your rules in, and use the `x-*` extension fields to keep your Compose files clean.

## Recap of the contract

A transformer is a Docker image that reads `/in/compose.yaml` and writes the resulting manifests to `/out/`. The Compose model arrives fully resolved (overrides applied, variables interpolated). Anything in between is up to you.

The default transformer images ship Go templates plus a small Go binary that walks the Compose model and renders the templates. Forking those templates is the simplest path to a custom transformer.

## Bootstrap from the default

Start a custom transformer by extracting the defaults:

```bash
docker compose bridge transformations create \
    --from docker/compose-bridge-kubernetes \
    my-template
```

The `my-template/` directory now contains:

```
my-template/
├── Dockerfile
└── templates/
    ├── base/
    │   ├── deployment.tmpl
    │   ├── service.tmpl
    │   ├── configmap.tmpl
    │   └── ...
    └── overlays/
        └── desktop/
            └── _index.tmpl
```

Each `*.tmpl` file is a Go template that produces YAML. A single template can emit multiple files by using the `#! filename.yaml` header notation; the runtime splits the output along those markers.

## Anatomy of a template

A trimmed look at the default `deployment.tmpl` shows the shape:

```go
{{ $project := .name }}
{{ range $name, $service := .services }}
---
#! {{ $name }}-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $name | safe }}
  namespace: {{ $project | safe }}
  labels:
    com.docker.compose.project: {{ $project }}
    com.docker.compose.service: {{ $name }}
spec:
  replicas: {{ if $service.scale }}{{ $service.scale }}{{ else }}1{{ end }}
  ...
{{ end }}
```

The Compose model is exposed as a tree with the same shape as the YAML: `.services`, `.networks`, `.volumes`, `.models`, plus everything underneath each service. The transformer registers helper functions on top of Go's templating builtins: `safe`, `title`, `uppercase`, `indent`, `hasAttribute`, `getAttribute`, `isString`, `or`, and a handful more.

## Folding in organisation rules

Suppose every Deployment in your organisation must carry three labels: `team`, `cost-center`, and `env`. Add them to the template:

```go
metadata:
  name: {{ $name | safe }}
  namespace: {{ $project | safe }}
  labels:
    com.docker.compose.project: {{ $project }}
    com.docker.compose.service: {{ $name }}
    team: {{ or (index $service "x-team") "unknown" }}
    cost-center: {{ or (index $service "x-cost-center") "default" }}
    env: {{ or (index $service "x-env") "dev" }}
```

The `x-team`, `x-cost-center`, and `x-env` values are read straight from the service definition. If the developer forgot to set them, sensible defaults kick in. This is enforcement without ceremony.

## Using `x-*` extension fields as transformer input

Extension fields ([Tip #27](/posts/compose-tip-027-extension-metadata/)) are the documented way to attach arbitrary metadata to a Compose model. Compose Bridge preserves them on the way to the transformer, so they make a natural input mechanism for custom rules.

A Compose file with explicit deployment hints:

```yaml
services:
  web:
    image: registry.example.com/web:1.4.0
    ports:
      - "8080:80"
    x-team: payments
    x-cost-center: cc-9821
    x-env: production
    x-ingress:
      host: pay.example.com
      class: nginx-internal
      tls: true
```

The values stay invisible to vanilla Compose (extension fields are ignored by anything that does not understand them) but feed the transformer directly. The Go template reads them with the `index` function:

```go
{{ $ingress := index $service "x-ingress" }}
{{ if $ingress }}
---
#! {{ $name }}-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $name | safe }}
  namespace: {{ $project | safe }}
  annotations:
    kubernetes.io/ingress.class: {{ index $ingress "class" | safe }}
spec:
  rules:
    - host: {{ index $ingress "host" | safe }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ $name | safe }}
                port:
                  number: 80
  {{ if index $ingress "tls" }}
  tls:
    - hosts:
        - {{ index $ingress "host" | safe }}
      secretName: {{ $name }}-tls
  {{ end }}
{{ end }}
```

A field that the upstream tool does not need stays out of the way until your transformer picks it up.

## Build, push, and use

The bootstrap directory ships with a `Dockerfile` that already knows how to package the templates into a transformer image. Build and push:

```bash
docker build --tag registry.example.com/platform/compose-transformer:1.0 --push .
```

Run the conversion with your image:

```bash
docker compose bridge convert \
    --transformation registry.example.com/platform/compose-transformer:1.0
```

Same output layout as the default (`out/base/` plus overlays), now with your labels and ingress logic baked in.

## Chain transformations

Compose Bridge accepts multiple `--transformation` flags. The transformers run in order, each one reading the output of the previous step. This is useful when you want to stack your rules on top of the default behaviour rather than replace it wholesale:

```bash
docker compose bridge convert \
    --transformation docker/compose-bridge-kubernetes \
    --transformation registry.example.com/platform/policy-transformer:1.0
```

A pattern that works well in practice:

- The first transformer produces the standard manifests.
- The second transformer post-processes them to inject service mesh sidecars, Prometheus annotations, mandatory `PodSecurityPolicy` settings, or whatever else the platform team owns.

This keeps the application-shape logic separate from the platform-policy logic, and either piece can evolve independently.

## Real-world things to encode in a custom transformer

A non-exhaustive list of cases that justify investing in a custom transformer:

- **Required labels** for cost tracking and ownership (`team`, `cost-center`, `owner-email`).
- **Mandatory `securityContext`**: `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, dropped capabilities. Compose itself only carries part of this; the transformer enforces the rest.
- **Image policy**: rewrite image references to point to your internal registry mirror, or refuse to render a manifest that references `:latest`.
- **Pod Security Standards**: stamp the namespace with the right `pod-security.kubernetes.io/enforce` label.
- **Observability defaults**: Prometheus scrape annotations, OpenTelemetry sidecars, structured-logging environment variables.
- **Ingress conventions**: pick the right ingress class, TLS issuer, and external-DNS annotations based on `x-env`.

Each one of these would be a footgun if every developer had to remember it. Bundling them into a single transformer image makes the right thing the easy thing.

## Pro tip: keep the templates under version control

The bootstrap output is just a directory of files. Commit it to a repository, code-review template changes like any other code, and tag the resulting transformer image with the same version your platform team ships. When a developer reports "the deployment changed shape between two runs", `git log` on the transformer repo is the first place to look.

## Further reading

- [Customize Compose Bridge documentation](https://docs.docker.com/compose/bridge/customize/)
- [Default transformer templates on GitHub](https://github.com/docker/compose-bridge-transformer)
- Previous: [Compose Bridge Deep Dive — Part 1: From Compose to Kubernetes](/posts/compose-bridge-deep-dive-070-introduction/)
- Next: [Compose Bridge Deep Dive — Part 3: Generating a Docker Model Runner app for Kubernetes](/posts/compose-bridge-deep-dive-072-model-runner/)
- Related: [Extension fields as metadata](/posts/compose-tip-027-extension-metadata/)
