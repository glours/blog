# Docker Compose Tips - Content Strategy

## Analysis of Existing Posts (Tips #1-5)

Based on the first 5 published posts, here's the established format:

### Key Metrics
- **Average length**: ~130-170 lines total
- **Word count**: ~400-600 words
- **Code examples**: 3-5 per post
- **Reading time**: 2-3 minutes

### Structure Pattern

1. **Opening Hook** (1-2 lines)
   - Problem statement or scenario
   - Direct, conversational tone
   - Example: "When your Compose setup gets complex, `docker compose config` becomes your best debugging tool."

2. **Core Content Sections** (3-5 sections)
   - Clear, descriptive headers
   - One main concept per section
   - Brief explanation followed by code example
   - Focus on practical, immediately usable information

3. **Code-to-Text Ratio**
   - ~40-50% code examples
   - ~50-60% explanatory text
   - Code blocks are concise (5-15 lines typical)

4. **Depth Level**
   - Cover the essential 80% use case
   - Include 1-2 advanced tips
   - Skip exhaustive documentation
   - Link to official docs for deep dives

## Content Guidelines

### What Makes a "1-Pager"

✅ **DO Include:**
- One focused tip/technique
- 2-3 practical code examples
- Common variations or patterns
- Quick debugging/troubleshooting section
- 1-2 "gotchas" or common mistakes

❌ **DON'T Include:**
- Exhaustive lists of all options
- Multiple unrelated scenarios
- Deep architectural discussions
- Performance benchmarks (unless core to the tip)
- Extensive real-world case studies

### Writing Style

- **Tone**: Direct, practical, maintainer's perspective
- **Voice**: "Here's what works" not "Let me teach you"
- **Examples**: Real commands and configs that can be copy-pasted
- **Explanations**: Just enough to understand why, not academic depth

### Code Examples

```yaml
# Good: Focused, practical example
services:
  web:
    image: nginx
    depends_on:
      db:
        condition: service_healthy
```

Not full production configs with every possible option.

### Section Templates

#### Basic Setup (when applicable)
- Show the simplest working example
- 1-2 paragraphs max
- Focus on the core pattern

#### Common Patterns
- 2-3 most useful variations
- Brief explanation of when to use each
- Keep code examples short

#### Debugging/Troubleshooting
- 1-2 common issues
- Quick fixes
- Commands to diagnose

#### Pro Tip (optional)
- One advanced usage
- Or one important gotcha
- 2-3 lines max

## Content Decisions

Based on user feedback, here are the established guidelines:

1. **Target Audience Level**
   - Include beginner-friendly posts when appropriate
   - Vary difficulty levels across the series
   - Tag posts accordingly (beginner/intermediate/advanced)

2. **Code Example Preference**
   - Flexible based on subject matter
   - Maintain 1-page format regardless
   - Balance between minimal snippets and working examples

3. **External Links**
   - ✅ Link to official Docker documentation
   - ✅ Link to Compose specification
   - ❌ Avoid other external links

4. **Advanced Content**
   - Include "Pro Tip" section when appropriate
   - Not mandatory for every post
   - Use judgment based on topic complexity

5. **Practical Focus**
   - ✅ Include real production examples
   - ✅ Show practical impact when relevant
   - Focus on real-world usage

6. **Visual Elements**
   - ✅ Include command outputs when they illustrate the point
   - Highlight interesting outputs
   - Keep visual elements purposeful

7. **Series Connection**
   - ✅ Reference previous blog posts when relevant
   - Build on established concepts
   - Each post should still be understandable standalone

## Proposed Format Template

```markdown
---
title: "Docker Compose Tip #X: [Concise Title]"
date: YYYY-MM-DDTHH:MM:SS+01:00
draft: false
tags: ["docker-compose", "docker", "tips", "[category]", "[level]"]
categories: ["Docker Compose Tips"]
author: "Guillaume Lours"
[standard Hugo front matter...]
---

[1-2 line hook - problem or scenario]

## The basics / The problem / The setup
[Core concept with simple example]
[5-10 lines explanation]
[5-15 lines code]

## [Main technique/solution]
[How it works]
[Main code example]
[When to use]

## [Variations/Common patterns]
[2-3 practical examples]
[Brief explanations]

## Debugging / Troubleshooting / Common issues (if applicable)
[1-2 issues and fixes]
[Diagnostic commands]

## Pro tip / Real impact / Why this matters (optional)
[1 advanced usage or impact statement]
[2-3 lines max]
```

## Next Steps

Once you answer the refinement questions above, I'll:
1. Create a final content template
2. Rewrite the Week 2 posts to match
3. Establish a repeatable process for future posts