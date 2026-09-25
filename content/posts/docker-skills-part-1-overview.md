---
title: "Docker Skills, Part 1: What It Is, Who It's For, How to Install It"
date: 2026-09-28T09:00:00+02:00
draft: false
tags: ["docker-skills", "ai-agents", "claude-code", "docker", "introduction"]
categories: ["Docker Skills"]
author: "Guillaume Lours"
showToc: true
TocOpen: false
hidemeta: false
comments: false
description: "Docker open-sourced docker/skills this week: a set of SKILL.md guides that teach AI coding agents how to write Dockerfiles, Compose files, sandboxes, and agent configs the Docker way. What's in it, which agents support it, and how to install it."
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

AI coding agents write a lot of Dockerfiles and Compose files these days, and most of them are mediocre: `latest` tags, missing health checks, credentials baked into layers, root users left in place. Not because the models don't know better in the abstract, but because "Docker best practice" is scattered across docs, blog posts, and tribal knowledge, and a generic coding agent has no reliable way to pull the right piece of it into a given prompt. This week Docker open-sourced [`docker/skills`](https://github.com/docker/skills), a small collection of files meant to fix exactly that. This is the first post in a series that walks through what's in it; today is the overview, later posts go deep on each product family.

## What a "skill" actually is

Docker Skills follows the [Agent Skills specification](https://agentskills.io/specification): a skill is a directory containing a `SKILL.md` file, plus optional `references/`, `assets/`, `scripts/`, and `checks/` subdirectories. The `SKILL.md` frontmatter carries a `name` and a `description`, and that description is the whole activation mechanism. There's no manifest to load first, no "entry point" skill: a compatible agent scans the descriptions of every installed skill and pulls in the ones whose description matches the current task.

That means the descriptions are written defensively, to catch a request even when it doesn't name Docker at all. The `docker-project-foundations` skill, for instance, activates on "a user asks how to run or develop a project locally and Docker is available", not just on "Dockerize this". Once a skill is loaded, its `SKILL.md` gives the agent the actual rules: what to always do, what to never do, and links to reference files and starter assets it can pull in for more detail.

## Eleven skills, four product families

The repository groups skills by the Docker product they cover, plus one cross-product skill:

| Product | Skills |
|---|---|
| **Dockerfile & Build** | `docker-project-foundations`, `docker-build-strategies` |
| **Docker Compose** | `docker-compose-patterns` |
| **Docker Sandboxes** | `docker-sandboxes-lifecycle`, `docker-sandboxes-network-credentials`, `docker-sandboxes-env` *(experimental)*, `docker-sandboxes-kits` *(experimental)* |
| **Docker Agent** | `docker-agent-config`, `docker-agent-run`, `docker-agent-deploy` |
| **Cross-Product** | `docker-destructive-guardrails` |

Two skills are marked experimental (`docker-sandboxes-env`, `docker-sandboxes-kits`): their schemas may still change, so treat their guidance as more likely to shift between releases than the other eight.

An agent isn't limited to one skill per task. The README spells out a loading order for tasks that span several: `docker-project-foundations` before `docker-build-strategies` or `docker-compose-patterns` on a project with no Docker setup yet, `docker-build-strategies` before `docker-compose-patterns` when both a `Dockerfile` and a `compose.yaml` change, and similar orderings for the Sandboxes and Agent skills. `docker-destructive-guardrails` sits outside that chain: it's the policy every other skill defers to whenever a task could end in an irreversible command, and it also indexes the destructive-command guidance that lives inside the Compose and Sandboxes skills rather than duplicating it.

## Which agents can use it

The repository targets any agent that implements the Agent Skills specification for discovery. As of this release that includes Claude Code, OpenAI Codex, Cursor, GitHub Copilot CLI, Gemini CLI, Google Antigravity, and OpenCode. Docker Sandboxes' `sbx` CLI has its own experimental installer into a shared sandbox skill store, and Docker Agent (`cagent`) consumes skills installed in the paths its config already looks at rather than shipping a dedicated installer.

## Installing it

The cross-client path is the [`skills` CLI](https://skills.sh), which reads a product-grouped index (`skills.sh.json`) generated from the repo's catalog:

```bash
# Browse what's available without installing anything
npx skills add docker/skills --list

# Install one skill, no prompts (project scope; add -g for user scope)
npx skills add docker/skills --skill docker-compose-patterns --yes

# Install everything into every agent the CLI detects
npx skills add docker/skills --all
```

Claude Code, Copilot CLI, and Codex also expose native plugin marketplaces:

```text
/plugin marketplace add docker/skills
/plugin install docker-skills@docker
```

Gemini CLI installs it as a repository-backed extension (`gemini extensions install https://github.com/docker/skills`), and Docker Sandboxes has its own experimental command (`sbx skills add docker/skills`). For a reviewed, pinned snapshot instead of the rolling `main` branch, clone a tagged release and copy the skill directories you want into the agent's skill path directly; there's no managed updater for that path, so updating means replacing the folder.

## Skills guide, they don't replace review

Worth repeating from the project's own guidance: these files change what an agent proposes, not whether you should check it. A skill can steer an agent toward pinned image tags and non-root users; it can't verify that the resulting Dockerfile actually builds a smaller image, or that a generated `healthcheck` matches the service that's really running. Review the diff the same way you would without a skill installed.

## What's next

Part 2 covers `docker-build-strategies` and `docker-project-foundations` together, including the BuildKit secret-mount rules for keeping registry credentials out of image layers. Part 3 goes into `docker-compose-patterns`: health-check sidecars for distroless images, the destructive-command guardrails baked into the skill, and the reasoning behind its `depends_on` rules.

## Further reading

- [Docker Skills documentation](https://docs.docker.com/ai/skills/)
- [`docker/skills` on GitHub](https://github.com/docker/skills)
- [Installation guide](https://docs.docker.com/ai/skills/install/)
- Next: [Docker Skills, Part 2: docker-build-strategies and docker-project-foundations](/posts/docker-skills-part-2-build-and-foundations/)
