---
title: "Docker Compose Tip #90: Seeing your service graph with docker compose alpha viz"
date: 2026-09-25T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "cli", "debugging", "beginner"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "docker compose alpha viz turns depends_on chains into a Graphviz graph, useful the moment a stack outgrows what you can trace by reading the file."
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

`depends_on` reads fine when a Compose file has two or three services. Past that, tracing who starts after whom means scrolling between blocks and holding the chain in your head. `docker compose alpha viz` reads the same file and prints the graph instead.

```bash
docker compose alpha viz
```

## What it prints

Against a two-service file (`web` depending on `db`), the default output is a minimal Graphviz digraph:

```
digraph "myapp" {
	layout=dot;
	"db" [style="filled" label=<<font point-size="15">db</font>>];
	"web" [style="filled" label=<<font point-size="15">web</font>>];

	"web" -> "db";
}
```

Add `--image`, `--ports`, and `--networks` and each node's label grows to match:

```
"web" [style="filled" label=<<font point-size="15">web</font><font point-size="10"><br/><br/><b>Networks:</b><br/>backend<br/>frontend</font><font point-size="10"><br/><br/><b>Ports:</b><br/>8080:80 (tcp, ingress)</font><font point-size="10"><br/><br/><b>Image:</b><br/>nginx:alpine</font>>];
```

Piped through `dot -Tpng`, that same output renders as:

![Graphviz render of a two-service Compose file, web depending on db, each node annotated with its networks, ports, and image](/images/tip-090-viz-graph.png)

`--spaces` swaps the default tab indentation for spaces, and `--indentation-size` sets how many, which matters if you're diffing the output in version control rather than just reading it once.

## Why it matters

The output is plain [DOT](https://graphviz.org/doc/info/lang.html), the input format Graphviz has read since long before Compose existed. With Graphviz installed, `docker compose alpha viz | dot -Tpng -o graph.png` turns any Compose file into a picture in one line, no need to hand-draw the dependency chain to explain a stack in a review or an onboarding doc. It reads the same `depends_on` graph Compose itself uses to decide startup order, so the picture and the actual behavior can't drift apart the way a hand-maintained diagram would.

## Pro tip: alpha doesn't come with a graduation timer

`viz` is the other command living under `docker compose alpha` alongside [`generate`](/posts/compose-tip-088-alpha-generate/), and the same rules from [Tip #85](/posts/compose-tip-085-alpha-commands/) apply: flag names and output format can change release to release, with no deprecation notice. `viz` first landed in April 2023, `generate` in October 2024. Unlike `watch`, which spent a year under `alpha` before graduating, neither has moved yet. Alpha status describes stability guarantees, not how long a command has been around.

If you're the kind of reader who read [Tip #88](/posts/compose-tip-088-alpha-generate/) and went looking through `pkg/compose/` in the Compose source, `viz`'s implementation is a short, self-contained file, a good second one to read after `generate`'s.

## Further reading

- [DOT language reference](https://graphviz.org/doc/info/lang.html)
- Related: [Tip #85, What docker compose alpha actually means](/posts/compose-tip-085-alpha-commands/)
- Related: [Tip #88, Reversing a Compose file with docker compose alpha generate](/posts/compose-tip-088-alpha-generate/)
