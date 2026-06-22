---
title: "Docker Compose Tip #80: additional_contexts for multi-context builds"
date: 2026-06-24T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "build", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Pull files from images, OCI layouts, git repos, or other Compose services into a Dockerfile build with additional_contexts and COPY --from=<name>."
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

A Dockerfile has one build context, the directory you point `docker build` at. That's enough for the vast majority of builds, but sometimes you need files from somewhere else: a base image, a separate git repository, a local directory outside the project root, or another service's build output. `additional_contexts` lets you wire all of those into a single build.

## The basic shape

Under `build:`, declare named contexts. Inside the Dockerfile, reference them with `COPY --from=<name>`:

```yaml
services:
  app:
    build:
      context: ./app
      additional_contexts:
        assets: ./shared/assets
```

```dockerfile
# app/Dockerfile
FROM node:22
WORKDIR /app
COPY . .
COPY --from=assets . /app/public/assets
RUN npm install && npm run build
```

The `assets` directory lives outside `./app` (the main context), so it would normally be unreachable from inside the Dockerfile. `additional_contexts` brings it in by name.

## Supported source schemes

A named context can point at four different kinds of source:

```yaml
build:
  context: ./app
  additional_contexts:
    # 1. A local directory (relative or absolute)
    shared: ../shared

    # 2. A Docker image — pulled and used as a context
    base: docker-image://my-base:1.2.3

    # 3. A local OCI layout (output of buildx, for instance)
    cached: oci-layout://./oci-cache

    # 4. A git repository
    docs: https://github.com/myorg/docs.git#main
```

Each scheme has its niche:

- **Local path** — share files between projects without restructuring.
- **`docker-image://`** — copy artefacts out of a published image (compiled binaries, certs, model weights) without a full multi-stage build.
- **`oci-layout://`** — reuse a pre-built layout, common in CI pipelines that cache layers as OCI artefacts.
- **`git://` / `https://...git`** — pull source from another repository at build time, pinning to a tag or commit.

## Pulling files out of an existing image

A pattern that replaces a lot of awkward multi-stage rewrites — grabbing a compiled binary from a published image:

```yaml
services:
  app:
    build:
      context: ./app
      additional_contexts:
        cli: docker-image://ghcr.io/myorg/mycli:v3.2.0
```

```dockerfile
# app/Dockerfile
FROM debian:bookworm-slim
COPY --from=cli /usr/local/bin/mycli /usr/local/bin/mycli
ENTRYPOINT ["/usr/local/bin/mycli"]
```

No need to vendor the binary, no need to install via a package manager — Compose pulls the image once and `COPY --from=cli` lifts the file out.

## Cross-service: build A using B's image

Compose also accepts a sibling service as a context. The build of one service can pull files from another service's image (in the same Compose file):

```yaml
services:
  builder:
    build: ./builder    # produces /out/artifact

  app:
    build:
      context: ./app
      additional_contexts:
        artefacts: service:builder
```

```dockerfile
# app/Dockerfile
FROM nginx:alpine
COPY --from=artefacts /out/artifact /usr/share/nginx/html/
```

This works because Compose orders the builds: `builder` is built first, then its image is exposed under the `artefacts` name when building `app`. It removes the need for a published intermediate image when the artefact only matters within the project.

## Pinning a git source

The git URL accepts a fragment to pin to a ref:

```yaml
additional_contexts:
  docs: https://github.com/myorg/docs.git#v1.4.0
  hooks: https://github.com/myorg/hooks.git#main
```

The fragment after `#` can be a branch, tag, or commit SHA. Pin to a tag or SHA for reproducible builds; `#main` is fine for documentation that should always be the latest.

## When to reach for it

`additional_contexts` shines when:

- The Dockerfile needs files outside the build context and you don't want to expand the context (which would bloat every layer).
- You're copying a single artefact out of a published image and a full multi-stage `FROM image AS x` feels heavyweight.
- A monorepo has shared resources used by several services and each service wants only its own slice.

When the data lives inside the same context, plain `COPY` is still the right answer.

## Pro tip: stable build cache

Named contexts participate in BuildKit's cache. As long as the source (the image digest, the git commit, the local directory's contents) hasn't changed, `COPY --from=<name>` is cached just like any other layer. Pinning git sources to a commit SHA (instead of `main`) keeps the cache stable across builds.

## Further reading

- [Compose specification: build.additional_contexts](https://docs.docker.com/reference/compose-file/build/#additional_contexts)
- [BuildKit named contexts](https://docs.docker.com/build/building/context/#named-contexts)
- Related: [Tip #32, Build contexts and dockerignore patterns](/posts/compose-tip-032-build-context-dockerignore/)
- Related: [Tip #45, Multi-stage builds with target](/posts/compose-tip-045-multi-stage-target/)
- Related: [Tip #77, Volume subpath for mounting a sub-directory](/posts/compose-tip-077-volume-subpath/)
