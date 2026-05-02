---
title: "Docker Compose Tip #60: Declaring LLMs with the models section"
date: 2026-05-08T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "tips", "ai", "llm", "configuration", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Declare and connect LLMs to your services using the new Compose models top-level key"
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

LLMs are now first-class citizens in Compose. The `models` top-level key lets you declare which models your application needs and wire them into your services, all in the same Compose file.

## Basic usage

Declare a model at the top level, reference it from a service:

```yaml
models:
  smollm:
    model: ai/smollm2

services:
  app:
    image: myapp
    models:
      - smollm
```

When the stack starts, Compose ensures the model is available locally and connects the `app` service to it. The container receives endpoint information via environment variables.

## Default environment variables

By default, Compose injects two environment variables for each connected model:

- `<MODEL_NAME>_URL`: the OpenAI-compatible endpoint URL
- `<MODEL_NAME>_MODEL`: the model identifier

For the example above, the container sees:

```
SMOLLM_URL=http://model-runner.docker.internal/engines/llama.cpp/v1/
SMOLLM_MODEL=ai/smollm2
```

Your code uses any standard OpenAI-compatible client to talk to it.

## Customizing the variable names

A common case: your code uses an official OpenAI client library, which reads the endpoint from `OPENAI_BASE_URL` by default. Override the injected variable names to match:

```yaml
models:
  smollm:
    model: ai/smollm2

services:
  app:
    image: myapp
    models:
      smollm:
        endpoint_var: OPENAI_BASE_URL
        model_var: OPENAI_MODEL
```

The container now sees `OPENAI_BASE_URL` and `OPENAI_MODEL`. Your existing code works with no changes:

```python
from openai import OpenAI

# Reads OPENAI_BASE_URL automatically
client = OpenAI(api_key="not-needed")
response = client.chat.completions.create(
    model=os.environ["OPENAI_MODEL"],
    messages=[{"role": "user", "content": "Hello!"}],
)
```

## Multiple models

Declare and connect to multiple models at once:

```yaml
models:
  chat:
    model: ai/smollm2
  embeddings:
    model: ai/granite-embedding-multilingual

services:
  api:
    image: myapp
    models:
      - chat
      - embeddings
```

Each model gets its own pair of environment variables.

## A practical RAG-style stack

Combining a chat model and an embedding model with a vector database:

```yaml
models:
  chat:
    model: ai/qwen2.5

  embeddings:
    model: ai/granite-embedding-multilingual

services:
  qdrant:
    image: qdrant/qdrant
    ports:
      - "6333:6333"

  api:
    build: ./api
    models:
      - chat
      - embeddings
    environment:
      QDRANT_URL: http://qdrant:6333
    depends_on:
      - qdrant
```

The API service has everything it needs: a chat model for generation, an embedding model for indexing, and a vector store, all declared in one Compose file.

## Why this matters

Before `models`, running an AI app meant juggling separate tools: a model server, environment variables for the endpoint, model lifecycle, and your application stack. With `models`, it's all in your `compose.yml` and starts with one `docker compose up`.

I covered this and other AI-related Compose features in detail at [Devoxx France 2026](/posts/devoxx-france-2026/), check the talk recording on YouTube once it's published.

## Further reading

- [Compose specification: models](https://docs.docker.com/reference/compose-file/models/)
- [Docker Model Runner](https://docs.docker.com/ai/model-runner/)
