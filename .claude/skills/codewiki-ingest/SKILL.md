---
name: codewiki-ingest
description: Digests raw source documents into human-approved CodeWiki pages with summaries, entities, decisions, links, index updates, log entries, and source drift checks. Use when new material appears under wiki/raw, the user asks to process docs, ingest articles/papers/transcripts/specs, bulk-import sources, or update the wiki from immutable raw evidence.
argument-hint: <source-file-path>
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# CodeWiki Ingest

<purpose>
Read a source document, extract durable project knowledge, and propose wiki updates that keep the
project wiki current over time. Preserve the human approval boundary: do not write wiki changes
until the user approves the proposal.
</purpose>

<process>
## Step 1: Resolve the source
- Treat `$ARGUMENTS` as the source file path.
- Read `.codewiki/config.yml` if it exists.
- If `.codewiki/config.yml` declares `wiki.path`, use it as the wiki root.
- If `wiki.path` is not declared, use `wiki/` as the wiki root.
- If `.codewiki/config.yml` declares `wiki.raw_path`, use it as the raw source root.
- If `wiki.raw_path` is not declared, use `wiki/raw/` as the raw source root.
- If no path was provided, ask the user which raw file to ingest.
- If the user provides a relative path and it exists, use that path.
- If the user provides a relative path and it does not exist, try resolving it under the raw source root.
- Default raw source locations are `wiki/raw/articles/`, `wiki/raw/papers/`, `wiki/raw/transcripts/`, `wiki/raw/specs/`, and `wiki/raw/assets/`.
- Read the source and note what kind of material it is (notes, article, transcript, spec, diff).
- If the source file cannot be read or is invalid, notify the user and skip processing that file.
- If the source has raw frontmatter with `sha256`, recompute the digest over the body after the closing `---`.
- Skip re-ingest when the recomputed digest matches. Flag source drift when it does not match.
- When capturing a new markdown source, add raw frontmatter with `source_url`, `ingested`, and `sha256` when those values are known.
- If `$ARGUMENTS` names multiple sources or a directory, use the bulk ingest rule: read every source first, identify shared entities/concepts once, then update index/log/backlinks once.

## Step 2: Orient in the current wiki
- Read `SCHEMA.md` from the resolved wiki root when it exists.
- Read `index.md` from the resolved wiki root before proposing any page changes.
- Read recent entries from `log.md` in the resolved wiki root.
- Read `_backlinks.json` from the resolved wiki root to understand which pages are most referenced and interconnected.
- Use `Glob` and `Grep` under the resolved wiki root to find existing wiki pages that match the source topic.
- Read any relevant pages so you do not duplicate or overwrite existing knowledge blindly.
- Read templates from `.codewiki/templates/` before creating any new page.

## Step 3: Extract candidate knowledge
- Pull out candidate entities, decisions, lessons, issues, source summaries, and useful cross-links.
- Separate verified facts from open questions, speculation, or disputed claims.
- Keep the wiki grounded in what the source actually supports.
- Assign `confidence: low` to weak, speculative, single-source, or fast-moving claims; use `confidence: high` only when evidence is strong.
- Mark `contested: true` and `contradictions` when the source creates unresolved conflicts.

## Step 4: Cross-reference and de-duplicate
- Compare each candidate item against existing wiki pages.
- Prefer updating an existing page over creating a duplicate page when the topic already exists.
- Create new pages only when the topic is central to one source or appears across two or more sources.
- Do not create pages for passing mentions, incidental details, or out-of-domain topics.
- Prefer splitting a page over about 200 lines into focused sub-pages with cross-links.
- Use only tags already listed in `SCHEMA.md`; if a new tag is needed, include the schema taxonomy update in the proposal before using it.
- Flag contradictions or stale claims that the new source strengthens, weakens, or overturns.

## Step 5: Propose changes
- Present a concise proposal before making edits:
  - pages to create
  - pages to update
  - raw source frontmatter or drift handling
  - index entries to add or revise
  - log entry in `## [YYYY-MM-DD] ingest | Source Title` format
  - contradictions, gaps, and open questions
- Wait for user approval before writing any file.

## Step 6: Write approved updates
- After approval, create or update only the approved pages.
- Use `.codewiki/templates/` as the default structure for new pages.
- Update `index.md` in the resolved wiki root so new material is discoverable.
- Keep the index "Last updated" date and "Total pages" count current.
- Update `_backlinks.json` in the resolved wiki root by scanning all modified and new pages for `[[wikilink]]` references. Add new backlink entries; do not remove existing ones unless a link was actually deleted.
- Append a concise ingest entry to `log.md` in the resolved wiki root.
- In the log entry, list every file created or updated.
- End with a short summary of what changed and what still needs human review.

## Step 7: Guardrails
- Never mutate the resolved wiki root without explicit approval in the current conversation.
- Never assume a source is correct when it conflicts with already-verified wiki content.
- Never create commits automatically; the user controls git operations.
</process>
