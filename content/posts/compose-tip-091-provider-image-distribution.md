---
title: "Docker Compose Tip #91: Providers now take part in the image phase"
date: 2026-10-12T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "advanced", "provider"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Compose 5.6.0 lets a provider opt into docker compose up and pull's image phase, so it can request the exact image bytes Compose just resolved instead of re-implementing that logic itself."
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

A provider managing containers on a remote or non-Docker runtime has always been able to declare `build:` or `image:` on its service, but getting the actual image bytes to wherever that runtime lives was left entirely to the provider: push to a registry it can reach, or shell out to `docker save`/`scp` and hope it matches what Compose actually resolved. [Tip #61](/posts/compose-tip-061-provider-services/) covered `provider` services for exactly this kind of external dependency: databases, tunnels, Kubernetes intercepts. Compose 5.6.0 adds the piece that tip didn't have yet: a provider can now opt into the same image phase every other service goes through.

## The opt-in

A provider declares support by including a `pull` block in its metadata output, even an empty one:

```json
{
  "up": { "parameters": [] },
  "pull": { "parameters": [] }
}
```

From then on, Compose invokes the provider during `up`'s image phase (after any build) and on `docker compose pull`:

```bash
my-provider compose --project-name myapp pull \
  --image=myapp-worker --source=local --policy=missing \
  --digest=sha256:abc123... --created=2026-10-01T12:00:00Z \
  worker
```

- `--source` is the authority Compose already computed: `local` means the local daemon's image is the desired state (a build-only service, or one this run just built); `registry` means resolve the reference upstream instead. The provider never has to re-implement that arbitration.
- `--policy` is `missing` on `up` (any usable version will do) or `always` on `docker compose pull` (verify freshness).
- `--digest`/`--created` describe the local daemon's cache, present only when it exists there. They're bookkeeping, not instructions: the provider compares them against what it already ingested.

## Requesting the bytes

When the provider actually needs the image, it asks for it over `stdout`:

```json
{"type": "get-image", "message": "myapp-worker"}
```

Compose answers on `stdin` with a JSON line announcing the stream (`{"type": "image-stream", "encoding": "chunked", "media-type": "application/x-tar"}`), then the chunked tar body itself, the same format `docker image save` produces. No registry round-trip required if the image only exists locally.

## Why it matters

This is opt-in and additive. A provider without a `pull` block keeps managing images exactly as before, and regular (non-provider) services are untouched either way. For the providers that do opt in, the win is one less decision to get wrong by hand: the local-vs-registry call and the freshness policy are Compose's job now, computed once and handed over as `--source`/`--policy` instead of being re-derived by every plugin author from scratch.

## Pro tip: one provider's pull failure doesn't take down the others

Provider pulls run independently rather than under fail-fast cancellation. If your stack has three provider-backed services and one of them fails its `pull`, the other two still run to completion and report their own result, instead of being cut off mid-run and surfacing a confusing `context canceled` in their place. Worth knowing before you go looking for a second bug that isn't actually there.

## Further reading

- [Compose extension protocol](https://github.com/docker/compose/blob/main/docs/extension.md)
- Related: [Tip #61, Provider services for non-container dependencies](/posts/compose-tip-061-provider-services/)
