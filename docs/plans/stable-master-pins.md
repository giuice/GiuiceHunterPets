# Plan — Stable Master Pins (in-game integration)

## Context

The Python scraper pipeline for stable master data is fully built (`scrapper/refresh_data_v_fast.py build-stable-masters`), but **none of it is wired into the addon**. To finish the feature we need to:

1. Generate `StableMastersData.lua`.
2. Load it in the addon.
3. Render pins on the World Map and Minimap (mirroring the pet pin pattern).
4. Add a settings toggle.
5. Update docs.

The pet pin code in `GiuiceWorldMapButton.lua` is the proven pattern to copy.

## Data shape (already defined in `scrapper/lua_export.py`)

```lua
GHP.stable_masters = {
    {
        ["npcID"] = 6929,
        ["name"] = "Tognus Flintfire",
        ["zone_name"] = "Loch Modan",
        ["zoneID"] = 38,
        ["coords"] = { { 33.4, 47.1 } },
        ["faction"] = "Alliance",  -- or "Horde" / "Neutral"
    },
    ...
}
```

## Files

**Read first** (existing patterns to mirror):
- `GiuiceWorldMapButton.lua` — world map + minimap pin code (`AddWorldMapIconMap`, `AddMinimapIconMap`, event hooks at lines ~245, ~300, ~332, ~488)
- `MapPetIndex.lua` — `BuildMapPetIndex`, `GetPetsForMap` pattern
- `Settings.lua` — checkbox/dropdown registration pattern (lines 60-99)
- `GiuiceHunterPets.toc` — load order

**Create:**
- `StableMastersData.lua` (project root, generated)
- `MapStableMasterIndex.lua` (index helpers)
- `GiuiceStableMasterPins.lua` (render pins, hook events)

**Modify:**
- `GiuiceHunterPets.toc` — register the 3 new files in correct order
- `Settings.lua` — add toggle for stable master pins
- `docs/research/data-refresh-runbook.md` — document v-fast stable master commands + promotion step
- `docs/desc-curse.md` — mention new feature

## Sequence — 6 commits, ~half day junior

### Commit 0 — Generate `StableMastersData.lua`

```bash
python3 -m scrapper.refresh_data_v_fast collect-stable-masters --limit-pages 200 --delay 2
python3 -m scrapper.refresh_data_v_fast build-stable-masters --from-cache --output scrapper/generated/StableMastersData.lua
cp scrapper/generated/StableMastersData.lua StableMastersData.lua
```

Verify: file exists at project root, contains `GHP.stable_masters = {`.

### Commit 1 — TOC registration

In `GiuiceHunterPets.toc` add after `Data.lua` (line 34):

```
StableMastersData.lua
```

Add to Templates section after `GiuiceWorldMapButton.lua` (line 30):

```
MapStableMasterIndex.lua
GiuiceStableMasterPins.lua
```

### Commit 2 — `MapStableMasterIndex.lua`

Mirror `MapPetIndex.lua`. Key functions:

```lua
function GHP.BuildMapStableMasterIndex(masters)
    local index = {}
    for _, m in ipairs(masters or {}) do
        if m.zoneID then
            index[m.zoneID] = index[m.zoneID] or {}
            table.insert(index[m.zoneID], m)
        end
    end
    return index
end

function GHP.GetStableMastersForMap(index, mapID, enabled)
    if not enabled or not mapID then return {} end
    return index and index[mapID] or {}
end
```

### Commit 3 — `GiuiceStableMasterPins.lua`

Skeleton, copying patterns from `GiuiceWorldMapButton.lua`:

