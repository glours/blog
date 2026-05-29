---
title: "Compose Bridge Deep Dive #72 — Part 3: Generating a Docker Model Runner app for Kubernetes"
date: 2026-06-05T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "compose-bridge", "kubernetes", "ai", "llm", "model-runner", "deep-dive", "advanced"]
categories: ["Compose Deep Dive"]
author: "Guillaume Lours"
showToc: true
TocOpen: false
hidemeta: false
comments: false
description: "Deploy a Compose file that declares LLMs to Kubernetes — either with the Docker Desktop host Model Runner or as a standalone in-cluster service — using Compose Bridge."
disableShare: false
disableHLJS: false
hideSummary: false
searchHidden: false
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: false
UseHugoToc: false
---

A Compose file with a `models:` section runs an AI application out of the box on a laptop. Shipping the same stack to Kubernetes used to mean writing the model server's Deployment, Service, ConfigMap, and PVC by hand, and remembering to point your application's environment variables at the right place. Compose Bridge now does that for you, in two distinct topologies.

This is the final post of the [Compose Bridge Deep Dive](/posts/compose-bridge-deep-dive-070-introduction/) series. Parts [1](/posts/compose-bridge-deep-dive-070-introduction/) and [2](/posts/compose-bridge-deep-dive-071-custom-transformers/) covered the fundamentals and customization. This one focuses on a concrete, end-to-end scenario built on top of the new model-runner support in the default transformers.

## Starting point: a Compose file with `models:`

