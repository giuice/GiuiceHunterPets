# Pet And Stable Data Refresh Design

Date: 2026-04-28

## Goal

Update GiuiceHunterPets data with current hunter pet records first, then add stable master data if it is viable within the same data-pipeline shape.

The priority is data freshness. World map pin defaults, rare-only defaults, and stable master rendering behavior are intentionally out of scope until the generated data is reliable.

## Scope

### In

- Diagnose and repair the current pet data pipeline in `scrapper/hunterpets.py`.
- Generate an updated `Data.lua` that preserves the existing `GHP.pet_by_zones` shape.
- Validate generated pet data before replacing the checked-in file.
- Investigate whether stable master data can use the same collect-normalize-export flow.
- Add stable master data as a separate table/file if the source can be converted reliably.

### Out

- Changing map pin defaults.
- Adding or changing settings UI.
- Rendering stable master pins on the map.
- Rewriting the map pin system.
- Manual in-game stable master data collection.

## Approach

Use a staged data refresh.

1. Pets are the main path. Make the existing scraper/exporter run, or replace only the broken collection layer if Playwright is the blocker.
2. Stable masters follow immediately after pet export is healthy. Try to reuse the same pipeline structure if the source can provide NPC IDs, names, zones, and coordinates.
3. If stable masters require a substantially different extraction path, keep a separate exporter but reuse small shared helpers for Lua generation and validation where useful.

This keeps the first useful result narrow: an updated `Data.lua`. Stable master data remains important, but it should not block pet data refresh if its source is messier.

## Data Flow

The preferred pipeline shape is:

```text
source pages or source files
  -> collect raw records
  -> normalize into project records
  -> validate required fields
  -> export Lua table
  -> review diff
```

For pets, the normalized record must continue matching `GHP.pet_by_zones`:

```lua
{
    zone_name = "Isle of Dorn",
    zoneID = 2248,
    name = "Adolescent Darkwolf",
    maxlevel = 80,
    minlevel = 70,
    class = "Normal",
    family = { 1, "Wolf" },
    displayId = 70178,
    NpcId = 226296,
    coords = { { 59.4, 34.6 } },
}
```

For stable masters, the normalized record should be separate from pets:

```lua
{
    npcID = 99856,
    name = "Stable Master Name",
    zoneID = 84,
    coords = { { 67.8, 71.4 } },
    faction = "Alliance",
}
```

## File Design

- Keep `Data.lua` as the production pet data file.
- Use generated temporary output before replacing `Data.lua`, such as `scrapper/generated/Data.lua`.
- If stable master export is viable, create a separate production data file such as `StableMastersData.lua`.
- Do not merge stable masters into `GHP.pet_by_zones`.
- Add any new production data file to `GiuiceHunterPets.toc` only after the generated table validates.

## Validation

Pet export validation should check:

- Generated Lua has valid syntax.
- Every pet has `name`, `NpcId`, `family`, `class`, `zoneID`, and non-empty `coords`.
- Coordinates are numeric percentages.
- Generated count is plausible compared with the previous `Data.lua`.
- A small sample of known current expansion pets exists in the output.

Stable master export validation should check:

- Every stable master has `npcID`, `name`, `zoneID`, and non-empty `coords`.
- `faction` is one of `Alliance`, `Horde`, or `Neutral` when present.
- Stable master data loads without requiring map pin rendering changes.

## Error Handling

- If collection fails, keep the existing committed `Data.lua` unchanged.
- If validation fails, write the invalid generated file to a temporary path for inspection but do not replace production data.
- If stable master extraction is not viable quickly, record why and continue with pet data refresh.

## Success Criteria

- A reproducible command or documented sequence generates updated pet data.
- Updated pet data can replace `Data.lua` without changing addon consumers.
- Generated data passes validation checks.
- Stable master feasibility is resolved:
  - either a generated stable master data file exists, or
  - a short blocker note explains why stable masters need a separate follow-up.

