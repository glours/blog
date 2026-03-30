# Docker Compose Tips - Social Media Posts - March 2026

## Week 9: March 2-6, 2026

### Monday, Mar 2 - Exec vs Run

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #34

exec vs run - know the difference!

exec: existing container
run: new container

docker compose exec web bash  # Debug running
docker compose run --rm test  # One-off task

Details: lours.me/posts/compose-tip-034-exec-vs-run/

#Docker #Debugging #CLI
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #34: Debugging with exec vs run

Choose the right tool! Understanding when to use each command.

```bash
# exec: Enter running container
docker compose exec web bash
docker compose exec db psql

# run: Create new container
docker compose run --rm migrate
docker compose run --rm --service-ports test
```

Key differences:
• exec requires running container
• run doesn't expose ports by default
• run doesn't start dependencies by default
• exec maintains existing environment
• run allows entrypoint override

Debug smarter: lours.me/posts/compose-tip-034-exec-vs-run/

#Docker #DockerCompose #Debugging #DevOps #CLI
```

---

### Wednesday, Mar 4 - Tmpfs Storage

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #35

⚡ RAM-speed storage with tmpfs!

tmpfs:
  - /tmp:size=100M
  - /app/cache:size=500M

Fast, secure, self-cleaning!

Guide: lours.me/posts/compose-tip-035-tmpfs-storage/

#Docker #Performance #Storage
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #35: Using tmpfs for ephemeral storage

Boost I/O performance with in-memory storage!

```yaml
services:
  app:
    tmpfs:
      - /tmp:size=100M
      - /app/cache:size=1G
    # Or with read-only root
    read_only: true
    tmpfs: [/tmp, /var/run]
```

Perfect for:
• Build caches and artifacts
• Session storage
• Temporary file processing
• Test databases
• CI/CD pipelines

Benefits: RAM speed, auto-cleanup, enhanced security!

Speed up your stack: lours.me/posts/compose-tip-035-tmpfs-storage/

#Docker #DockerCompose #Performance #Storage #Security
```

---

### Friday, Mar 6 - Extra Hosts (Tip #36)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #36

Custom DNS without touching /etc/hosts!

extra_hosts:
  - "api.local:192.168.1.100"
  - "host.docker:host-gateway"

Perfect for local development!

Learn: lours.me/posts/compose-tip-036-extra-hosts/

#Docker #Networking #DNS
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #36: Using extra_hosts for custom DNS entries

Add custom hostname mappings directly in Compose!

```yaml
services:
  app:
    extra_hosts:
      - "api.local:192.168.1.100"
      - "db.local:192.168.1.101"
      - "host.machine:host-gateway"
```

Use cases:
• Override production URLs for testing
• Connect to host machine services
• Create service aliases
• Environment-specific endpoints
• Mock external dependencies

No system file changes needed: lours.me/posts/compose-tip-036-extra-hosts/

#Docker #DockerCompose #Networking #DNS #Development
```

---

## Week 10: March 9-13, 2026

### Monday, Mar 9 - Understanding include, extends, and override files (Tip #37)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #37

3 ways to split Compose configs — each works differently!

Override files → project-level merge
extends → service-level inheritance
include → isolated sub-project import

Know which to reach for!

Guide: lours.me/posts/compose-tip-037-include-extends-overrides/

#Docker #Configuration #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #37: Understanding include, extends, and override files

Three mechanisms, three different scopes!

Override files → merge at project level (all services)
extends → a service inherits from another service definition
include → import a self-contained sub-project in isolation

Key difference with include: the imported file is parsed with its own working directory and .env file — it can't see or override the parent's services.

Full breakdown: lours.me/posts/compose-tip-037-include-extends-overrides/

Watch the deep dive: youtu.be/VOyyGX1MOU0

#Docker #DockerCompose #Configuration #Architecture #DevOps
```

---

