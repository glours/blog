# Docker Compose Tips - Social Media Posts - June 2026

## Week 22: June 1-5, 2026 — Compose Bridge Deep Dive

This week is a 3-part deep dive on Compose Bridge instead of standalone tips. The series shares the same numbering continuity (#70, #71, #72) so the counter stays consistent.

### Monday, June 1 - Compose Bridge intro (#70, Part 1)

**🦋 Bluesky:**
```
🐳 🐙 Compose Bridge Deep Dive — Part 1

Turn a Compose file into Kubernetes manifests.

docker compose bridge convert
kubectl apply -k out/overlays/desktop/

Same source of truth, dev to prod. Transformer images do the work.

Guide: lours.me/posts/compose-bridge-deep-dive-070-introduction/

#Docker #Kubernetes
```

**💼 LinkedIn:**
```
🐳 🐙 Compose Bridge Deep Dive — Part 1: From Compose to Kubernetes

Local dev with Compose, production on Kubernetes. Two YAML trees describing the same application is where drift, bugs, and "works on my laptop" stories come from. Compose Bridge keeps Compose as the single source of truth and generates the deployable artefact for you.

```bash
docker compose bridge convert
kubectl apply -k out/overlays/desktop/
```

How it works:
• A transformer image reads /in/compose.yaml and writes /out/
• Default: docker/compose-bridge-kubernetes (Kustomize-style base + overlays)
• Alternative: docker/compose-bridge-helm (Helm chart)
• Compose constructs map cleanly: services → Deployment + Service, configs → ConfigMap, healthcheck → probes, volumes → PVC

This is the first post of a three-part deep dive. Parts 2 and 3 cover custom transformers for enterprise rules, and shipping a Docker Model Runner application to Kubernetes.

Full guide: lours.me/posts/compose-bridge-deep-dive-070-introduction/

#Docker #DockerCompose #Kubernetes #DevOps #Platform
```

---

### Wednesday, June 3 - Custom transformers & x-* extensions (#71, Part 2)

**🦋 Bluesky:**
```
🐳 🐙 Compose Bridge Deep Dive — Part 2

Bake your enterprise rules into the conversion!

docker compose bridge transformations create \
    --from docker/compose-bridge-kubernetes my-template

Then use x-* fields in the Compose file to drive your templates. No more copy-paste manifests.

Guide: lours.me/posts/compose-bridge-deep-dive-071-custom-transformers/

#Docker #Kubernetes #Platform
```

**💼 LinkedIn:**
```
🐳 🐙 Compose Bridge Deep Dive — Part 2: Custom transformers and x-* extensions

Default transformers cover the common cases. Real organisations have their own rules: required labels, mandatory securityContext, ingress class conventions, observability defaults. The clean way to enforce them is a custom transformer.

```bash
# Fork the defaults
docker compose bridge transformations create \
    --from docker/compose-bridge-kubernetes my-template

# Build and use
docker build --tag mycompany/transform --push .
docker compose bridge convert --transformation mycompany/transform
```

The x-* extension fields (Tip #27) become the input mechanism. A Compose file with:

```yaml
services:
  web:
    x-team: payments
    x-cost-center: cc-9821
    x-ingress:
      host: pay.example.com
      class: nginx-internal
```

…drives Go templates that read those fields and stamp the right labels, annotations, and Ingress objects on the way out. Vanilla Compose ignores the extensions; the transformer picks them up.

Chain transformations to layer org policy on top of the default output:

```bash
docker compose bridge convert \
    --transformation docker/compose-bridge-kubernetes \
    --transformation mycompany/policy-transformer
```

Full guide: lours.me/posts/compose-bridge-deep-dive-071-custom-transformers/

#Docker #DockerCompose #Kubernetes #Platform #DevOps
```

---

### Friday, June 5 - Docker Model Runner on Kubernetes (#72, Part 3)

**🦋 Bluesky:**
```
🐳 🐙 Compose Bridge Deep Dive — Part 3

Ship an AI app to Kubernetes from a Compose file with `models:`.

Two topologies, same source:
• host Model Runner (Docker Desktop)
• in-cluster docker/model-runner Deployment + Service + PVC

helm install myapp ./out --set modelRunner.enabled=true

Guide: lours.me/posts/compose-bridge-deep-dive-072-model-runner/

#Docker #AI #Kubernetes
```

**💼 LinkedIn:**
```
🐳 🐙 Compose Bridge Deep Dive — Part 3: Docker Model Runner on Kubernetes

A Compose file with `models:` (Tip #60) runs an AI app on a laptop out of the box. Shipping the same stack to Kubernetes used to mean writing the model server's Deployment, Service, ConfigMap, and PVC by hand. The default Compose Bridge transformers now do that for you, in two distinct topologies.

```yaml
models:
  chat:
    model: ai/qwen2.5

services:
  web:
    build: ./web
    ports: ["8080:8080"]
    models:
      chat:
        endpoint_var: OPENAI_BASE_URL
```

Topology 1 — Host Model Runner (Docker Desktop only):
• No model pods on the cluster
• App pods get OPENAI_BASE_URL=http://host.docker.internal:12434/engines/v1/
• Fastest cold start, smallest footprint

Topology 2 — In-cluster Model Runner (any Kubernetes):
• docker/model-runner Deployment with init container + model-init sidecar
• ConfigMap drives the model pre-pull from /models/create
• ClusterIP Service docker-model-runner on port 80 → 12434
• PVC keeps the weights between restarts
• App pods get OPENAI_BASE_URL=http://docker-model-runner/engines/v1/

Same Compose file, switched with a single flag in the Helm transformer:

```bash
helm install myapp ./out --set modelRunner.enabled=true   # in-cluster
helm install myapp ./out --set modelRunner.enabled=false  # host (Desktop)
```

One artefact, two runtime topologies. Pick what fits your environment.

Full guide: lours.me/posts/compose-bridge-deep-dive-072-model-runner/

#Docker #DockerCompose #Kubernetes #AI #LLM #ModelRunner
```

---

## Week 23: June 8-12, 2026 — back to regular tips

### Monday, June 8 - expose vs ports (Tip #73)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #73

expose vs ports, what's the difference?

ports: publishes to the host
expose: documents intent, no host binding

Inter-service traffic works either way.

Guide: lours.me/posts/compose-tip-073-expose-vs-ports/

#Docker #Networking
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #73: expose vs ports — what actually gets published

Two directives that look similar but do completely different things!

```yaml
services:
  web:
    image: nginx
    ports:
      - "8080:80"      # publishes to the host

  db:
    image: postgres:16
    expose:
      - "5432"         # documents intent, no host binding
```

Key facts:
• ports actually binds a container port to the host
• expose is documentation only — Compose tooling reads it as the service's contract
• Services on the same network can reach each other on any listening port, with or without expose
• ports: "5432:5432" on a database binds to 0.0.0.0 by default — accidental internet exposure
• Safer: 127.0.0.1:5432:5432 or just expose: ["5432"]

Use expose to make the service contract explicit; reserve ports for what truly needs to leave the network.

Full guide: lours.me/posts/compose-tip-073-expose-vs-ports/

#Docker #DockerCompose #Networking #Security #DevOps
```

---

### Wednesday, June 10 - docker compose ls (Tip #74)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #74

docker compose ps shows the current project.
docker compose ls shows EVERY Compose stack on the host.

Finds the zombie project still holding port 5432.

Guide: lours.me/posts/compose-tip-074-compose-ls/

#Docker #CLI
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #74: docker compose ls and cross-project visibility

ps shows the current project. ls zooms out: every Compose stack running on the host, no matter which directory you're in.

```bash
# Every running stack
docker compose ls

# Include stopped projects
docker compose ls --all

# Filter (only name= is supported)
docker compose ls --filter name=api

# Scripting-friendly: json or --quiet
docker compose ls --format json
docker compose ls -q
```

The "who's holding port 5432" workflow:

```bash
# 1. Find every running stack
docker compose ls

# 2. Inspect a suspect one from anywhere
docker compose -f /path/to/old-prototype/compose.yaml ps

# 3. Bring it down by name, no cd needed
docker compose -p old-prototype down
```

A one-liner to clean up every stopped Compose project on the host (keep this one away from production):

```bash
docker compose ls --all --format json \
  | jq -r '.[] | select(.Status | startswith("exited")) | .Name' \
  | xargs -I{} docker compose -p {} down --volumes
```

Full guide: lours.me/posts/compose-tip-074-compose-ls/

#Docker #DockerCompose #CLI #DevOps
```

---

### Friday, June 12 - attach: false (Tip #75)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #75

Hide noisy service logs from `compose up`!

services:
  proxy:
    image: nginx
    attach: false

Or per run:
docker compose up --no-attach proxy

Logs still streamable via `compose logs`.

Guide: lours.me/posts/compose-tip-075-attach-false/

#Docker #Runtime
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #75: Silencing noisy services with attach: false

docker compose up streams every service's logs into one terminal. With a chatty proxy or a model server, signal drowns in noise. attach: false fixes it without stopping the service.

```yaml
services:
  web:
    image: myapp

  reverse-proxy:
    image: nginx
    attach: false      # logs hidden from `compose up`

  metrics:
    image: prom/prometheus
    attach: false
```

CLI override for one-off cases:

```bash
docker compose up --no-attach reverse-proxy
docker compose up --attach api          # only show api logs
```

Where it earns its keep:
• Sidecars and proxies (Envoy, Nginx, Traefik) where access logs are background noise
• Model servers (docker/model-runner et al.) that print tokenizer warnings every second
• Healthcheck loops that exec a probe every 2s
• Background workers whose tracebacks aren't today's bug

It doesn't stop the service or silence it permanently — docker compose logs still streams. Reach for profiles (Tip #24) when the goal is to skip the service entirely.

Full guide: lours.me/posts/compose-tip-075-attach-false/

#Docker #DockerCompose #Runtime #Logging #DevOps
```

---

## Week 24: June 15-19, 2026 — Mixed Themes

### Monday, June 15 - docker compose down options (Tip #76)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #76

docker compose down — the flags that decide what actually gets removed.

down            → containers + networks
down -v         → also named volumes (data gone!)
down --rmi local → also local images
down --remove-orphans → cleanup old services

Guide: lours.me/posts/compose-tip-076-compose-down-options/

#Docker #CLI
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #76: docker compose down and its options

down looks like a tidy shutdown. The flags around it decide whether you walk away with your data intact — or with a database wiped because you typed -v out of habit.

What plain `down` removes:
• Every container in the project
• The default network Compose created
• Anonymous volumes

What it does NOT remove:
• Named volumes (data is safe)
• Images
• External networks
• Containers for services outside the current Compose file

The flags worth knowing:

```bash
# Also remove named volumes — irreversible data loss, no confirmation prompt
docker compose down -v

# Also remove images built by this project
docker compose down --rmi local

# Also remove every image referenced by the project (incl. pulled bases)
docker compose down --rmi all

# Clean up containers from services that no longer exist in the file
docker compose down --remove-orphans

# Wait longer than the default 10s before SIGKILL
docker compose down -t 60
```

A safer habit: type the long form `--volumes` when you mean it. Never alias `down` to `down -v`.

Before destructive teardown, dry-run it first (Tip #54):

```bash
docker compose down -v --rmi all --remove-orphans --dry-run
```

Reading that list once is cheaper than restoring from backup.

Full guide: lours.me/posts/compose-tip-076-compose-down-options/

#Docker #DockerCompose #CLI #DevOps
```

---

### Wednesday, June 17 - Volume subpath (Tip #77)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #77

One named volume, multiple services, each scoped to its own sub-directory:

volumes:
  - type: volume
    source: app-data
    target: /var/data
    volume:
      subpath: api

Same backup unit, clean isolation.

Guide: lours.me/posts/compose-tip-077-volume-subpath/

#Docker #Storage
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #77: Volume subpath for mounting a sub-directory

Named volumes default to mounting the entire volume root at the container target. Sometimes you want only a sub-directory — for instance, several services sharing one named volume, each scoped to its own corner.

```yaml
services:
  api:
    image: myapi
    volumes:
      - type: volume
        source: app-data
        target: /var/data
        volume:
          subpath: api

  worker:
    image: myworker
    volumes:
      - type: volume
        source: app-data
        target: /var/data
        volume:
          subpath: worker

  backup:
    image: alpine
    command: tar -czf /backup/snapshot.tgz /source
    volumes:
      - type: volume
        source: app-data
        target: /source
        # No subpath, sees the whole volume

volumes:
  app-data:
```

Why not just use N separate named volumes? Three reasons:
• Single backup unit — one snapshot, one restore
• Shared driver options (NFS, encryption, perf tuning) inherited by every consumer
• Atomic migration — moving the storage moves all sub-paths at once

Bonus: since Compose v2.35, `image.subpath` does the same trick for OCI-image-backed volumes — mount only the directory you need from a larger image.

Full guide: lours.me/posts/compose-tip-077-volume-subpath/

#Docker #DockerCompose #Storage #DevOps
```

---

### Friday, June 19 - COMPOSE_* environment variables (Tip #78)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #78

Stop retyping -f and -p. Pin defaults in the project .env file:

COMPOSE_FILE=compose.yaml:compose.dev.yaml
COMPOSE_PROJECT_NAME=myapp-dev
COMPOSE_PROFILES=full

Compose loads it before parsing compose.yaml. No shell setup needed.

Guide: lours.me/posts/compose-tip-078-compose-env-vars/

#Docker #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #78: The COMPOSE_* environment variables

Almost every Compose CLI flag has an environment-variable counterpart. Set them once, in your shell or CI, and stop retyping the same -f / -p / --profile / --env-file on every command.

The ones that show up most:

• COMPOSE_FILE — path(s) to the Compose file(s) (use COMPOSE_PATH_SEPARATOR to change the separator)
• COMPOSE_PROJECT_NAME — project name
• COMPOSE_PROFILES — profiles to enable
• COMPOSE_ENV_FILES — project-level env files
• COMPOSE_PROGRESS — auto / tty / plain / json / quiet
• COMPOSE_REMOVE_ORPHANS — always clean up orphans on up/down
• COMPOSE_IGNORE_ORPHANS — silence the warning
• COMPOSE_PARALLEL_LIMIT — cap parallel operations

Local pattern — drop the COMPOSE_* vars into the project .env file (the one Compose already loads for ${VAR} interpolation):

```ini
# .env
COMPOSE_FILE=compose.yaml:compose.dev.yaml
COMPOSE_PROJECT_NAME=myapp-dev
COMPOSE_PROFILES=full
```

No shell setup, no third-party tool. cd into the directory and every command picks up the right defaults. The values stay scoped to Compose — if you need them visible to other shell commands, export them in your shell or use a tool like direnv on top.

CI pattern — deterministic runs, no flag drift:

```yaml
env:
  COMPOSE_FILE: compose.yaml:compose.ci.yaml
  COMPOSE_PROJECT_NAME: ${{ github.run_id }}
  COMPOSE_PROGRESS: plain
  COMPOSE_REMOVE_ORPHANS: "true"
```

Precedence (low → high):
1. Compose defaults
2. Project .env
3. COMPOSE_* env vars
4. Explicit CLI flags

So `--file compose.alt.yaml` always beats COMPOSE_FILE in the shell. The env vars are defaults, not overrides.

Pro tip: when "it works on my machine" strikes, run `env | grep ^COMPOSE_`. Half the support requests on Compose stacks are someone with COMPOSE_FILE pointing at the wrong file.

Full guide: lours.me/posts/compose-tip-078-compose-env-vars/

#Docker #DockerCompose #CLI #DevOps #Platform
```

---

## Week 25: June 22-26, 2026 — Mixed Themes

### Monday, June 22 - docker compose run advanced flags (Tip #79)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #79

docker compose run — the flags worth memorising:

--rm              clean up after exit
--service-ports   actually publish the ports
--no-deps         skip depends_on
--entrypoint sh   override the entrypoint
--build           rebuild before run

Guide: lours.me/posts/compose-tip-079-compose-run-advanced/

#Docker #CLI
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #79: docker compose run advanced flags

`run` creates a fresh container for a service and attaches your terminal. The flags around it decide what gets started, what gets cleaned up, and whether ports are published.

The set worth knowing by heart:

• --rm — remove the container on exit. Use on every interactive run.
• --service-ports — actually publish the ports declared on the service (the default is to skip them to avoid clashes with `up`)
• -e KEY=VALUE — ad-hoc env vars, no file edit needed
• --entrypoint sh — bypass the image's entrypoint to get a shell
• --build — rebuild the image before running
• --no-deps — skip the depends_on graph
• -v src:dst — one-off bind mount

The combo for "give me a shell in a freshly built image":

```bash
docker compose run --rm \
  --no-deps \
  --entrypoint sh \
  --build \
  api
```

Rebuild, drop into a shell, no dependency setup, clean up on exit. The canonical "let me poke at this" command.

Pro tip — an alias pair pays off fast:

```bash
alias dcr='docker compose run --rm'
alias dcrsh='docker compose run --rm --no-deps --entrypoint sh'
```

Full guide: lours.me/posts/compose-tip-079-compose-run-advanced/

#Docker #DockerCompose #CLI #DevOps
```

---

### Wednesday, June 24 - additional_contexts for builds (Tip #80)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #80

Need files from outside the build context? additional_contexts wires them in by name.

build:
  context: ./app
  additional_contexts:
    cli: docker-image://ghcr.io/myorg/mycli:v3
    docs: https://github.com/myorg/docs.git#main

Then: COPY --from=cli ...

Guide: lours.me/posts/compose-tip-080-additional-contexts/

#Docker #BuildKit
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #80: additional_contexts for multi-context builds

A Dockerfile has one build context. Sometimes you need files from elsewhere — a base image, an OCI layout, a separate git repo, or another service's build output. `additional_contexts` wires all of them into a single build.

```yaml
services:
  app:
    build:
      context: ./app
      additional_contexts:
        shared: ../shared                              # local dir
        cli: docker-image://ghcr.io/myorg/mycli:v3.2.0 # image
        cached: oci-layout://./oci-cache               # OCI layout
        docs: https://github.com/myorg/docs.git#main   # git repo
```

Then in the Dockerfile, reference them by name:

```dockerfile
COPY --from=cli /usr/local/bin/mycli /usr/local/bin/
COPY --from=docs /reference /app/docs
```

The killer pattern: pull a compiled binary out of a published image without a heavyweight multi-stage rewrite. No vendoring, no package manager, just `COPY --from=cli`.

Cross-service variant — build A using B's image as a context:

```yaml
services:
  builder:
    build: ./builder

  app:
    build:
      context: ./app
      additional_contexts:
        artefacts: service:builder
```

Compose orders the builds: `builder` first, then its image is exposed under `artefacts` when building `app`. Removes the need for a published intermediate image when the artefact only matters within the project.

Pin git sources to a commit SHA or tag (not `#main`) to keep the cache stable across builds.

Full guide: lours.me/posts/compose-tip-080-additional-contexts/

#Docker #DockerCompose #BuildKit #DevOps
```

---

### Friday, June 26 - tty + stdin_open (Tip #81)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #81

The Compose equivalent of docker run -it:

services:
  shell:
    image: alpine
    command: sh
    stdin_open: true   # = -i
    tty: true          # = -t

Pair with `docker compose run` to actually type into it.

Guide: lours.me/posts/compose-tip-081-tty-stdin-open/

#Docker #Runtime
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #81: tty and stdin_open for interactive containers

Drop a `bash` or `python` service into a compose.yaml and it exits immediately on `up`. The container starts, sees no stdin, prints nothing, and stops. The fix is the Compose equivalent of `docker run -it`:

```yaml
services:
  shell:
    image: alpine
    command: sh
    stdin_open: true   # = docker run -i
    tty: true          # = docker run -t
```

Setting the flags is half the story. By default, `up` attaches every service to a multiplexed terminal — keystrokes don't reach one specific container. Three ways to make the interactive flow actually work:

1. `docker compose run --rm <service>` (Tip #79) — always attaches
2. `docker compose up -d` then `docker compose attach <service>`
3. Start only the interactive service in the foreground

Where this earns its keep:
• Debug toolboxes (nicolaka/netshoot brought up on demand)
• Pinned language REPLs (python -i, node, ghci) shared across the team
• In-stack CLI clients (redis-cli, mongosh, mysql)
• Interactive migration runners that ask for confirmation

A reproducible pattern with a database client:

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: dev

  psql:
    image: postgres:16
    depends_on: [db]
    command: psql -h db -U postgres
    stdin_open: true
    tty: true
```

```bash
docker compose up -d db
docker compose run --rm psql
```

If you don't want the interactive service polluting `up` logs, pair with `attach: false` (Tip #75) and bring it forward with `docker compose attach` only when needed.

Full guide: lours.me/posts/compose-tip-081-tty-stdin-open/

#Docker #DockerCompose #Runtime #DevOps
```
