# Social Media Posts for Docker Compose Tips

## Completed Posts ✅

### Week 1 (Jan 5-9, 2026) - DONE

---

### Monday, Jan 5 - Debug your configuration with config

**🦋 Bluesky:**
```
🐳 🐙Docker Compose Tip #1

Profiles confusing? Use docker compose config to debug.

docker compose --profile dev config --services

Shows ALL services that will run, including dependencies pulled in without the profile.

Details: lours.me/posts/compose-tip-001-validate-config/

#Docker #DockerCompose
```

**💼 LinkedIn:**
```
🐳 🐙Docker Compose Tip #1: Debug complex configurations

`docker compose config` is the go-to debugging tool for complex setups.

Especially useful with profiles - they can be tricky. Services get pulled in through dependencies even without the profile.

```bash
docker compose --profile dev config --services
```

Shows exactly what will run, how variables resolve, and how multiple files merge.

For CI/CD, validate all profiles:
```bash
for profile in dev staging prod; do
  docker compose --profile $profile config --quiet || exit 1
done
```

Full post: lours.me/posts/compose-tip-001-validate-config/

#Docker #DockerCompose #DevOps
```

---

### Tuesday, Jan 6 - Using --env-file for different environments

**🦋 Bluesky:**
```
🐳 🐙Docker Compose Tip #2

Same compose.yml for dev/staging/prod:

docker compose --env-file .env.dev up
docker compose --env-file .env.prod up

No more copying env vars around. Each environment gets its own file.

More: lours.me/posts/compose-tip-002-env-files/

#Docker #DockerCompose
```

**💼 LinkedIn:**
```
🐳 🐙Docker Compose Tip #2: Environment files

One compose.yml, multiple environments. Here's what works:

docker compose --env-file .env.dev up     # Development
docker compose --env-file .env.prod up    # Production

Keep your environments separate:
- .env.dev for local development
- .env.staging for testing
- .env.prod for production

Layer them if needed:
docker compose --env-file .env.base --env-file .env.prod up

This setup saves hours of environment debugging.

Details: lours.me/posts/compose-tip-002-env-files/

#Docker #DockerCompose #DevOps
```

---

### Wednesday, Jan 7 - Service dependencies with health checks

**🦋 Bluesky:**
```
🐳 🐙Docker Compose Tip #3

"Connection refused" at startup? Stop using sleep 10.

depends_on:
  db:
    condition: service_healthy

Now your app waits for the database to actually be ready.

Examples: lours.me/posts/compose-tip-003-depends-on-healthcheck/

#Docker #DockerCompose
```

**💼 LinkedIn:**
```
🐳 🐙Docker Compose Tip #3: Health checks for dependencies

Connection refused errors? Your app starts before the database is ready.

Fix it properly:

```yaml
depends_on:
  db:
    condition: service_healthy
```

No more arbitrary sleep commands. The app waits until the database passes its health check.

Works with PostgreSQL, MySQL, Redis - any service with a health check.

Examples and patterns: lours.me/posts/compose-tip-003-depends-on-healthcheck/

#Docker #DockerCompose #DevOps
```

---

### Thursday, Jan 8 - Using SSH keys during build

**🦋 Bluesky:**
```
🐳 🐙Docker Compose Tip #4

Need private repos during build? Use SSH securely:

build:
  ssh:
    - default

RUN --mount=type=ssh \
    git clone git@github.com:private/repo.git

Keys never stored in image!

Guide: lours.me/posts/compose-tip-004-ssh-build/

#Docker #Security
```

**💼 LinkedIn:**
```
🐳 🐙Docker Compose Tip #4: SSH keys in builds

Accessing private repositories during Docker builds? Here's the secure way:

```yaml
services:
  app:
    build:
      ssh:
        - default  # Uses SSH agent
```

In Dockerfile:
```dockerfile
RUN --mount=type=ssh \
    git clone git@github.com:company/private-repo.git
