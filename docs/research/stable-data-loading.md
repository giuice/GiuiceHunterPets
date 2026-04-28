# Stable Data Loading Research

## Question

Can GiuiceHunterPets display the full stabled pet list for a hunter before that character visits or opens a stable master after installing/reloading the addon?

## Current Code Path

- `GiuiceHunterPets.lua` calls `C_StableInfo.GetStabledPetList()`.
- The packaged Blizzard Stable UI source in `docs/outdated.tar.gz` also refreshes the stabled list from `C_StableInfo.GetStabledPetList()`.
- `C_StableInfo.GetActivePetList()` is separate and may still return the active call-pet slots.

## Sources Checked

- Warcraft Wiki: `API_C_StableInfo.GetStabledPetList`
- Warcraft Wiki: `API_C_StableInfo.GetStablePetInfo`
- Warcraft Wiki: `API_C_StableInfo.GetNumStablePets`
- Warcraft Wiki: `API_C_StableInfo.IsAtStableMaster`
- Warcraft Wiki: `PET_STABLE_SHOW`
- Warcraft Wiki: `PET_STABLE_UPDATE`
- Packaged local Blizzard Stable UI source: `docs/outdated.tar.gz` -> `outdated/Blizzard_StableUI.lua.md`

## Source Findings

- Warcraft Wiki documents the stable API surface, including `C_StableInfo.GetStabledPetList`, `C_StableInfo.GetActivePetList`, `C_StableInfo.GetNumStablePets`, and `C_StableInfo.IsAtStableMaster`, but does not document an addon-callable API that explicitly requests or preloads the full hunter stable away from a stable master.
- Warcraft Wiki documents `PET_STABLE_SHOW` and `PET_STABLE_UPDATE` as StableInfo events with no payload.
- The packaged Blizzard Stable UI source registers `PET_STABLE_SHOW` on load and `PET_STABLE_UPDATE` while shown. Its `StableStabledPetListMixin:Refresh()` assigns `self.pets = C_StableInfo.GetStabledPetList()` and then rebuilds displayed pets from that list.
- The packaged Blizzard source also uses `C_StableInfo.GetStablePetInfo(index)` for slot-specific stable reads, but those reads are part of the stable UI flow and are not evidence of a preload mechanism.

## In-Game Test Script

Run these in-game on a hunter before opening a stable master:

```lua
/dump C_StableInfo.GetActivePetList()
/dump C_StableInfo.GetStabledPetList()
/dump C_StableInfo.GetNumActivePets()
/dump C_StableInfo.GetNumStablePets()
/dump C_StableInfo.IsAtStableMaster()
```

Then open a stable master and run the same commands again:

```lua
/dump C_StableInfo.GetActivePetList()
/dump C_StableInfo.GetStabledPetList()
/dump C_StableInfo.GetNumActivePets()
/dump C_StableInfo.GetNumStablePets()
/dump C_StableInfo.IsAtStableMaster()
```

## Findings

- Before stable master:
  - `GetActivePetList`: returned 2 active pets, `Milla` and `Pipica`.
  - `GetStabledPetList`: returned an empty table.
  - `GetNumActivePets`: returned `2`.
  - `GetNumStablePets`: returned `0`.
  - `IsAtStableMaster`: returned `false`.
  - Events seen in `/etrace`: not captured.
- After stable master:
  - `GetActivePetList`: not observed in this coding session.
  - `GetStabledPetList`: not observed in this coding session.
  - `GetNumStablePets`: not observed in this coding session.
  - Events seen in `/etrace`: not observed in this coding session.

## Conclusion

Inconclusive for hunters that have pets in the stable but have not loaded stable data yet. Confirmed for hunters with an empty stable: `GetStabledPetList()` can legitimately return an empty table while `GetActivePetList()` returns active pets before visiting a stable master.

The researched API/source material does not show a supported way to force-load a hunter's full stable list without opening a stable master. GiuiceHunterPets should therefore handle `nil` or empty stabled-list results as a normal loading/empty state, show active pets when only active data is available, render active-pet detail data safely, and refresh after `PET_STABLE_SHOW` or `PET_STABLE_UPDATE`.

## References

- https://warcraft.wiki.gg/wiki/API_C_StableInfo.GetStabledPetList
- https://warcraft.wiki.gg/wiki/API_C_StableInfo.GetStablePetInfo
- https://warcraft.wiki.gg/wiki/API_C_StableInfo.GetNumStablePets
- https://warcraft.wiki.gg/wiki/API_C_StableInfo.IsAtStableMaster
- https://warcraft.wiki.gg/wiki/PET_STABLE_SHOW
- https://warcraft.wiki.gg/wiki/PET_STABLE_UPDATE
