---
title: "See you at Devoxx France 2026!"
date: 2026-04-20T09:00:00+02:00
draft: false
tags: ["devoxx", "conference", "speaking", "docker", "compose", "ai"]
categories: ["Events"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "I'll be giving three talks at Devoxx France 2026 covering Docker Sandboxes, Compose for AI, and a tiny LLM powered RPG"
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

This week, no Docker Compose tips, I'll be at [Devoxx France 2026](https://devoxx.fr/) at the Palais des Congrès in Paris, from April 22 to April 24. I'm lucky to be on stage three times, with topics ranging from AI agents to a text-based RPG powered by tiny language models, and as you'd expect, containers and Compose are part of the story.

Here's what I'll be talking about.

## Wednesday, April 22 — 17:50-18:20 (Tools-in-Action)

### Vos coding agents en mode YOLO... mais en toute sécurité

There's a term for what happens when you use AI coding agents heavily: **permission fatigue**. You end up clicking through approval prompts without really reading them. To work around this, tools now offer YOLO modes (`trust-all-tools`, `bypass permissions`...) that give agents full autonomy.

But that autonomy comes at a cost. Agents can then do *anything* on your dev machine. Many developers have lost work or had their local environment silently altered.

In this Tools-in-Action, I'll present **Docker Sandboxes**, a solution for running AI coding agents autonomously without compromising developer workstation security. By combining isolated VMs and containers, it lets agents act freely while protecting the host, controlling network access, and securing keys and credentials.

👉 [Session details](https://m.devoxx.com/events/devoxxfr2026/talks/77063/vos-coding-agents-en-mode-yolo-mais-en-toute-scurit)

## Thursday, April 23 — 13:30-16:30 (3H Deep Dive, with Philippe Charrière)

### Compose & Dragons: le jeu de rôle des agents nourris aux Tiny Language Models

Let's debunk some myths about tiny LLMs, the ones with fewer than 4 billion parameters. People often say they're useless, don't know anything, and are bad at function calling (so no MCP for them).

That's partly wrong, and we can do something about the rest.

Together with Philippe Charrière, we'll build a text-mode dungeon crawler RPG live on stage, using Docker's AI capabilities. The whole thing runs on very small models (like Jan-nano-gguf 4b, qwen2.5 1.5b, granite-embedding 278m for RAG...). You'll see how to create NPCs with personalities, a dungeon master managing moves, combat, and conversations, all powered by models you can run on your laptop.

Our game won't be Diablo, but you'll leave with recipes and tips to build your own lightweight AI agent systems.

👉 [Session details](https://m.devoxx.com/events/devoxxfr2026/talks/26815/compose-dragons-le-jeu-de-rle-des-agents-nourris-aux-tiny-language-models)

## Friday, April 24 — 11:35-12:20 (Conference, with Nicolas De Loof)

### Docker Compose, votre Dev Toolkit pour AI & Cloud

Docker Compose is an essential tool for orchestrating local development environments. In the AI era, it takes another step forward.

With Nicolas De Loof, we'll show how the latest Docker Compose features let you declaratively define LLM-based applications. On the menu, live:

- Defining an LLM in a Compose file with the `models` key
- Accessing those models from application containers
- Using provider services to prepare or connect external resources
- Offloading heavy workloads (GPU) remotely with Docker Offload
- Using a single Compose file to orchestrate code, models, and execution context

A concrete, fast-paced session for developers working on AI, agents, or modern multi-service architectures who want to see how Docker adapts to these new use cases.

👉 [Session details](https://m.devoxx.com/events/devoxxfr2026/talks/45204/docker-compose-votre-dev-toolkit-pour-ai-cloud)

## Come say hi!

If you're attending Devoxx France, come say hi between sessions or at one of these talks. Docker will also have a booth at the conference, and I'll be there quite often, so feel free to stop by for a chat. And if you're not coming this year, all sessions are recorded and will be available on the [Devoxx YouTube channel](https://www.youtube.com/@DevoxxFRvideos) afterwards.

Docker Compose tips will be back the following week. See you soon!
