---
title: "Docker Skills, Part 5: Configuring, Running, and Deploying Docker Agent"
date: 2026-10-07T09:00:00+02:00
draft: false
tags: ["docker-skills", "docker-agent", "ai-agents", "docker", "mcp", "cagent"]
categories: ["Docker Skills"]
author: "Guillaume Lours"
showToc: true
TocOpen: false
hidemeta: false
comments: false
description: "The Docker Skills guides for Docker Agent: docker-agent-config for authoring agent.yaml, docker-agent-run for safety modes and sandbox isolation, and docker-agent-deploy for serving, sharing, and evaluating an agent."
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

An agent that only describes a plan instead of executing it isn't a model problem. It's usually missing the one tool it needs to act, and the fix is a single line in `agent.yaml`: `type: shell` or `type: todo`. That's the kind of symptom Docker Agent is built to catch. Docker Agent (the CLI is `docker agent`, built on the open-source `cagent` engine) lets you define an AI agent, its model, its instructions, the tools it can call, optionally a whole team of sub-agents delegating to each other, in a single YAML file instead of application code, then run, serve, or publish that file the same way you'd run, serve, or publish a container image. See the [Docker Agent documentation](https://docs.docker.com/ai/docker-agent/) for the full product picture. `docker-agent-config`, `docker-agent-run`, and `docker-agent-deploy`, the three skills this post covers, take that file from authoring through production.

This post groups all three, since they split the same lifecycle rather than three unrelated topics: `docker-agent-config` owns the `agent.yaml` file, `docker-agent-run` owns invoking it locally, and `docker-agent-deploy` owns exposing it to the outside world.

## What a generic agent.yaml gets wrong

The minimum viable config is one agent with a model, a description, and an instruction:

```yaml
agents:
  root:
    model: anthropic/claude-sonnet-4-5
    description: A coding assistant
    instruction: |
      You are an expert developer. Help users write clean,
      efficient code. Explain your reasoning step by step.
    toolsets:
      - type: filesystem
      - type: shell
      - type: think
```

Asked to wire up a provider, the obvious next line for a generic model is the API key, inline, in the YAML. `docker-agent-config` is explicit that this is wrong: never hardcode a key in `agent.yaml`, credentials come from environment variables or from `~/.config/cagent/.env`, written by `docker agent setup` rather than typed in by hand. The skill also has an opinion on which provider to reach for at all: prefer `dmr/<model>` (Docker Model Runner, local, no credential, no cost) for anything that must run offline or must not send data out, and save a paid cloud provider for when the task actually needs it, a judgment call a generic agent has no reason to make on its own.

`description` isn't decoration either: in a multi-agent team, other agents read it to decide whether to delegate to this one, so it has to be accurate rather than generic. Left to its own devices, a generic agent also rarely adds resilience unprompted: a `fallback` block is what keeps a run going through a provider outage or a rate limit instead of just stopping cold mid-task.

```yaml
agents:
  root:
    model: anthropic/claude-sonnet-4-5
    fallback:
      models: [openai/gpt-5, google/gemini-3.5-flash]
      retries: 2      # per model, for 5xx errors
      cooldown: 1m    # stick with fallback after a 429
```

Toolsets are where the skill corrects a different default instinct. Built-in toolsets cover a lot of ground with no external dependency at all: `filesystem`, `shell`, `think`, `todo`, `tasks`, `memory`, `fetch`, `background-jobs`, `script`, `lsp`, `api`. Asked for something outside that list, the fastest-looking answer for a generic model is a bespoke integration wired by hand; the skill's preference is an MCP server from Docker's own catalog instead, since it runs containerized and is reusable across agents rather than one-off code tied to this config. `defer: true` on a toolset loads its tools on demand instead of at startup, worth reaching for once an agent carries enough toolsets that startup latency actually shows up.

For multi-agent teams, a coordinator lists `sub_agents: [coder, reviewer]`, which automatically enables the `transfer_task` tool on the parent so it can delegate. The skill's own template, `assets/team-agent.yaml`, keeps the reviewer agent `readonly: true`; that restriction is worth keeping when adapting it, since a filesystem toolset alone would otherwise let a "review-only" agent write, the kind of gap a name alone doesn't prevent.

On the safety side, the one rule worth internalizing is `redact_secrets: true` on any agent that runs shell or fetch tools against untrusted input. It's explicitly defense in depth, not a guarantee: it scrubs recognized secret patterns, but arbitrary passwords or customer data can still slip through undetected. The skill also closes a leak a generic agent wouldn't think to check for: `${env.VAR}` interpolation in an `instruction` expands the value directly into the prompt text sent to the model, so a credential stored in an env file is still disclosed the moment a prompt references it.

## Running it without assuming more isolation than it gives

`docker agent run` exposes four `--safety` levels, and the skill is specific about which one to default to, not just what each one does: `strict` asks before every tool call, `balanced` auto-approves what it classifies as safe, `restricted` auto-approves the safe calls and denies the rest outright, and `autonomous` (same as `--yolo`) approves everything. Left unprompted, a generic agent has no reason to pick `restricted` over `autonomous` for an unattended run, cron, CI, a server endpoint, since both "work" in the demo; the skill is what rules `autonomous` out for exactly those cases, because `restricted` makes an unexpected tool call fail closed instead of running unreviewed.

```bash
# CI-safe: unreviewed tool calls are denied, not silently approved.
docker agent run --exec --safety restricted ./agent.yaml "Triage the failing test"
```

`--sandbox` runs the agent inside an isolated microVM managed by the `sbx` CLI, the same tool [Part 4](/posts/docker-skills-part-4-sandboxes-core/) covers directly, and the skill corrects two assumptions a reasonable person would make about it. First, it's tempting to assume the flag means total isolation; a local stdio MCP server declared on the agent still runs as a host process outside the sandbox, so it has to be treated as a trusted host integration, not a sandboxed one. Second, it's tempting to assume a fresh VM every run; sandboxes persist and are reused across runs from the same workspace instead, so a stale kit or leftover state from a prior run can carry forward silently unless the mount set changes to force recreation. The network proxy inside is default-deny, so a custom MCP server or third-party API usually needs an explicit allowlist entry, added once rather than rediscovered on every run:

```bash
docker agent sandbox allow api.example.com
```

For headless automation, `--worktree` isolates an agent's edits in a fresh git worktree, and the skill flags an asymmetry a generic agent would carry over from interactive use without checking: an interactive session auto-removes a clean worktree when it ends, but a headless `--exec` run never auto-cleans, regardless of state, so an agent scripting unattended runs needs its own cleanup step rather than assuming one happens automatically.

When a run reports "no model is currently available" or a credential seems missing, the skill's answer is `docker agent doctor ./agent.yaml` before touching the YAML at all: it reports the resolved model/provider and whether a usable credential was actually found, rather than guessing at a config fix for what might just be a missing export.

## Serving, sharing, and evaluating without the easy mistakes

`docker agent serve mcp` turns the same `agent.yaml` into an MCP server other tools can call, Claude Desktop among them. It defaults to stdio for local clients; `--http` switches to a network-reachable endpoint, and here the skill overrides the path of least resistance directly: binding any server flag to a non-loopback address without an auth token or key is refused outright, with `--insecure-no-auth` existing only as a deliberate, documented exception, never a default a generic agent should reach for just to get past an error. For `serve mcp` (over HTTP), `serve chat`, and `serve a2a`, Docker's own docs state `--safety` defaults to `restricted` when left unset, matching the unattended-run guidance above.

```bash
docker agent serve mcp ./agent.yaml --http --listen 127.0.0.1:9090 --auth-token "$TOKEN"
```

Distribution reuses the exact mental model of container images: `docker agent share push`/`pull` moves an `agent.yaml` through the same registry and `docker login` auth as an image. The part worth knowing before manually working around it: an `instruction_file` referenced from the config looks like a dependency a push would leave behind, but it gets inlined into the pushed artifact automatically, so a published agent is already self-contained without extra steps.

```bash
docker agent share push ./agent.yaml docker.io/username/my-agent:latest
docker agent share pull docker.io/username/my-agent:latest
```

For regression testing, `docker agent eval` scores an agent against recorded sessions on four dimensions: tool-call sequence, an LLM-judge relevance score, response-size bucket, and deterministic assertions. Left to a generic default, the LLM-judge relevance score is the path of least resistance, since it needs the least precision to set up; the skill's preference runs the other way, assertions whenever a check can be exact, since they need no judge model at all. Provider API keys forward into the eval's containers automatically, but a broader host credential doesn't follow the same rule and is easy to assume it would: `GITHUB_TOKEN`/`GH_TOKEN` is never forwarded automatically, since it's a host credential rather than a model key, so an eval for a `github-copilot`-backed agent needs it passed explicitly with `-e GITHUB_TOKEN`. The CI-shaped use case is `--baseline`:

```bash
docker agent eval ./agent.yaml --baseline results/2026-08-01-run.json --regression-tolerance 0.05
```

A previously-passing eval that now fails gates the build regardless of tolerance; cost changes get reported but never gate on their own, a distinction worth keeping a CI config from over-enforcing on.

## What's next

Part 6, the last post in this series, turns to `docker-destructive-guardrails`, the cross-product policy referenced throughout the Build, Compose, and now Agent posts, the one every other skill defers to before running an irreversible command.

## Further reading

- [Docker Agent documentation](https://docs.docker.com/ai/docker-agent/)
- [`docker/skills` on GitHub](https://github.com/docker/skills)
- Previous: [Docker Skills, Part 4: Sandbox Lifecycle, Network Policy, and Credentials](/posts/docker-skills-part-4-sandboxes-core/)
