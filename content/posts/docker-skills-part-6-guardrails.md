---
title: "Docker Skills, Part 6: Destructive-Command Guardrails and a Series Wrap-Up"
date: 2026-10-09T09:00:00+02:00
draft: false
tags: ["docker-skills", "docker", "ai-agents", "security", "cli"]
categories: ["Docker Skills"]
author: "Guillaume Lours"
showToc: true
TocOpen: false
hidemeta: false
comments: false
description: "docker-destructive-guardrails, the cross-product Docker Skills policy for irreversible Docker CLI commands: the Tier 1/Tier 2 split for container cleanup, why docker network rm -f and docker context rm -f behave differently despite sharing a flag name, and a wrap-up of all 11 skills in the series."
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

`docker network rm -f` and `docker context rm -f` share a flag name and do different things. `docker network rm --help` says its `-f` means "Do not error if the network does not exist": a network still attached to a running container survives it regardless. `docker context rm --help` says its own `-f` means "Force the removal of a context in use": on a context, `-f` genuinely forces removal even while it's the active one. Both commands describe their own behavior accurately. The trap is assuming `-f` means the same thing everywhere because it's the same letter, and skipping the one `--help` you actually needed to read. `docker-destructive-guardrails`, the skill this closing post covers, exists for exactly this kind of inconsistency: the places where "it looked like the other command" is how damage happens.

[Part 1](/posts/docker-skills-part-1-overview/) through [Part 5](/posts/docker-skills-part-5-agent/) covered the Dockerfile, Build, Compose, Sandboxes, and Agent families. This closing post covers the last of the eleven skills, the cross-product one every other skill in the repository defers to before running an irreversible command.

## An index, not a duplicate

`docker-destructive-guardrails` doesn't re-litigate Compose or Sandboxes destructive commands. `docker compose down -v` and `docker compose rm -v` stay owned by `docker-compose-patterns`, covered in [Part 3](/posts/docker-skills-part-3-compose-patterns/). `sbx rm` and `sbx prune` stay owned by `docker-sandboxes-lifecycle`, covered in [Part 4](/posts/docker-skills-part-4-sandboxes-core/). This skill owns the generic Docker CLI surface that has no more specific home: container removal, image and network pruning, build cache, builder instances, contexts, and standalone (non-Compose) volumes, and it points an agent at whichever skill owns the rest instead of repeating that guidance twice and letting the two copies drift apart.

## The one place the skill allows acting without asking first

The core rule for everything in this skill is flat: state exactly what gets deleted, stopped, or lost, and get explicit confirmation before running it. Container cleanup is the one exception, and it's narrow enough that it reads more like a checklist than a loophole. Tier 1, no confirmation required, applies only when every one of these holds at once: the container is already stopped, or the agent itself created and started it earlier in the same session purely for testing; nothing unpersisted is at risk; the command targets one specific, named container rather than a sweep; and the agent is acting on an explicit ask this session, not its own initiative.

```bash
docker rm old-test-container        # already stopped, Tier 1
docker rm -f my-session-test-db     # agent's own throwaway container, Tier 1
```

