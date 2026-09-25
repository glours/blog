---
title: "Docker Skills, Part 2: docker-build-strategies and docker-project-foundations"
date: 2026-09-30T09:00:00+02:00
draft: false
tags: ["docker-skills", "docker-build", "dockerfile", "ai-agents", "docker", "security"]
categories: ["Docker Skills"]
author: "Guillaume Lours"
showToc: true
TocOpen: false
hidemeta: false
comments: false
description: "The Docker Skills guides for Dockerfiles: docker-build-strategies for multi-stage builds, BuildKit secret mounts, and non-root images, and docker-project-foundations for scaffolding a Dockerized project from nothing."
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

A registry token passed through `ARG` never shows up in `docker run`, never gets printed by the app, looks completely invisible. It's still sitting in the image's layer history, one `docker history` away from anyone who pulls it. That's the exact mistake `docker-build-strategies` is written to intercept, and it's one of several the Dockerfile & Build family of Docker Skills, covered here alongside `docker-project-foundations`, catches before the image ships.

[Part 1](/posts/docker-skills-part-1-overview/) introduced Docker Skills and the eleven skills it ships. The two skills in this post are deliberately scoped apart: `docker-project-foundations` handles the case where there's no Docker setup at all yet, and steps aside once a project has a mature one that only needs minor edits; `docker-build-strategies` optimizes and hardens an existing Dockerfile, and steps aside when the actual need is that first-pass scaffold, or when the task is really about Compose wiring rather than image internals. [Part 3](/posts/docker-skills-part-3-compose-patterns/) covers that Compose wiring skill next.

## Build strategies: the size-and-speed rules

`docker-build-strategies` opens with multi-stage builds: name every stage explicitly (`FROM ... AS build`, `FROM ... AS runtime`), use the smallest sane runtime base (`distroless`, `alpine`, or a `slim` variant), copy only the final artifact across with `COPY --from=build`, and prefer `COPY --link` since it makes that copy independent of earlier layers, which improves cache reuse.

Layer ordering follows the usual "least to most frequently changed" rule: dependency manifests (`package.json`, `go.mod`, `requirements.txt`) and their install step come before the application source is copied in, so an unrelated source change doesn't invalidate the dependency-install cache. On top of that, the skill pushes BuildKit cache mounts for the package manager itself:

```dockerfile
RUN --mount=type=cache,target=/go/pkg/mod go build ...
RUN --mount=type=cache,target=/root/.npm npm ci
RUN --mount=type=cache,target=/root/.cache/pip pip install ...
```

For the runtime stage, the size guidance is concrete rather than generic: prefer `FROM scratch` for static Go binaries, distroless, or Alpine; remove package manager caches in the *same* `RUN` layer that installs packages (`apt-get install -y ... && rm -rf /var/lib/apt/lists/*`), since a separate layer doesn't shrink the image; and skip documentation, man pages, and debug tooling in the runtime image entirely.

A handful of smaller rules round it out: `# syntax=docker/dockerfile:1` as the first line to opt into current BuildKit features, `WORKDIR` set explicitly before any `COPY`/`RUN` rather than relying on the default `/`, and `ENTRYPOINT` in exec form (`["binary"]`) rather than shell form.

## Credentials never touch a layer

The most detailed section of the skill, by far, is build-time secrets, and it's written as a hard "do not" list rather than a suggestion. Credentials must never go through `ARG` or `ENV`: both persist into image layers and are readable with `docker history`. Credential files, `.npmrc`, `.pypirc`, `.netrc`, cloud credential directories, SSH keys, must never be `COPY`'d into the build context either, even if a later stage doesn't carry them forward. They still sit in an intermediate layer and in the build cache. And the skill flags a subtler leak: don't `echo` or otherwise re-expand a secret's value inside a `RUN` command in a way that ends up in a layer or in `--progress=plain` build logs.

The mechanism it prescribes instead is `RUN --mount=type=secret` for registry credentials and `RUN --mount=type=ssh` for private Git access:

```dockerfile
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc,required=false \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev
```

```dockerfile
RUN --mount=type=ssh \
    mkdir -p -m 0700 /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts && \
    git clone git@github.com:org/private-repo.git
```

Both mounts make the secret available only inside that specific `RUN` step; nothing persists to a layer. The `ssh-keyscan` line is deliberate too: the skill explicitly rules out `StrictHostKeyChecking=no` as a shortcut, since it disables host-key verification entirely rather than just working around the missing `known_hosts` file. On the invocation side, both mounts need to be passed to `buildx` explicitly:

```bash
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519
docker buildx build --secret id=npmrc,src=$HOME/.npmrc --ssh default .
```

`.dockerignore` exclusions for `.env` and credential files are still worth keeping, but the skill is explicit that they're defense in depth, not the primary control: the mount-based approach is what actually prevents the leak.

## Non-root, down to the chown

The non-root guidance goes one level more specific than "add a `USER` line". After creating a dedicated user and group and copying files with `--chown`, the skill calls out a real gotcha: when `--chown` is combined with `COPY --link`, it has to use the numeric UID:GID, not a named user. `--link` creates an independent layer, and named users defined in an earlier `RUN` aren't visible from it. On distroless images specifically, there's already a built-in account for this: `USER nonroot:nonroot`.

## Project foundations: three files, every time

`docker-project-foundations` covers the case one step earlier: a project with no Docker setup at all. Its rule is unconditional about scope: always produce all three of `.dockerignore`, `Dockerfile`, and `compose.yaml` together, not just whichever one the request happened to mention. `.dockerignore` comes first specifically so the initial build context stays small from the start.

Its most concrete rule is about infrastructure dependencies: when a project needs a database, cache, or queue, it always gets defined as a service in `compose.yaml`, never as a host-level install. The skill spells out the negative case directly: never suggest `brew install postgres` or `apt install redis` for a development dependency when Docker is already available.

The bootstrap checklist adds a few defaults that are easy to skip when scaffolding fast: bind published application ports to loopback unless another device genuinely needs to reach the service, and keep unauthenticated datastores on the Compose network rather than publishing their ports at all, publishing to loopback only if a local host tool truly needs direct access.

For npm-specific setups, the skill applies the same BuildKit-secret discipline as `docker-build-strategies`: exclude `.npmrc` at every depth (`**/.npmrc` in `.dockerignore`), and for private registries, pass the config through `--secret id=npmrc,src="$HOME/.npmrc"` rather than copying the file. It even offers a ready-made Compose override, `compose.npm.yaml`, that grants that secret to the build only when a private registry is actually in play, so a public-package project doesn't need the override at all.

## What's next

Part 3 moves to `docker-compose-patterns`: health-check sidecars for distroless images, `depends_on` readiness rules, and the destructive-command guardrails baked into the skill.

## Further reading

- [Docker Build documentation](https://docs.docker.com/build/)
- [`docker/skills` on GitHub](https://github.com/docker/skills)
- Previous: [Docker Skills, Part 1: What It Is, Who It's For, How to Install It](/posts/docker-skills-part-1-overview/)
- Next: [Docker Skills, Part 3: docker-compose-patterns in Depth](/posts/docker-skills-part-3-compose-patterns/)
