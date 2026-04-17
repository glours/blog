# AI Agents Configuration

This file documents AI agent interactions and guidelines for this repository.

## Project Overview

**Name:** Compose, Break, Repeat
**Type:** Hugo Blog with PaperMod Theme
**Author:** Guillaume Lours
**Purpose:** A blog about software engineering, Docker, and the iterative process of building and breaking things

## Development Environment

- **Framework:** Hugo v0.154.2 (Extended)
- **Theme:** PaperMod (Git submodule)
- **Container:** Docker with Compose Watch
- **Deployment:** GitHub Actions to GitHub Pages
- **Domain:** Custom domain via GitHub Secret

## Key Technologies

- Hugo Static Site Generator
- Docker & Docker Compose
- GitHub Actions CI/CD
- Markdown for content
- YAML for configuration

## Project Structure

```
blog/
├── .github/workflows/   # GitHub Actions workflows
├── content/             # Blog posts and pages (Markdown)
│   ├── posts/           # Blog posts (auto-publish based on date)
│   ├── archives.md      # Archives page
│   └── search.md        # Search functionality
├── content-planning/    # Editorial planning (not published)
│   ├── compose-tips-ideas.md  # Monthly content calendar
│   └── social-media-posts.md  # Social media templates
├── layouts/             # Custom Hugo templates
├── static/              # Static assets
├── themes/PaperMod/     # Theme (git submodule)
├── compose.yml          # Docker Compose with Watch
├── Dockerfile           # Multi-stage build
├── config.yml           # Hugo configuration
└── README.md            # Documentation
```

## AI Agent Guidelines

### When Working on This Project

1. **Docker First**: Always use Docker Compose for local development
   - Use `docker compose up --watch` for development with live reload
   - Test builds with `docker compose --profile build up`

2. **Content Creation**:
   - Blog posts go in `content/posts/`
   - Use Hugo front matter for metadata
   - Follow existing post structure
   - Posts auto-publish based on date (no manual intervention needed)
   - Editorial planning in `content-planning/` (not published)

3. **Configuration**:
   - Main config is `config.yml`
   - Custom domain is handled via GitHub Secret `CUSTOM_DOMAIN`
   - Do NOT hardcode domain names

4. **Privacy Focus**:
   - No analytics or tracking
   - Privacy-first approach
   - No third-party scripts except for essential functionality

### Blog Post Format

#### Front Matter Template
```yaml
---
title: "Your Post Title"
date: 2025-01-06T09:00:00+01:00  # Auto-publishes at this time
draft: false                       # Use false with future dates
tags: ["docker-compose", "docker", "tips", "category-tag"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
showToc: false                     # Table of contents (usually false for short tips)
TocOpen: false
hidemeta: false
comments: false
description: "SEO description - what problem does this solve?"
disableShare: false
disableHLJS: false                 # Syntax highlighting
hideSummary: false
searchHidden: false
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: false
UseHugoToc: false
---
```

#### Content Structure for Tips
1. **Hook**: Problem statement or scenario (1-2 sentences)
2. **The Command/Solution**: Clear example with code
3. **Real-World Example**: Practical implementation
4. **Why This Matters**: Business/technical value
5. **Pro Tip**: Advanced usage or gotcha

#### Writing Style Guidelines
- **Natural Language**: Write conversationally, like a human developer sharing knowledge
- **Simple and Direct**: Use short sentences, avoid complex structures
- **Neutral Tone**: Stay professional and neutral - avoid "I", "my", "we", "our"
- **No AI Patterns**:
  - Avoid catchy/clickbait titles
  - No excessive excitement or superlatives
  - Skip phrases like "Let's dive in", "game-changer", "revolutionary"
  - No decorative bullet points (✅, 🎯, etc.) unless requested
  - Minimal emojis unless specifically asked
- **Concrete Examples**: Use real numbers and actual scenarios
- **Practical Focus**: Share what works in production, not theory

#### Sanity Checks for Blog Posts

Before declaring a post ready, always run these checks:

1. **YAML validation**: Test every YAML example with `docker compose -f <file> config`
2. **Link verification**: Check all links in the post
   - External links: verify HTTP status returns 200 (e.g., `curl -sL -o /dev/null -w "%{http_code}" <url>`)
   - Internal links (`/posts/...`): confirm the target file exists in `content/posts/`
3. **Image references**: Only use official images or trusted publishers (CNCF projects, official Docker images, Docker Hardened Images). Never use personal/untrusted images as recommended examples.
4. **Command accuracy**: Prefer `docker compose <command>` over `docker <command>` when a Compose equivalent exists (e.g., `docker compose stats`, `docker compose ps --filter`, not the non-Compose versions).

### Common Tasks

#### Creating a New Blog Post
```bash
hugo new posts/post-title.md
# Or manually create in content/posts/
# Set date in the future for auto-publishing
```

#### Testing Locally
```bash
docker compose up --watch
# Visit http://localhost:1313
```

#### Building for Production
```bash
docker compose --profile build up
```

### Important Conventions

- **No Analytics**: This blog intentionally has no analytics
- **Minimal Dependencies**: Keep the setup simple and maintainable
- **Docker Best Practices**: As maintained by Docker Compose maintainer
- **Privacy First**: No tracking, no cookies, no third-party analytics

### Security Considerations

- Custom domain stored as GitHub Secret
- No sensitive information in public files
- All social links are public profiles
- MIT licensed for open source

## Agent Capabilities

AI agents can help with:
- ✅ Creating and editing blog posts
- ✅ Updating configuration
- ✅ Docker and deployment troubleshooting
- ✅ Hugo theme customization
- ✅ GitHub Actions workflow modifications
- ✅ Content planning and editorial calendar
- ✅ Social media post generation

AI agents should NOT:
- ❌ Add analytics or tracking
- ❌ Expose the custom domain in code
- ❌ Add unnecessary dependencies
- ❌ Modify git submodules directly

## Contact

**Author:** Guillaume Lours
**GitHub:** [@glours](https://github.com/glours)
**Blog:** Compose, Break, Repeat

## Content Planning Structure

### Editorial Calendar (`content-planning/compose-tips-ideas.md`)
- Monthly planning for Docker Compose tips
- Categories: Runtime, Build, Configuration, AI/Development Tools
- Publishing schedule: Monday-Friday, 9am CET
- One-page format for quick daily reads

### Social Media Templates (`content-planning/social-media-posts.md`)
- Platform-specific posts (Bluesky & LinkedIn)
- Bluesky: Concise, developer-focused (< 300 chars)
- LinkedIn: Professional, detailed with context
- Includes hashtag strategy and engagement tips

## Notes for AI Agents

This project emphasizes:
1. **Simplicity** - Keep it simple and maintainable
2. **Privacy** - No tracking or analytics
3. **Performance** - Static site generation for speed
4. **Modern Practices** - Docker Compose Watch, GitHub Actions
5. **Professional Standards** - As maintained by a Docker Compose maintainer
6. **Content Strategy** - Daily tips auto-published based on date
7. **Social Engagement** - Cross-platform content distribution

When making changes, ensure they align with these principles.