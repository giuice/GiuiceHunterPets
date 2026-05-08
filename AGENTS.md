---
name: best-practices-guidelines
description: Behavioral guidelines to reduce common LLM coding mistakes. Use when writing, reviewing, or refactoring code to avoid overcomplication, make surgical changes, surface assumptions, and define verifiable success criteria.
license: MIT
---
**User-facing conversation may be Portuguese; repository documentation and planning artifacts must be written in English.**

# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes on LLM coding pitfalls.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

<!-- codewiki:start -->
## CodeWiki

Codex uses the shared `.agents/skills/codewiki-<name>/SKILL.md` tree for CodeWiki skills, plus Codex-owned hooks and agents under `.codex/`.

CodeWiki is not query-time RAG. It maintains a persistent, human-reviewed markdown wiki that compounds project knowledge across sessions. Use it as durable project memory: read/query the wiki before answering questions that depend on project history, and keep the wiki current when sources or substantial code changes add durable knowledge.

### Operating Flow

- At session start for wiki work: read `.codewiki/config.yml`, `wiki/SCHEMA.md`, `wiki/index.md`, and recent `wiki/log.md` before ingest/query/lint/absorb.
- New external source in `wiki/raw/` or user asks to process docs: use `codewiki-ingest`. Raw sources are immutable; wiki edits are proposed for review.
- User asks how the project works, why a decision was made, or where knowledge lives: use `codewiki-query` and cite wiki pages rather than inventing answers.
- User asks what to do next, resumes a session, starts a feature, or needs routing across CodeWiki workflows: use `codewiki-flow` to choose the next focused skill.
- New feature or larger change: use `codewiki-prd`, then `codewiki-tasks`, then `codewiki-process` to work one task at a time inside the generated phases.
- After a substantial coding session: run `codewiki-absorb` deliberately to capture durable lessons, entities, decisions, and issues from recent changes.
- Periodically or when drift is suspected: run `codewiki-lint` and `codewiki-breakdown` to find contradictions, stale claims, orphan pages, and missing high-signal pages.
- When setting up or auditing Obsidian usage: use `codewiki-obsidian` to keep vault structure, attachments, wikilinks, Dataview-ready frontmatter, and graph navigation compatible with CodeWiki.
- When `.codewiki/state/pending-absorb.jsonl` exists, treat it as a pending follow-up signal: invoke `codewiki-wiki-updater` for durable wiki-relevant changes, or explicitly defer the same work to `codewiki-absorb` at the next completed phase or explicit user request.
- After `codewiki-wiki-updater` proposes a non-trivial wiki change, invoke `codewiki-verifier` for read-only contradiction, reference, frontmatter, index, log, and backlink review before applying approved wiki edits.
- Hooks provide optional context and persistent change signals; they do not replace deliberate ingest/query/absorb/lint work or human approval of wiki writes.

### Schema Discipline

- Treat `wiki/SCHEMA.md` as the routing contract for page types, frontmatter, tag taxonomy, page thresholds, archive policy, index metadata, and log format.
- Raw markdown sources should preserve provenance fields such as `source_url`, `ingested`, and `sha256`; use `codewiki-ingest`/`codewiki-lint` to detect unchanged sources or source drift.
- Wiki pages should make uncertainty visible with `confidence`, `contested`, `contradictions`, and `sources` frontmatter instead of presenting weak claims as settled facts.
- New tags must be added to the schema taxonomy before use. Do not create pages for passing mentions; prefer updating existing pages unless the schema thresholds justify a new page.
- Substantial query answers can be proposed as durable pages under `wiki/queries/` or `wiki/comparisons/`; trivial lookups should stay in chat.
- Use the verifier agent for read-only review of proposed wiki changes that touch frontmatter, tags, confidence, contradictions, archive moves, index/log updates, or backlinks.

### Skills

- `codewiki-ingest`, `codewiki-query`, `codewiki-lint`
- `codewiki-absorb`, `codewiki-breakdown`, `codewiki-obsidian`
- `codewiki-prd`, `codewiki-tasks`, `codewiki-process`, `codewiki-flow`

### Approval Boundary

- Treat `wiki/` as human-reviewed knowledge.
- Propose wiki edits first and wait for approval before writing them.
- Use the verifier agent as a read-only check when a wiki change needs contradiction, reference, or index review.

### Codex Hooks

- `.codex/config.toml` enables `[features] codex_hooks = true`
- `.codex/hooks.json` wires `UserPromptSubmit`, `PostToolUse`, and loop-safe `Stop`
- `UserPromptSubmit` may load short prompt-level wiki context from `.codewiki/hooks/pre-wiki-context.sh` when the prompt is wiki-relevant
- Prompt context is filtered by explicit CodeWiki/wiki workflow terms and deduped per emitted context fingerprint under `.codewiki/state/`
- `PreToolUse` is not wired by default; `.codex/hooks/pre-tool-use.sh` remains packaged for future opt-in blocking guardrails
- `PostToolUse` records deduped pending absorb state through `.codewiki/hooks/post-verify.sh`; visible hook context is debug-only
- `Stop` wraps `.codewiki/hooks/session-end.sh` without blocking by default, records deduped lifecycle state, and respects `stop_hook_active` to avoid continuation loops
- `CODEWIKI_HOOK_DEBUG=1` writes hook diagnostics to state logs; `CODEWIKI_HOOK_CONTEXT_BYPASS=1` bypasses prompt-context dedupe only for diagnostics

### Important Paths

- Hooks: `.codex/hooks.json`, `.codex/config.toml`
- Agents: `.codex/agents/`
- Wiki: `wiki/`
- Schema: `wiki/SCHEMA.md`
- Raw sources: `wiki/raw/`
- PRD/task workflow: `.codewiki/tasks/`
- Config: `.codewiki/config.yml`
- Pending absorb state: `.codewiki/state/pending-absorb.jsonl`
- Backlinks index: `wiki/_backlinks.json`
<!-- codewiki:end -->

@RTK.md