### Wednesday, Mar 11 - When to use include vs extends vs overrides (Tip #38)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #38

Which one to use?

Adapting per environment? → Override files
Sharing base config across services? → extends
Importing a self-contained stack? → include

Simple decision guide inside!

Guide: lours.me/posts/compose-tip-038-when-to-use-which/

#Docker #Configuration #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #38: When to use include vs extends vs overrides

A practical decision guide:

Override files → dev vs prod differences, local developer customizations, CI tweaks
extends → common restart policies, logging, labels shared across services
include → monitoring stacks, database stacks, reusable service libraries

Quick rule of thumb:
• Adapting existing services? Override files
• DRY service config? extends
• Importing a group of services? include

Full guide: lours.me/posts/compose-tip-038-when-to-use-which/

Watch the deep dive: youtu.be/VOyyGX1MOU0

#Docker #DockerCompose #Configuration #BestPractices #DevOps
```

---

### Friday, Mar 13 - Combining include, extends, and overrides (Tip #39)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #39

Combine all 3 for a clean setup!

include → reusable infra stacks
extends → DRY service config
Overrides → env differences

Each handles its own concern!

lours.me/posts/compose-tip-039-combining-include-extends-overrides/

#Docker #Configuration
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #39: Combining include, extends, and overrides

The real power comes from using all three together:

include: infra stacks (database, monitoring) are isolated and reusable across projects
extends: service config (logging, labels, restart) is DRY and consistent
Override files: environment differences are explicit and targeted

Result:
• Change logging config? → update base/service-base.yml once
• Swap database stack? → replace one include line
• Adjust dev ports? → edit compose.override.yml, nothing else changes

Full walkthrough: lours.me/posts/compose-tip-039-combining-include-extends-overrides/

Watch the deep dive: youtu.be/VOyyGX1MOU0

#Docker #DockerCompose #Configuration #Architecture #DevOps
```

---

## Week 11: March 16-20, 2026

### Monday, Mar 16 - Labels for organization and monitoring (Tip #40)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #40

Labels cost nothing but unlock a lot!

labels:
  com.example.team: "backend"
  com.example.env: "production"

Filter, organize, integrate with Traefik & Prometheus.

Guide: lours.me/posts/compose-tip-040-labels/

#Docker #Configuration #Monitoring
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #40: Using labels for service organization and monitoring

Labels are free metadata that unlock powerful workflows!

```yaml
services:
  api:
    labels:
      com.example.team: "backend"
      com.example.env: "production"
```

Use them for:
• Filtering containers with `docker compose ps --filter`
• Traefik automatic routing configuration
• Prometheus service discovery
• Team ownership and environment tracking
• Consistent organization across all resources

Zero cost, high value: lours.me/posts/compose-tip-040-labels/

#Docker #DockerCompose #Monitoring #Configuration #DevOps
```

---

### Wednesday, Mar 18 - Container lifecycle hooks (Tip #41)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #41

Run commands at container lifecycle events!

post_start:
  - command: /app/init.sh
pre_stop:
  - command: /app/drain.sh

Init after start, cleanup before stop.

Guide: lours.me/posts/compose-tip-041-lifecycle-hooks/

#Docker #Runtime #Containers
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #41: Container lifecycle hooks

Run commands at specific points in a container's lifecycle!

```yaml
services:
  api:
    post_start:
      - command: /app/warm-cache.sh
    pre_stop:
      - command: /app/drain-connections.sh
    stop_grace_period: 30s
```

Key points:
• post_start runs inside the container after it starts
• pre_stop runs before the stop signal hits the main process
• Multiple commands run sequentially
• Different from entrypoint — hooks are side tasks

Graceful starts and stops: lours.me/posts/compose-tip-041-lifecycle-hooks/

#Docker #DockerCompose #Runtime #Containers #DevOps
```

---

### Friday, Mar 20 - Variable substitution and defaults (Tip #42)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #42

