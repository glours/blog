# Docker Compose Tips - Social Media Posts - September 2026

## Special publication — Tuesday, September 1, 2026

This deep dive is published outside the regular Docker Compose Tips schedule. It follows a current discussion about how credentials should move from a password manager into a Compose service, without targeting or naming another article.

### Compose secrets runtime delivery deep dive

**🦋 Bluesky:**
```
🐳 🐙 Compose secret sources do not behave alike.

`secrets.file` → bind mount
`secrets.environment` → writable layer
Swarm → in-memory mount

Same `/run/secrets` path, different persistence.

Deep dive: lours.me/posts/compose-secrets-deep-dive-runtime-delivery/

#Docker #Security
```

**💼 LinkedIn:**
```
🐳 🐙 Compose Secrets Deep Dive: Providers, Persistence, and the Last Mile

A recent post about keeping Docker Compose credentials out of plaintext files made me revisit a broader question: what are the best ways to move a secret into a Compose service, given the platform's current limitations?

The answer depends on the starting point. If Git must support an offline deployment or disaster recovery, keeping an encrypted copy there can provide a useful operational property. But when the credential already lives in a password manager that is reachable during deployment, creating another copy — even an encrypted one — also creates another access policy, key lifecycle, and rotation path. In that situation, the password manager should remain the source of truth.

The next question is the last mile: how does the value reach the application without ending up in a regular environment variable, a persistent host file, the container configuration, or an accidental image snapshot?

One assumption did not survive testing: a file under `/run/secrets/` is not necessarily backed by memory. Swarm secrets use an in-memory mount, but local Compose materializes an environment-sourced secret in the container's writable layer. It stays out of `Config.Env` and avoids a host source file, but `docker commit` captures it.

Other paths make different trade-offs:

• `environment:` and `env_file:` put the plaintext in the container configuration
• `secrets.file` uses a bind mount, so `docker commit` excludes its content
• rendering that source file under a host tmpfs avoids persistent host storage on Linux
• a runtime provider can resolve a reference without putting the value in the Compose model
• `_FILE` support keeps the value out of the application environment
• a small entrypoint wrapper remains the fallback when the application only accepts the value itself

The password manager should remain the source of truth. The last mile is about choosing where plaintext is allowed to exist, how long it remains there, and what survives a container snapshot or host restart.

Full deep dive: lours.me/posts/compose-secrets-deep-dive-runtime-delivery/

#Docker #DockerCompose #Security #DevOps #SecretsManagement
```

---

## Week 26: September 7-11, 2026 - What changed over the break

Resuming after the summer break with tips grounded in real Compose changes from v5.2.0 through v5.5.1, released while the series was paused.

### Monday, September 7 - pre_start hooks and native init containers (Tip #82)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #82

pre_start: native init containers for Compose. Runs once, in its own container, before the service starts.

A failing step stays around for inspection now.

Guide: lours.me/posts/compose-tip-082-pre-start-init-containers/

#Docker #Runtime
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #82: pre_start hooks and native init containers

post_start and pre_stop (Tip #41) run a command inside the already-running service container. pre_start is different: since Compose 5.3, each step runs in its own ephemeral container, created after the service container exists but before it starts.

```yaml
services:
  api:
    build: .
    depends_on:
      db:
        condition: service_healthy
    pre_start:
      - image: myapp-migrate
        command: ["./migrate.sh", "up"]
```

Key facts:
• Waits on depends_on first, so a step can reach those services
• Defaults to the service's own image, set image: for different tooling
• Runs once for the service, not once per replica
• A failing step keeps its container around, output tail included in the error, for docker logs / docker inspect
• Ctrl-C while a step is running kills and removes it instead, no leftovers

Full guide: lours.me/posts/compose-tip-082-pre-start-init-containers/

#Docker #DockerCompose #Runtime #Configuration #DevOps
```

---

### Wednesday, September 9 - Why up recreated containers that never changed (Tip #83)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #83

Ever had `up` recreate a container that never changed?

Compose used to digest images differently per pull, build, or bake. Fixed in 5.5.0: one canonical digest, every path.

Guide: lours.me/posts/compose-tip-083-image-digest-reconciliation/

#Docker #Build
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #83: Why up recreated containers that never changed

A service recreates on every single docker compose up. No file change, no rebuild, nothing actually different about the image. Before Compose 5.5.0, that wasn't a flaky environment, it was a real bug class.

Compose decides whether to recreate a container by comparing the image's current identity against a label it recorded last time, com.docker.compose.image. Before 5.5.0, that identity was computed differently depending on how the image got there: a pull, the classic builder, buildx bake, or a local inspect could each produce a different kind of digest for the exact same image.

Where it showed up:
• A locally built image with provenance attestations enabled got a digest that changed on every rebuild
• A platform-pinned service could get resolved against the host's platform instead of its own
• Pulling the same tag for different platforms concurrently could record whichever pull finished last
• A type: image volume's mount source could stop resolving entirely once that digest value changed shape

5.5.0 introduces one canonical digest producer used by every path, and a single function writing the label. If a service has been recreating for no visible reason, upgrading is the fix, not a Compose file change.

Full guide: lours.me/posts/compose-tip-083-image-digest-reconciliation/

#Docker #DockerCompose #Build #DevOps
```

---

### Friday, September 11 - Lifecycle hooks now show you why they failed (Tip #84)

**🦋 Bluesky:**
```
🐳 🐙 Docker Compose Tip #84

A failing post_start / pre_stop / pre_start hook used to report only:

db hook exited with status 1

Since Compose 5.5.1, its output travels with the error too.

Guide: lours.me/posts/compose-tip-084-lifecycle-hook-output/

#Docker #Debugging
```

**💼 LinkedIn:**
```
🐳 🐙 Docker Compose Tip #84: Lifecycle hooks now show you why they failed

A failing lifecycle hook, post_start, pre_stop, or the new pre_start (Tip #82), used to report only its exit code. What it actually printed depended on how it ran: streamed live under a plain up but never carried into the error, or not attached at all under restart, run, or a library caller.

```yaml
services:
  api:
    build: .
    post_start:
      - command: ./migrate.sh
```

Since Compose 5.5.1, a failing hook's error reads like this instead:

db hook exited with status 1: SQLSTATE[42S02]: Base table or view not found

Key facts:
• Compose keeps the last 10 lines or 2 KiB of stdout and stderr, tracked separately
• The error prefers stderr, falls back to stdout
• Only on a non-zero exit, a passing hook is unchanged
• Captured whether or not a listener is attached

Gotcha: that output can carry secrets. A hook that prints a connection string or credential on failure now puts it in the error message too.

Full guide: lours.me/posts/compose-tip-084-lifecycle-hook-output/

#Docker #DockerCompose #Debugging #DevOps
```
