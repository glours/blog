---
title: "Docker Compose Tip #50: GPU support with deploy.resources"
date: 2026-04-08T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "runtime", "gpu", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Reserve and use GPU devices in your Compose services for ML, AI, and compute workloads"
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

Running ML models, video processing, or any GPU-accelerated workload? Compose lets you reserve GPU devices for specific services.

## Basic GPU access

Give a service access to all available GPUs:

```yaml
services:
  ml-training:
    image: pytorch/pytorch
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

## Limiting GPU count

Reserve a specific number of GPUs instead of all:

```yaml
services:
  inference:
    image: mymodel:latest
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

## Selecting specific GPUs by ID

Target specific GPU devices when you have multiple:

```yaml
services:
  training:
    image: pytorch/pytorch
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ["0", "1"]
              capabilities: [gpu]

  inference:
    image: mymodel:latest
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ["2"]
              capabilities: [gpu]
```

This lets you dedicate GPUs to different workloads on the same machine.

## Combining GPU with memory limits

For ML workloads, you often want to limit both GPU and system memory:

```yaml
services:
  training:
    image: pytorch/pytorch
    deploy:
      resources:
        reservations:
          memory: 8G
          devices:
            - driver: nvidia
              count: 2
              capabilities: [gpu]
        limits:
          memory: 16G
```

## A complete ML stack

```yaml
services:
  # Jupyter notebook with GPU
  notebook:
    image: jupyter/pytorch-notebook
    ports:
      - "8888:8888"
    volumes:
      - ./notebooks:/home/jovyan/work
      - model-data:/home/jovyan/models
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  # Model serving
  serving:
    image: mymodel-server:latest
    expose:
      - "8080"
    volumes:
      - model-data:/models:ro
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  # Standard API gateway — no GPU needed
  api:
    image: nginx
    ports:
      - "80:80"
    depends_on:
      - serving

volumes:
  model-data:
```

Only the services that need GPUs get them — the API gateway runs as a regular container without any GPU reservation.

## Pro tip

Check GPU availability inside a container:

```bash
# Verify GPU is accessible
docker compose exec training nvidia-smi

# Check CUDA version
docker compose exec training nvcc --version
```

## Further reading

- [Compose specification: devices](https://docs.docker.com/reference/compose-file/deploy/#devices)
- [GPU support in Docker](https://docs.docker.com/engine/containers/resource_constraints/#gpu)
