---
title: "Compose Secrets Deep Dive: Providers, Persistence, and the Last Mile"
date: 2026-09-01T09:00:00+02:00
draft: false
tags: ["docker-compose", "docker", "secrets", "security", "password-manager", "vault", "deep-dive", "advanced"]
categories: ["Compose Deep Dive"]
author: "Guillaume Lours"
showToc: true
TocOpen: false
hidemeta: false
comments: false
description: "What happens between a password manager and a Compose service: runtime providers, tmpfs files, container layers, and application delivery."
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

Compose makes secret delivery look settled. Declare a top-level secret, grant a service access to it, and the value appears under `/run/secrets/`. The interface is simple; the storage and delivery path behind it are not.

Outside Swarm, a file-backed Compose secret is a bind mount. A secret sourced from the host environment follows a different path and, with current Compose versions, ends up in the container's writable layer. Both appear under `/run/secrets`, but they leave different traces on the host and behave differently when someone runs `docker commit`. The path alone says nothing about whether the value lives in a `tmpfs`.

That distinction matters when the credential is already stored safely. A database password or API key can begin in a password manager with scoped access and an audit trail, then accumulate unmanaged copies as deployment tooling moves it through a shell, an environment variable, a temporary file, the container configuration, or its writable filesystem.

Tip [#22](/posts/compose-tip-022-secrets/) covers how to declare Compose secrets. This deep dive focuses on that last mile: how a long-lived runtime credential gets from an existing password manager or secrets manager into a local Compose service, what each option leaves behind, and which component should resolve the plaintext. Build-time secrets are a separate lifecycle; one-off commands are covered later because they need fewer persistence guarantees.

Take a password manager CLI that can return one field:

```console
$ op read op://Infra/prod-db/password
sup3rSecretValue
```

`op` is 1Password's CLI, but the same shape applies to HashiCorp Vault, OpenBao, Bitwarden, AWS Secrets Manager, and internal stores. The command is not the interesting part. The question is what happens after it prints the value.

The goal cannot be to hide a credential from the application that uses it. The process must eventually hold the value or an identity that grants equivalent access. The useful goal is to keep the plaintext out of Git, image metadata, container configuration, persistent host storage, command-line arguments, and accidental snapshots for as long as the platform allows.

There is no single Compose feature that satisfies every one of those properties. The preference order starts with a provider that resolves a reference at runtime, then works down through the compromises available when Compose has to materialize the value itself.

## Start by ruling out `environment:` and `env_file:`

A service-level environment variable is the most common way a credential reaches a container. The value might be written directly under `environment:`, interpolated from the shell or the project `.env` file, or loaded through `env_file:`. Those inputs play different roles in Compose, but once they populate a service environment, the resulting container configuration is the same.

The project `.env` file is not injected automatically. Compose uses it for interpolation, so a declaration such as `DATABASE_PASSWORD: ${DATABASE_PASSWORD}` copies the resolved value into the service environment. An `env_file:` entry skips that interpolation step and adds its entries to the service environment directly:

```yaml
services:
  api:
    image: myapp:1.4
    env_file:
      - .env
```

Either route leaves the plaintext in `Config.Env`:

```console
$ docker inspect api-1 --format '{{.Config.Env}}'
[DATABASE_PASSWORD=sup3rSecretValue PATH=/usr/local/sbin:...]

$ docker commit api-1 api-snapshot
$ docker inspect api-snapshot --format '{{.Config.Env}}'
[DATABASE_PASSWORD=sup3rSecretValue PATH=/usr/local/sbin:...]
```

`docker commit` is often used to preserve a debugging session or share a broken container. Environment-based credentials turn that snapshot into an image carrying the secret in its configuration, regardless of whether the original value came from the shell, `environment:`, `.env`, or `env_file:`.

A plaintext file adds another exposure outside the container. `.gitignore` can prevent an untracked `.env` file from entering the next commit, but it does not protect copied project directories, backups, support archives, or values already present in Git history. A password manager reference avoids that long-lived local copy, but only if the next delivery step does not immediately turn it back into a regular service environment variable.

## Best case: let a provider resolve a reference

A secret provider changes what travels through the deployment configuration. Instead of passing the credential, the configuration passes a reference:

```text
reference in configuration
        ↓
authenticated provider
        ↓
password manager or vault
        ↓
runtime delivery
```

The provider can be a runtime integration, an agent running next to the application, a plugin supplied by the password manager, or a custom adapter for an internal secrets service. The implementation matters less than the contract:

- The repository contains a reference, never the plaintext.
- The password manager remains the source of truth.
- The provider authenticates with an identity scoped to the required secrets.
- Resolution happens when the workload starts or when it needs the value.
- Rotation and access revocation stay with the system that owns the credential.

[Docker Secrets Engine](https://github.com/docker/secrets-engine) is one implementation of this model. It resolves `se://` references at container startup through provider plugins:

```yaml
services:
  api:
    image: myapp:1.4
    environment:
      DATABASE_PASSWORD: se://docker/db/prod/password
```

The Compose file carries the reference, not the password. Docker Secrets Engine is bundled with Docker Desktop; its Docker CE integration requires `dockerd` 29.2.0 or higher and is explicitly experimental — the project's own README says outright: "Do not rely on it for production workloads yet." It is an example of the architecture worth adopting once that changes, not something to point a CE production host at today.

Agents follow the same model with a different last mile. An agent authenticates to the vault, fetches or renews the credential, and renders it into a file or exposes it through a local API. Applications with native SDK support can also resolve references themselves. That works particularly well with workload identities and short-lived credentials, but it couples the application to the provider and raises the first question every provider design must answer: how does the workload authenticate before it has any secret?

That bootstrap credential — sometimes called the *secret zero* — is where a provider either earns or loses its value. A cloud workload identity, client certificate, hardware-backed identity, or tightly-scoped runtime integration can establish trust without another static password in Compose. Replacing the database password with a long-lived vault token in `environment:`, on the other hand, only moves the problem and may increase the blast radius.

A provider is not automatically safe either. Some inject the resolved value into the process environment, some render a file, and some return it directly to application memory. Check the last mile with the same tools used for every option below: `docker inspect`, `docker diff`, `docker commit`, the host filesystem, and `/proc/<pid>/environ`. Also test restarts while the provider is unavailable. A secure resolution path that prevents a service from recovering after a host reboot may still be the wrong operational trade-off.

When a suitable provider is available, it is the preferred design. The remaining options are fallbacks for environments where Compose still has to materialize the value itself.

## Stable fallback on Linux: render a file under `tmpfs`

Compose secrets sourced from a file are bind mounts outside Swarm. That becomes useful when the source file itself lives on an in-memory host filesystem such as `/run`:

```console
$ secret_dir="${XDG_RUNTIME_DIR:?}/compose-secrets/api"
$ install -d -m 0700 "$secret_dir"
$ umask 077
$ op read op://Infra/prod-db/password \
    > "$secret_dir/db_password"
$ docker compose up -d
```

```yaml
services:
  api:
    image: myapp:1.4
    environment:
      DATABASE_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password

secrets:
  db_password:
    file: ${XDG_RUNTIME_DIR}/compose-secrets/api/db_password
```

This keeps the password manager as the source of truth and avoids persistent host storage. The secret is absent from `Config.Env`, apart from the non-sensitive `_FILE` path, and the bind-mounted content is excluded from `docker commit`:

```console
$ docker inspect api-1 --format '{{.Config.Env}}'
[DATABASE_PASSWORD_FILE=/run/secrets/db_password PATH=/usr/local/sbin:...]

$ docker inspect api-1 --format '{{json .Mounts}}'
[{"Type":"bind","Source":"/run/user/1000/compose-secrets/api/db_password","Destination":"/run/secrets/db_password",...}]
```

The trade-off is lifecycle management. The source file must remain present for as long as the container needs the mount. Removing it immediately after `up` isn't a safe shortcut either: Docker Desktop's file-sharing layer invalidates the secret right away, and relying on a native Linux bind mount to behave differently isn't a portable assumption. Because `/run` is normally cleared at boot, deployment automation must fetch the value again before Docker recreates or restarts the service. This pattern is therefore a good fit for a managed Linux host, but not a portable assumption for Docker Desktop or an unattended server — which may also have no boot-time access to the password manager, and, without an active `systemd-logind` session, no guaranteed `XDG_RUNTIME_DIR` to render into at all.

File permissions also come from the source. Compose cannot apply `uid`, `gid`, or `mode` to a file-backed secret because the bind mount preserves the host file's ownership and permissions. Create the directory with restrictive access and set the file mode at render time.

## No host file: an environment-sourced Compose secret

Compose can source a secret from the environment of the Compose process:

```yaml
services:
  api:
    image: myapp:1.4
    secrets:
      - db_password

secrets:
  db_password:
    environment: DATABASE_PASSWORD
```

Fetch it for one invocation without exporting it into the calling shell:

```console
$ DATABASE_PASSWORD="$(op read op://Infra/prod-db/password)" \
    docker compose up -d
```

This avoids both a persistent shell variable and a source file on the host. It also keeps the value out of the container's configured environment:

```console
$ docker inspect api-1 --format '{{.Config.Env}}'
[PATH=/usr/local/sbin:...]

$ docker inspect api-1 --format '{{json .Mounts}}'
[]
```

The empty mount list reveals the counter-intuitive cost. With current Docker Compose outside Swarm, the environment-sourced secret is materialized in the container's writable layer, not mounted into a `tmpfs`. `docker diff` reports the file, and `docker commit` captures it:

```console
$ docker diff api-1
C /run
A /run/secrets
A /run/secrets/db_password

$ docker commit api-1 api-snapshot
$ docker run --rm api-snapshot cat /run/secrets/db_password
sup3rSecretValue
```

This is different from Docker Swarm secrets, which are mounted into an in-memory filesystem. Using the same `secrets:` syntax does not give local Compose the same storage implementation.

The environment-sourced form is still useful when creating any host file is unacceptable and `docker commit` is prohibited by policy. It is not a universal first choice: it exchanges host-file exposure for snapshot exposure.

## Prefer file-aware applications

Whichever source created `/run/secrets/db_password`, let the application read that file directly when possible. Many official images support the `_FILE` convention, including `POSTGRES_PASSWORD_FILE` and `MYSQL_ROOT_PASSWORD_FILE`:

```yaml
services:
  database:
    image: postgres:18
    environment:
      POSTGRES_USER: app
      POSTGRES_DB: app
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password

secrets:
  db_password:
    file: ${XDG_RUNTIME_DIR}/compose-secrets/api/db_password
```

The path is safe to expose in `Config.Env`. The password stays in the mounted file and in whatever application memory PostgreSQL uses after reading it; it does not automatically become part of the process environment.

## Last resort: the application only accepts the value

When an application requires `DATABASE_PASSWORD` rather than a file path, an entrypoint wrapper can read the Compose secret after container creation:

```sh
#!/bin/sh
export DATABASE_PASSWORD="$(cat /run/secrets/db_password)"
exec "$@"
```

```yaml
services:
  api:
    image: myapp:1.4
    entrypoint: ["/entrypoint-with-secrets.sh"]
    command: ["node", "server.js"]
    secrets:
      - db_password

secrets:
  db_password:
    file: ${XDG_RUNTIME_DIR}/compose-secrets/api/db_password
```

The exported value is absent from `Config.Env` because the wrapper creates it after the container starts. It is, however, present in the environment of the real application process and can be observed through `/proc/<pid>/environ` by sufficiently privileged users. This is a property of this wrapper, not of applications that read `_FILE` directly.

The wrapper also becomes part of the application's startup contract. It must preserve signals with `exec`, avoid `set -x`, never log the value, and handle missing or empty files explicitly if the application cannot do so itself.

## One-off commands need less persistence

A migration or rotation command does not need the service to retain a credential for its entire lifetime. `docker compose exec` can pass a value to one new process without changing the existing container configuration or filesystem:

```console
$ DATABASE_PASSWORD="$(op read op://Infra/prod-db/password)" \
    docker compose exec -e DATABASE_PASSWORD api ./scripts/migrate.sh
```

Pass only the variable name to `-e`, as above. Writing `-e DATABASE_PASSWORD=sup3rSecretValue` puts the value into the Compose CLI arguments, where host process listings can expose it. The called process still receives the credential in its environment, but `docker inspect`, `docker diff`, and `docker commit` on the existing container remain unchanged unless the command itself writes the value somewhere.

## Where encrypted secrets in Git fit

Some deployment tools encrypt secret values before committing them, then decrypt them on an authorized machine during deployment. That is a valid design when Git must also support offline deployment or disaster recovery without access to a password manager. It does not put plaintext in the repository, but it does introduce another decryption identity, access policy, and rotation procedure. The ciphertext also remains in every clone and in the repository history. When a password manager is already reachable at deployment time, keep one source of truth unless that encrypted copy provides a deliberate operational benefit.

## What none of these options protects against

None of these paths protects a live service from an attacker who has equivalent control over that service. Access to the Docker daemon is enough to start privileged containers, copy mounted files, or execute commands in running containers. Host root can inspect process memory and environments. A compromised application can use any credential it legitimately holds, whether it arrived through a provider, a file, or an environment variable.

Providers introduce their own failure modes too. An identity with access to an entire vault can be more damaging than one static database password. Scope it to the smallest useful set of paths, make tokens short-lived where possible, keep resolution out of logs, and test what happens when the provider or network is unavailable.

The delivery mechanism reduces accidental persistence and limits blast radius. It does not turn a compromised runtime into a trusted one.

## Conclusion: references first, values only at the edge

When a password manager is already the source of truth, keep it that way. Prefer a provider that resolves references at runtime, using a workload identity scoped to the application. If the platform cannot do that reliably, render a file under a host `tmpfs` and expose it as a file-backed Compose secret. Use `secrets.environment` when avoiding a host file matters more than protection against container snapshots, and export the value inside an entrypoint only when the application leaves no file-based option.

Never commit a plaintext secret. Commit an encrypted one only when the repository genuinely needs to support offline deployment or recovery and the decryption-key lifecycle is deliberately managed.

There is no golden Compose syntax here. The useful question is always the same: where does the plaintext exist, for how long, who can retrieve it again, and what survives after the container stops?

## Further reading

- [Compose secrets documentation](https://docs.docker.com/compose/use-secrets/)
- [Docker Secrets Engine](https://github.com/docker/secrets-engine)
- [Docker Swarm secrets](https://docs.docker.com/engine/swarm/secrets/)
- [1Password CLI secret references](https://developer.1password.com/docs/cli/secret-references/)
- Related: [Tip #22, Using secrets in Compose files](/posts/compose-tip-022-secrets/)
- Related: [Tip #64, `docker compose cp`](/posts/compose-tip-064-compose-cp/)
