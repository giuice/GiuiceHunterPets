# Pet And Stable Data Refresh Design

Date: 2026-04-28

## Goal

Update GiuiceHunterPets data with current hunter pet records first, then add stable master data if it is viable within the same data-pipeline shape.

The priority is data freshness. Before writing an implementation plan, the project must validate the current local state and use modern browser/source-discovery tooling to decide the best collection approach. World map pin defaults, rare-only defaults, and stable master rendering behavior are intentionally out of scope until the generated data is reliable.

## Scope

### In

- Diagnose and repair the current pet data pipeline in `scrapper/hunterpets.py`.
- Validate current scraper/tooling state before planning implementation.
- Use the best available modern browser tool to discover the current source shape.
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

## Current State

Validated on 2026-04-28:

- `python3` is available.
- Python `playwright` is not installed in the active environment.
- Importing `scrapper/hunterpets.py` fails with `ModuleNotFoundError: No module named 'playwright'`.
- `scrapper/wow_pets.db` exists with 7071 pet rows and 60 families.
- 360 existing pet rows have empty/null coordinates.
- Existing DB pet timestamps range from 2024-11-16 to 2024-11-17.

## Browser Tooling Decision

Do not assume the old Python Playwright scraper is the best implementation just because it exists. Use browser tooling for discovery first, then choose the simplest repeatable exporter.

Preferred order:

1. **Vercel Agent Browser / Vercel Browser skill, if available**
   - Best for AI-assisted live source discovery.
   - Use it to inspect current Wowhead/source pages, DOM/accessibility snapshots, and network behavior.
   - Prefer it for exploration because it can reveal current data shape without immediately committing to brittle CSS selectors.

2. **Playwright CLI / Playwright trace tooling**
   - Best for reproducible local browser debugging.
   - Use it for saved traces, screenshots, network logs, and deterministic local browser runs.
   - Install/update Python or Node Playwright only after explicit approval, then document the exact setup.

3. **Plain HTTP parser/exporter**
   - Best final exporter if source discovery finds usable JSON/listview data without requiring rendered browser automation.
   - Prefer this over browser automation when possible because it is simpler, faster, and less environment-dependent.

Implementation planning must wait until source discovery records which shape is actually available:

- embedded JSON/listview data suitable for HTTP parsing;
- rendered DOM requiring browser automation;
- blocked/obfuscated data requiring a different source.

## Approach

Use a staged data refresh.

0. Validate tooling and source shape first. Prefer Vercel Browser if available; otherwise use Playwright CLI/trace after approval.
1. Pets are the main path. Make the existing scraper/exporter run, or replace only the broken collection layer if discovery shows a better path.
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

- Current local tooling/data state is documented before implementation planning.
- Browser/source discovery identifies whether the final exporter should use HTTP parsing or browser automation.
- A reproducible command or documented sequence generates updated pet data.
- Updated pet data can replace `Data.lua` without changing addon consumers.
- Generated data passes validation checks.
- Stable master feasibility is resolved:
  - either a generated stable master data file exists, or
  - a short blocker note explains why stable masters need a separate follow-up.
