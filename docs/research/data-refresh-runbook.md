# Data Refresh Runbook

## Source Shape

Validated with `agent-browser 0.26.0` on 2026-04-28/2026-04-29:

- `https://www.wowhead.com/hunter-pets` exposes pet families through `g_listviews.pets.data`.
- `https://www.wowhead.com/pet=<family-id>` exposes tameable NPC rows through `g_listviews.tameable.data`.
- `https://www.wowhead.com/npc=<npc-id>` exposes coordinates through `g_mapperData` when Wowhead has mapped locations.
- `https://www.wowhead.com/search?q=stable%20master` exposes stable master candidates through `g_listviews.npcs.data`.

## Pet Sample

```bash
rtk python3 -m scrapper.refresh_data pets --limit-families 1 --output scrapper/generated/Data.sample.lua
```

Expected:

- Exit code `0`.
- `scrapper/generated/Data.sample.lua` exists.
- `scrapper/generated/Data.sample.lua` contains `GHP.pet_by_zones = {`.
- `scrapper/generated/Data.sample.lua` contains at least one `["coords"] = { {`.

## Full Pet Refresh

```bash
rtk python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua
```

Before replacing production `Data.lua`:

```bash
rtk rg -n 'GHP.pet_by_zones = \{|\["NpcId"\]|\["coords"\]' scrapper/generated/Data.lua
rtk git diff --no-index Data.lua scrapper/generated/Data.lua
```

Review requirements:

- Generated pet count is plausible compared with checked-in `Data.lua`.
- Sample current expansion pets appear in the generated output.
- `scrapper/generated/pet-validation-errors.md` is empty or absent.
- If Wowhead blocks source fetches, `scrapper/generated/pet-refresh-blockers.md` records the HTTP error and production `Data.lua` must not be replaced.
- Coordinate-heavy diffs are expected; missing-coordinate records are not accepted into generated output.

## Stable Master Feasibility

```bash
rtk python3 -m scrapper.refresh_data stable-masters --output scrapper/generated/StableMastersData.lua
```

If the command exits `0`, review:

```bash
rtk rg -n 'GHP.stable_masters = \{|\["npcID"\]|\["faction"\]' scrapper/generated/StableMastersData.lua
rtk sed -n '1,80p' scrapper/generated/stable-master-skipped.md
```

If the command exits non-zero, review:

```bash
rtk sed -n '1,120p' scrapper/generated/stable-master-blockers.md
rtk sed -n '1,120p' scrapper/generated/stable-master-validation-errors.md
```

## Production Replacement

Only replace `Data.lua` after the generated pet file validates and the diff is reviewed.

Only add `StableMastersData.lua` and `GiuiceHunterPets.toc` after stable master validation passes. This phase loads data only; it does not render stable master pins.
