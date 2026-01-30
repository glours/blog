# Docker Compose Tips - Social Media Posts - February 2026

## Week 5: February 2-6, 2026

### Monday, Feb 2 - Bridge vs Host Networking

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #21

Bridge vs Host networking explained!

Bridge: Isolated, secure, default
Host: Direct access, no isolation

When to use each mode and security implications.

Guide: lours.me/posts/compose-tip-021-bridge-vs-host/

#Docker #Networking #Security
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #21: Understanding bridge vs host networking modes

Choose the right networking mode for your containers! Understand the trade-offs between isolation and performance.

Bridge mode (default):
```yaml
services:
  web:
    networks:
      - mybridge
networks:
  mybridge:
    driver: bridge
```

Host mode (direct access):
```yaml
services:
  monitoring:
    network_mode: host
```

Key differences:
• Bridge: Port mapping, network isolation, container-to-container DNS
• Host: No port mapping needed, better performance, less isolation
• Security: Bridge provides better isolation
• Use cases: Host for system monitoring, Bridge for applications

Make informed networking decisions: lours.me/posts/compose-tip-021-bridge-vs-host/

#Docker #DockerCompose #Networking #Security #Architecture
```

---

### Tuesday, Feb 3 - Using Secrets

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #22

Secure your sensitive data!

secrets:
  db_password:
    file: ./secrets/db_pass.txt

Never commit secrets. Use files or external managers.

Learn more: lours.me/posts/compose-tip-022-secrets/

#Docker #Security #BestPractices
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #22: Using secrets in Compose files

Keep passwords and API keys secure! Docker Compose secrets provide a safe way to handle sensitive data.

```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    environment: API_KEY

services:
  app:
    image: myapp
    secrets:
      - db_password
      - api_key
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password
```

Best practices:
• Never hardcode secrets in compose files
• Use .gitignore for secret files
• Read from /run/secrets/ in containers
• Consider external secret managers for production
• Set proper file permissions (400)

Secure your deployments: lours.me/posts/compose-tip-022-secrets/

#Docker #DockerCompose #Security #SecretsManagement #DevSecOps
```

---

### Wednesday, Feb 4 - Multi-platform Builds

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #23

Build for ARM and x86!

build:
  platforms:
    - linux/amd64
    - linux/arm64

One image, multiple architectures. Perfect for M1 Macs and cloud.

Details: lours.me/posts/compose-tip-023-multi-platform/

#Docker #ARM #CrossPlatform
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #23: Multi-platform builds with platforms

Build once, run everywhere! Create images that work on both ARM and x86 architectures.

```yaml
services:
  app:
    build:
      context: .
      platforms:
        - linux/amd64
        - linux/arm64
        - linux/arm/v7
```

Setup (Docker Desktop handles this automatically):
```bash
# Only needed if not using Docker Desktop:
docker buildx create --use
# Then build and push:
docker compose build --push
```

Benefits:
• Support M1/M2 Macs and Intel machines
• Deploy to ARM-based cloud instances (Graviton)
• Raspberry Pi compatibility
• Single registry tag for all platforms

Future-proof your containers: lours.me/posts/compose-tip-023-multi-platform/

#Docker #DockerCompose #ARM #CrossPlatform #CloudNative
```

---

### Thursday, Feb 5 - Service Profiles

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #24

Organize optional services!

profiles: ["debug", "test"]

docker compose --profile debug up

Enable only what you need. Keep compose files clean.

Learn how: lours.me/posts/compose-tip-024-profiles/

#Docker #Development #Organization
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #24: Using profiles to organize optional services

Control which services start! Profiles let you group services for different scenarios.

```yaml
services:
  app:
    image: myapp
    # Always starts

  debug:
    image: debug-tools
    profiles: ["debug"]

  tests:
    image: test-runner
    profiles: ["test"]

  monitoring:
    image: prometheus
    profiles: ["debug", "monitoring"]
```

Usage:
```bash
# Normal startup
docker compose up

# Include debug tools
docker compose --profile debug up

# Run tests
docker compose --profile test up

# Multiple profiles
docker compose --profile debug --profile monitoring up
```

Perfect for: Debug tools, test services, monitoring stacks, development databases

Flexible service orchestration: lours.me/posts/compose-tip-024-profiles/

#Docker #DockerCompose #Development #Testing #DevEx
```

---

### Friday, Feb 6 - Docker Compose Events

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #25

Monitor container lifecycle!

docker compose events --json

Track starts, stops, health changes. Build monitoring and automation.

Full guide: lours.me/posts/compose-tip-025-events/

#Docker #Monitoring #Observability
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #25: Using docker compose events for monitoring

Real-time container lifecycle monitoring! Track what's happening in your Compose stack.

```bash
# Watch all events
docker compose events

# JSON output for processing
docker compose events --json

# Filter specific services
docker compose events web worker

# Since timestamp
docker compose events --since "2024-02-06T10:00:00"
```

Event types:
• Container: create, start, stop, die, kill
• Health: health_status changes
• Network: connect, disconnect
• Volume: mount, unmount

Automation ideas:
```bash
docker compose events --json | \
  jq 'select(.action=="die")' | \
  while read event; do
    notify-slack "Container died: $event"
  done
```

Build powerful monitoring workflows: lours.me/posts/compose-tip-025-events/

#Docker #DockerCompose #Monitoring #Observability #Automation
```