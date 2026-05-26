# Docker Compose Tips - Social Media Posts - May 2026

## Week 18: May 4-8, 2026

### Monday, May 4 - Compose configs for config files (Tip #58)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #58

Mount config files declaratively!

configs:
  nginx_conf:
    file: ./nginx.conf

services:
  web:
    configs:
      - source: nginx_conf
        target: /etc/nginx/nginx.conf

Like secrets, but for non-sensitive config.

Guide: lours.me/posts/compose-tip-058-configs/

#Docker #Configuration
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #58: Using configs for config files

The forgotten cousin of secrets! Mount config files declaratively, no volumes needed.

```yaml
configs:
  prometheus_conf:
    content: |
      global:
        scrape_interval: 15s

services:
  prometheus:
    image: prom/prometheus
    configs:
      - source: prometheus_conf
        target: /etc/prometheus/prometheus.yml
```

Why use configs?
• Declared in your Compose file, not external dirs
• Inline content support (no separate file needed)
• Variable interpolation in inline content
• Always read-only, safe by default
• Set permissions and ownership

Perfect for nginx.conf, prometheus.yml, app config files.

Full guide: lours.me/posts/compose-tip-058-configs/

#Docker #DockerCompose #Configuration #DevOps #BestPractices
```

---

### Wednesday, May 6 - entrypoint vs command (Tip #59)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #59

entrypoint vs command, what's the difference?

entrypoint: the executable
command: arguments passed to it

Container runs: <entrypoint> <command>

Subtle but important!

Guide: lours.me/posts/compose-tip-059-entrypoint-vs-command/

#Docker #Runtime #Containers
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #59: entrypoint vs command

Both define what runs at startup, but they play different roles!

```yaml
services:
  app:
    image: python:3.12
    entrypoint: ["python"]    # The executable
    command: ["app.py"]       # Arguments
```

Mental model: container runs <entrypoint> <command>

Common patterns:
• Override only command — switch behavior of an existing image
• Override entrypoint — bypass the image default
• entrypoint: [] — clear the image's entrypoint completely
• Always prefer exec form ([...]) over shell form for proper signal handling

Quick override at runtime:
```bash
docker compose run --rm app pytest tests/
docker compose run --rm --entrypoint /bin/sh app
```

Full guide: lours.me/posts/compose-tip-059-entrypoint-vs-command/

#Docker #DockerCompose #Runtime #Containers #DevOps
```

---

### Friday, May 8 - Compose models for LLMs (Tip #60)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #60

LLMs as first-class citizens in Compose!

models:
  smollm:
    model: ai/smollm2

services:
  app:
    models:
      - smollm

Endpoint URL injected automatically.

Guide: lours.me/posts/compose-tip-060-models-section/

#Docker #AI #LLM
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #60: Declaring LLMs with the models section

LLMs are now first-class citizens in Compose!

```yaml
models:
  chat:
    model: ai/qwen2.5
  embeddings:
    model: ai/granite-embedding-multilingual

services:
  qdrant:
    image: qdrant/qdrant

  api:
    build: ./api
    models:
      - chat
      - embeddings
    depends_on:
      - qdrant
```

What you get:
• Model lifecycle managed by Compose
• Endpoint URL injected via environment variables
• Customize variable names (e.g. OPENAI_BASE_URL for official OpenAI clients)
• Multiple models per service
• OpenAI-compatible API for any client

One docker compose up, full AI stack ready. I covered this at Devoxx France 2026 with Nicolas De Loof — recording coming soon!

Full guide: lours.me/posts/compose-tip-060-models-section/

#Docker #DockerCompose #AI #LLM #GenerativeAI
```

---

## Week 19: May 11-15, 2026

### Monday, May 11 - Compose provider services (Tip #61)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #61

Beyond containers: provider services!

services:
  tunnel:
    provider:
      type: telepresence
      options:
        namespace: avatars
        service: api

Manage Kubernetes intercepts, managed DBs, VPN tunnels, all in compose.yml.

Guide: lours.me/posts/compose-tip-061-provider-services/

#Docker #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #61: Provider services for non-container dependencies

Not everything in your stack is a container. Compose 2.36 introduced provider services to manage external dependencies declaratively!

```yaml
services:
  api:
    image: my-api:latest

  tunnel:
    provider:
      type: telepresence
      options:
        namespace: avatars
        service: api
        port: 5732:api-80
```

Use cases:
• Kubernetes traffic intercepts (Telepresence)
• Managed databases (RDS provisioning)
• VPN tunnels (wireguard, OpenVPN)
• SaaS APIs with auth setup
• Message queues
• Any external resource that needs lifecycle management

How it works:
• provider.type points to a binary in your $PATH
• Compose calls it on up and down
• Provider publishes env vars to dependent services via JSON

Want to write your own? Reference implementation in Go: github.com/glours/compose-telepresence-plugin

Full guide: lours.me/posts/compose-tip-061-provider-services/

#Docker #DockerCompose #DevOps #Kubernetes #BestPractices
```