Everything else drops to Tier 2 and needs confirmation first, no exceptions: `docker kill` (always, there's no stopped-container case for it), `docker container prune` (it sweeps every stopped container on the host, never just the one being cleaned up), `docker rm -f` on a container the agent didn't start this session, and any unscoped sweep like `docker rm -f $(docker ps -aq)`. The dividing line isn't "is this reversible", it's "did a human actually ask for this specific thing to go away, right now."

## `docker stop` plays by a different rule entirely

`docker stop` doesn't remove anything. The container still exists and restarts with `docker start`, which is why it sits outside the Tier 1/Tier 2 model above rather than inside it. It still belongs in this skill because `SIGTERM`, then `SIGKILL` after a timeout, discards any unpersisted in-container state the same as a kill does. On the agent's own test container, it gets the Tier 1 treatment: stop it, say what happened, move on. On anything else, state what's about to be interrupted and wait for confirmation first.

## The prune flags that quietly change scope

Three commands look like they do one thing and actually gate a second, wider deletion behind a flag:

```bash
docker system prune --volumes   # anonymous volumes only, named volumes untouched
docker image prune -a           # every unreferenced image, not just dangling ones
docker volume prune -a          # named volumes too, not just anonymous ones
```

`docker system prune --volumes` is the one worth remembering precisely, because its scope matches `docker volume prune`'s default: both touch unused *anonymous* volumes only. A named volume holding real database state, the kind declared under a service's `volumes:` entry, survives either command. Deleting it takes a separate, explicit `docker volume rm` or `docker volume prune -a`, each needing its own confirmation. Treating "I ran prune with `--volumes`" as proof that named data is gone is the exact mistake this section exists to prevent.

`docker network prune` doesn't even need a widening flag to reach that scope: left alone, it removes every user-defined network not currently attached to a running container in one pass, static IPs, custom subnets, and all. There's no narrower default the way `image prune`'s dangling-only behavior gives one. Confirming the specific network names first, one at a time with `docker network rm`, is the safer habit here, not an optional extra step.

## What confirmation actually looks like

The core rule behind every command in this skill is one sentence: state exactly what gets deleted, stopped, or lost, and wait for an explicit answer before running it. A generic agent asked to "clean things up" tends to treat that sentence as optional once it has found a command that obviously works:

> **User:** Docker's taking up a lot of disk space, can you clean things up?
>
> **Agent:** Sure, running `docker system prune -a --volumes` now... Done, freed 12GB.

That reply "worked," in the sense that disk space came back, and it's still wrong: nothing was named before it ran, and nobody was asked. The skill's version of the same exchange orders the options by risk instead of jumping straight to the most thorough one, and stops there:

> **Agent:** I can reclaim space, but there are a few options with different levels of risk:
>
> - `docker container prune`, removes stopped containers only. Low risk.
> - `docker image prune`, removes dangling (untagged) images only. Low risk.
> - `docker image prune -a`, removes *all* images not referenced by any container, running or stopped, including tagged ones you might want to reuse. You'd need to re-pull or rebuild them later.
> - `docker system prune -a --volumes`, the most aggressive option. Also deletes every unused *anonymous* volume (named volumes, like database state, aren't touched; those need a separate `docker volume rm`).
>
> Want me to start with the low-risk options, or do you want the more aggressive cleanup?

Nothing runs until the user picks one. That's the entire skill compressed into one exchange: not a longer list of commands to memorize, but a habit of naming the blast radius before acting on it, exactly the step a model left to its own judgment skips the moment it has found a command that works.

## The flags `--help` doesn't fully settle

Most of this skill is about reading the right `--help` text instead of assuming one `-f` behaves like another. A few flags don't resolve even once you've read the right one, and the skill treats that gap itself as a reason to ask, not a reason to guess:

- `docker rmi -f` / `docker image rm -f`: its own `--help` text says only "Force removal of the image." It's commonly understood to override protection for a multi-tag image or one referenced by a stopped container, but that override behavior isn't spelled out in the help text itself. Treat it as documented by convention, not confirmed, and get confirmation before using `-f` on an image that might still be tagged or referenced elsewhere.
- `docker volume rm -f` on a standalone volume (no Compose project involved): the plain command's `--help` states plainly, "You cannot remove a volume that is in use by a container." Whether `-f` genuinely overrides that, or merely suppresses a "no such volume" error the way `docker network rm -f` does, is left open. The safer path: run without `-f` first, and if it fails because the volume is in use, stop or remove the container using it, with its own confirmation, before retrying.
- `docker buildx rm`: a different resource from the build cache `docker builder prune` clears. It removes a builder *instance*, its registration, and (unless `--keep-daemon`/`--keep-state` is passed) its daemon state. `--all-inactive` widens that to every inactive builder at once instead of the one named.

An agent that already knows to check `--help` before acting can still get this wrong, because checking doesn't always produce a clean answer. The skill's fallback for an unresolved flag is the same fallback as everywhere else in it: ask, rather than pick the reading that lets the command run.

## Closing the series

Across six posts, Docker Skills turned out to be eleven skills across four product families plus this cross-product one: `docker-project-foundations` and `docker-build-strategies` for Dockerfiles, `docker-compose-patterns` for wiring services, `docker-sandboxes-lifecycle` and `docker-sandboxes-network-credentials` for isolating an agent in a microVM, `docker-agent-config`, `docker-agent-run`, and `docker-agent-deploy` for building and shipping agents on `cagent`, and `docker-destructive-guardrails` tying the destructive edge of all of them together. Two more in that count, `docker-sandboxes-env` and `docker-sandboxes-kits`, ship in the same release and cover declarative `sbxenv.yaml` environments and kit `spec.yaml` packaging; both are marked experimental in the source, and whether they get their own deep dive is still open.

None of it replaces review. A skill steers an agent toward a pinned tag, a health check, a Tier 1 cleanup instead of a Tier 2 one; it doesn't verify the result builds, runs, or means what it says. Install it the same way as Part 1 described, and check the diff the same way you would without it:

```bash
npx skills add docker/skills
```

## Further reading

- [`docker/skills` on GitHub](https://github.com/docker/skills)
- [Docker Skills documentation](https://docs.docker.com/ai/skills/)
- Previous: [Docker Skills, Part 5: Configuring, Running, and Deploying Docker Agent](/posts/docker-skills-part-5-agent/)
