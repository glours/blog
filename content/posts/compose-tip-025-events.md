---
title: "Docker Compose Tip #25: Using docker compose events for monitoring"
date: 2026-02-06T09:00:00+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "monitoring", "debugging", "events", "intermediate"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false
TocOpen: false
hidemeta: false
comments: false
description: "Monitor container lifecycle and build automation with docker compose events"
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

Track everything happening in your Compose stack! Events provide real-time insights into container lifecycle changes.

## Basic event monitoring

Watch events as they happen:

```bash
# Stream all events
docker compose events

# JSON format for parsing
docker compose events --json

# Specific services only
docker compose events web worker

# Since a specific time
docker compose events --since "2026-02-06T10:00:00"
```

## Event types

Common events you'll see:

```
container create    # Container created
container start     # Container started
container stop      # Stop initiated
container die       # Container exited
container destroy   # Container removed
health_status       # Health check changed
network connect     # Network attached
network disconnect  # Network detached
```

## Processing events

**Parse with jq:**
```bash
# Watch for container deaths
docker compose events --json | \
  jq 'select(.action=="die")'

# Filter by service
docker compose events --json | \
  jq 'select(.service=="web")'

# Extract specific fields
docker compose events --json | \
  jq '{time, service, action, attributes}'
```

## Automation examples

**Auto-restart on failure:**
```bash
#!/bin/bash
docker compose events --json | while read event; do
  action=$(echo $event | jq -r '.action')
  service=$(echo $event | jq -r '.service')

  if [ "$action" = "die" ]; then
    exit_code=$(echo $event | jq -r '.attributes.exitCode')
    if [ "$exit_code" != "0" ]; then
      echo "Service $service died with code $exit_code"
      docker compose restart $service
    fi
  fi
done
```

**Health monitoring:**
```bash
docker compose events --json | \
  jq 'select(.action=="health_status")' | \
  while read event; do
    service=$(echo $event | jq -r '.service')
    health=$(echo $event | jq -r '.attributes.health_status')

    if [ "$health" = "unhealthy" ]; then
      notify-slack "Service $service is unhealthy!"
    fi
  done
```

## Logging events

Save events for analysis:

```bash
# Log to file
docker compose events --json >> compose-events.log &

# Rotate logs daily
docker compose events --json | \
  rotatelogs -l compose-events-%Y%m%d.log 86400 &

# Send to syslog
docker compose events --json | \
  logger -t docker-compose-events
```

## Debugging with events

Track service startup sequence:

```bash
# See startup order
docker compose events --json | \
  jq 'select(.action=="start") |
      {time: .time, service: .service}'

# Measure startup time
docker compose events --json | \
  jq 'select(.action=="start" or .action=="die") |
      {service, action, time}' | \
  awk '/start/{start[$2]=$4}
       /die/{if(start[$2])
         print $2, $4-start[$2], "seconds"}'
```

## Filtering events

Target specific scenarios:

```bash
# Only container events
docker compose events --json | \
  jq 'select(.scope=="container")'

# Exclude health checks
docker compose events --json | \
  jq 'select(.action != "health_status")'

# Errors only
docker compose events --json | \
  jq 'select(.attributes.exitCode != "0")'
```

## Pro tip

Create a monitoring dashboard:

```bash
#!/bin/bash
# compose-monitor.sh
clear
echo "=== Compose Stack Monitor ==="

docker compose events --json | while read event; do
  time=$(echo $event | jq -r '.time' | xargs -I {} date -d @{})
  service=$(echo $event | jq -r '.service')
  action=$(echo $event | jq -r '.action')

  case $action in
    start) color="\033[32m" ;;  # Green
    die) color="\033[31m" ;;    # Red
    *) color="\033[33m" ;;      # Yellow
  esac

  printf "${color}[%s] %-15s %s\033[0m\n" "$time" "$service" "$action"
done
```

Example output:
```
=== Compose Stack Monitor ===
[Thu Feb 6 10:15:23] web             start        # Green
[Thu Feb 6 10:15:24] database        start        # Green
[Thu Feb 6 10:15:25] web             health_status # Yellow
[Thu Feb 6 10:15:28] worker          start        # Green
[Thu Feb 6 10:16:45] worker          die          # Red
[Thu Feb 6 10:16:46] worker          stop         # Yellow
[Thu Feb 6 10:16:48] worker          create       # Yellow
[Thu Feb 6 10:16:49] worker          start        # Green
```

Real-time, color-coded visibility into your stack's behavior!

## Further reading

- [Docker events documentation](https://docs.docker.com/engine/reference/commandline/events/)
- [Compose CLI reference](https://docs.docker.com/compose/reference/)