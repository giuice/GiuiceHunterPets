---
type: log
---

# CodeWiki Log

> Chronological record of accepted wiki actions.
> Format: `## [YYYY-MM-DD] action | subject`
> Actions: ingest, update, query, lint, create, archive, delete, absorb, breakdown
> Rotate when this file exceeds 500 entries.

## [2026-05-04] create | CodeWiki initialized

- CodeWiki initialized. Future updates require human approval.

## [2026-05-04] ingest | WoW API Migration Research

- Created: `wiki/sources/wow-api-migration-sources.md` (SOURCE-001)
- Created: `wiki/concepts/wow-addon-api-migration.md` (CONCEPT-001)
- Updated: `wiki/index.md` — added 2 entries, total pages: 2
- Updated: `wiki/_backlinks.json` — added cross-links between SOURCE-001 and CONCEPT-001
- Raw source: `wiki/raw/specs/wow-api-migration-research.md` — provenance frontmatter added, SHA256 verified, no drift

## [2026-05-04] ingest | Data Refresh Runbook

- Created: `wiki/lessons/data-refresh-pipeline.md` (LESSON-001)
- Updated: `wiki/index.md` — added 1 entry, total pages: 3
- Updated: `wiki/_backlinks.json` — added LESSON-001
- Raw source: `wiki/raw/specs/data-refresh-runbook.md` — provenance frontmatter added, SHA256 verified, no drift

## [2026-05-04] ingest | Pipeline Pitfalls

- Created: `wiki/lessons/pipeline-pitfalls.md` (LESSON-002)
- Updated: `wiki/index.md` — added 1 entry, total pages: 4
- Updated: `wiki/_backlinks.json` — added LESSON-002 with cross-links to LESSON-001
- Raw source: `wiki/raw/specs/pipeline-pitfalls.md` — provenance frontmatter added, SHA256 verified, no drift

## [2026-05-04] ingest | Library Update Safety

- Created: `wiki/lessons/library-update-safety.md` (LESSON-003)
- Updated: `wiki/index.md` — added 1 entry, total pages: 5
- Updated: `wiki/_backlinks.json` — added LESSON-003
- Raw source: `wiki/raw/specs/library-update-safety.md` — provenance frontmatter added, SHA256 verified, no drift

## [2026-05-04] absorb | Stable Master Pins

- Created: `wiki/entities/stable-master-pins.md` (ENTITY-001)
- Created: `wiki/decisions/stable-master-neutral-faction.md` (ADR-001)
- Updated: `wiki/lessons/data-refresh-pipeline.md` — removed stale pending-integration claim and linked stable master release checks
- Updated: `wiki/index.md` — added 2 entries, total pages: 7
- Updated: `wiki/_backlinks.json` — added links among stable master pins, neutral faction decision, and data refresh pipeline lesson

## [2026-05-05] lint | CodeWiki Health Check

- Fixed raw source SHA drift in 4 raw specs by aligning stored hashes to the schema body-hash rule.
- Fixed stale backlinks and one missing required frontmatter field.
- Added addon-relevant cross-links among data refresh, pipeline pitfalls, stable master pins, library safety, and WoW API migration pages.
