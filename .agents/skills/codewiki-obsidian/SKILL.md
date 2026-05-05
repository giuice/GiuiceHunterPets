---
name: codewiki-obsidian
description: Configures and audits CodeWiki as an Obsidian-compatible markdown vault while preserving CodeWiki schema, raw-source immutability, wikilinks, attachments, Dataview-ready frontmatter, graph readability, and vault sync safety. Use when setting up Obsidian, managing assets, migrating an existing vault, or reviewing Obsidian navigation quality.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# CodeWiki Obsidian

<purpose>
Make the local CodeWiki wiki work well as an Obsidian vault without weakening the core CodeWiki
contract: raw sources stay immutable, wiki pages stay human-reviewed, and every durable change
remains discoverable through schema, index, log, and backlinks.
</purpose>

<process>
## Step 1: Resolve and orient in the vault
- Read `.codewiki/config.yml` if it exists.
- If `.codewiki/config.yml` declares `wiki.path`, use it as the wiki root.
- If `wiki.path` is not declared, use `wiki/` as the wiki root.
- Read `SCHEMA.md`, `index.md`, recent `log.md`, and `_backlinks.json` from the resolved wiki root before proposing changes.
- Confirm the vault root is the wiki root itself, not the repository root, unless the user specifies in writing that Obsidian should show project files too.
- Treat raw-source immutability, schema correctness, and approval-gated edits as mandatory. Treat plugin and convenience recommendations as optional.

## Step 2: Check Obsidian-compatible structure
- Confirm the resolved wiki root contains `raw/assets/`, `raw/articles/`, `raw/papers/`, `raw/transcripts/`, and `raw/specs/`.
- Keep attachments and downloaded images under `raw/assets/`.
- Keep synthesized pages in typed folders such as `entities/`, `decisions/`, `concepts/`, `comparisons/`, `lessons/`, `issues/`, `sources/`, and `queries/`.
- Do not introduce database-only state. The vault must remain useful as plain markdown in any editor.

## Step 3: Preserve CodeWiki markdown conventions
- Use Obsidian `[[wikilinks]]` for wiki-to-wiki references.
- Use `![[asset-name.ext]]` or relative markdown image links only for files stored under `raw/assets/`.
- Keep YAML frontmatter parseable by Obsidian and Dataview.
- Add any new tag to the `SCHEMA.md` taxonomy before using it.
- Avoid aliases or link formats that make `_backlinks.json` impossible to rebuild deterministically.

## Step 4: Recommend Obsidian settings
- Recommend setting Obsidian's attachment folder path to `raw/assets/`.
- Recommend keeping Wikilinks enabled.
- Recommend Dataview only when the user wants dynamic tables over frontmatter.
- If the user clips web pages, recommend storing the markdown source under the appropriate `raw/` subfolder and downloading referenced images into `raw/assets/`.
- Treat plugin choices as optional. CodeWiki must not depend on Obsidian plugins to remain correct.

## Step 5: Handle existing vaults
- If the user points CodeWiki at an existing Obsidian vault, inventory the vault before proposing moves.
- Identify markdown pages that already look like raw sources versus synthesized wiki pages.
- Propose a migration plan that preserves existing user-authored notes and clearly separates them from CodeWiki-owned pages.
- Do not move, rename, or rewrite existing notes without explicit approval.

## Step 6: Audit graph and navigation quality
- Find broken `[[wikilinks]]`, missing reciprocal links, orphan pages, and pages absent from `index.md`.
- Check whether important assets referenced in markdown actually exist under `raw/assets/`.
- Check that high-value pages have enough outbound links to be visible in graph view.
- Use `_backlinks.json` to identify hubs, thin pages, and isolates that need curation.

## Step 7: Propose changes
- Present a concise proposal before writing:
  - vault setting recommendations
  - files or folders to create
  - pages whose links/frontmatter/assets need cleanup
  - `index.md`, `log.md`, and `_backlinks.json` changes
  - risks for existing user-authored Obsidian notes
- Wait for explicit user approval before editing any wiki or vault file.

## Step 8: Write approved updates
- Create missing CodeWiki folders only after approval.
- Update markdown links, frontmatter, `index.md`, `log.md`, and `_backlinks.json` only within the approved scope.
- Append log entries in `## [YYYY-MM-DD] update | Obsidian vault maintenance` format unless the change is better classified as `lint`, `ingest`, or `archive`.
- End by listing the vault path and every file changed.

## Step 9: Guardrails
- Never mutate raw sources in `raw/`; move corrections into synthesized wiki pages.
- Never require proprietary sync or plugins for the wiki to function.
- Never treat Obsidian graph aesthetics as more important than accurate provenance and maintainable pages.
- Do not auto-commit.
</process>
