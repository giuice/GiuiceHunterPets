---
name: codewiki-flow
description: Routes the current request to the right CodeWiki skill based on user intent and repository state. Use when the user asks what to do next, wants the recommended workflow, resumes a session, starts a feature, reacts to pending absorb state, or needs help choosing between CodeWiki skills.
allowed-tools: [Read, Glob, Grep, Bash]
---

# CodeWiki Flow

<purpose>
Choose the right CodeWiki workflow for the current repository state and user intent. This is an
routing skill: identify the best next CodeWiki skill, state the next action, and avoid
duplicating the detailed procedures that belong in the focused skills.
</purpose>

<process>
## Step 1: Orient in the repository
- Read `.codewiki/config.yml` if it exists.
- Use `wiki.path` as the wiki root when present; otherwise use `wiki/`.
- Use `wiki.raw_path` as the raw source root when present; otherwise use `wiki/raw/`.
- Use `wiki.tasks_path` as the PRD/task directory when present; otherwise use `.codewiki/tasks/`.
- Read `SCHEMA.md`, `index.md`, and recent `log.md` from the resolved wiki root when they exist
  and when they help distinguish between plausible routes.

## Step 2: Route by user intent
- If the user already asked for a specific CodeWiki skill and it clearly fits, use that skill
  directly instead of re-routing.
- New raw source, clipped article, transcript, spec, or document under the raw source root: use `codewiki-ingest`.
- Question about project knowledge, history, decisions, entities, issues, or lessons: use `codewiki-query`.
- New feature, larger change, or unclear product request before implementation: use `codewiki-prd`.
- Existing PRD that needs executable work: use `codewiki-tasks`.
- Existing phase plan with incomplete tasks or a request to continue implementation: use `codewiki-process`.
- Substantial code changes that should become durable wiki knowledge: use `codewiki-absorb`.
- Repeated references, missing pages, or thin important concepts: use `codewiki-breakdown`.
- Suspected contradictions, stale claims, broken links, drift, or wiki health work: use `codewiki-lint`.
- Obsidian setup, attachments, Dataview/frontmatter, wikilinks, graph readability, or vault migration: use `codewiki-obsidian`.

## Step 3: Follow the default lifecycle
- For a fresh repository, initialize CodeWiki, ingest existing raw sources, then use `codewiki-query`
  to confirm the wiki has enough context.
- For feature work, run `codewiki-prd`, then `codewiki-tasks`, then `codewiki-process`.
- During implementation, treat `.codewiki/state/pending-absorb.jsonl` as the durable hook signal:
  invoke `codewiki-wiki-updater` for durable wiki-relevant changes, or explicitly defer the same
  work to `codewiki-absorb` at the next completed phase or explicit user request.
- Treat hooks as state sensors only; they do not directly run updater, verifier, absorb, or any
  focused CodeWiki workflow.
- After a non-trivial wiki update proposal, invoke `codewiki-verifier` for read-only review before
  applying approved wiki edits.
- Between features, use `codewiki-query`, `codewiki-lint`, and `codewiki-breakdown` to keep the wiki
  searchable, linked, and current.

## Step 4: Preserve boundaries
- Do not write wiki files from this routing skill.
- Do not bypass focused skills when the user intent clearly matches one of them.
- Do not override an explicit user choice unless that choice is impossible, unsafe, or clearly mismatched.
- Never mutate the resolved wiki root without explicit approval in the current conversation.
- If multiple routes are plausible, recommend the next skill in one sentence, give the reason, and
  ask only when choosing the wrong route would waste work.
</process>
