# Phase 1: Shipped Baseline Reader - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-30
**Phase:** 1-Shipped Baseline Reader
**Areas discussed:** Parser scope, Loader API and audit summary, Duplicate fallback rows, Hunter-first data salvage

---

## Parser Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Focused current-shape parser | Parse the exported `GHP.pet_by_zones` shape from `Data.lua`, tolerating small formatting differences. | yes |
| General Lua parser | Support arbitrary Lua syntax. | |

**User's choice:** Focused parser for the current exported shape.
**Notes:** The user agreed the loader should not become a full Lua interpreter.

---

## Loader API And Audit Summary

| Option | Description | Selected |
|--------|-------------|----------|
| Simple primary API | `load_existing_pet_records(path)` returns only `dict[int, PetRecord]`. | yes |
| Compound return | Return records plus summary together. | |
| Log only | Print/log dropped and salvaged counts without structured access. | |

**User's choice:** Keep the main loader API simple.
**Notes:** Summary/audit data is not a core problem for the user. It may exist if lightweight, but it should not complicate the loader contract.

---

## Duplicate Fallback Rows

| Option | Description | Selected |
|--------|-------------|----------|
| Last valid baseline row wins | If the same `NpcId` appears multiple times inside `Data.lua`, keep the later valid row. | yes |
| Merge coordinates | Combine duplicate rows into one fallback record. | |
| Fail on conflict | Treat duplicates as loader errors. | |

**User's choice:** Use the newer/current source when available; for the baseline-only loader, keep the simple last-valid-row behavior.
**Notes:** The user emphasized that current Wowhead information should win when it exists. Phase 1 only reads `Data.lua`; Phase 2 handles Wowhead-vs-baseline authority.

---

## Hunter-First Data Salvage

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve partial trustworthy guidance | Prefer useful partial location information over hiding the pet entirely. | yes |
| Strict all-or-nothing rows | Drop rows whenever any field or coordinate is imperfect. | |

**User's choice:** Preserve validated partial data because the addon exists to help hunters find pets.
**Notes:** The user explicitly framed this as the product truth: think like a hunter searching for a pet. A zone or area can already help the player search.

## the agent's Discretion

- The planner may add lightweight counters or helper functions only if they keep the primary API simple.
- The planner may choose the most maintainable small parser approach that satisfies the current `Data.lua` shape.

## Deferred Ideas

- Phase 2 should enforce current Wowhead scrape data winning over shipped baseline fallback.
- More advanced duplicate audits can wait until real data proves they are needed.
