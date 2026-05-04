---
type: schema
project: "GiuiceHunterPets"
---

# CodeWiki Schema

This file is the project-specific contract for CodeWiki. Read it before ingesting sources, answering wiki-grounded questions, linting, or absorbing code changes.

## Purpose

CodeWiki maintains durable, human-reviewed project knowledge as markdown. It is not query-time RAG. Raw sources are preserved as evidence; wiki pages are synthesized knowledge that the agent proposes and updates with human approval.

## Locations

- Wiki root: `wiki/`
- Raw sources: `wiki/raw/`
- Obsidian attachments: `wiki/raw/assets/`
- Backlinks index: `wiki/_backlinks.json`
- Chronological log: `wiki/log.md`
- Content index: `wiki/index.md`
- Operational tasks: `.codewiki/tasks/`

## Source Rules

- Treat files under `wiki/raw/` as immutable source material.
- Store web articles in `wiki/raw/articles/`.
- Store papers and PDFs in `wiki/raw/papers/`.
- Store meeting notes, interviews, and transcripts in `wiki/raw/transcripts/`.
- Store specs, PRDs from outside this project, and design docs in `wiki/raw/specs/`.
- Store referenced images and attachments in `wiki/raw/assets/`.
- If opening the wiki in Obsidian, use `wiki/` as the vault root and set the attachment folder path to `raw/assets/`.
- Obsidian plugins such as Dataview are optional. CodeWiki pages must remain valid plain markdown with parseable YAML frontmatter.
- Raw markdown sources should start with frontmatter:
  - `source_url`: original URL when applicable
  - `ingested`: date captured
  - `sha256`: hash of the body after the closing frontmatter fence
- Re-ingest should recompute the body `sha256`; skip unchanged sources and flag drift when the digest changes.
- Corrections and interpretation belong in wiki pages, not by rewriting raw sources.

## Orientation Rule

Before any ingest, query, lint, absorb, or breakdown operation:

1. Read this `SCHEMA.md`.
2. Read `wiki/index.md`.
3. Read recent entries from `wiki/log.md`.
4. Read `wiki/_backlinks.json` when ranking, linking, or checking orphan pages.

## Page Categories

- `wiki/entities/`: components, modules, services, people, teams, products, or other named things.
- `wiki/decisions/`: architecture and product decisions.
- `wiki/concepts/`: recurring concepts, patterns, domain terms, and technical ideas.
- `wiki/comparisons/`: side-by-side analyses and tradeoff records.
- `wiki/lessons/`: durable lessons learned from implementation, debugging, or review.
- `wiki/issues/`: known issues, risks, workarounds, and resolved problems.
- `wiki/sources/`: summaries of raw sources.
- `wiki/queries/`: substantial answers worth preserving for future sessions.

## Page Frontmatter

Every wiki page must include these fields unless the page type has a documented exception:

```yaml
---
type: entity | decision | concept | comparison | lesson | issue | source-summary | query
title: Page Title
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [from-taxonomy]
sources: []
confidence: high | medium | low
contested: false
contradictions: []
verified_by: human
approved: false
---
```

- Use `confidence: low` for single-source, weakly supported, speculative, or fast-moving claims.
- Use `contested: true` when unresolved contradictions remain.
- Add page slugs or paths to `contradictions` when another page disagrees.
- Do not mark `confidence: high` unless the claim is well-supported by source evidence or direct code inspection.

## Tag Taxonomy

Add a new tag here before using it on any page.

- `architecture`: system structure, modules, boundaries, and data flow.
- `cli`: command-line behavior, flags, output, and invocation workflows.
- `adapter`: tool adapters, generated instructions, and integration surfaces.
- `hook`: hook scripts, lifecycle events, and automated context capture.
- `concept`: recurring project concepts, patterns, domain terms, and technical ideas.
- `comparison`: side-by-side analyses, alternatives, and tradeoff records.
- `query`: substantial filed answers produced from wiki-grounded questions.
- `testing`: tests, fixtures, verification strategy, and coverage notes.
- `release`: packaging, publishing, migration, and compatibility notes.
- `decision`: accepted, proposed, or rejected product and technical decisions.
- `issue`: known problems, risks, regressions, and workarounds.
- `lesson`: durable learnings from implementation, debugging, or review.
- `source`: source summaries and provenance-focused pages.

## Page Thresholds

- Create a page when an entity or concept is central to one source or appears across two or more sources.
- Update an existing page when the source mentions something already covered.
- Do not create pages for passing mentions, incidental details, or topics outside the project domain.
- Split pages over about 200 lines into focused sub-pages with cross-links.
- Archive fully superseded pages under `wiki/_archive/`, remove active index entries, update links, and log the archive action.

## Maintenance Rules

- Every accepted wiki page change must keep `wiki/index.md` discoverable.
- Every accepted ingest, absorb, lint, or notable query must append to `wiki/log.md`.
- Every new or changed wikilink should be reflected in `wiki/_backlinks.json`.
- Prefer updating an existing page over creating a duplicate page.
- Create a new page when a concept or entity is central to a source or recurring across sources.
- Do not create pages for passing mentions.
- Keep `wiki/index.md` metadata current: update its "Last updated" date and "Total pages" count after accepted page changes.
- Split index sections above 50 entries into useful sub-sections; when the full index exceeds 200 entries, create `wiki/_meta/topic-map.md`.
- Keep `wiki/log.md` append-only with entries formatted as `## [YYYY-MM-DD] action | subject`.
- Allowed log actions: `ingest`, `update`, `query`, `lint`, `create`, `archive`, `delete`, `absorb`, `breakdown`.
- Rotate the log when it exceeds 500 entries by moving the old log to a dated archive and starting a fresh `wiki/log.md`.

## Approval Boundary

- Agents may propose wiki edits after reading current context.
- Agents must wait for explicit human approval before writing to `wiki/`.
- Generated proposals should list pages to create, pages to update, index/log changes, and unresolved questions.

## Contradictions

When new information conflicts with existing wiki content:

1. Check dates and source provenance.
2. Preserve both claims when the conflict is real.
3. Mark the affected page with `contested: true` and add the conflicting page to `contradictions`.
4. Surface the contradiction to the user before writing changes.

## Bulk Ingest

When ingesting multiple sources at once, read all sources first, identify entities and concepts once,
check existing pages in one pass, update pages in one batch, then update `index.md`, `log.md`, and
`_backlinks.json` once at the end.

## Query Filing

Substantial query answers should compound back into the wiki when the user approves. File comparisons
under `wiki/comparisons/` and durable syntheses under `wiki/queries/`. Do not file trivial lookups.
