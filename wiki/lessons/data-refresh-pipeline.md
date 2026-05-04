---
type: lesson
id: LESSON-001
title: Data Refresh Pipeline Operations
created: 2026-05-04
updated: 2026-05-04
tags: [lesson, cli]
sources: [wiki/raw/specs/data-refresh-runbook.md]
confidence: high
contested: false
contradictions: []
verified_by: human
approved: true
linked_issues: []
---

# LESSON-001: Data Refresh Pipeline Operations

## Trigger

Run the data refresh pipeline when:
- A new WoW patch adds zones, pets, or stable master NPCs
- Wowhead has updated pet or stable master data
- Existing `Data.lua` has known coordinate or zone inaccuracies

## Verified Lesson

### Authority Hierarchy

The checked-in production `Data.lua` is the **trusted shipped baseline** — validated by real player use. The pipeline treats Wowhead as a **corrective/additive layer**, not the primary authority:

1. **Wowhead scrape succeeds** → scraper wins, baseline is overridden
2. **Wowhead fails for a pet** → `Data.lua` baseline record used as fallback
3. **Entire family fails to parse or has no cache** → all pets for that family loaded from baseline
4. **Build fails** → only when zero total records are produced

`scrapper/wow_pets.db` is **auxiliary/comparison only** — never overrides baseline without explicit audit.

### Two Backends (Shared Cache)

| Module | Speed | When to Use |
|--------|-------|-------------|
| `scrapper.refresh_data_v_fast` (FastFetcher) | ~3-4x faster | **Default.** Python urllib with gzip/brotli, keep-alive, Chrome headers, referer chain, jitter. |
| `scrapper.refresh_data` (agent-browser) | Slower | Fallback if v-fast fails. Left untouched for stability. |

Cache and manifest are shared — switch freely between backends.

### Operational Commands

**Pets:**

```bash
# Collect (resumable, re-run until 0 new pages)
python3 -m scrapper.refresh_data_v_fast collect-pets --limit-pages 200 --delay 2

# Build from cache
python3 -m scrapper.refresh_data_v_fast build-pets --from-cache --output scrapper/generated/Data.candidate.lua

# Inspect reports
head -50 scrapper/generated/pet-fallback.md        # baseline recoveries
head -50 scrapper/generated/pet-skipped.md          # lost pets (usually dungeon-only)
head -50 scrapper/generated/pet-scraper-vs-baseline-diff.md  # zone/coord mismatches
```

**Stable Masters:**

```bash
python3 -m scrapper.refresh_data_v_fast collect-stable-masters --limit-pages 200 --delay 2
python3 -m scrapper.refresh_data_v_fast build-stable-masters --from-cache --output scrapper/generated/StableMastersData.lua
```

No shipped baseline exists for stable masters — skip-and-continue per record, but no fallback.

### Promotion Checklist

Replace `Data.lua` only when:
- `pet-fallback.md` is within expected range (no massive regressions)
- `pet-scraper-vs-baseline-diff.md` audited line-by-line
- `pet-validation-errors.md` is empty/absent
- Spot-check of current-expansion pets exists in output

```bash
cp Data.lua Data.lua.bak
cp scrapper/generated/Data.candidate.lua Data.lua
```

## Evidence

### Locked-in Decisions

| Topic | Decision |
|-------|----------|
| Default backend | `refresh_data_v_fast` (FastFetcher with gzip + keep-alive) |
| Fallback source | Shipped `Data.lua` is authority |
| `wow_pets.db` | Auxiliary/comparison only |
| Drop on load | Rows with `zoneID=0` or no coords are discarded |
| Scraper vs baseline conflict | Scraper wins when scrape succeeds; diff logged |
| Family (id, name) | Wowhead wins over baseline in fallback |
| `g_mapperData` empty/missing | Treated as "no coords" (not fatal); manifest self-heals |
| Malformed row in family listview | Drop row only; family continues |
| Stable masters | No fallback, skip-and-continue per record; root `StableMastersData.lua` feeds [[stable-master-pins]] through `StableMasterIndex.lua` and `StableMasterPins.lua` |
| Stable master Neutral records | Visible to Alliance and Horde in v1; see [[stable-master-neutral-faction]] |
| External `while true` loop | No longer needed |

### Wowhead Source Shape (validated 2026-04-28 / 2026-05-02)

| URL Pattern | Data Extracted |
|-------------|---------------|
| `wowhead.com/hunter-pets` | `g_listviews.pets.data` (families) |
| `wowhead.com/pet=<family-id>` | `g_listviews.tameable.data` (pets in family) |
| `wowhead.com/npc=<npc-id>` | `g_mapperData` (coordinates) |
| `wowhead.com/search?q=stable%20master` | `g_listviews.npcs.data` via `WH.getPageData` pointer (since 2026-05) |

## Future Guidance

- **Cloudflare 403s**: increase `--delay` from 2 to 3 or 4; wait a few minutes before resuming
- **`--reset-cache`**: almost never needed; only when cache key structure changes or forcing total re-collection
- **Manifest self-healing**: pages marked `parse_error` that parse successfully in a subsequent build revert to `ok`
- **Candidate has fewer records than original `Data.lua`**: expected — baseline parser discards ~1400 rows with `zoneID=0` that would fail validation
- **Cache junk from old `agent-browser` runs**: 39-byte stubs marked `ok`; detect and clean with inline Python, then re-collect
- **Stable master release checks**: after promoting `StableMastersData.lua`, verify [[stable-master-pins]] in-game on Horde and Alliance Hunters. Confirm world map pins, minimap pins, tooltip content, toggle refresh, faction filtering, pet pin isolation, and icon texture availability.
