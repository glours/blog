# Docker Compose Tips - Social Media Posts - September 2026

## Special publication — Tuesday, September 1, 2026

This deep dive is published outside the regular Docker Compose Tips schedule. It follows a current discussion about how credentials should move from a password manager into a Compose service, without targeting or naming another article.

### Compose secrets runtime delivery deep dive

**🦋 Bluesky:**
```
🐳 🐙 Compose secret sources do not behave alike.

`secrets.file` → bind mount
`secrets.environment` → writable layer
Swarm → in-memory mount

Same `/run/secrets` path, different persistence.

Deep dive: lours.me/posts/compose-secrets-deep-dive-runtime-delivery/

#Docker #Security
```

**💼 LinkedIn:**
```
🐳 🐙 Compose Secrets Deep Dive: Providers, Persistence, and the Last Mile

A recent post about keeping Docker Compose credentials out of plaintext files made me revisit a broader question: what are the best ways to move a secret into a Compose service, given the platform's current limitations?

The answer depends on the starting point. If Git must support an offline deployment or disaster recovery, keeping an encrypted copy there can provide a useful operational property. But when the credential already lives in a password manager that is reachable during deployment, creating another copy — even an encrypted one — also creates another access policy, key lifecycle, and rotation path. In that situation, the password manager should remain the source of truth.

The next question is the last mile: how does the value reach the application without ending up in a regular environment variable, a persistent host file, the container configuration, or an accidental image snapshot?

One assumption did not survive testing: a file under `/run/secrets/` is not necessarily backed by memory. Swarm secrets use an in-memory mount, but local Compose materializes an environment-sourced secret in the container's writable layer. It stays out of `Config.Env` and avoids a host source file, but `docker commit` captures it.

Other paths make different trade-offs:

• `environment:` and `env_file:` put the plaintext in the container configuration
• `secrets.file` uses a bind mount, so `docker commit` excludes its content
• rendering that source file under a host tmpfs avoids persistent host storage on Linux
• a runtime provider can resolve a reference without putting the value in the Compose model
• `_FILE` support keeps the value out of the application environment
• a small entrypoint wrapper remains the fallback when the application only accepts the value itself

The password manager should remain the source of truth. The last mile is about choosing where plaintext is allowed to exist, how long it remains there, and what survives a container snapshot or host restart.

Full deep dive: lours.me/posts/compose-secrets-deep-dive-runtime-delivery/

#Docker #DockerCompose #Security #DevOps #SecretsManagement
```

---

## Week 26: September 7-11, 2026 - What changed over the break

Resuming after the summer break with tips grounded in real Compose changes from v5.2.0 through v5.5.1, released while the series was paused.

### Monday, September 7 - pre_start hooks and native init containers (Tip #82)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #82

pre_start: native init containers for Compose. Runs once, in its own container, before the service starts.

A failing step stays around for inspection now.

Guide: lours.me/posts/compose-tip-082-pre-start-init-containers/

#Docker #Runtime
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #82: pre_start hooks and native init containers

