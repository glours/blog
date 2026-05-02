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