```

Key points:
- SSH keys never stored in the image
- Only available during the specific RUN command
- BuildKit handles forwarding securely
- Works with git, npm, pip, any SSH-based tool

No more copying keys into images or complex token workarounds.

Full guide: lours.me/posts/compose-tip-004-ssh-build/

#Docker #DockerCompose #Security #DevOps
```

---

### Friday, Jan 9 - Writing Compose files for AI tools

**🦋 Bluesky:**
```
🐳 🐙Docker Compose Tip #5

Help AI tools help you. Add comments:

# PostgreSQL with geographic data
db:
  image: postgis/postgis:15-3.3
  # WARNING: Check ./data ownership (1000:1000)

Future maintainers will appreciate it too.

Guide: lours.me/posts/compose-tip-005-ai-documentation/

#Docker #AI
```

**💼 LinkedIn:**
```
🐳 🐙Docker Compose Tip #5: Documentation for AI tools

AI assistants work better when they understand your setup.

Add context:
```yaml
# Primary API - handles auth and rate limiting
# Needs: db (PostgreSQL), redis (sessions)
api:
  image: myapi:latest
  environment:
    JWT_SECRET: ${JWT_SECRET:?Required}  # Min 256 bits
```

With good comments, AI can:
• Write relevant health checks
• Spot security issues
• Generate CI/CD configs
• Suggest improvements

Makes a real difference when working with Copilot or Claude.

Patterns: lours.me/posts/compose-tip-005-ai-documentation/

#Docker #DockerCompose #AI #DevTools
```

---

## Posting Schedule & Strategy

### Timing
- **Post at 9:00 AM CET** (peak European work hours)
- **Cross-post immediately** on both platforms

### Hashtags
**Bluesky**: Keep it minimal (2-4 tags)
- Always: #Docker #DockerCompose
- Rotate: #DevOps #DevTools #Performance

**LinkedIn**: More comprehensive (5-8 tags)
- Always: #Docker #DockerCompose #DevOps
- Add relevant: #SoftwareEngineering #CICD #BestPractices #Microservices

### Engagement Tips
1. **Reply to comments** within first 2 hours
2. **Share in relevant communities**:
   - LinkedIn: Docker groups, DevOps communities
   - Bluesky: Tech feeds, Docker community
3. **Pin the week's overview** on Monday
4. **Thread related tips** for better visibility

### Analytics to Track
- Engagement rate per platform
- Click-through to blog
- Most popular tip of the week
- Best performing hashtags

---

## Week 2 (Jan 13-17, 2026) - Mixed Themes

---

### Monday, Jan 13 - Service discovery and internal DNS

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #6

No more hardcoded IPs. Services find each other by name:

web:
  environment:
    DB_HOST: postgres  # Just the service name

Compose handles the DNS. Zero config needed.

Details: lours.me/posts/compose-tip-006-service-discovery/

#Docker #DockerCompose
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #6: Service discovery and internal DNS

Stop hardcoding IPs. Compose gives each service a DNS name automatically.

```yaml
services:
  web:
    environment:
      API_URL: http://api:3000  # 'api' resolves to the right container

  api:
    image: myapi:latest
```

No configuration needed. It just works.

DNS updates when containers restart, handles scaling, everything.

Check it: docker compose exec web nslookup api

More: lours.me/posts/compose-tip-006-service-discovery/

#Docker #DockerCompose #Networking #DevOps
```

---

### Tuesday, Jan 14 - Restarting single services

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #7

Need to restart just one service? Keep the rest running:

docker compose up -d web

Updates and restarts ONLY the web service. Database stays up, no data loss.

Perfect for code changes without full stack restart!

Guide: lours.me/posts/compose-tip-007-restart-single/

#Docker #DockerCompose
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #7: Restart single services without stopping the stack

Stop doing `docker compose down && docker compose up` for every change!

Restart just what you need:
```bash
# Restart only the web service
docker compose up -d web

# Force recreate with new image
docker compose up -d --force-recreate api

