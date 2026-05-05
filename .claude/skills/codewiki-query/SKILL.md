---
name: codewiki-query
description: Searches the local CodeWiki and synthesizes grounded answers with citations to wiki pages. Use when the user asks how the project works, why a decision was made, where knowledge lives, what is known about an entity/issue/lesson/source, or whether a substantial answer should be filed back into the wiki.
argument-hint: <question>
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# CodeWiki Query

<purpose>
Answer a question by reading the local wiki first, then synthesizing a grounded response from the
matched wiki pages. Treat the wiki as the primary knowledge layer between the user and the raw
project sources stored for CodeWiki, such as notes, articles, transcripts, specs, and other source
documents.
</purpose>

<process>
## Step 1: Read the query
- Treat `$ARGUMENTS` as the user question.
- If the question is missing or unclear, ask for the exact question before searching.

## Step 2: Resolve and orient in the wiki
- Read `.codewiki/config.yml` if it exists.
- If `.codewiki/config.yml` declares `wiki.path`, use it as the wiki root.
- If `wiki.path` is not declared, use `wiki/` as the wiki root.
- Read `index.md` from the resolved wiki root before anything else.
- Read `SCHEMA.md` from the resolved wiki root when it exists.
- Read recent entries from `log.md` in the resolved wiki root.
- Read `_backlinks.json` from the resolved wiki root when it exists.
- Use `index.md` to identify candidate entity, decision, lesson, issue, and source pages.
- Use `_backlinks.json` to identify higher-importance pages when multiple candidates look relevant. Pages with many backlinks are more likely to contain authoritative answers.

## Step 3: Search for relevant pages
- Use `Grep` under the resolved wiki root for keywords, aliases, file names, and adjacent concepts from the question.
- Use `Glob` to expand from promising matches into the specific markdown pages that matter.
- Use `_backlinks.json` from the resolved wiki root to prioritize pages with higher backlink counts when multiple pages match the query.
- Prefer a small set of high-signal pages over broad, noisy retrieval.

## Step 4: Read matched pages
- Read the matched wiki pages in full when they appear central to the answer.
- Note supporting evidence, contradictions, and unresolved gaps.

## Step 5: Synthesize the answer
- Answer the question directly.
- Cite the supporting wiki entries with file paths so the user can inspect them.
- Call out uncertainty when the wiki is incomplete or conflicting.

## Step 6: File valuable answers
- If the answer is a substantial comparison, deep dive, or new synthesis that would be painful to re-derive, propose filing it under `comparisons/` or `queries/`.
- Do not file trivial lookups, simple pointers, or answers that add no durable synthesis.
- Wait for explicit user approval before writing any query-derived page.
- Filed pages must use schema-approved tags, include `sources`, `confidence`, `contested`, and `contradictions` frontmatter, and be added to `index.md`.
- Append a `## [YYYY-MM-DD] query | Question summary` entry to `log.md` that says whether the answer was filed.

## Step 7: Handle misses explicitly
- If no relevant wiki pages are found, say so clearly.
- Suggest what kind of source or wiki page would be needed to answer the question better.

## Step 8: Boundaries
- Stay local: this is a wiki-grounded markdown search workflow, not an API call.
- Do not edit files unless the user explicitly approves filing the answer in the current conversation.
</process>
