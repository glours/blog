---
title: "Docker Compose Tip #4: Using SSH keys during build"
date: 2026-01-08T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "build", "security"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to securely use SSH keys in Docker builds for private repositories"
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

Need to access private Git repositories during build? Here's how to do it securely with SSH.

## The setup

Enable SSH forwarding in your compose.yml:

```yaml
services:
  app:
    build:
      context: .
      ssh:
        - default  # Uses your default SSH agent
```

Or use specific keys for different services:

```yaml
services:
  app:
    build:
      context: .
      ssh:
        - github=/home/user/.ssh/github_key  # Custom key for GitHub
        - gitlab=/home/user/.ssh/gitlab_key  # Different key for GitLab
```

## The Dockerfile

Use BuildKit's SSH mount to clone private repos:

```dockerfile
# syntax=docker/dockerfile:1
FROM node:20

# Using default SSH key
RUN --mount=type=ssh \
    git clone git@github.com:mycompany/private-lib.git /tmp/lib && \
    cd /tmp/lib && npm install && npm run build && \
    cp -r dist /app/vendor/

# Using a specific key ID
RUN --mount=type=ssh,id=github \
    git clone git@github.com:mycompany/private-package.git /tmp/package

# Different key for GitLab
RUN --mount=type=ssh,id=gitlab \
    git clone git@gitlab.com:mycompany/internal-tool.git /tmp/tool
```

## Building with SSH

Make sure your SSH agent is running:

```bash
# Start SSH agent if needed
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa

# Build with SSH forwarding
docker compose build --ssh default
```

## CI/CD setup

For GitHub Actions or similar:

```yaml
services:
  app:
    build:
      context: .
      ssh:
        - default=${{ secrets.SSH_KEY }}
```

## Security notes

- SSH keys are **never** stored in the image
- They're only available during the RUN command with `--mount=type=ssh`
- No secrets leak into your final container
- BuildKit handles the SSH agent forwarding securely

## Common issues

**"Could not read from remote repository"**

Make sure the host is in known_hosts:
```dockerfile
RUN --mount=type=ssh \
    mkdir -p ~/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts && \
    git clone git@github.com:mycompany/repo.git
```

**"SSH agent not available"**

On macOS, the SSH agent should work automatically. On Linux:
```bash
docker compose build --ssh default=$SSH_AUTH_SOCK
```

## Why this matters

No more:
- Copying SSH keys into images (security risk!)
- Building everything publicly
- Complex workarounds with access tokens

Just secure, straightforward access to private dependencies during build.