The `models:` top-level key ([Tip #60](/posts/compose-tip-060-models-section/)) declares LLMs as first-class citizens. The same file works locally with `docker compose up` and on the cluster after running it through Compose Bridge:

```yaml
models:
  chat:
    model: ai/qwen2.5

services:
  web:
    build: ./web
    ports:
      - "8080:8080"
    models:
      chat:
        endpoint_var: OPENAI_BASE_URL
        model_var: OPENAI_MODEL
```

Locally, Docker Desktop's host Model Runner serves the model and Compose injects `OPENAI_BASE_URL` into the `web` container. The application code uses any OpenAI-compatible client. So far so familiar.

## Two topologies for the same Compose file

Once Kubernetes enters the picture, there are two reasonable ways to expose the model to application pods. Compose Bridge supports both.

**Topology 1 — Host Model Runner (Docker Desktop only).**
Pods point at the Model Runner that runs on the host alongside Docker Desktop. No model pod inside the cluster, no GPU contention, fastest cold-start. The trade-off is that this only works on Docker Desktop's embedded Kubernetes cluster.

**Topology 2 — In-cluster Model Runner (standalone Kubernetes).**
A `docker/model-runner` Deployment runs inside the cluster, a `ClusterIP` Service exposes it as `docker-model-runner`, a PersistentVolumeClaim holds the model weights, and a ConfigMap drives the model pre-pull. Pods talk to the in-cluster service. This works on any Kubernetes cluster.

The same Compose file produces both layouts — only the conversion target changes.

## Topology 2 with the Kustomize transformer

The default transformer ships a `model-runner` overlay that adds everything needed to run the model server inside the cluster. Convert and apply:

```bash
docker compose bridge convert
kubectl apply -k out/overlays/model-runner/
```

The resulting tree:

```
out/
├── base/
│   ├── web-deployment.yaml          # env vars point to docker-model-runner
│   ├── web-service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── desktop/
    └── model-runner/
        ├── kustomization.yaml
        ├── model-runner-deployment.yaml
        ├── model-runner-service.yaml
        ├── model-runner-configmap.yaml
        └── model-runner-volume-claim.yaml
```

What gets deployed when the overlay is applied:

- A **Deployment** named `docker-model-runner` running `docker/model-runner:latest`, listening on port `12434`. An init container fixes permissions on `/models`; a sidecar (`model-init`) pre-pulls the models listed in the ConfigMap by hitting the runtime's `/models/create` endpoint.
- A **ClusterIP Service** named `docker-model-runner` exposing port `80` and forwarding to `12434`. This is the hostname application pods talk to.
- A **ConfigMap** named `docker-model-runner-init` containing the model list pulled from the Compose `models:` section. Adding a model is a Compose-file change, nothing else.
- A **PersistentVolumeClaim** for `/models`, so the downloaded weights survive pod restarts.

The application Deployments generated for each service have their environment variables pre-wired to the in-cluster Service:

```yaml
env:
  - name: OPENAI_BASE_URL
    value: "http://docker-model-runner/engines/v1/"
  - name: OPENAI_MODEL
    value: "ai/qwen2.5"
```

Liveness and readiness probes hit `/engines/status` on the Model Runner pod, so Kubernetes only routes traffic once the model is actually loaded.

## Topology 1 with the Helm transformer

The Helm transformer wraps the same logic in a single chart with a `modelRunner.enabled` toggle. Generate it once:

```bash
docker compose bridge convert --transformation docker/compose-bridge-helm
```

Then install for either topology without regenerating:

```bash
# In-cluster Model Runner (works on any cluster)
helm install myapp ./out --set modelRunner.enabled=true

# Docker Desktop host Model Runner (Desktop only)
helm install myapp ./out --set modelRunner.enabled=false
```

When `modelRunner.enabled=true`, the chart deploys the Model Runner Deployment, Service, ConfigMap, and PVC, exactly like the Kustomize overlay. When `modelRunner.enabled=false`, those resources are skipped entirely; the application Deployment is generated with `OPENAI_BASE_URL=http://host.docker.internal:12434/engines/v1/` instead, which is how Docker Desktop's host Model Runner is reachable from pods running on its Kubernetes cluster.

One artefact, one toggle, two runtime topologies. Pick the in-cluster mode for shared environments, pick the host mode for local Kubernetes sandboxing.

## Walking through what happens at deploy time

For the in-cluster mode:

1. Apply the manifests. Kubernetes creates the PVC, the ConfigMap, the Model Runner Service, the Model Runner Deployment, and the application Deployments.
2. The Model Runner pod starts. The init container chmods `/models`. The main container starts the runtime on port `12434`. The `model-init` sidecar reads the model list from the ConfigMap and calls the runtime's `/models/create` for each entry. The first pull is the slow part; once weights are on the PVC, subsequent restarts are fast.
3. The readiness probe stays red until the runtime answers on `/engines/status`. The Service does not route traffic to a pod that is not ready, so application pods see no transient `Connection refused`.
4. Application pods start. Their environment variables point at `http://docker-model-runner/engines/v1/`. Any OpenAI-compatible client just works.

For the host mode (Docker Desktop):

1. Apply the manifests. Only the application Deployments and Services exist on the cluster.
2. Application pods start with `OPENAI_BASE_URL=http://host.docker.internal:12434/engines/v1/`. The Model Runner is the one that Docker Desktop already manages on the host, so there is no warm-up cost on the cluster side.

## Production considerations

A few things to think about before pointing this at a real cluster:

- **Storage**: the PVC needs a `StorageClass` that fits the cluster. The default chart leaves it implicit; override `model-runner-volume-claim.yaml` (Kustomize) or set `modelRunner.storage.className` (Helm) to pin it.
- **GPU**: the templates leave commented hints for `nvidia.com/gpu` resources and `accelerator` node selectors. Uncomment them when targeting a cluster that has the NVIDIA or AMD device plugin installed.
- **Sharing**: the default PVC is `ReadWriteOnce`. Scaling the Model Runner Deployment beyond one replica requires either `ReadWriteMany` or per-replica storage.
- **Resources**: the defaults (100m–1000m CPU, 256Mi–2Gi memory) are a starting point. Real models, especially without GPU offload, will need more. Tune via `deploy.resources` on the model in Compose, or directly in the chart values.
- **Pre-pull time**: the first deploy is bottlenecked on the model download. For large models, consider seeding the PVC out of band (a Job, a baked image, or a snapshot) before the first rollout.

## Wrapping up the series

Three posts, one tool. Part 1 introduced Compose Bridge and the transformer concept. Part 2 showed how to plug your own rules in via custom transformers and `x-*` extensions. Part 3 used the new model-runner overlay to ship an AI application to Kubernetes in two different topologies — same Compose file, two real production layouts, no manual YAML.

A Compose file remains the smallest accurate description of an application. Compose Bridge keeps that property all the way to production.

## Further reading

- [Compose Bridge documentation](https://docs.docker.com/compose/bridge/)
- [Docker Model Runner](https://docs.docker.com/ai/model-runner/)
- [Default transformer templates on GitHub](https://github.com/docker/compose-bridge-transformer)
- Related: [Declaring LLMs with the Compose `models` section](/posts/compose-tip-060-models-section/)
- Previous: [Compose Bridge Deep Dive — Part 2: Custom transformers and `x-*` extensions](/posts/compose-bridge-deep-dive-071-custom-transformers/)
