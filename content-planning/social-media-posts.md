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
