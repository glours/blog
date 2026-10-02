---
title: "Docker Skills, Part 4: Sandbox Lifecycle, Network Policy, and Credentials"
date: 2026-10-05T09:00:00+02:00
draft: false
tags: ["docker-skills", "docker-sandboxes", "ai-agents", "docker", "sbx", "security"]
categories: ["Docker Skills"]
author: "Guillaume Lours"
showToc: true
TocOpen: false
hidemeta: false
comments: false
description: "The two core Docker Sandboxes skills: docker-sandboxes-lifecycle for creating, reattaching to, and removing isolated sbx microVMs, and docker-sandboxes-network-credentials for the egress policy and credential injection that keep real secrets out of the sandbox's hands."
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

One command, `sbx run claude .`, and Claude gets a complete, disposable place to work: its own filesystem, its own network, its own Docker daemon, built from the current directory in a few seconds, instead of running directly on your machine with your own shell, your own files, and your own network access. That's Docker Sandboxes: a standalone `sbx` CLI that runs an AI coding agent inside an isolated microVM so a runaway command, a bad `rm`, or a prompt-injected instruction stays contained to a disposable environment instead of your actual laptop. See the [Docker Sandboxes documentation](https://docs.docker.com/ai/sandboxes/) for the full product picture; `docker-sandboxes-lifecycle` and `docker-sandboxes-network-credentials`, the two skills this post covers, are what make that sandbox practical to drive day to day: how isolated the agent's workspace is, how you get back into a sandbox you left running, and exactly what it can reach on the network and authenticate with.

[Part 1](/posts/docker-skills-part-1-overview/) through [Part 3](/posts/docker-skills-part-3-compose-patterns/) covered the Dockerfile, Build, and Compose families. This post moves to Docker Sandboxes, and specifically to the two skills that teach an agent to drive `sbx` on a user's behalf. `sbx` is new enough, and its flags specific enough, that a generic coding agent asked to "put yourself in a sandbox" or "let the sandboxed agent call our API" has no reliable way to know the right command shape without them, the same gap Part 1 described for Dockerfiles and Compose files.

## Picking the right entry point, not just the right agent

`sbx run AGENT [PATH...]` creates a sandbox if it doesn't exist yet and attaches in the same step; `AGENT` isn't locked to Claude; the built-in choices are `claude`, `codex`, `cursor`, `devin`, `docker-agent`, `gemini`, `opencode`, or a plain `shell`. `docker-sandboxes-lifecycle` spells these out explicitly, because they aren't the kind of thing a model would otherwise guess correctly:

```bash
sbx run claude .          # Claude, current directory mounted
sbx run codex .           # same isolation, a different agent
```

The skill also flags a trap worth knowing before it bites: `sbx run claude` with no path mounts the current directory, but `sbx create claude` with no path mounts nothing at all. An agent that doesn't know this asymmetry can produce a `create` command that looks identical to the working `run` version and silently stand up a sandbox with an empty filesystem instead of the project it was supposed to contain. The skill's fix is simple, always pass a path explicitly with `create`, but only useful if the agent has been told the two commands aren't interchangeable.

## Knowing when `--clone` is even an option

By default the workspace is a read/write bind mount: the agent writes straight to the host working tree. `--clone`, set only at creation time, isolates that instead: the host repository is mounted read-only, the agent's commits land in a private in-container clone, reachable from the host through a `sandbox-<name>` git remote.

```bash
sbx create --clone --name demo claude .
# on the host, later:
git fetch sandbox-demo
```

The part worth an agent actually checking before it recommends `--clone`, rather than just appending the flag: it needs an explicit path, that path has to sit inside a real Git repository, and it can't be a worktree or a submodule. Suggesting `--clone` without checking those first produces a creation failure instead of a sandbox. The skill also carries a recovery detail a generic agent wouldn't think to mention: fetched work survives at `refs/sandboxes/demo/*` even after the sandbox is removed, so an agent helping a user clean up sandboxes knows to suggest `git fetch sandbox-demo` first rather than just running `sbx rm`.

## Reaching into a running sandbox without guessing at syntax

Once a sandbox exists, a user is as likely to ask their agent to "grab that log file" or "run the tests in there" as to ask it to create one in the first place, and the skill gives the agent the exact shape for each of those requests instead of leaving it to improvise flags that look plausible but are wrong:

- `sbx exec SANDBOX COMMAND`, with `docker exec`-style flags: `sbx exec -it my-sandbox bash`, `sbx exec -u root my-sandbox apt-get update`.
- `sbx cp SRC DST`, one side always `SANDBOX:PATH`: `sbx cp ./config.json my-sandbox:/home/agent/` pushes a file in, the reverse pulls one out.
- `sbx ports`, to publish or drop a port on a sandbox that's already running, without recreating it, for when the agent starts a dev server mid-session and the user wants to hit it from the host.

`sbx ls` is what the skill tells an agent to check first when a request is ambiguous ("is my sandbox still up?"), before reaching for `sbx stop` (pauses, state kept) or `sbx rm`/`sbx prune` (gone for good, `--dry-run --filter until=168h` previews a sweep before it runs for real).

## Not reaching for a plain `--env` when a user hands over a key

Asked to give a sandboxed agent an API key, the unguided move for a generic coding agent is the obvious one: pass it as a literal `--env` or `--kit-arg` value. `docker-sandboxes-network-credentials` tells the agent specifically not to, that value lands as unmasked text in the sandbox's environment and in `sbx env plan`'s state file, defeating the point of isolating the agent in the first place. The rule it gives instead: if the key already lives in a host environment variable, `sbx secret import` pulls it straight into the credential store (`OPENAI_API_KEY`, `GH_TOKEN`, prompting per entry unless `--all`); otherwise `sbx secret set SERVICE` stores it directly:

```bash
sbx secret set github                       # interactive
printf '%s' "$ANTHROPIC_API_KEY" | sbx secret set anthropic
```

Either way, the sandbox itself never sees the raw value, the proxy injects it only on requests to domains the agent's kit declares, which is precisely the difference between an agent that followed the skill and one that didn't. Registry credentials default the other way, host-pulls-only unless `--all-sandboxes` or `--sandbox NAME` says otherwise, a distinction worth an agent getting right before assuming a private image will just pull inside a sandbox the way it does on the host.

## Telling an agent what it's allowed to reach, and having it stick

A sandbox's network is default-deny until the global policy says otherwise, and `sbx policy init balanced` is the one-time setup an agent should check for before anything else fails with a confusing network error. From there, the skill's rule for scoping access is specific: deny always wins over allow for the same host, which is also why `--deny-network` at creation time is safe for an agent to reach for even under centralized governance, it can only narrow a single sandbox's egress, never widen it past whatever the org-level policy already permits:

```bash
sbx policy allow network "api.example.com,cdn.example.com"
sbx policy deny network ads.example.com
```

When a request fails and the reason isn't obvious, the skill points an agent at `sbx policy check network TARGET` to answer "would this be allowed" before guessing, and `sbx policy log` to see what was actually decided and why.

## What's next

Part 5 moves to Docker Agent: `docker-agent-config`, `docker-agent-run`, including `docker agent run --sandbox`, which hands off to this same sandbox lifecycle, and `docker-agent-deploy`. Part 6 closes the series with `docker-destructive-guardrails`, the cross-product policy referenced throughout this series.

## Further reading

- [`docker/sandboxes` on GitHub](https://github.com/docker/sandboxes)
- [`docker/skills` on GitHub](https://github.com/docker/skills)
- Previous: [Docker Skills, Part 3: docker-compose-patterns in Depth](/posts/docker-skills-part-3-compose-patterns/)