---

### Wednesday, May 13 - Network aliases (Tip #62)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #62

One service, multiple hostnames!

networks:
  app-net:
    aliases:
      - db
      - database
      - postgres-primary

Perfect for migrations and legacy clients.

Guide: lours.me/posts/compose-tip-062-network-aliases/

#Docker #Networking
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #62: Network aliases for service routing

Give a service multiple hostnames on a network!

```yaml
services:
  identity:
    image: identity:v2
    networks:
      app-net:
        aliases:
          - auth-service   # Old name kept as alias
```

Use cases:
• Migrate service names without breaking existing clients
• Different aliases per network (public vs internal)
• Drop-in replacements with profiles
• Multiple semantic names for one service

Don't confuse with extra_hosts (Tip #36):
• aliases — adds hostnames FOR a service that other containers can reach
• extra_hosts — adds entries to a container's /etc/hosts for EXTERNAL hostnames

Full guide: lours.me/posts/compose-tip-062-network-aliases/

#Docker #DockerCompose #Networking #DevOps
```

---

### Friday, May 15 - ulimits and shm_size (Tip #63)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #63

Beyond CPU/memory limits!

ulimits:
  nofile: 65536

shm_size: 2gb

For Chrome, PyTorch, high-concurrency servers.

Guide: lours.me/posts/compose-tip-063-ulimits-shm-size/

#Docker #Performance
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #63: Tuning containers with ulimits and shm_size

Two settings that solve specific runtime problems!

```yaml
services:
  scraper:
    image: chrome-headless
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    shm_size: 2gb
```

When you need them:
• ulimits/nofile: high-concurrency servers (nginx, Node.js) hitting "Too many open files"
• shm_size: Chrome/Puppeteer (defaults to 64MB and crashes), PyTorch DataLoaders, busy PostgreSQL
• ulimits/nproc: apps that fork heavily

These complement CPU/memory limits (Tip #16): one caps the resources Docker hands out, the other configures how the container uses them.

Full guide: lours.me/posts/compose-tip-063-ulimits-shm-size/

#Docker #DockerCompose #Performance #Runtime #DevOps
```

---

## Week 20: May 18-22, 2026

### Monday, May 18 - docker compose cp (Tip #64)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #64

Need to grab a log out of a container?

docker compose cp app:/var/log/app/error.log ./error.log

Push a config in the other way:
docker compose cp ./nginx.conf web:/etc/nginx/nginx.conf

One-shot file copy, no volume needed.

Guide: lours.me/posts/compose-tip-064-compose-cp/

#Docker #CLI #Debugging
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #64: Copying files with docker compose cp

When you need a one-off file transfer between host and container, no volume required.

```bash
# Out of the container
docker compose cp app:/var/log/app/error.log ./error.log

# Into the container
docker compose cp ./nginx-debug.conf web:/etc/nginx/nginx.conf

# Target a specific replica
docker compose cp --index=2 worker:/var/log/worker.log ./worker-2.log
```

Common uses:
• Pull logs or build artifacts for offline analysis
• Push a quick config tweak without rebuilding
• Seed test data into a database container
• Extract coredumps for debugging

