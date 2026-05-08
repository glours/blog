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