```lua
local addonName, GHP = ...
local HBD = LibStub("HereBeDragons-2.0")
local pins = LibStub("HereBeDragons-Pins-2.0")
if (select(3, UnitClass("player")) ~= 3) then return end

local STABLE_KEY = "GiuiceStableMasterIcons"
local STABLE_MINIMAP_KEY = "GiuiceStableMasterMinimapIcons"
local STABLE_TEXTURE = "Interface\\MINIMAP\\Tracking\\StableMaster"

local function EnsureIndex()
    if not GHP.stable_masters then return end
    if GHP.stableMasterIndexSource ~= GHP.stable_masters then
        GHP.stableMasterIndex = GHP.BuildMapStableMasterIndex(GHP.stable_masters)
        GHP.stableMasterIndexSource = GHP.stable_masters
    end
end

local function CreatePin(parent, master, isMinimap)
    local pin = CreateFrame("Button", nil, parent)
    pin:SetSize(isMinimap and 14 or 20, isMinimap and 14 or 20)
    local tex = pin:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetTexture(STABLE_TEXTURE)
    -- Tint by faction
    if master.faction == "Alliance" then tex:SetVertexColor(0.4, 0.6, 1.0)
    elseif master.faction == "Horde" then tex:SetVertexColor(1.0, 0.4, 0.4)
    else tex:SetVertexColor(0.9, 0.9, 0.6) end

    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(master.name)
        GameTooltip:AddLine("Stable Master", 1, 0.82, 0)
        GameTooltip:AddLine(master.zone_name, 0.7, 0.7, 0.7)
        GameTooltip:AddLine(master.faction, 1, 1, 1)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return pin
end

function GHP.RefreshStableMasterWorldMapPins()
    EnsureIndex()
    pins:RemoveAllWorldMapIcons(STABLE_KEY)
    if not GHP_SavedVars.stableMasterPins then return end
    local mapId = WorldMapFrame:GetMapID()
    if not mapId then return end
    for _, m in ipairs(GHP.GetStableMastersForMap(GHP.stableMasterIndex, mapId, true)) do
        for _, c in ipairs(m.coords) do
            local x, y = unpack(c)
            local pin = CreatePin(WorldMapFrame:GetCanvas(), m, false)
            pins:AddWorldMapIconMap(STABLE_KEY, pin, mapId, x/100, y/100, HBD_PINS_WORLDMAP_SHOW_WORLD)
        end
    end
end

function GHP.RefreshStableMasterMinimapPins()
    EnsureIndex()
    pins:RemoveAllMinimapIcons(STABLE_MINIMAP_KEY)
    if not GHP_SavedVars.stableMasterPins then return end
    local mapId = HBD:GetPlayerZone()
    if not mapId then return end
    for _, m in ipairs(GHP.GetStableMastersForMap(GHP.stableMasterIndex, mapId, true)) do
        for _, c in ipairs(m.coords) do
            local x, y = unpack(c)
            local pin = CreatePin(Minimap, m, true)
            pins:AddMinimapIconMap(STABLE_MINIMAP_KEY, pin, mapId, x/100, y/100, true)
        end
    end
end

-- Event hooks
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:SetScript("OnEvent", function()
    GHP.RefreshStableMasterMinimapPins()
end)

WorldMapFrame:HookScript("OnShow", GHP.RefreshStableMasterWorldMapPins)
hooksecurefunc(WorldMapFrame, "OnMapChanged", GHP.RefreshStableMasterWorldMapPins)
```

Notes:
- HBD-Pins keys (`STABLE_KEY`, `STABLE_MINIMAP_KEY`) are independent from pet pins so toggling stable masters does not affect pet pins.
- Faction tint is a quick-and-dirty visual cue; can be replaced with custom textures later.
- Player faction filtering deferred to v2 — show all factions for now (some hunters care about cross-faction stables).

### Commit 4 — Settings toggle

In `Settings.lua`, after the minimap pins block (~line 99), add:

```lua
do
    local name = "Show Stable Master Pins"
    local variableKey = "stableMasterPins"
    local defaultValue = true

    local function GetValue() return GHP_SavedVars.stableMasterPins ~= false end
    local function SetValue(value) GHP_SavedVars.stableMasterPins = value end

    local setting = Settings.RegisterProxySetting(category,
        variableKey, type(defaultValue), name, defaultValue, GetValue, SetValue)

    local tooltip = "Show stable master locations on the world map and minimap."
    setting:SetValueChangedCallback(function(_, value)
        GHP_SavedVars.stableMasterPins = value
        GHP.RefreshStableMasterWorldMapPins()
        GHP.RefreshStableMasterMinimapPins()
    end)
    Settings.CreateCheckbox(category, setting, tooltip)
end
```

