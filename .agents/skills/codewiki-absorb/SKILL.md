---
name: codewiki-absorb
description: Extracts durable CodeWiki knowledge from recent code changes, git diffs, changed files, and phase outcomes. Use when a phase is complete, pending absorb state exists, substantial coding work has landed, or lessons/entities/issues/decisions from implementation should be proposed for human-approved wiki updates.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# CodeWiki Absorb

<purpose>
Read recent code changes, cross-reference them against the local wiki, and propose updates that
capture durable project knowledge. This is code-focused absorption: reason from git diffs and
changed files, not from raw documents. Do not create, update, or rewrite wiki files unless the
user explicitly approves the proposed updates in the current conversation.
</purpose>

<process>
Follow this priority order throughout: first inspect recent code changes accurately, then propose
wiki updates, and only then write approved wiki files. If any later heuristic conflicts with that
order, follow the earlier item.

## Step 1: Gather recent changes
- Read `.codewiki/state/pending-absorb.jsonl` when it exists.
- Treat pending entries as hook-recorded state only; hooks do not run updater, verifier, absorb, or write wiki files directly.
- Run `git diff` and `git diff --cached` to inspect current uncommitted work.
- If the working tree has uncommitted changes, also check `git diff --cached` and plain `git diff`.
- List the changed files and summarize what changed semantically, not line-by-line.

## Step 2: Resolve and load wiki state
- Read `.codewiki/config.yml` if it exists.
- Use `wiki.path` as the wiki root when present; otherwise use `wiki/`.
- Read `SCHEMA.md` from the resolved wiki root when it exists.
- Read `index.md` from the resolved wiki root first.
- Read recent entries from `log.md` in the resolved wiki root.
- Read `_backlinks.json` from the resolved wiki root to see which pages are most referenced and interconnected.
- Use `Glob` under the resolved wiki root to inventory the full wiki before proposing edits.

## Step 3: Cross-reference changes against wiki
- For each changed file, search the resolved wiki root for existing pages that mention it or the concepts it affects.
- Identify three buckets:
  - existing pages that need updating
  - new entities, decisions, lessons, or issues implied by the changes
  - contradictions between the new code and the current wiki narrative

## Step 4: Apply anti-cramming
- If an existing page would gain a third paragraph about the same sub-topic, propose a new dedicated page instead.
- Prefer 30 focused pages over 5 bloated ones.
- Split pages over about 200 lines into focused sub-pages with cross-links.
- Do not create pages for passing mentions; create a page only when the entity or concept is central to the change or already recurs across sources/wiki pages.

## Step 5: Apply anti-thinning
- Every page you touch must get meaningfully richer.
- If a topic is mentioned in 4+ other pages, its own page must not remain a three-sentence stub.
- Flag thin pages that should be expanded while this change is fresh.
- Use only tags from `SCHEMA.md`; propose a taxonomy update before using any new tag.
- Set `confidence`, `contested`, and `contradictions` frontmatter when the code change weakens, disputes, or only partially supports an existing claim.

## Step 6: Update backlinks
- After proposing changes, rebuild `_backlinks.json` in the resolved wiki root by scanning all wiki pages for `[[wikilink]]` references.
- Use the structure `{ "page-path": ["referencing-page-1", "referencing-page-2"] }`.

## Step 7: Propose changes
- Present a concise proposal covering:
  - pages to create
  - pages to update
  - backlink changes needed in `_backlinks.json`
  - contradictions or stale claims found
- Wait for user approval before writing any wiki files.

## Step 8: Write approved updates
- After approval, create or update only the approved pages using `.codewiki/templates/`.
- Update `index.md`, `log.md`, and `_backlinks.json` in the resolved wiki root so the wiki stays navigable.
- Keep index metadata current and append log entries in `## [YYYY-MM-DD] absorb | Subject` format.

## Step 9: Guardrails
- Never write to the resolved wiki root without explicit approval in the current conversation.
- Never auto-commit.
- If the detected code changes are trivial, such as whitespace or formatting only, say so and skip wiki edits.
</process>
