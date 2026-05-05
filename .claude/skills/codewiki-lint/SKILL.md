---
name: codewiki-lint
description: Audits CodeWiki health for contradictions, broken wikilinks, orphan pages, stale code claims, source drift, frontmatter/tag problems, oversized pages, and log/index issues. Use when wiki drift is suspected, contested knowledge needs review, a periodic health check is due, or large batches of wiki changes need validation.
allowed-tools: [Read, Glob, Grep, Bash]
---

# CodeWiki Lint

<purpose>
Inspect the wiki for structural and content health problems so the knowledge base keeps compounding
instead of silently drifting out of sync with the project.
</purpose>

<process>
## Step 1: Resolve and load the wiki catalog
- Read `.codewiki/config.yml` if it exists.
- If `.codewiki/config.yml` declares `wiki.path`, use it as the wiki root.
- If `wiki.path` is not declared, use `wiki/` as the wiki root.
- Read `SCHEMA.md` from the resolved wiki root when it exists.
- Read `index.md` from the resolved wiki root first.
- Read recent entries from `log.md` in the resolved wiki root.
- Glob all markdown files under the resolved wiki root to inventory every wiki page currently present.
- Read `_backlinks.json` from the resolved wiki root to identify high-importance pages (many backlinks) versus orphaned pages (zero backlinks).
- Run the remaining checks in severity order: HIGH findings first, then MEDIUM findings, then LOW findings.

## Step 2: Validate links and index coverage
- Programmatically scan all markdown files for `[[wikilinks]]`.
- Flag broken wikilinks that do not resolve to any wiki page.
- Find pages that exist under the resolved wiki root but are not listed in its `index.md`.
- Check whether index metadata includes current `Last updated` and `Total pages` values.

## Step 3: Validate frontmatter and tags
- Check every active wiki page for required frontmatter: `title`, `created`, `updated`, `type`, `tags`, `sources`, `confidence`, `contested`, and `contradictions`.
- Check raw markdown sources for `source_url`, `ingested`, and `sha256` when applicable.
- Extract the tag taxonomy from `SCHEMA.md`; flag tags used on pages but missing from the taxonomy.

## Step 4: Detect contradictions and quality risks
- Look for conflicting claims about the same entity, decision, issue status, or file ownership.
- Report the conflicting pages and the statements that disagree.
- Surface every page with `contested: true` or non-empty `contradictions`.
- List pages with `confidence: low`.
- Flag single-source pages that have no explicit `confidence` field.

## Step 5: Detect orphaned pages
- Cross-reference with `_backlinks.json` from the resolved wiki root: pages with zero backlinks and missing index coverage are strong orphan candidates.
- Flag each orphan with its path and likely category.

## Step 6: Detect source drift
- For each raw markdown file with `sha256` frontmatter, recompute the digest over the body after the closing `---`.
- Flag digest mismatches as source drift or raw immutability violations.

## Step 7: Detect stale content
- Search for references to deleted, renamed, or missing project files.
- Flag claims that appear to describe code paths or behaviors that no longer exist.

## Step 8: Detect missing cross-references
- Find pages that should link to each other but do not.
- Prefer high-value gaps: entity-to-decision, issue-to-lesson, source-to-entity.

## Step 9: Detect page size and template drift
- Flag pages over 200 lines as split candidates.
- Compare representative pages against `.codewiki/templates/` expectations.
- Flag pages whose structure has drifted so far that future maintenance becomes unreliable.

## Step 10: Check log health
- Count `log.md` entries matching `## [YYYY-MM-DD] action | subject`.
- Flag malformed log entries and recommend rotation if the log exceeds 500 entries.
- Include the exact lint log entry the user should append if they approve logging the lint run.

## Step 11: Report findings
- Output a structured report grouped by severity:
  - HIGH: broken links, contradictions, source drift, or materially stale claims
  - MEDIUM: missing index coverage, orphan pages, invalid frontmatter, unknown tags, low-confidence/contested pages
  - LOW: template drift, oversized pages, thin pages, discoverability gaps, log rotation
- If the wiki looks healthy, say so explicitly and list any small improvement opportunities.

## Step 12: Boundaries
- This is a read-only lint pass.
- Do not edit files from this command.
</process>