Smart variable substitution!

${TAG:-latest}    # default value
${TAG:?required}  # fail if missing

Flexible configs with safety built in.

Guide: lours.me/posts/compose-tip-042-variable-substitution/

#Docker #Configuration #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #42: Variable substitution and defaults

Make your Compose files flexible and safe!

```yaml
services:
  app:
    # Default value if unset
    image: myapp:${TAG:-latest}
    environment:
      # Fail with message if missing
      API_KEY: ${API_KEY:?API_KEY is required}
      # Default for dev
      LOG_LEVEL: ${LOG_LEVEL:-debug}
```

Three patterns to know:
• ${VAR:-default} — fallback value
• ${VAR:?message} — required with error message
• $$ — escape literal dollar signs

Use `docker compose config` to see resolved values!

Full guide: lours.me/posts/compose-tip-042-variable-substitution/

#Docker #DockerCompose #Configuration #BestPractices #DevOps
```

---

## Week 12: March 23-27, 2026

### Monday, Mar 23 - Read-only root filesystems (Tip #43)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #43

Harden containers in one line!

read_only: true
tmpfs:
  - /tmp:size=50M

Immutable filesystem + writable only where needed.

Guide: lours.me/posts/compose-tip-043-read-only-rootfs/

#Docker #Security #Containers
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #43: Read-only root filesystems

One of the simplest and most effective hardening measures!

```yaml
services:
  app:
    image: myapp
    read_only: true
    tmpfs:
      - /tmp:size=50M
      - /var/run:size=10M
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
```

Why it matters:
• Prevents attackers from modifying binaries
• No malicious files can be dropped
• Combined with tmpfs for writable paths
• Works great with capability dropping
• Simple to enable, huge security win

Harden your containers: lours.me/posts/compose-tip-043-read-only-rootfs/

#Docker #DockerCompose #Security #DevSecOps #Containers
```

---

### Wednesday, Mar 25 - Signal handling in containers (Tip #44)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #44

Graceful shutdowns need the right signal!

stop_signal: SIGQUIT
stop_grace_period: 30s
init: true

Control what happens when you stop.

Guide: lours.me/posts/compose-tip-044-signal-handling/

#Docker #Runtime #Containers
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #44: Signal handling in containers

Control how your containers shut down gracefully!

```yaml
services:
  nginx:
    stop_signal: SIGQUIT    # Graceful shutdown
    stop_grace_period: 30s

  worker:
    init: true              # Proper signal forwarding
    stop_grace_period: 120s # Time for long jobs
```

Key concepts:
• SIGTERM is sent by default, then SIGKILL after timeout
• stop_signal changes which signal is sent
• stop_grace_period controls the timeout
• init: true fixes the PID 1 signal forwarding problem
• Combine with pre_stop hooks for maximum control

Shut down cleanly: lours.me/posts/compose-tip-044-signal-handling/

#Docker #DockerCompose #Runtime #Containers #DevOps
```

---

### Friday, Mar 27 - Multi-stage builds with target (Tip #45)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #45

One Dockerfile, multiple targets!

build:
  context: .
  target: dev    # or production

Different images for dev and prod from the same file.

Guide: lours.me/posts/compose-tip-045-multi-stage-target/

#Docker #Build #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #45: Multi-stage builds with target

Build different images from the same Dockerfile!

```yaml
# compose.yml
services:
  app:
    build:
      context: .
      target: production

# compose.override.yml (local dev)
services:
  app:
    build:
      target: dev
    volumes:
      - .:/app
```

Use cases:
• Dev stage with hot reload and debug tools
• Production stage minimal and optimized
• Test stage with test dependencies included
• Multiple services from one Dockerfile
• Override files to switch targets per environment

One Dockerfile, many uses: lours.me/posts/compose-tip-045-multi-stage-target/

#Docker #DockerCompose #Build #CICD #DevOps
```

---

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