# Rebuild and restart
docker compose up -d --build worker
```

Your database stays running, Redis keeps its cache, queues don't lose messages.

This simple pattern saves hours of waiting for services to reinitialize during development.

Real-world example: Updating API code while keeping PostgreSQL, Redis, and RabbitMQ running. Development time cut by 70%.

Full guide: lours.me/posts/compose-tip-007-restart-single/

#Docker #DockerCompose #DeveloperProductivity #DevOps
```

---

### Wednesday, Jan 15 - Healthchecks with Docker Hardened Images

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #8

DHI images = max security. But no curl for healthchecks!

Solution: Secure sidecar
app-health:
  image: dhi.io/curl:8-debian13-dev
  network_mode: "service:app"

Shares network namespace → localhost works!

Guide: lours.me/posts/compose-tip-008-dhi-healthcheck/

#Docker #Security
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #8: Healthchecks with Docker Hardened Images

Docker Hardened Images (DHI) maximize security but lack shells and curl. Solution: secure sidecar with shared network namespace.

```yaml
app:
  image: dhi.io/node:25-debian13-sfw-ent-dev
  ports:
    - "3000:3000"

app-health:
  image: dhi.io/curl:8-debian13-dev
  network_mode: "service:app"  # Shares app's network!
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
```

Key insight: `network_mode: "service:app"` lets the sidecar access localhost directly.

Benefits:
🔒 Both containers use DHI - maximum security
🎯 Sidecar sees only app's network
📊 Full observability maintained
🚀 Pattern works in Kubernetes too

Real impact: Zero shell access in production while keeping healthchecks.

Full guide: lours.me/posts/compose-tip-008-dhi-healthcheck/

#Docker #DockerCompose #Security #DHI #DevSecOps
```

---

### Thursday, Jan 16 - Publishing Compose applications as OCI artifacts

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #9

Publish Compose apps as OCI artifacts!

docker compose publish myapp:v1

Users run with one command:
docker compose -f oci://docker.io/myapp:v1 up

No git clone, no README. Just run.

Guide: lours.me/posts/compose-tip-009-oci-artifacts/

#Docker #OCI
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #9: Publishing Compose applications as OCI artifacts

Package and distribute entire Compose applications through container registries!

```bash
# Publish your compose.yml as OCI artifact
docker compose publish mycompany/app:v1.0

# Users run directly from registry
docker compose -f oci://docker.io/mycompany/app:v1.0 up
```

The compose.yml is stored as an OCI artifact alongside your images.

Key features:
📦 Compose config stored in registry
🚀 One command deployment
🔒 Registry authentication & scanning
📌 Pin images with --resolve-image-digests

Perfect for:
• Demo applications
• Internal tool distribution
• Development environments
• Customer deployments

Requires Docker Compose 2.34.0+

This transforms app distribution - from complex READMEs to single commands.

Complete guide: lours.me/posts/compose-tip-009-oci-artifacts/

#Docker #DockerCompose #OCI #CloudNative #DevOps
```

---

### Friday, Jan 17 - Using init: true for proper PID 1 handling

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #10

Zombie processes? Signals not working?

services:
  app:
    init: true

Adds tiny init system (Tini) as PID 1. Handles signals properly, reaps zombies.

Essential for Node.js, Python apps!

Details: lours.me/posts/compose-tip-010-init-pid1/

#Docker #BestPractices
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #10: Proper PID 1 handling with init

Your app shouldn't run as PID 1 in a container. Here's why and how to fix it:

```yaml
services:
  app:
    image: node:20
    init: true  # Adds Tini as PID 1
    command: node server.js
```

What it solves:
🧟 Zombie process reaping
📡 Proper signal forwarding (SIGTERM, SIGINT)
🛑 Clean shutdowns
⚡ Faster container stops

Without init:
• Your app becomes PID 1
• Must handle UNIX signals properly
• Must reap zombie processes
• Many runtimes (Node.js, Python) don't do this well

Real impact:
• Graceful shutdowns in Kubernetes
• No more 10-second waits on docker stop
• Zero zombie processes in long-running containers

Essential for production, especially with interpreted languages.

Full explanation: lours.me/posts/compose-tip-010-init-pid1/

#Docker #DockerCompose #ProcessManagement #BestPractices #Production
```