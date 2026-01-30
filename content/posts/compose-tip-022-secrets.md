---
title: "Docker Compose Tip #22: Using secrets in Compose files"
date: 2026-02-03T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "security", "secrets", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "How to securely manage passwords and API keys in Docker Compose"
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

Stop hardcoding passwords! Docker Compose secrets provide a secure way to handle sensitive data.

## Basic secret setup

Define secrets and use them in services:

```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    file: ./secrets/api_key.txt

services:
  app:
    image: myapp:latest
    secrets:
      - db_password
      - api_key
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password
      API_KEY_FILE: /run/secrets/api_key
```

Secrets appear as files in `/run/secrets/` inside containers.

## Reading secrets in your app

**Node.js example:**
```javascript
const fs = require('fs');

function getSecret(name) {
  try {
    return fs.readFileSync(`/run/secrets/${name}`, 'utf8').trim();
  } catch (err) {
    return process.env[name]; // Fallback for dev
  }
}

const dbPassword = getSecret('db_password');
```

**Python example:**
```python
def get_secret(name):
    try:
        with open(f'/run/secrets/{name}') as f:
            return f.read().strip()
    except FileNotFoundError:
        return os.environ.get(name)  # Fallback
```

## Environment variables as secrets

For development, use environment variables:

```yaml
secrets:
  db_password:
    environment: DB_PASSWORD
  api_key:
    environment: API_KEY

services:
  app:
    image: myapp
    secrets:
      - db_password
      - api_key
```

Run with:
```bash
DB_PASSWORD=secret API_KEY=key123 docker compose up
```

## Multiple environments

Use different secret sources per environment:

```yaml
# compose.yml (base)
services:
  app:
    image: myapp
    secrets:
      - db_password

# compose.dev.yml
secrets:
  db_password:
    environment: DB_PASSWORD

# compose.prod.yml
secrets:
  db_password:
    file: /secure/vault/db_password
```

## Secret permissions

Control access within containers:

```yaml
services:
  app:
    image: myapp
    secrets:
      - source: db_password
        target: database_password  # Rename in container
        uid: '1000'
        gid: '1000'
        mode: 0400  # Read-only for owner
```

## External secrets

Use secrets from Docker Swarm or external sources:

```yaml
secrets:
  db_password:
    external: true
    external_name: prod_db_password
```

## Common patterns

**Database connection:**
```yaml
services:
  postgres:
    image: postgres:15
    secrets:
      - postgres_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
```

**API keys:**
```yaml
services:
  api:
    image: api:latest
    secrets:
      - stripe_key
      - jwt_secret
    command: >
      sh -c "
      export STRIPE_KEY=$$(cat /run/secrets/stripe_key) &&
      export JWT_SECRET=$$(cat /run/secrets/jwt_secret) &&
      npm start"
```

## Pro tip
Never commit secrets. Always use `.gitignore` 😅.

## Further reading

- [Compose secrets specification](https://docs.docker.com/compose/use-secrets/)
- [Docker secrets management](https://docs.docker.com/engine/swarm/secrets/)