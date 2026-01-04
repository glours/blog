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

3. **Configuration**:
   - Main config is `config.yml`
   - Custom domain is handled via GitHub Secret `CUSTOM_DOMAIN`
   - Do NOT hardcode domain names

4. **Privacy Focus**:
   - No analytics or tracking
   - Privacy-first approach
   - No third-party scripts except for essential functionality

### Common Tasks

#### Creating a New Blog Post
```bash
hugo new posts/post-title.md
# Or manually create in content/posts/
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

AI agents should NOT:
- ❌ Add analytics or tracking
- ❌ Expose the custom domain in code
- ❌ Add unnecessary dependencies
- ❌ Modify git submodules directly

## Contact

**Author:** Guillaume Lours
**GitHub:** [@glours](https://github.com/glours)
**Blog:** Compose, Break, Repeat

## Notes for AI Agents

This project emphasizes:
1. **Simplicity** - Keep it simple and maintainable
2. **Privacy** - No tracking or analytics
3. **Performance** - Static site generation for speed
4. **Modern Practices** - Docker Compose Watch, GitHub Actions
5. **Professional Standards** - As maintained by a Docker Compose maintainer

When making changes, ensure they align with these principles.