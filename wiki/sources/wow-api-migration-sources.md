---
type: source-summary
id: SOURCE-001
title: WoW API Migration Sources (11.0.7 to 12.0.5)
created: 2026-05-04
updated: 2026-05-04
raw_source: wiki/raw/specs/wow-api-migration-research.md
tags: [source, architecture]
sources: [wiki/raw/specs/wow-api-migration-research.md]
related_pages: [[wow-addon-api-migration]]
confidence: high
contested: false
contradictions: []
verified_by: human
approved: true
---

# SOURCE-001: WoW API Migration Sources (11.0.7 to 12.0.5)

## Source

Ranked catalog of external sources for migrating a WoW addon from patch 11.0.7 (The War Within) through 12.0.5 (Midnight). Covers 10 active sources and 4 deprecated sources, with usefulness and maintenance-confidence ratings as of April 2026. Includes an 8-step recommended migration-research workflow.

## Ranked Active Sources

| Rank | Source | Usefulness | Confidence (Apr 2026) | Best For |
|------|--------|-----------|----------------------|----------|
| 1 | **Warcraft Wiki** API change summaries + per-patch pages | Highest | High | Human-readable API delta; build patch checklist first |
| 2 | **Ketho/BlizzardInterfaceResources** | Very high | Very high (12.0.5 build 67186, Apr 23 2026) | Mechanical diffs: which function/event/widget exists in 11.0.7 vs 12.0.5 |
| 3 | **KethoDoc** | High-medium | High-medium | Reproducible API dumps against specific client builds; deprecated API may be omitted if `Blizzard_Deprecated` is disabled |
| 4 | **Gethe/wow-ui-source** | High | High | Blizzard UI source, XML templates, mixins, Blizzard addon rewrites; shows how Blizzard migrated its own UI |
| 5 | **Blizzard_APIDocumentation** + `/api` | High (runtime only) | Very high | Confirm final 12.0.5 runtime contract; not sufficient for migration history |
| 6 | **Blizzard official patch notes / hotfix logs** | Low granularity | Very high | Policy intent, risk framing, launch instability; too coarse for API refactoring |
| 7 | **WoWUIDev Discord + Wowhead archives** | Essential | High | Secure-value behavior, secret values, combat-addon restrictions, last-minute API changes not in generated diffs |
| 8 | **wago.tools + Marlamin/wow.tools.local** | Medium | High | Datamining, build diffs, DB2 data; not human-readable migration guidance |
| 9 | **ExportInterfaceFiles code** | Medium | High | Snapshot exact installed client; no historical source unless archived |
| 10 | **Runtime tools** (`/etrace`, DevTool, BugSack) | Low (verification only) | Medium-high | Live-client verification once addon runs on 12.0.5 |

## Deprecated Sources

| Source | Status | Replacement |
|--------|--------|-------------|
| Townlong-Yak FrameXML browser | Gone | Gethe/wow-ui-source |
| Old wow.tools | Legacy/degraded | wago.tools or wow.tools.local |
| Blizzard Interface AddOn Kit | Not updated for years | `ExportInterfaceFiles code` |
| Tekkub's FrameXML mirror | Historical only | Gethe/wow-ui-source |

## Recommended Workflow

1. Create a **patch ledger** from Warcraft Wiki: `11.0.7 → 11.1.0 → 11.1.5 → 11.1.7 → 11.2.0 → 11.2.5 → 11.2.7 → 12.0.0 → 12.0.1 → 12.0.5`.
2. Treat **12.0.0 and 12.0.1 as one breaking wave** — most final addon API work landed in 12.0.1.
3. Use Warcraft Wiki for human-readable delta, then verify mechanically with BlizzardInterfaceResources.
4. Use wow-ui-source for Blizzard UI source changes (XML, templates, mixins).
5. Search `Blizzard_Deprecated` and deprecated aliases aggressively — 12.0.0 is where old 11.x compat paths disappear.
6. Use WoWUIDev/Wowhead for secure-value behavior not captured in API diffs.
7. Use official notes only for policy and stability context.
8. Verify on live 12.0.5 with `/api`, `/etrace`, DevTool, and BugSack.

## Patch Dates and Relevance

| Patch | Date | Key Migration Relevance |
|-------|------|------------------------|
| 11.0.7 | Dec 17, 2024 | Baseline; `Interface: 110007` |
| 11.1.0 | Feb 25, 2025 | Category/grouping metadata, secure-environment changes |
| 11.1.5 | — | UI/API: user-configurable color override system |
| 11.1.7 | Jun 17, 2025 | `AllowAddOnTableAccess`, `C_AddOns.GetAddOnLocalTable` |
| 11.2.0 | Aug 5, 2025 | `TextLocale`, `AllowLoadTextLocale` TOC behavior |
| 11.2.5 | — | Socket APIs moved under `C_ItemSocketInfo` |
| 11.2.7 | — | ChatFrame reorganized into `ChatFrameUtil` / mixins |
| 12.0.0 | — | Wide-reaching addon capability limits; non-updated addons not loadable |
| 12.0.1 | — | Majority of remaining addon/API changes shifted here from 12.0.0 |
| 12.0.5 | Apr 21, 2026 | Current live target; turbulent launch with hotfix tracking needed |

## Candidate Wiki Updates

None beyond this page and [[wow-addon-api-migration]]. Individual source entities (Warcraft Wiki, KethoDoc, etc.) are cataloged here; dedicated entity pages would be justified if multiple wiki sources reference them.

## Approval Checklist

- [x] Human reviewed source summary.
- [x] Human approved related wiki page updates.