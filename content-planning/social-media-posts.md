# Docker Compose Tips - Social Media Posts - April 2026

## Week 13: March 30 - April 3, 2026

### Monday, Mar 30 - Build args vs environment variables (Tip #46)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #46

Build args vs env vars — different times, different jobs!

build.args → build time only (ARG)
environment → runtime only (ENV)

Don't mix them up! And never put secrets in build args.

Guide: lours.me/posts/compose-tip-046-build-args-vs-env/

#Docker #Build #Configuration
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #46: Build args vs environment variables

Two ways to pass values — but they work at completely different times!

```yaml
services:
  app:
    build:
      args:
        NODE_VERSION: "20"    # Build time only
    environment:
      DATABASE_URL: postgres://db/myapp  # Runtime only
```

Key differences:
• Build args → available during docker build (ARG in Dockerfile)
• Environment → available in running container (ENV)
• Build args are visible in image history — never use for secrets!
• Need both? Use ARG + ENV in your Dockerfile

Know when to use which: lours.me/posts/compose-tip-046-build-args-vs-env/

#Docker #DockerCompose #Build #Configuration #DevOps
```

---

### Wednesday, Apr 1 - Sidecar container patterns (Tip #47)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #47

Sidecars with Compose-native features!

network_mode: service:app  # Share network
volumes_from: app:ro       # Share volumes

TLS proxy, log forwarding, pod-like patterns.

Guide: lours.me/posts/compose-tip-047-sidecar-patterns/

#Docker #Architecture #Patterns
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #47: Sidecar container patterns

Add capabilities without modifying your application — using Compose-native features!

```yaml
services:
  app:
    image: myapp

  proxy:
    image: nginx
    network_mode: service:app  # Shared network namespace
    volumes_from:
      - app:ro                 # Access app's volumes
```

Key Compose sidecar features:
• network_mode: service:<name> — share localhost with another container
• volumes_from — mount all volumes from another service
• Combine both for Kubernetes pod-like patterns
• depends_on with healthcheck for startup ordering

Full patterns: lours.me/posts/compose-tip-047-sidecar-patterns/

#Docker #DockerCompose #Architecture #Patterns #DevOps
```

---

### Friday, Apr 3 - Network debugging with docker compose port (Tip #48)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #48

Which host port maps to your container?

docker compose port web 80
→ 0.0.0.0:8080

Works with scaled services too — use --index!

Guide: lours.me/posts/compose-tip-048-network-debugging-port/

#Docker #Debugging #Networking
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #48: Network debugging with docker compose port

Find out exactly which host port maps to a container port!

```bash
docker compose port web 80
# → 0.0.0.0:8080

# With scaled services
docker compose up -d --scale web=3
docker compose port --index=1 web 80
docker compose port --index=2 web 80
```

Especially useful when:
• Using dynamic port mapping (ports: ["80"])
• Running scaled services with --index
• Querying UDP ports with --protocol

Quick overview of all mappings:
docker compose ps --format "table {{.Name}}\t{{.Ports}}"

Full guide: lours.me/posts/compose-tip-048-network-debugging-port/

#Docker #DockerCompose #Debugging #Networking #DevOps
```

---

## Week 14: April 6-10, 2026

### Monday, Apr 6 - Mixed platforms with Linux and Wasm (Tip #49)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #49

Mix Linux containers and Wasm in one stack!

platform: wasi/wasm
runtime: io.containerd.wasmtime.v1

nginx + Wasm API + Postgres — all in one Compose file.

Guide: lours.me/posts/compose-tip-049-mixed-platforms-wasm/

#Docker #Wasm #Advanced
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #49: Mixed platforms with Linux containers and Wasm

Run Linux containers and WebAssembly modules side by side!

```yaml
services:
  nginx:
    image: nginx
    ports: ["80:80"]

  api:
    image: wasmedge/example-wasi-http
    runtime: io.containerd.wasmedge.v1

  postgres:
    image: postgres:16
```

Why mix platforms?
• Wasm: millisecond cold starts, tiny images, sandboxed by default
• Linux: databases, proxies, and mature tooling
• Compose orchestrates both seamlessly

The best of both worlds: lours.me/posts/compose-tip-049-mixed-platforms-wasm/

#Docker #DockerCompose #Wasm #WebAssembly #CloudNative
```

---

### Wednesday, Apr 8 - GPU support (Tip #50)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #50

GPU access in Compose!

deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]

ML training, inference, video processing.

Guide: lours.me/posts/compose-tip-050-gpu-support/

#Docker #GPU #MachineLearning
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #50: GPU support with deploy.resources

Reserve GPUs for ML, AI, and compute workloads!

```yaml
services:
  training:
    image: pytorch/pytorch
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 2
              capabilities: [gpu]

  api:
    image: nginx  # No GPU needed
```

