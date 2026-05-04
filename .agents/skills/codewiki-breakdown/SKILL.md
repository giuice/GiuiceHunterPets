---
name: codewiki-breakdown
description: Find undocumented entities referenced in wiki and propose new pages
allowed-tools: [Read, Glob, Grep, Bash]
---

# CodeWiki Breakdown

<purpose>
Scan the wiki for concrete entities, patterns, and decisions that are referenced but still lack a
dedicated page. Rank the strongest candidates by backlink count so the most important knowledge
gaps get filled first.
</purpose>

<process>
## Step 1: Resolve and orient in the wiki
- Read `.codewiki/config.yml` if it exists.
- Use `wiki.path` as the wiki root when present; otherwise use `wiki/`.
- Read `SCHEMA.md` from the resolved wiki root when it exists.
- Read `index.md` from the resolved wiki root.
- Read recent entries from `log.md` in the resolved wiki root.

## Step 2: Load backlink index and wiki inventory
- Read `_backlinks.json` from the resolved wiki root.
- If it is missing or empty, scan markdown files under the resolved wiki root for `[[wikilink]]` references and build the backlink index before continuing.
- Use `Glob` under the resolved wiki root to inventory all existing wiki pages.

## Step 3: Find undocumented references
- For each `[[wikilink]]` target surfaced by the backlink index, check whether a corresponding wiki page exists.
- Collect the targets that are referenced but have no dedicated page.

## Step 4: Scan code for additional candidates
- Grep the codebase for entity names mentioned in wiki pages but not yet documented.
- Prioritize concrete, code-backed items such as exported functions, class names, config keys, CLI flags, and environment variables.

## Step 5: Rank by importance
- Sort candidates using this order:
  - backlink count from `_backlinks.json`
  - number of wiki pages mentioning the entity
  - whether the entity is also visible in code
- Drop candidates that are only passing mentions, incidental details, or outside the project domain.
- Prefer candidates that are central to one source/change or appear across two or more sources/wiki pages.

## Step 6: Propose batch
- Present the top 5-10 candidates with:
  - entity name
  - reference count
  - suggested wiki category (`entity`, `decision`, `lesson`, or `issue`)
  - schema-approved tags to use, or a proposed taxonomy addition
  - one-line description
- Wait for user approval or selection before creating any page.

## Step 7: Create approved pages
- For each approved candidate, create the page using `.codewiki/templates/`.
- Update `index.md` in the resolved wiki root with the new entries.
- Keep the index "Last updated" date and "Total pages" count current.
- Update `_backlinks.json` in the resolved wiki root after the new pages and links exist.
- Append a concise `## [YYYY-MM-DD] breakdown | Subject` entry to `log.md` in the resolved wiki root.

## Step 8: Guardrails
- Never create pages without approval.
- Keep the batch size at 10 or fewer candidates per run to avoid context overload.
- If no meaningful gaps are found, say so explicitly.
</process>
