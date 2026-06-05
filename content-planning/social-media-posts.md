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