Features:
• Reserve all GPUs or a specific count
• Target specific GPUs by device ID
• Combine GPU and memory limits
• Only GPU-hungry services get GPUs

Full ML stack example: lours.me/posts/compose-tip-050-gpu-support/

#Docker #DockerCompose #GPU #MachineLearning #AI
```

---

### Friday, Apr 10 - docker compose up --wait (Tip #51)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #51

Stop using sleep in your CI scripts!

docker compose up --wait --wait-timeout 60
npm test

Blocks until all services are healthy.

Guide: lours.me/posts/compose-tip-051-up-wait/

#Docker #CICD #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #51: docker compose up --wait for scripting and CI

No more fragile sleep-based scripts!

```bash
# Before: fragile
docker compose up -d
sleep 10
npm test

# After: reliable
docker compose up --wait --wait-timeout 60
npm test
```

How it works:
• Starts services in detached mode
• Blocks until all healthchecks pass
• Exits non-zero if a service fails to become healthy
• --wait-timeout prevents infinite hangs in CI

Requires healthchecks on your services to work properly!

Reliable CI pipelines: lours.me/posts/compose-tip-051-up-wait/

#Docker #DockerCompose #CICD #Testing #DevOps
```

---

## Week 15: April 13-17, 2026

### Monday, Apr 13 - CI test environment with Compose (Tip #52)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #52

Dedicated CI test environment with Compose!

compose.ci.yml override:
- Seeded database
- Test runner service
- Clean teardown with --volumes

docker compose -f compose.yml -f compose.ci.yml up --exit-code-from tests

Guide: lours.me/posts/compose-tip-052-ci-test-environment/

#Docker #CICD #Testing
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #52: Setting up a CI test environment

Your dev Compose file isn't your CI Compose file!

```bash
docker compose -f compose.yml -f compose.ci.yml up \
  --build --exit-code-from tests

docker compose down --volumes
```

The CI override adds:
• Database seeded with test fixtures via init scripts
• Test runner service with depends_on healthchecks
• No persistent volumes — fresh state every run
• Frontend disabled via profiles when not needed

Real example using dockersamples/sbx-quickstart!

Full setup: lours.me/posts/compose-tip-052-ci-test-environment/

#Docker #DockerCompose #CICD #Testing #DevOps
```

---

### Wednesday, Apr 15 - Project name and working directory (Tip #53)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #53

Control your project name!

name: myapp-${ENV:-dev}

Avoid conflicts, run multiple instances, keep things clean.

docker compose ls  # See all projects

Guide: lours.me/posts/compose-tip-053-project-name-workdir/

#Docker #Configuration #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #53: Compose project name and working directory

Every Compose stack gets a project name — it prefixes all your resources.

```yaml
name: myapp-${ENV:-dev}
services:
  web:
    image: nginx
```

Three ways to set it (in order of precedence):
• -p flag: docker compose -p myproject up
• Environment: COMPOSE_PROJECT_NAME=myproject
• In the file: name: myproject (recommended)

Use cases:
• Run staging and production side by side
• Isolate parallel CI runs with -p "ci-${BUILD_ID}"
• Consistent naming across the team

List all projects: docker compose ls

Full guide: lours.me/posts/compose-tip-053-project-name-workdir/

#Docker #DockerCompose #Configuration #DevOps #BestPractices
```

---

### Friday, Apr 17 - Preview changes with --dry-run (Tip #54)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #54

Not sure what will happen?

docker compose up --dry-run

See the plan before executing. Works with up, down, rm, pull, restart.

No surprises!

Guide: lours.me/posts/compose-tip-054-dry-run/

#Docker #Debugging #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #54: Preview changes with --dry-run

See what Compose will do before it does it!

```bash
docker compose up -d --dry-run
```

```
DRY-RUN MODE - Container myapp-db-1  Running
DRY-RUN MODE - Container myapp-web-1 Recreating
DRY-RUN MODE - Container myapp-web-1 Recreated
```

Works with many commands:
• docker compose down --dry-run
• docker compose rm --dry-run
• docker compose pull --dry-run

Perfect for:
• Checking what changed after editing compose.yml
• Validating override files before applying
• Safe exploration in unfamiliar environments

Full guide: lours.me/posts/compose-tip-054-dry-run/

#Docker #DockerCompose #Debugging #BestPractices #DevOps
```

---

## Week 16: April 20-24, 2026 - NO TIPS (Devoxx France)

### Monday, Apr 20 - Devoxx France announcement

**🦋 Bluesky:**
```
🐳 🐙 No Compose tips this week — I'm at Devoxx France! (Apr 22-24)