For persistent file sharing, use volumes or configs (Tip #58). cp is for snapshots in time.

Full guide: lours.me/posts/compose-tip-064-compose-cp/

#Docker #DockerCompose #CLI #Debugging #DevOps
```

---

### Wednesday, May 20 - DNS config (Tip #65)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #65

Custom DNS in your containers!

dns:
  - 1.1.1.1
dns_search:
  - corp.example.com
dns_opt:
  - "ndots:2"

Different from extra_hosts (Tip #36) which edits /etc/hosts.

Guide: lours.me/posts/compose-tip-065-dns-config/

#Docker #Networking #DNS
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #65: Custom DNS configuration with dns and dns_search

Three directives, full control over container DNS resolution!

```yaml
services:
  dev-app:
    image: myapp
    dns:
      - 10.0.0.1            # Corporate DNS via VPN
      - 1.1.1.1             # Public fallback
    dns_search:
      - corp.example.com
    dns_opt:
      - "ndots:1"
      - "timeout:2"
```

What each does:
• dns: which resolver servers to query
• dns_search: search domains for short names
• dns_opt: resolver tuning (ndots, timeout, attempts)

Common use cases: corporate DNS through VPN, Pi-hole, NextDNS, internal hostname resolution.

Don't confuse with extra_hosts (Tip #36):
• dns: changes the resolver
• extra_hosts: pins specific hostnames in /etc/hosts

Full guide: lours.me/posts/compose-tip-065-dns-config/

#Docker #DockerCompose #Networking #DNS #DevOps
```

---

### Friday, May 22 - Volume drivers with NFS (Tip #66)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #66

NFS volumes in one declaration!

volumes:
  shared:
    driver: local
    driver_opts:
      type: nfs
      o: "addr=nfs.example.com,rw,nfsvers=4"
      device: ":/exports/shared"

Shared storage across hosts.

Guide: lours.me/posts/compose-tip-066-volume-drivers-nfs/

#Docker #Storage
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #66: Volume drivers with NFS

Compose volumes go beyond local disk! The built-in local driver supports NFS out of the box.

```yaml
volumes:
  shared:
    driver: local
    driver_opts:
      type: nfs
      o: "addr=nfs-server.example.com,rw,nfsvers=4"
      device: ":/exports/shared"

services:
  app:
    image: myapp
    volumes:
      - shared:/data
```

Use cases:
• Multi-host shared storage
• Static assets served by multiple web containers
• Backup destinations off the host
• Sharing data with non-Docker systems

Common options to know:
• addr=<server>, nfsvers=4, ro/rw, hard/soft, timeo=N

For cloud storage (EBS, EFS, Azure Disk), use a plugin driver instead. The same volume mechanism works for both.

Full guide: lours.me/posts/compose-tip-066-volume-drivers-nfs/

#Docker #DockerCompose #Storage #NFS #DevOps
```

---

## Week 21: May 25-29, 2026

### Monday, May 25 - pull_policy (Tip #67)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #67

Control when Compose pulls images!

pull_policy: always   # every up
pull_policy: never    # CI: fail if missing
pull_policy: build    # force local build
pull_policy: daily    # refresh once a day

Match the policy to your tag.

Guide: lours.me/posts/compose-tip-067-pull-policy/

#Docker #Build
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #67: Controlling image pulls with pull_policy

Decide exactly when Compose pulls from a registry!

```yaml
services:
  api:
    image: myregistry/api:latest
    pull_policy: always
```

Available policies:
• missing (default): pull only if not local (latest tag is always pulled!)
• always: pull on every up
• never: don't pull, fail if missing (great for CI)
• build: force build over pull, rebuild even if image is present
• daily / weekly: periodic refresh without the cost of always
• every_<duration>: fine-grained refresh (e.g. every_12h, every_1h30m)

CLI override: docker compose up --pull always|missing|never

Match the policy to how often the underlying tag is expected to move.

Full guide: lours.me/posts/compose-tip-067-pull-policy/

#Docker #DockerCompose #Build #DevOps #CICD
```

---

### Wednesday, May 27 - docker compose wait (Tip #68)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #68

docker compose wait waits for service exit!

Different from up --wait (Tip #51) which waits for healthy.

Perfect for migrations, test runners, batch jobs.

Propagates exit code in CI.

Guide: lours.me/posts/compose-tip-068-compose-wait/

#Docker #CICD
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #68: Waiting for service exit with docker compose wait

Different from up --wait (Tip #51): wait blocks until services EXIT, not until they're healthy!

```bash
# Start the stack and wait for everything to be healthy
docker compose up -d --wait --wait-timeout 60

# Run the test suite, then wait for it to finish
docker compose up -d tests
docker compose wait tests
TESTS_EXIT=$?

docker compose down --volumes
exit $TESTS_EXIT
```

When to use each:
• up --wait: wait for services to be ready to serve (healthchecks pass)
• wait: wait for one-shot services to finish (migrations, tests, batch jobs)

Multiple services: docker compose wait migrate seeder (waits for ALL to exit)

Full guide: lours.me/posts/compose-tip-068-compose-wait/

#Docker #DockerCompose #CICD #Testing #DevOps
```

---

### Friday, May 29 - pid and ipc namespace sharing (Tip #69)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #69

Share namespaces between containers!

debugger:
  pid: service:app
  cap_add: [SYS_PTRACE]

Attach strace/gdb to a running service without baking debug tools in.

Guide: lours.me/posts/compose-tip-069-pid-ipc/

#Docker #Debugging
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #69: Sharing namespaces with pid and ipc

Two containers, one PID or IPC namespace. The escape hatch from default isolation!

```yaml
services:
  app:
    image: myapp

  debugger:
    image: alpine
    pid: service:app          # See app's processes
    cap_add:
      - SYS_PTRACE
    command: sleep infinity
```

Use cases:
• pid: service:<name> — attach strace/gdb/perf to another service without modifying its image
• ipc: service:<name> — share System V IPC and shared memory (e.g. pgbackrest with postgres)
• pid: host — monitoring agents that need to see all host processes
• ipc: none — strict isolation for untrusted code

Security: sharing namespaces removes isolation. Don't combine with untrusted images.

Full guide: lours.me/posts/compose-tip-069-pid-ipc/

#Docker #DockerCompose #Debugging #Runtime #DevOps
```