Also add `stableMasterPins = true` to the default `GHP_SavedVars` table at line 4.

### Commit 5 — Update runbook

In `docs/research/data-refresh-runbook.md`:

1. Replace all `python3 -m scrapper.refresh_data` with `python3 -m scrapper.refresh_data_v_fast` and update default `--delay 5` to `--delay 2`.
2. Update the Stable Masters section:

```markdown
## Stable Masters

### Coleta + Build

```bash
python3 -m scrapper.refresh_data_v_fast collect-stable-masters --limit-pages 200 --delay 2
python3 -m scrapper.refresh_data_v_fast build-stable-masters --from-cache --output scrapper/generated/StableMastersData.lua
```

### Promoção

```bash
cp scrapper/generated/StableMastersData.lua StableMastersData.lua
```

`/reload` no jogo. Verifique pins no World Map em zonas com stable master conhecido (Stormwind, Orgrimmar, Valdrakken, etc).
```

3. Add `StableMastersData.lua` to "Decisoes Locked-in" table.

### Commit 6 — Update CurseForge description

In `docs/desc-curse.md`, add a sub-section under "Features":

```markdown
### Stable Master Pins (NEW)

Stable Masters now show as pins on the world map and minimap, color-coded by faction. Useful for travelers, fresh alts, and anyone who forgets where the nearest stable is.
```

Add to "What's New":

```markdown
- 🐎 **Stable Master pins** on world map and minimap (toggle in settings).
```

## Verification

After Commit 4:

1. `/reload` in WoW.
2. Open World Map in Stormwind. Pins should appear at known stable masters (Cathedral Square, Trade District).
3. Open settings panel. "Show Stable Master Pins" checkbox toggles them off/on instantly.
4. Walk near a stable master in Orgrimmar/Valdrakken. Minimap pin appears.
5. Hover a pin. Tooltip shows name + "Stable Master" + zone + faction.

## Pitfalls

1. **TOC load order:** `StableMastersData.lua` MUST come BEFORE `GiuiceStableMasterPins.lua` (data must be loaded before code that reads it). Same rule as `Data.lua` before `GiuiceWorldMapButton.lua`.
2. **HBD-Pins keys:** `STABLE_KEY` and `STABLE_MINIMAP_KEY` must NOT collide with pet pin keys (`GiuiceHunterPetsIcons`, `GiuiceHunterPetsMinimapIcons`). Verified separate above.
3. **Settings default:** new players need `stableMasterPins = true` in the default SavedVars seed (Settings.lua:4-10) so the feature is on by default.
4. **Class guard:** the `select(3, UnitClass("player")) ~= 3` early-return is in place; non-Hunter chars get nothing. Same as pet pins.
5. **Texture path:** `Interface\MINIMAP\Tracking\StableMaster` is the standard atlas — verify it exists in current client; fall back to atlas `"StableMaster"` or a custom BLP if missing.
6. **Coords scaling:** scraped coords are 0-100 (already validated by lua_export). Divide by 100 for HBD-Pins.

## Total sizing

| Commit | Estimate |
|---|---|
| 0 — generate data | 0.25 day |
| 1 — TOC + file move | 0.1 day |
| 2 — Index helpers | 0.1 day |
| 3 — Pin renderer | 1.5h |
| 4 — Settings toggle | 0.25h |
| 5 — Runbook | 0.5h |
| 6 — CurseForge desc | 0.25h |
| **Total** | **~half day** |

## How to use this plan in a new chat

```
Read docs/plans/stable-master-pins.md and execute commits 0-6 in order.
Skip ExitPlanMode; just implement directly.
```