3 talks to catch me on stage:
🔐 Wed 17:50 - YOLO coding agents, safely
🐉 Thu 13:30 - Compose & Dragons (Tiny LLMs RPG)
🤖 Fri 11:35 - Compose for AI & Cloud

Full details: lours.me/posts/devoxx-france-2026/

#DevoxxFR #Docker
```

**💼 LinkedIn:**
```
🐳 🐙 No Docker Compose tips this week — I'm at Devoxx France 2026!

If you're attending April 22-24 at the Palais des Congrès in Paris, catch me on stage for 3 sessions:

🔐 Wednesday, April 22 — 17:50-18:20 (Tools-in-Action)
"Vos coding agents en mode YOLO... mais en toute sécurité"
Docker Sandboxes: running AI coding agents autonomously without compromising your dev machine.

🐉 Thursday, April 23 — 13:30-16:30 (3H Deep Dive, with Philippe Charrière)
"Compose & Dragons: le jeu de rôle des agents nourris aux Tiny Language Models"
Building a text-based dungeon crawler RPG powered by very small LLMs (<4B params).

🤖 Friday, April 24 — 11:35-12:20 (Conference, with Nicolas De Loof)
"Docker Compose, votre Dev Toolkit pour AI & Cloud"
New Compose features for LLM-based apps: models section, provider services, and Docker Offload for GPU workloads.

Full abstracts and session links: lours.me/posts/devoxx-france-2026/

Come say hi! Tips will be back the week after.

#DevoxxFR #Docker #DockerCompose #AI
```

---

## Week 17: April 27 - May 1, 2026

### Monday, Apr 27 - docker compose config advanced usage (Tip #55)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #55

docker compose config is more than validation!

--services  # List all services
--hash='*'  # Detect config changes
--resolve-image-digests  # Pin images
--format json  # Pipe to jq

Guide: lours.me/posts/compose-tip-055-config-advanced/

#Docker #Debugging #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #55: docker compose config advanced usage

Most people use it for validation. It does much more!

```bash
# List resources
docker compose config --services
docker compose config --volumes
docker compose config --profiles

# Change detection for CI caching
docker compose config --hash='*'

# Pin image digests for production
docker compose config --resolve-image-digests > compose.resolved.yml

# JSON for jq
docker compose config --format json | jq '.services.web.environment'
```

Useful for:
• Scripting — loop over services
• CI caching — detect config changes with hashes
• Reproducible deploys — pin image digests
• Debugging — see raw vs interpolated config

Full guide: lours.me/posts/compose-tip-055-config-advanced/

#Docker #DockerCompose #Debugging #DevOps #BestPractices
```

---

### Wednesday, Apr 29 - env_file advanced patterns (Tip #56)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #56

env_file has more than you think!

env_file:
  - .env.common
  - path: .env.local
    required: false

Multiple files, optional loading, interpolation.

Guide: lours.me/posts/compose-tip-056-env-file-advanced/

#Docker #Configuration #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #56: env_file advanced patterns

A single .env file is just the start!

```yaml
services:
  app:
    env_file:
      - .env.common               # Shared defaults
      - .env.${ENV:-dev}          # Environment-specific
      - path: .env.local          # Optional local tweaks
        required: false
    environment:
      LOG_LEVEL: debug            # This wins over env_file
```

Key patterns:
• Multiple files — later overrides earlier
• required: false — optional files don't break Compose
• Interpolation — use ${VAR} from host/.env inside env files
• environment > env_file — direct env vars always win

Perfect for multi-environment setups with shared defaults and local overrides.

Full guide: lours.me/posts/compose-tip-056-env-file-advanced/

#Docker #DockerCompose #Configuration #BestPractices #DevOps
```

---

### Friday, May 1 - Container resource monitoring (Tip #57)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #57

Something feels slow?

docker compose top    # Processes per service
docker compose stats  # Live CPU/memory/IO

Auto-scoped to your current project. Quick debugging for resource issues.

Guide: lours.me/posts/compose-tip-057-resource-monitoring/

#Docker #Debugging #Monitoring
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #57: Container resource monitoring

When your stack feels slow, these two commands tell you why!

```bash
# What's running inside each service?
docker compose top

# Live CPU, memory, network, disk I/O (scoped to your project)
docker compose stats

# Snapshot with custom columns
docker compose stats --no-stream \
  --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemPerc}}"
```

Quick debugging workflow:
1. docker compose ps — what's running
2. docker compose stats --no-stream — resource usage snapshot
3. docker compose top <service> — processes in the hot service
4. docker compose events --since 5m — recent restarts/OOMs

Bonus: docker compose stats is auto-scoped to your project, no manual filtering needed.

Full guide: lours.me/posts/compose-tip-057-resource-monitoring/

#Docker #DockerCompose #Debugging #Monitoring #DevOps
```
