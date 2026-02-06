---
title: "Docker Compose Tip #29: Container capabilities and security options"
date: 2026-02-12T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "security", "capabilities", "advanced"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Fine-tune container security with Linux capabilities and security options"
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

Secure containers with principle of least privilege! Control exactly what your containers can do.

## Understanding capabilities

Linux capabilities break down root privileges into distinct units:

```yaml
services:
  # Drop all capabilities, then add only what's needed
  secure-app:
    image: myapp
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Bind to ports < 1024
      - CHOWN             # Change file ownership

  # Default Docker capabilities (for reference)
  default-app:
    image: myapp
    # Implicitly has: CHOWN, DAC_OVERRIDE, FSETID, FOWNER,
    # MKNOD, NET_RAW, SETGID, SETUID, SETFCAP, SETPCAP,
    # NET_BIND_SERVICE, SYS_CHROOT, KILL, AUDIT_WRITE
```

## Common capability patterns

**Web server (needs port 80/443):**
```yaml
services:
  nginx:
    image: nginx
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Bind to privileged ports
      - CHOWN             # Change file ownership
      - SETUID            # Switch users
      - SETGID            # Switch groups
    ports:
      - "80:80"
      - "443:443"
```

**Network tools:**
```yaml
services:
  tcpdump:
    image: tcpdump
    cap_drop:
      - ALL
    cap_add:
      - NET_RAW           # Raw socket access
      - NET_ADMIN         # Network configuration
    network_mode: host
```

**Time synchronization:**
```yaml
services:
  chrony:
    image: chrony
    cap_drop:
      - ALL
    cap_add:
      - SYS_TIME          # Set system time
```

## Read-only root filesystem

Prevent modifications to the container filesystem:

```yaml
services:
  api:
    image: api:latest
    read_only: true
    tmpfs:
      - /tmp            # Writable temp directory
      - /var/run        # Runtime data
    volumes:
      - type: tmpfs
        target: /app/cache
        tmpfs:
          size: 100M
```

## Security options

Additional security controls:

```yaml
services:
  app:
    image: myapp
    security_opt:
      - no-new-privileges:true    # Prevent privilege escalation
      - apparmor:docker-default    # AppArmor profile
      - seccomp:unconfined        # Seccomp profile
      - label:type:container_t    # SELinux label

  # Custom seccomp profile
  restricted:
    image: restricted-app
    security_opt:
      - seccomp:./security/seccomp-profile.json
```

## Privileged mode (use cautiously)

Sometimes needed for system-level tools:

```yaml
services:
  # Docker-in-Docker
  dind:
    image: docker:dind
    privileged: true  # Full host capabilities
    volumes:
      - /var/lib/docker

  # System monitoring
  monitoring:
    image: sysdig/sysdig
    privileged: true
    volumes:
      - /dev:/host/dev
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
```

## User namespace remapping

Run as non-root with user namespaces:

```yaml
services:
  app:
    image: myapp
    user: "1000:1000"  # Run as specific user
    userns_mode: host   # Use host user namespace

  # Or with custom mapping
  isolated:
    image: isolated-app
    user: "5000:5000"
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

## Complete security example

Defense in depth approach:

```yaml
services:
  secure-api:
    image: api:production
    # User settings
    user: "1000:1000"

    # Capabilities
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE

    # Security options
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default

    # Filesystem
    read_only: true
    tmpfs:
      - /tmp:size=10M,mode=1770,uid=1000,gid=1000

    # Resource limits
    deploy:
      resources:
        limits:
          cpus: "1"
          memory: 256M

    # Network isolation
    networks:
      - internal

    # Health monitoring
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s

networks:
  internal:
    internal: true  # No external access
```

## Pro tip

Audit container capabilities:

```bash
#!/bin/bash
# audit-capabilities.sh

for service in $(docker compose ps --services); do
  echo "=== Service: $service ==="

  # Get capabilities
  container=$(docker compose ps -q $service)
  if [ -n "$container" ]; then
    echo "Current capabilities:"
    docker inspect $container | jq '.[0].HostConfig.CapAdd // []'

    echo "Dropped capabilities:"
    docker inspect $container | jq '.[0].HostConfig.CapDrop // []'

    echo "Security options:"
    docker inspect $container | jq '.[0].HostConfig.SecurityOpt // []'

    # Check if running as root
    user=$(docker inspect $container | jq -r '.[0].Config.User // "root"')
    if [ "$user" = "root" ] || [ "$user" = "" ]; then
      echo "⚠️  WARNING: Running as root user"
    else
      echo "✅ Running as user: $user"
    fi
  fi
  echo
done
```

Minimal privileges, maximum security!

## Further reading

- [Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [Docker security](https://docs.docker.com/engine/security/)