post_start and pre_stop (Tip #41) run a command inside the already-running service container. pre_start is different: since Compose 5.3, each step runs in its own ephemeral container, created after the service container exists but before it starts.

```yaml
services:
  api:
    build: .
    depends_on:
      db:
        condition: service_healthy
    pre_start:
      - image: myapp-migrate
        command: ["./migrate.sh", "up"]
```

Key facts:
• Waits on depends_on first, so a step can reach those services
• Defaults to the service's own image, set image: for different tooling
• Runs once for the service, not once per replica
• A failing step keeps its container around, output tail included in the error, for docker logs / docker inspect
• Ctrl-C while a step is running kills and removes it instead, no leftovers

Full guide: lours.me/posts/compose-tip-082-pre-start-init-containers/

#Docker #DockerCompose #Runtime #Configuration #DevOps
```

---

### Wednesday, September 9 - Why up recreated containers that never changed (Tip #83)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #83

Ever had `up` recreate a container that never changed?

Compose used to digest images differently per pull, build, or bake. Fixed in 5.5.0: one canonical digest, every path.

Guide: lours.me/posts/compose-tip-083-image-digest-reconciliation/

#Docker #Build
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #83: Why up recreated containers that never changed

A service recreates on every single docker compose up. No file change, no rebuild, nothing actually different about the image. Before Compose 5.5.0, that wasn't a flaky environment, it was a real bug class.

Compose decides whether to recreate a container by comparing the image's current identity against a label it recorded last time, com.docker.compose.image. Before 5.5.0, that identity was computed differently depending on how the image got there: a pull, the classic builder, buildx bake, or a local inspect could each produce a different kind of digest for the exact same image.

Where it showed up:
• A locally built image with provenance attestations enabled got a digest that changed on every rebuild
• A platform-pinned service could get resolved against the host's platform instead of its own
• Pulling the same tag for different platforms concurrently could record whichever pull finished last
• A type: image volume's mount source could stop resolving entirely once that digest value changed shape

5.5.0 introduces one canonical digest producer used by every path, and a single function writing the label. If a service has been recreating for no visible reason, upgrading is the fix, not a Compose file change.

Full guide: lours.me/posts/compose-tip-083-image-digest-reconciliation/

#Docker #DockerCompose #Build #DevOps
```

---

### Friday, September 11 - Lifecycle hooks now show you why they failed (Tip #84)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #84

A failing post_start / pre_stop / pre_start hook used to report only:

db hook exited with status 1

Since Compose 5.5.1, its output travels with the error too.

Guide: lours.me/posts/compose-tip-084-lifecycle-hook-output/

#Docker #Debugging
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #84: Lifecycle hooks now show you why they failed

A failing lifecycle hook, post_start, pre_stop, or the new pre_start (Tip #82), used to report only its exit code. What it actually printed depended on how it ran: streamed live under a plain up but never carried into the error, or not attached at all under restart, run, or a library caller.

```yaml
services:
  api:
    build: .
    post_start:
      - command: ./migrate.sh
```

Since Compose 5.5.1, a failing hook's error reads like this instead:

db hook exited with status 1: SQLSTATE[42S02]: Base table or view not found

Key facts:
• Compose keeps the last 10 lines or 2 KiB of stdout and stderr, tracked separately
• The error prefers stderr, falls back to stdout
• Only on a non-zero exit, a passing hook is unchanged
• Captured whether or not a listener is attached

Gotcha: that output can carry secrets. A hook that prints a connection string or credential on failure now puts it in the error message too.

Full guide: lours.me/posts/compose-tip-084-lifecycle-hook-output/

#Docker #DockerCompose #Debugging #DevOps
```

---

## Week 27: September 14-18, 2026 - Mixed Themes

### Monday, September 14 - What docker compose alpha actually means (Tip #85)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #85

See what's incubating: docker compose alpha is where new commands land before going stable.

Right now: viz (dependency graphs) and generate (reverse a Compose file from running containers).

Guide: lours.me/posts/compose-tip-085-alpha-commands/

#Docker #CLI
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #85: What docker compose alpha actually means

Want a preview of what's incubating for Compose? docker compose alpha is where new commands land before they're stable, and right now two are worth a look:

• viz: reads a Compose file and prints a Graphviz graph of the service dependency graph, useful the moment depends_on stops being readable at a glance
• generate: points at already-running containers and writes back a Compose file, useful for adopting Compose on a stack that only ever existed as docker run commands

Both are getting their own dedicated deep-dive tip soon.

One caveat before you build anything on top of them: alpha commands can change or vanish between releases without warning, and that's not hypothetical. docker compose watch itself lived under alpha from January 2023 to January 2024 before it became the stable command it is today. docker compose publish made the same move, and its old alpha alias still runs. Read the --help output for what's current, not a blog post.

Full guide: lours.me/posts/compose-tip-085-alpha-commands/

#Docker #DockerCompose #CLI #DevOps
```

---

### Wednesday, September 16 - initial_sync just got a lot more trustworthy (Tip #86)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #86

Meet initial_sync, the watch attribute for catching up a running stack.

5.5.1: every file now syncs, Dockerfiles stay out, symlinks don't break it.

Guide: lours.me/posts/compose-tip-086-watch-sync-reliability/

#Docker #Development
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #86: initial_sync just got a lot more trustworthy

Tip #11 covered sync and rebuild. Meet the attribute it didn't cover: initial_sync, which re-syncs a path into containers that already exist, for when you reattach watch to a stack that's still running.

```yaml
services:
  web:
    build: .
    develop:
      watch:
        - path: ./src
          target: /app/src
          action: sync
          initial_sync: true
```

Compose 5.5.1 closes three ways it could still let you down:

• Every file now syncs, regardless of when it was last touched. The old mtime check skipped anything older than the image, which is backwards: source code checked out from git is almost always older than the image built from it, so the files initial_sync exists to catch up were exactly the ones it silently left behind.

• Dockerfile and compose files stay out of the container again, the way initial_sync's own doc comment always promised. A January 2025 refactor had quietly dropped the filter enforcing that.

• A sync into a path the container resolves through a symlink no longer aborts the whole batch. Compose retries a rejected copy without the directory headers its own file entries already imply, so the sync lands where it should.

Full guide: lours.me/posts/compose-tip-086-watch-sync-reliability/

#Docker #DockerCompose #Development #DevOps
```

---

### Friday, September 18 - The depends_on options tip #3 didn't cover (Tip #87)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #87

depends_on has more than service_healthy: wait for a one-shot with service_completed_successfully, cascade restarts with restart: true, or soften it with required: false.

Guide: lours.me/posts/compose-tip-087-advanced-depends-on/

#Docker #Configuration
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #87: The depends_on options tip #3 didn't cover

Tip #3 stopped at condition: service_healthy. The long-form depends_on syntax has three more fields, each solving a different problem:

```yaml
services:
  api:
    build: .
    depends_on:
      migrate:
        condition: service_completed_successfully
      cache:
        condition: service_started
        restart: true
      metrics:
        condition: service_started
        required: false
```

service_completed_successfully waits for a service to exit, and only starts the dependent if it exited zero. If migrate exits non-zero, api never starts, and the error names exactly which dependency failed.

restart: true is easy to misread as "restart me if the dependency container restarts." It doesn't. It only fires on an explicit docker compose restart: run docker compose restart cache, and every service that declared cache as a dependency with restart: true restarts right after it. A restart: always policy reviving cache on its own doesn't trigger anything here.

required: false changes what happens when Compose gives up, not whether it waits first. If the dependency has a container running, Compose polls its condition exactly like a required one. required only decides whether a failed or timed-out wait becomes a hard error or a warning, instead of blocking the dependent entirely.

Full guide: lours.me/posts/compose-tip-087-advanced-depends-on/

#Docker #DockerCompose #Configuration #DevOps
```

---

## Week 28: September 21-25, 2026 - Mixed Themes

### Monday, September 21 - Reversing a Compose file with docker compose alpha generate (Tip #88)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #88

docker compose alpha generate reverses a Compose file from running containers. Still alpha: skip a host IP on a published port and it writes host_ip: invalid IP.

A real bug, and an easy first PR.

Guide: lours.me/posts/compose-tip-088-alpha-generate/

#Docker #CLI
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #88: Reversing a Compose file with docker compose alpha generate

Tip #28 covered translating docker run flags to Compose by hand. docker compose alpha generate does the same job the other way: point it at a container that's already running and it inspects it, then writes back the Compose file.

```bash
docker compose alpha generate mycontainer --name myapp
```

It reads networks, volumes, and healthchecks the same way. Two things worth knowing before committing the output:

• Environment and labels include everything baked into the image, not just what you passed on the command line
• Publish a port without pinning a host IP and generate writes host_ip: invalid IP into the port entry instead of 0.0.0.0, traced to a zero-value netip.Addr in pkg/compose/generate.go, confirmed present in the released v5.5.1

generate and viz (Tip #90) are the only two commands under alpha right now: still being built, no deprecation notice required if something changes between releases. That also makes them one of the more approachable places to start reading Compose's own source, and to send a fix.

Full guide: lours.me/posts/compose-tip-088-alpha-generate/

#Docker #DockerCompose #CLI #OpenSource #DevOps
```

---

### Wednesday, September 23 - What cap_drop actually takes away from root (Tip #89)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #89

cap_drop: ALL doesn't just fence in non-root users, it takes CHOWN away from root (uid 0) too.

Gotcha: the classic "drop NET_RAW, ping breaks" demo often does nothing on modern hosts.

Guide: lours.me/posts/compose-tip-089-capability-dropping/

#Docker #Security
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #89: What cap_drop actually takes away from root

Tip #29 listed which cap_add values pair with which workload. Here's the part worth sitting with: what cap_drop: ALL removes even from a container running as root.

```yaml
services:
  hardened:
    image: alpine
    cap_drop:
      - ALL
    command: sh -c "touch /tmp/f && chown 2000:2000 /tmp/f && echo OK"
```

Run that from a uid 0 process and it fails: chown: /tmp/f: Operation not permitted. Add cap_add: [CHOWN] back and it succeeds. Capabilities aren't a non-root safeguard bolted on top of the UID check, they gate root's own privileges.

Gotcha for whoever reaches for the classic demo instead: dropping NET_RAW and expecting ping to fail doesn't prove much if net.ipv4.ping_group_range covers your container's group. 0 2147483647 is the wide-open default on several distros, including Docker Desktop's VM. Same story for NET_BIND_SERVICE and net.ipv4.ip_unprivileged_port_start. Check both sysctls before building a demo, a test, or a security argument on either capability. CAP_CHOWN has no such escape hatch.

Full guide: lours.me/posts/compose-tip-089-capability-dropping/

#Docker #DockerCompose #Security #DevOps
```

---

### Friday, September 25 - Seeing your service graph with docker compose alpha viz (Tip #90)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #90

docker compose alpha viz turns depends_on into a Graphviz graph. Pipe into dot -Tpng and any Compose file becomes a picture.

Still alpha since April 2023, no graduation date yet.

Guide: lours.me/posts/compose-tip-090-alpha-viz/

#Docker #CLI
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #90: Seeing your service graph with docker compose alpha viz

depends_on reads fine at two or three services. Past that, tracing who starts after whom means scrolling between blocks and holding the chain in your head. docker compose alpha viz reads the same file and prints the graph instead.

```bash
docker compose alpha viz --image --ports --networks
```

The output is plain DOT, the format Graphviz has read since long before Compose existed. With Graphviz installed, docker compose alpha viz | dot -Tpng -o graph.png turns any Compose file into a picture in one line. Because it reads the same depends_on graph Compose itself uses to decide startup order, the picture can't drift from the actual behavior the way a hand-maintained diagram would.

viz is the other command living under alpha alongside generate (Tip #88), and the same caveat applies: flag names and output can change release to release, no deprecation notice required. viz first landed in April 2023, generate in October 2024. Unlike watch, which spent a year under alpha before graduating, neither has moved yet, alpha status describes stability guarantees, not how long a command has been around.

Full guide: lours.me/posts/compose-tip-090-alpha-viz/

#Docker #DockerCompose #CLI #DevOps
```

---

## Special publication — Friday, September 25, 2026

Published alongside Tip #90, outside the regular tip slot. Announces the `docker/skills` open-source release and the two-week Docker Skills deep dive series starting Monday (no blog post exists yet to link to, so this points to the GitHub repo and docs instead).

### Docker Skills open-source announcement

**🦋 Bluesky:**
```
🐳 🐙 Docker open-sourced docker/skills (v0.3.0): SKILL.md guides teaching AI agents pinned tags, health checks, non-root images, no baked-in credentials.

11 skills, 4 product families.

Deep dive series starts Monday.

Repo: github.com/docker/skills
Docs: docs.docker.com/ai/skills/

#Docker #AI
```

**💼 LinkedIn:**
```
🐳 🐙 docker/skills is now open source

I'm happy to share a project I've worked on recently: docker/skills, which Docker open-sourced this week (v0.3.0). I initiated it and remain one of its contributors.

It's a set of SKILL.md guides that teach AI coding agents the Docker-specific rules a generic model has no reliable way to pull into a prompt on its own: pinned image tags, health checks that actually verify readiness, non-root users, and credentials that never touch an image layer.

The repository ships 11 skills across 4 product families:

• Dockerfile & Build: docker-project-foundations, docker-build-strategies
• Docker Compose: docker-compose-patterns
• Docker Sandboxes: docker-sandboxes-lifecycle, docker-sandboxes-network-credentials, plus two experimental skills
• Docker Agent: docker-agent-config, docker-agent-run, docker-agent-deploy

Plus one cross-product skill, docker-destructive-guardrails, that every other skill defers to before running an irreversible command.

Each skill is a SKILL.md file following the Agent Skills specification: no entry point to load first, an agent scans every installed skill's description and pulls in whichever one matches the task at hand. Supported today: Claude Code, OpenAI Codex, Cursor, GitHub Copilot CLI, Gemini CLI, Google Antigravity, and OpenCode, plus a dedicated experimental installer for Docker Sandboxes' sbx CLI.

Install with the cross-client skills CLI:

npx skills add docker/skills

Starting Monday, this blog runs a two-week deep dive series covering each product family in detail, sidecars for healthchecks on distroless images, BuildKit secret mounts, sandbox isolation, and more. First post: what's in the repo, which agents it supports, and how to install it.

Repo: github.com/docker/skills
Docs: docs.docker.com/ai/skills/

#Docker #DockerCompose #AI #AIAgents #OpenSource #DevOps
```

---

## Week 29: September 28 - October 2, 2026 - Docker Skills Deep Dive, Part 1/2

No tips this week. Three-part series on the `docker/skills` repo, one post per product family covered.

### Monday, September 28 - What Docker Skills is, who it's for, how to install it (Part 1)

**🦋 Bluesky:**
```
🐳 🐙 Docker Skills, Part 1

AI agents write mediocre Dockerfiles: latest tags, no health checks, root left in place. docker/skills fixes that: 11 SKILL.md guides across Build, Compose, Sandboxes, Agent.

npx skills add docker/skills

lours.me/posts/docker-skills-part-1-overview/

#Docker #AI
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Skills, Part 1: What It Is, Who It's For, How to Install It

AI coding agents write a lot of Dockerfiles and Compose files these days, and most of them are mediocre: latest tags, missing health checks, credentials baked into layers, root users left in place. docker/skills, open-sourced this week, gives a compatible agent the missing context: SKILL.md guides it loads automatically based on the task at hand, no entry point skill required.

11 skills across 4 product families:

• Dockerfile & Build: docker-project-foundations, docker-build-strategies
• Docker Compose: docker-compose-patterns
• Docker Sandboxes: docker-sandboxes-lifecycle, docker-sandboxes-network-credentials, plus two experimental skills
• Docker Agent: docker-agent-config, docker-agent-run, docker-agent-deploy

Plus docker-destructive-guardrails, the cross-product policy every other skill defers to before an irreversible command.

Supported today: Claude Code, OpenAI Codex, Cursor, GitHub Copilot CLI, Gemini CLI, Google Antigravity, OpenCode, plus a dedicated sbx CLI installer for Docker Sandboxes.

npx skills add docker/skills

Part 1 of a series going deep on each product family. Part 2 (Wednesday) covers Dockerfile builds and project scaffolding.

Full guide: lours.me/posts/docker-skills-part-1-overview/

#Docker #DockerCompose #AI #AIAgents #OpenSource #DevOps
```

---

### Wednesday, September 30 - docker-build-strategies and docker-project-foundations (Part 2)

**🦋 Bluesky:**
```
🐳 🐙 Docker Skills, Part 2

Credentials passed through ARG end up in docker history. docker-build-strategies + docker-project-foundations fix that: BuildKit secrets, non-root images, project scaffolding.

lours.me/posts/docker-skills-part-2-build-and-foundations/

#Docker #Security
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Skills, Part 2: docker-build-strategies and docker-project-foundations

A registry token passed through ARG or ENV never shows up in docker run. It's still sitting in the image's layer history, one docker history away from anyone who pulls it. That's the exact mistake docker-build-strategies is written to intercept.

```dockerfile
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc,required=false \
    npm ci --omit=dev
```

The secret is available only inside that RUN step, never written to a layer. The skill also covers:

• Multi-stage builds: explicit stage names, COPY --from=build, COPY --link for cache reuse
• Layer ordering: dependency manifests before source code, BuildKit cache mounts per package manager
• Non-root users, down to a specific gotcha: --chown with COPY --link needs the numeric UID:GID, not a named user

docker-project-foundations covers the earlier case, no Docker setup at all: always scaffold .dockerignore, Dockerfile, and compose.yaml together, and always define a database or cache as a Compose service instead of a host install.

Part 3 (Friday) moves to Docker Compose service wiring.

Full guide: lours.me/posts/docker-skills-part-2-build-and-foundations/

#Docker #DockerCompose #Security #AI #DevOps
```

---

### Friday, October 2 - docker-compose-patterns in depth (Part 3)

**🦋 Bluesky:**
```
🐳 🐙 Docker Skills, Part 3

depends_on only guarantees a container started, not that it's ready. docker-compose-patterns fixes that with service_healthy, plus a sidecar pattern for images with no shell.

lours.me/posts/docker-skills-part-3-compose-patterns/

#Docker #DockerCompose
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Skills, Part 3: docker-compose-patterns in Depth

depends_on only guarantees a container has started, not that whatever it's serving is ready. docker-compose-patterns closes that gap with condition: service_healthy, paired with a healthcheck.

For distroless or hardened images with no shell, no curl, the skill's answer is a sidecar:

```yaml
api-health:
  image: curlimages/curl:8
  network_mode: "service:api"
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
```

Also in the skill:

• Naming and file conventions: compose.yaml, lowercase role-based service names, pinned image tags
• Compose Watch mapped to action types: sync for source, rebuild for dependency manifests, sync+restart for config files
• Destructive-command guardrails: docker compose down -v and rm -v need explicit confirmation before running, never as a side effect of "just cleaning up"

This closes the Build and Compose half of the Docker Skills series. Week 2 goes into Docker Sandboxes and Docker Agent.

Full guide: lours.me/posts/docker-skills-part-3-compose-patterns/

#Docker #DockerCompose #AI #DevOps
```
