# Social Media Posts for Docker Compose Tips

## Week 1 (Jan 6-10, 2025)

---

### Monday, Jan 6 - Debug your configuration with config

**🦋 Bluesky:**
```
🐳 Docker Compose Tip #1

Profiles confusing? Use docker compose config to debug.

docker compose --profile dev config --services

Shows ALL services that will run, including dependencies pulled in without the profile.

Details: lours.me/posts/compose-tip-001-validate-config/

#Docker #DockerCompose
```

**💼 LinkedIn:**
```
🐳 Docker Compose Tip #1: Debug complex configurations

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

### Tuesday, Jan 7 - Using --env-file for different environments

**🦋 Bluesky:**
```
🐳 Docker Compose Tip #2

Same compose.yml for dev/staging/prod:

docker compose --env-file .env.dev up
docker compose --env-file .env.prod up

No more copying env vars around. Each environment gets its own file.

More: lours.me/posts/compose-tip-002-env-files/

#Docker #DockerCompose
```

**💼 LinkedIn:**
```
🐳 Docker Compose Tip #2: Environment files

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

### Wednesday, Jan 8 - Service dependencies with health checks

**🦋 Bluesky:**
```
🐳 Docker Compose Tip #3

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
🐳 Docker Compose Tip #3: Health checks for dependencies

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

### Thursday, Jan 9 - Using SSH keys during build

**🦋 Bluesky:**
```
🐳 Docker Compose Tip #4

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
🐳 Docker Compose Tip #4: SSH keys in builds

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

### Friday, Jan 10 - Writing Compose files for AI tools

**🦋 Bluesky:**
```
🐳 Docker Compose Tip #5

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
🐳 Docker Compose Tip #5: Documentation for AI tools

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

## Week 2 (Jan 13-17, 2025) - Advanced Networking

---

### Monday, Jan 13 - Service discovery

**🦋 Bluesky:**
```
🐳 Docker Compose Tip #6

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
🐳 Docker Compose Tip #6: Service discovery

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

#Docker #DockerCompose #Networking
```

---

### Tuesday, Jan 14 - Connecting multiple projects

**🦋 Bluesky:**
```
🐳 Docker Compose Tip #7

Connect separate Compose projects with external networks:

docker network create shared
# Then use external: true in your compose files

Share databases, caches, anything between projects.

Guide: lours.me/posts/compose-tip-007-external-networks/

#Docker #DockerCompose
```

**💼 LinkedIn:**
```
🐳 Docker Compose Tip #7: External networks

Need multiple Compose projects to talk to each other?

```bash
docker network create shared-services
```

Then in each compose.yml:
```yaml
networks:
  default:
    external: true
    name: shared-services
```

Now your projects can share databases, caches, whatever you need.

Great for microservices or when you want to keep projects separate but connected.

Examples: lours.me/posts/compose-tip-007-external-networks/

#Docker #DockerCompose #Microservices
```

---

### Wednesday, Jan 15 - Port Publishing Strategies

**🦋 Bluesky:**
```
🐳 Docker Compose Tip #8: Master port publishing!

Short: "3000:3000"
Long:
  - target: 3000      # Container
    published: 3000   # Host
    protocol: tcp
    mode: host        # or ingress

Long syntax = more control! 🎯

Examples: lours.me/posts/compose-tip-008-port-publishing/

#Docker #DockerCompose
```

**💼 LinkedIn:**
```
🐳 Docker Compose Daily Tip #8: Port Publishing - Short vs Long Syntax

Not all port mappings are created equal. The long syntax gives you precise control over how services are exposed.

Short syntax (simple cases):
```yaml
ports:
  - "3000:3000"              # host:container
  - "127.0.0.1:8080:80"     # IP:host:container
```

Long syntax (production ready):
```yaml
ports:
  - target: 80          # Container port
    published: 8080     # Host port
    host_ip: 127.0.0.1 # Bind to specific interface
    protocol: tcp       # tcp or udp
    mode: host         # host or ingress (Swarm)
```

Why use long syntax?
🔒 Bind to localhost only (security)
🎛️ UDP support for specialized protocols
📊 Explicit protocol documentation
🌐 Swarm mode compatibility

Pro tip: Use `published: "8000-9000"` for port ranges in development.

Complete guide with security considerations: lours.me/posts/compose-tip-008-port-publishing/

#Docker #DockerCompose #Security #Networking #DevOps #BestPractices
```

---

### Thursday, Jan 16 - Network Aliases for Service Communication

**🦋 Bluesky:**
```
🐳 Docker Compose Tip #9: Network aliases = service flexibility!

db:
  networks:
    backend:
      aliases:
        - postgres
        - database
        - primary-db

Multiple names, one service. Perfect for legacy app migration! 🔄

Learn more: lours.me/posts/compose-tip-009-network-aliases/

#Docker #DockerCompose
```

**💼 LinkedIn:**
```
🐳 Docker Compose Daily Tip #9: Network Aliases for Flexible Service Discovery

Need a service accessible by multiple names? Network aliases let one container answer to many hostnames.

```yaml
services:
  db:
    image: postgres:15
    networks:
      backend:
        aliases:
          - postgres
          - postgresql
          - primary-database
          - legacy-db  # For backward compatibility

  app:
    image: myapp
    environment:
      # All these work!
      DB_URL: postgresql://legacy-db:5432/mydb
```

Perfect for:
🔄 Gradual migrations (old and new service names)
🏗️ Multi-tenant architectures
🔧 Protocol compatibility (mysql vs mariadb)
📚 Documentation-friendly naming

Real scenario: Migrating from MySQL to PostgreSQL? Add aliases for both during transition, allowing gradual service updates.

This pattern has saved countless hours during service migrations in production environments.

Full migration strategies: lours.me/posts/compose-tip-009-network-aliases/

#Docker #DockerCompose #Migration #Networking #DevOps #Architecture
```

---

### Friday, Jan 17 - Structuring Compose Files for AI Readability

**🦋 Bluesky:**
```
🐳 Docker Compose Tip #10: Structure for AI tools! 🤖

Group related services, use consistent naming:

# Frontend Services
web:
api:

# Data Layer
db:
cache:

AI understands context → better suggestions!

Template: lours.me/posts/compose-tip-010-ai-structure/

#Docker #AI #DevTools
```

**💼 LinkedIn:**
```
🐳 Docker Compose Daily Tip #10: Structuring Compose Files for AI Assistance

AI coding assistants are more effective when they understand your architecture. Here's how to structure Compose files for maximum AI comprehension.

Organizational patterns that work:
```yaml
# === Frontend Services ===
web:
  image: nginx:alpine
  # Serves React SPA, proxies to API

api:
  image: node:20
  # REST API, handles business logic

# === Data Layer ===
postgres:
  image: postgres:15
  # Primary datastore for user data

redis:
  image: redis:7
  # Session store and cache

# === Supporting Services ===
mailhog:
  image: mailhog/mailhog
  # Development email testing
```

AI tools can then:
🎯 Understand service relationships
🔧 Generate appropriate health checks
🚀 Suggest performance improvements
🔒 Identify security considerations
📝 Create accurate documentation

Clear structure = better AI suggestions = faster development.

When working with GitHub Copilot or Claude, this organization pattern consistently produces more relevant and accurate suggestions.

Complete AI collaboration guide: lours.me/posts/compose-tip-010-ai-structure/

#Docker #DockerCompose #AI #CodingAssistants #DeveloperProductivity #BestPractices
```