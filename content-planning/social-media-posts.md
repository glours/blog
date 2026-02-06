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
```# Docker Compose Tips - Social Media Posts - Week 6

## Week 6: February 9-13, 2026

### Monday, Feb 9 - Restart Policies

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #26

Keep services running with smart restart policies!

restart: always | unless-stopped | on-failure | no

Configure automatic recovery from crashes and failures.

Guide: lours.me/posts/compose-tip-026-restart-policies/

#Docker #Reliability #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #26: Using restart policies effectively

Ensure your containers recover from crashes automatically! Choose the right restart policy for each service.

```yaml
services:
  # Critical services
  database:
    restart: always

  # Dev services
  debug:
    restart: unless-stopped

  # Flaky services
  api:
    restart: on-failure:5
```

Options explained:
• always: Restarts even after Docker daemon restart
• unless-stopped: Restarts unless manually stopped
• on-failure: Only on non-zero exit (with optional retry limit)
• no: Never restart (default)

Build resilient applications: lours.me/posts/compose-tip-026-restart-policies/

#Docker #DockerCompose #Reliability #DevOps #Containers
```

---

### Tuesday, Feb 10 - Extension Fields as Metadata

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #27

Extension fields aren't just for YAML reuse!

x-region: us-east-1
x-kubernetes:
  namespace: production

services:
  api:
    x-tier: frontend
    x-owner: api-team

Metadata for tools & platforms!

Guide: lours.me/posts/compose-tip-027-extension-metadata/

#Docker #Kubernetes #Metadata
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #27: Extension fields as metadata for tools and platforms

Use extension fields to carry metadata for Kubernetes, monitoring, and deployment tools!

```yaml
x-kubernetes:
  namespace: production
  ingress-class: nginx

services:
  web:
    image: webapp:v2
    x-kubernetes:
      annotations:
        prometheus.io/scrape: "true"
    x-aws:
      instance-type: "t3.medium"
    x-monitoring:
      slo-target: 99.95
```

Use cases:
• Platform-specific configurations (AWS, Azure, GCP)
• Kubernetes deployment hints via Compose Bridge
• Monitoring and alerting metadata
• Cost tracking and ownership information
• CI/CD pipeline configuration

Bridge Compose to any platform: lours.me/posts/compose-tip-027-extension-metadata/

#Docker #DockerCompose #Kubernetes #CloudNative #Metadata
```

---

### Wednesday, Feb 11 - Docker Run to Compose

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #28

Convert docker run to Compose!

docker run -p 3000:3000 -v ./data:/app myapp

Becomes:
services:
  myapp:
    image: myapp
    ports: ["3000:3000"]
    volumes: ["./data:/app"]

Clean & maintainable!

Guide: lours.me/posts/compose-tip-028-docker-run-to-compose/

#Docker #Migration #DevOps
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #28: Converting docker run commands to Compose

Stop managing long docker run commands! Transform them into clean Compose files.

```bash
docker run -d --name app \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -v $(pwd)/data:/app/data \
  --restart unless-stopped \
  myapp:latest
```

Becomes:
```yaml
services:
  app:
    image: myapp:latest
    ports: ["3000:3000"]
    environment:
      NODE_ENV: production
    volumes: ["./data:/app/data"]
    restart: unless-stopped
```

Common mappings:
• -p → ports, -v → volumes, -e → environment
• --network → networks, --user → user
• --memory/--cpus → deploy.resources
• --cap-add/drop → cap_add/cap_drop
• --restart → restart

Version control your container configs: lours.me/posts/compose-tip-028-docker-run-to-compose/

#Docker #DockerCompose #Migration #DevOps #Automation
```

---

### Thursday, Feb 12 - Container Capabilities

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #29

Principle of least privilege!

cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE

Drop all capabilities, add only what's needed.

Secure containers properly!

Guide: lours.me/posts/compose-tip-029-container-capabilities/

#Docker #Security #Linux
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #29: Container capabilities and security options

Fine-tune container security! Control exactly what your containers can do with Linux capabilities.

```yaml
services:
  secure-app:
    image: myapp
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Bind ports < 1024
      - CHOWN            # Change file ownership
    security_opt:
      - no-new-privileges:true
    read_only: true
    user: "1000:1000"
```

Security patterns:
• Drop ALL capabilities by default
• Add only required capabilities
• Use read-only root filesystem
• Run as non-root user
• Enable no-new-privileges

Defense in depth for containers: lours.me/posts/compose-tip-029-container-capabilities/

#Docker #DockerCompose #Security #Linux #DevSecOps
```

---

### Friday, Feb 13 - Compose Include

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #30

Modular configs with include!

include:
  - path: ./services/database.yml
  - path: ./monitoring.yml
  - path: ${ENV_CONFIG:-dev.yml}

Keep configurations DRY and reusable.

Learn more: lours.me/posts/compose-tip-030-include/

#Docker #Configuration #Modular
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #30: Compose include for modular configurations

Build modular, reusable configurations! The include directive enables clean, organized Compose setups.

```yaml
# compose.yml
include:
  - path: ./services/database.yml
  - path: ./services/cache.yml
  - path: ./environments/${ENV:-dev}.yml

services:
  app:
    image: myapp
    depends_on:
      - postgres
      - redis
```

Benefits:
• Split configs into logical modules
• Share common configurations across teams
• Create reusable service libraries
• Conditional includes based on environment
• Layer configurations with overrides

Scale your compose architecture: lours.me/posts/compose-tip-030-include/

#Docker #DockerCompose #Configuration #Architecture #DevOps
```