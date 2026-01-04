# Compose, Break, Repeat

A blog about software engineering, Docker, and the iterative process of building and breaking things. Built with Hugo and the PaperMod theme, configured for GitHub Pages deployment.

## Features

- 🔍 **Full-text Search**: Built-in search functionality using Fuse.js
- 🏷️ **Tags & Categories**: Organize and browse content by topics
- 📱 **Responsive Design**: Looks great on all devices
- 🌓 **Dark/Light Mode**: Automatic theme switching
- 🔗 **Social Media Links**: Connect with readers through social platforms
- 📊 **Reading Time & Word Count**: Article metadata
- 🚀 **Fast Performance**: Static site generation for blazing-fast load times
- 🐳 **Docker Support**: Easy local development with Docker Compose
- 🤖 **Automated Deployment**: GitHub Actions workflow for GitHub Pages

## Prerequisites

For local development, you need **one** of the following:

### Option 1: Docker (Recommended)
- Docker and Docker Compose installed

### Option 2: Native Installation
- Hugo Extended version (0.121.0 or later)
- Git

## Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd blog
```

### 2. Update Configuration

Edit `config.yml` and update the following:

- `baseURL`: Keep as `/` for local development (production URL is set automatically via GitHub Actions)
- `params.socialIcons`: Update with your social media links
- `params.homeInfoParams`: Customize your welcome message
- `params.author`: Add your name

### 3. Local Development

#### Using Docker Compose (Recommended)

```bash
# Start development server with live reload
docker compose up --watch

# The site will be available at http://localhost:1313/
```

Alternative commands:
```bash
# Build for production
docker compose --profile build up

# Preview production build with nginx
docker compose --profile preview up

# Simple development server without watch
docker compose up
```

#### Using Native Hugo

```bash
# Start the development server
hugo server -D

# The site will be available at http://localhost:1313
```

## Creating Content

### New Blog Post

```bash
# Using Hugo CLI
hugo new posts/my-new-post.md

# Or manually create a file in content/posts/
```

### Post Front Matter Template

```yaml
---
title: "Your Post Title"
date: 2024-01-04T10:00:00+00:00
draft: false
tags: ["tag1", "tag2", "tag3"]
categories: ["Category"]
author: "Your Name"
showToc: true
TocOpen: false
description: "Post description for SEO"
cover:
    image: "path/to/cover-image.jpg"
    alt: "Cover image description"
    caption: "Image caption"
---

Your content here...
```

## Deployment

### GitHub Pages Setup

1. **Create a GitHub Repository**
   - Repository name can be anything (doesn't need to be `username.github.io`)

2. **Enable GitHub Pages**
   - Go to Settings → Pages
   - Source: GitHub Actions

3. **Optional: Configure Custom Domain**
   - Add a repository secret named `CUSTOM_DOMAIN` with your domain (e.g., `example.com`)
   - Go to Settings → Secrets and variables → Actions → New repository secret
   - Configure your DNS provider to point to GitHub Pages:
     - For apex domain: A records to GitHub's IPs
     - For subdomain: CNAME record to `YOUR_USERNAME.github.io`
   - The workflow will automatically create the CNAME file during deployment

4. **Push to GitHub**
   ```bash
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git push -u origin main
   ```

5. **Automatic Deployment**
   - The GitHub Actions workflow will automatically build and deploy your site
   - Check the Actions tab in your repository to monitor the deployment
   - Your site will be available at:
     - With custom domain: `https://YOUR_DOMAIN/`
     - Without custom domain: `https://YOUR_USERNAME.github.io/YOUR_REPO_NAME/`

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions deployment workflow
├── archetypes/                 # Content templates
├── content/
│   ├── posts/                  # Blog posts
│   ├── archives.md             # Archives page
│   └── search.md               # Search page
├── themes/
│   └── PaperMod/               # Theme submodule
├── static/                     # Static assets (images, etc.)
├── config.yml                  # Hugo configuration
├── compose.yml                 # Docker development setup
└── README.md                   # This file
```

## Customization

### Theme Colors

Edit `config.yml` to change theme settings:

```yaml
params:
  defaultTheme: auto  # Options: light, dark, auto
  disableThemeToggle: false
```

### Navigation Menu

Modify the menu in `config.yml`:

```yaml
menu:
  main:
    - identifier: custom
      name: Custom Page
      url: /custom/
      weight: 50
```

### Social Icons

Available social icons in `config.yml`:

```yaml
params:
  socialIcons:
    - name: github
    - name: twitter
    - name: linkedin
    - name: email
    - name: facebook
    - name: instagram
    - name: youtube
    - name: rss
```

## Docker Commands Reference

```bash
# Development with live reload (recommended)
docker compose up --watch

# Build production site
docker compose --profile build up

# Preview production build
docker compose --profile preview up

# View logs
docker compose logs -f server

# Stop all services
docker compose down

# Rebuild images
docker compose build --no-cache
```

## Troubleshooting

### Port 1313 Already in Use

```bash
# Find process using port 1313
lsof -i :1313  # macOS/Linux
netstat -ano | findstr :1313  # Windows

# Kill the process or use a different port in docker-compose.yml
```

### Build Failures

```bash
# Clean Hugo cache
rm -rf resources/ public/ .hugo_build.lock

# Rebuild
hugo server -D
```

## Tips

1. **Draft Posts**: Set `draft: true` in front matter to hide posts from production
2. **Future Posts**: Posts with future dates won't appear until that date
3. **Syntax Highlighting**: Use triple backticks with language names for code blocks
4. **Images**: Place images in `static/images/` and reference as `/images/filename.jpg`
5. **SEO**: Fill out description and keywords in post front matter

## Resources

- [Hugo Documentation](https://gohugo.io/documentation/)
- [PaperMod Theme Wiki](https://github.com/adityatelange/hugo-PaperMod/wiki)
- [PaperMod Features](https://adityatelange.github.io/hugo-PaperMod/posts/papermod/papermod-features/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)

## License

This project is open source and available under the [MIT License](LICENSE).