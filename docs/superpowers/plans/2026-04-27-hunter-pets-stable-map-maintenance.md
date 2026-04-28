# Hunter Pets Stable And Map Maintenance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the hunter pet window behave clearly when stable data is not loaded, research whether stable data can be loaded without visiting a stable master, modernize the remaining risky API usage, and reduce map-pin lag.

**Architecture:** Keep changes surgical. Add small testable helper modules for stable-list state and zone filtering, then wire them into the existing Lua files without restructuring the addon. Treat APIs that only exist in the WoW client as manual/in-game verification points.

**Tech Stack:** World of Warcraft addon Lua/XML, `C_StableInfo`, `C_Map`, `HereBeDragons-2.0`, `HereBeDragons-Pins-2.0`, `/api`, `/etrace`, BugSack/BugGrabber, local `/usr/bin/lua` for pure helper tests.

---

## File Structure

- Create: `docs/research/stable-data-loading.md`
  - Records the research outcome for whether a hunter's stable data can be read without visiting a stable master.
- Create: `tests/stable_list_state_test.lua`
  - Pure Lua tests for the state helper that classifies stable API results.
- Create: `tests/map_pet_index_test.lua`
  - Pure Lua tests for map-pet indexing and filtering.
- Create: `StablePetList.lua`
  - Small helper layer for stable pet list state, empty/loading messages, and safe filtering.
- Create: `MapPetIndex.lua`
  - Small helper layer for indexing `GHP.pet_by_zones` by map ID and filtering by pin setting.
- Modify: `GiuiceHunterPets.toc`
  - Load the new helper files before the UI files that consume them.
- Modify: `GiuiceHunterPets.lua`
  - Use `StablePetList.lua`, show an actionable empty/loading state, and refresh after stable events.
- Modify: `GiuiceWorldMapButton.lua`
  - Use `MapPetIndex.lua`, register world-map hooks once, and avoid unnecessary pin rebuilds.
- Modify: `GiuiceTooltipEnhancement.lua`
  - Replace repeated linear tameable lookup with an indexed lookup if Task 5 exposes one safely.

## Assumptions

- The current visible bug is caused by `C_StableInfo.GetStabledPetList()` returning no stabled pets for a hunter whose stable cache has not been loaded in the current client/account session.
- This is not yet confirmed. Task 1 must confirm it in-game and research official/community API behavior before implementation decisions depend on it.
- There is no automated WoW-client test runner in this repo. Pure logic gets local Lua tests; frame/API behavior gets manual client verification.
- Do not modify vendored libraries under `Libs/`.
- Do not modify unrelated untracked workspace files such as `.codex`, `AGENTS.md`, `CLAUDE.md`, or `.copilot-instructions.md`.

## Success Criteria

- A second hunter with no loaded stable data no longer sees a silently empty window.
- The window explains the next action or shows loaded active pets/stabled pets when available.
- Research documents whether there is a supported way to read/load stable pets without visiting a stable master.
- Deprecated/high-risk API usage is either replaced or documented as still supported for the target client.
- Opening the world map no longer repeatedly stacks hooks or rebuilds pins when map/filter state has not changed.
- Local Lua tests pass with `/usr/bin/lua`.
- Manual in-game checklist passes after `/reload`.

---

### Task 1: Research Stable Data Loading Without Visiting A Stable

**Files:**
- Create: `docs/research/stable-data-loading.md`

- [ ] **Step 1: Create the research note**

Add this file:

```markdown
# Stable Data Loading Research

## Question

Can GiuiceHunterPets display the full stabled pet list for a hunter before that character visits or opens a stable master after installing/reloading the addon?

## Current Code Path

- `GiuiceHunterPets.lua` calls `C_StableInfo.GetStabledPetList()`.
- The Blizzard stable UI source also builds its stabled list from `C_StableInfo.GetStabledPetList()`.
- `C_StableInfo.GetActivePetList()` is separate and may still return the five active call-pet slots.

## Sources To Check

- Warcraft Wiki: `API_C_StableInfo.GetStabledPetList`
- Warcraft Wiki: `API_C_StableInfo.GetStablePetInfo`
- Warcraft Wiki: `API_C_StableInfo.GetNumStablePets`
- Warcraft Wiki: `API_C_StableInfo.IsAtStableMaster`
- Warcraft Wiki: `PET_STABLE_SHOW`
- Warcraft Wiki: `PET_STABLE_UPDATE`
- In-game `/api C_StableInfo`
- In-game `/etrace` while opening the addon before and after opening a stable master
- Current Blizzard Stable UI source from `Gethe/wow-ui-source` or local `docs/outdated/Blizzard_StableUI.lua.md`

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
  - `GetActivePetList`: record result.
  - `GetStabledPetList`: record result.
  - `GetNumStablePets`: record result.
  - Events seen in `/etrace`: record result.
- After stable master:
  - `GetActivePetList`: record result.
  - `GetStabledPetList`: record result.
  - `GetNumStablePets`: record result.
  - Events seen in `/etrace`: record result.

## Conclusion

Use one of these exact outcomes:

- Supported without visiting stable: describe the API/event that loads or exposes the data.
- Not supported without visiting stable: show an actionable empty state and refresh after `PET_STABLE_SHOW` or `PET_STABLE_UPDATE`.
- Inconclusive: ship the actionable empty state and leave the code path conservative.
```

- [ ] **Step 2: Verify the research note contains no empty conclusion**

Run:

```bash
rtk rg -n "record result|Use one of these exact outcomes" docs/research/stable-data-loading.md
```

Expected before in-game research: matches are present because they are the research worksheet.

- [ ] **Step 3: Perform in-game research**

Use a hunter that reproduces the empty list. Fill every "record result" line in `docs/research/stable-data-loading.md` with actual observed values.

- [ ] **Step 4: Replace worksheet markers with actual findings**

After the in-game test, this command must return no output:

```bash
rtk rg -n "record result|Use one of these exact outcomes" docs/research/stable-data-loading.md
```

Expected: no output.

- [ ] **Step 5: Commit the research**

```bash
git add docs/research/stable-data-loading.md
git commit -m "docs: research stable data loading"
```

---

### Task 2: Add Stable List State Tests

**Files:**
- Create: `tests/stable_list_state_test.lua`
- Create later: `StablePetList.lua`

- [ ] **Step 1: Write the failing test**

Create `tests/stable_list_state_test.lua`:

```lua
package.path = "./?.lua;" .. package.path

local GHP = { utils = {} }
_G.GHP = GHP

dofile("StablePetList.lua")

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTableLength(value, expected, label)
    if type(value) ~= "table" then
        error(label .. ": expected table", 2)
    end
    if #value ~= expected then
        error(string.format("%s: expected length %d, got %d", label, expected, #value), 2)
    end
end

local tests = {}

function tests.nil_stabled_list_is_unloaded()
    local state = GHP.utils.GetStablePetListState(nil, nil)
    assertEqual(state.status, "unloaded", "status")
    assertTableLength(state.pets, 0, "pets")
    assertEqual(state.message, "Stable data is not loaded yet. Open a stable master once on this hunter, then reopen this window.", "message")
end

function tests.empty_stabled_and_empty_active_list_is_empty()
    local state = GHP.utils.GetStablePetListState({}, {})
    assertEqual(state.status, "empty", "status")
    assertTableLength(state.pets, 0, "pets")
    assertEqual(state.message, "No stable pets were returned for this hunter.", "message")
end

function tests.empty_stabled_list_falls_back_to_active_pets()
    local activePets = {
        { name = "Active One", familyName = "Cat", level = 70 },
        { name = "Active Two", familyName = "Wolf", level = 70 },
    }
    local state = GHP.utils.GetStablePetListState({}, activePets)
    assertEqual(state.status, "active-only", "status")
    assertTableLength(state.pets, 2, "pets")
    assertEqual(state.message, "Only active pets are available. Open a stable master once on this hunter to load the full stable.", "message")
end

function tests.stabled_pets_take_priority()
    local stabledPets = {
        { name = "Stable One", familyName = "Bear", level = 70 },
    }
    local activePets = {
        { name = "Active One", familyName = "Cat", level = 70 },
    }
    local state = GHP.utils.GetStablePetListState(stabledPets, activePets)
    assertEqual(state.status, "loaded", "status")
    assertTableLength(state.pets, 1, "pets")
    assertEqual(state.message, nil, "message")
end

function tests.filters_by_name_family_and_level_safely()
    local pets = {
        { name = "Shadow", familyName = "Spirit Beast", level = 70 },
        { name = "Bark", familyName = "Wolf", level = 65 },
        { name = nil, familyName = nil, level = nil },
    }

    local byName = GHP.utils.FilterStablePets(pets, "sha", "name")
    assertTableLength(byName, 1, "byName")
    assertEqual(byName[1].name, "Shadow", "byName first")

    local byFamily = GHP.utils.FilterStablePets(pets, "wolf", "family")
    assertTableLength(byFamily, 1, "byFamily")
    assertEqual(byFamily[1].name, "Bark", "byFamily first")

    local byLevel = GHP.utils.FilterStablePets(pets, "70", "level")
    assertTableLength(byLevel, 1, "byLevel")
    assertEqual(byLevel[1].name, "Shadow", "byLevel first")
end

local passed = 0
for name, test in pairs(tests) do
    test()
    passed = passed + 1
    print("PASS stable_list_state_test." .. name)
end

print(string.format("PASS stable_list_state_test: %d tests", passed))
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
rtk lua tests/stable_list_state_test.lua
```

Expected: FAIL with an error that `StablePetList.lua` cannot be opened.

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/stable_list_state_test.lua
git commit -m "test: cover stable pet list state"
```

---

### Task 3: Implement Stable List State And Empty UI

**Files:**
- Create: `StablePetList.lua`
- Modify: `GiuiceHunterPets.toc`
- Modify: `GiuiceHunterPets.lua`

- [ ] **Step 1: Add the helper implementation**

Create `StablePetList.lua`:

```lua
local addonName, GHP = ...

GHP = GHP or _G.GHP or {}
GHP.utils = GHP.utils or {}

local UNLOADED_MESSAGE = "Stable data is not loaded yet. Open a stable master once on this hunter, then reopen this window."
local ACTIVE_ONLY_MESSAGE = "Only active pets are available. Open a stable master once on this hunter to load the full stable."
local EMPTY_MESSAGE = "No stable pets were returned for this hunter."

function GHP.utils.GetStablePetListState(stabledPets, activePets)
    if stabledPets == nil then
        return {
            status = "unloaded",
            pets = {},
            message = UNLOADED_MESSAGE,
        }
    end

    if #stabledPets > 0 then
        return {
            status = "loaded",
            pets = stabledPets,
            message = nil,
        }
    end

    if activePets and #activePets > 0 then
        return {
            status = "active-only",
            pets = activePets,
            message = ACTIVE_ONLY_MESSAGE,
        }
    end

    return {
        status = "empty",
        pets = {},
        message = EMPTY_MESSAGE,
    }
end

local function LowerText(value)
    return tostring(value or ""):lower()
end

function GHP.utils.FilterStablePets(pets, searchText, searchType)
    if not searchText or searchText == "" then
        return pets
    end

    local needle = searchText:lower()
    local filteredPets = {}

    for _, pet in ipairs(pets) do
        local value
        if searchType == "family" then
            value = pet.familyName
        elseif searchType == "level" then
            value = pet.level
        else
            value = pet.name
        end

        if LowerText(value):find(needle, 1, true) then
            table.insert(filteredPets, pet)
        end
    end

    return filteredPets
end
```

- [ ] **Step 2: Run helper tests to verify they pass**

Run:

```bash
rtk lua tests/stable_list_state_test.lua
```

Expected: all `PASS stable_list_state_test.*` lines and final `PASS stable_list_state_test: 5 tests`.

- [ ] **Step 3: Load the helper before UI files**

Modify `GiuiceHunterPets.toc` so `StablePetList.lua` loads before `GiuiceHunterPetListItemMixin.lua` and `GiuiceHunterPets.lua`:

```toc
# Templates
GiuiceHunterPets.xml
StablePetList.lua
GiuiceHunterPetListItemMixin.lua
GiuiceWorldMapButton.lua
```

- [ ] **Step 4: Add an empty-state font string to the main frame**

In `CreateMainFrame()` after `frame.scrollChild = scrollChild`, add:

```lua
    local emptyState = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyState:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 16, -16)
    emptyState:SetPoint("RIGHT", scrollFrame, "RIGHT", -16, 0)
    emptyState:SetJustifyH("LEFT")
    emptyState:SetText("")
    emptyState:Hide()

    frame.emptyState = emptyState
```

- [ ] **Step 5: Use stable list state and safe filtering**

Replace `GHP.utils.UpdatePetList` in `GiuiceHunterPets.lua` with:

```lua
function GHP.utils.UpdatePetList(frame, searchText)
    local scrollChild = frame.scrollChild

    for _, child in pairs({ scrollChild:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local stabledPets = C_StableInfo.GetStabledPetList()
    local activePets = C_StableInfo.GetActivePetList()
    local state = GHP.utils.GetStablePetListState(stabledPets, activePets)
    local filteredPets = GHP.utils.FilterStablePets(state.pets, searchText, frame.searchType())

    if frame.emptyState then
        if state.message and #filteredPets == 0 then
            frame.emptyState:SetText(state.message)
            frame.emptyState:Show()
        else
            frame.emptyState:Hide()
        end
    end

    local previousElement
    local totalHeight = 0

    for _, petInfo in ipairs(filteredPets) do
        local petContainer = GHP.utils.CreatePetEntry(scrollChild, petInfo)
        petContainer:SetSize(scrollChild:GetWidth() - 8, 70)
        if previousElement then
            petContainer:SetPoint("TOPLEFT", previousElement, "BOTTOMLEFT", 0, -2)
        else
            petContainer:SetPoint("TOPLEFT", 0, 0)
        end
        previousElement = petContainer
        totalHeight = totalHeight + 72
    end

    if #filteredPets > 0 then
        GHP.utils.ShowPetDetails(GHP.frames.mainFrame.detailPanel, filteredPets[1])
    end

    scrollChild:SetHeight(math.max(totalHeight, frame:GetHeight()))
end
```

- [ ] **Step 6: Run local tests again**

Run:

```bash
rtk lua tests/stable_list_state_test.lua
```

Expected: all tests pass.

- [ ] **Step 7: In-game verification**

After `/reload`, verify:

```text
1. Hunter with known loaded stable: /hunterpets shows stabled pets.
2. Search by name filters without Lua errors.
3. Search by family filters without Lua errors.
4. Search by level filters without Lua errors.
5. Hunter with unloaded stable: /hunterpets shows a clear message instead of a silent blank list.
6. Opening a stable master fires PET_STABLE_SHOW/PET_STABLE_UPDATE and refreshes the window.
```

- [ ] **Step 8: Commit stable list fix**

```bash
git add StablePetList.lua GiuiceHunterPets.toc GiuiceHunterPets.lua tests/stable_list_state_test.lua
git commit -m "fix: show stable list loading state"
```

---

### Task 4: Review And Modernize Deprecated Or Risky APIs

**Files:**
- Modify: `GiuiceWorldMapButton.lua`
- Modify: `docs/research/stable-data-loading.md`

- [ ] **Step 1: Confirm current active deprecated API hits**

Run:

```bash
rtk rg -n "\b(GetSpellInfo|GetSpellCooldown|GetSpellTexture|GetSpellCharges|IsUsableSpell|GetNumSpellTabs|GetSpellTabInfo|GetSpellBookItemName|SetPortraitToTexture|GetStablePetInfo|GetStablePetFoodTypes|PlayerModel)\b" --glob '!Libs/**' --glob '!docs/outdated/**' --glob '!scrapper/**'
```

Expected current active hits:

```text
GiuiceWorldMapButton.lua: PlayerModel
GiuiceHunterPets.lua: commented SetPortraitToTexture only
```

- [ ] **Step 2: Replace tooltip `PlayerModel` with a guarded model preview toggle**

In `GiuiceWorldMapButton.lua`, replace:

```lua
local petTooltipModel = CreateFrame("PlayerModel", "GHPTooltipModel", GameTooltip)
petTooltipModel:Hide()
```

with:

```lua
local petTooltipModel
```

Replace `SetupTooltipModel(displayId)` with:

```lua
local function SetupTooltipModel(displayId)
    if not displayId then
        return
    end

    if not petTooltipModel then
        petTooltipModel = CreateFrame("ModelScene", "GHPTooltipModel", GameTooltip, "PanningModelSceneMixinTemplate")
        petTooltipModel:SetSize(130, 130)
        petTooltipModel:SetFrameStrata("TOOLTIP")
    end

    petTooltipModel:ClearAllPoints()
    petTooltipModel:SetPoint("TOPRIGHT", GameTooltip, "TOPRIGHT", -4, -30)
    petTooltipModel:ClearScene()
    petTooltipModel:TransitionToModelSceneID(718, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)

    local actor = petTooltipModel:GetActorByTag("pet")
    if not actor then
        actor = petTooltipModel:CreateActorByTag("pet")
    end

    if actor then
        actor:SetModelByCreatureDisplayID(displayId)
        actor:SetScale(0.8)
        actor:Show()
    end

    petTooltipModel:Show()
end
```

Replace tooltip hide code:

```lua
petTooltipModel:Hide()
```

with:

```lua
if petTooltipModel then
    petTooltipModel:Hide()
end
```

- [ ] **Step 3: Run static search again**

Run:

```bash
rtk rg -n "\b(PlayerModel|SetPortraitToTexture|GetSpellInfo|GetStablePetInfo)\b" --glob '!Libs/**' --glob '!docs/outdated/**' --glob '!scrapper/**'
```

Expected:

```text
GiuiceHunterPets.lua: commented SetPortraitToTexture only
GiuiceWorldMapButton.lua: no PlayerModel
GiuiceWorldMapButton.lua: C_Spell.GetSpellInfo only, not global GetSpellInfo
```

- [ ] **Step 4: In-game verification**

After `/reload`, hover a world-map pet pin.

Expected:

```text
1. Tooltip opens.
2. Pet name/family/level lines still render.
3. Model preview either renders or fails silently without Lua errors.
4. BugSack/BugGrabber reports no errors from GHPTooltipModel.
```

- [ ] **Step 5: Commit API modernization**

```bash
git add GiuiceWorldMapButton.lua docs/research/stable-data-loading.md
git commit -m "fix: modernize map tooltip model preview"
```

---

### Task 5: Add Map Pet Index Tests

**Files:**
- Create: `tests/map_pet_index_test.lua`
- Create later: `MapPetIndex.lua`

- [ ] **Step 1: Write the failing test**

Create `tests/map_pet_index_test.lua`:

```lua
package.path = "./?.lua;" .. package.path

local GHP = {}
_G.GHP = GHP

dofile("MapPetIndex.lua")

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTableLength(value, expected, label)
    if type(value) ~= "table" then
        error(label .. ": expected table", 2)
    end
    if #value ~= expected then
        error(string.format("%s: expected length %d, got %d", label, expected, #value), 2)
    end
end

local pets = {
    { zoneID = 1, name = "Common Cat", class = "Normal", family = { 1, "Cat" }, coords = { { 10, 20 } } },
    { zoneID = 1, name = "Rare Wolf", class = "Rare", family = { 2, "Wolf" }, coords = { { 30, 40 } } },
    { zoneID = 1, name = "Elite Bear", class = "Elite", family = { 3, "Bear" }, coords = { { 50, 60 } } },
    { zoneID = 2, name = "Other Zone", class = "Rare", family = { 4, "Fox" }, coords = { { 70, 80 } } },
}

local index = GHP.BuildMapPetIndex(pets)

local allPets = GHP.GetPetsForMap(index, 1, 1)
assertTableLength(allPets, 3, "allPets")
assertEqual(allPets[1].name, "Common Cat", "allPets first")

local rarePets = GHP.GetPetsForMap(index, 1, 2)
assertTableLength(rarePets, 1, "rarePets")
assertEqual(rarePets[1].name, "Rare Wolf", "rarePets first")

local elitePets = GHP.GetPetsForMap(index, 1, 3)
assertTableLength(elitePets, 1, "elitePets")
assertEqual(elitePets[1].name, "Elite Bear", "elitePets first")

local disabledPets = GHP.GetPetsForMap(index, 1, 4)
assertTableLength(disabledPets, 0, "disabledPets")

local missingMapPets = GHP.GetPetsForMap(index, 999, 1)
assertTableLength(missingMapPets, 0, "missingMapPets")

print("PASS map_pet_index_test: map indexing and filtering")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
rtk lua tests/map_pet_index_test.lua
```

Expected: FAIL with an error that `MapPetIndex.lua` cannot be opened.

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/map_pet_index_test.lua
git commit -m "test: cover map pet indexing"
```

---

### Task 6: Implement Map Pin Indexing And Hook Guard

**Files:**
- Create: `MapPetIndex.lua`
- Modify: `GiuiceHunterPets.toc`
- Modify: `GiuiceWorldMapButton.lua`
- Modify: `GiuiceTooltipEnhancement.lua`

- [ ] **Step 1: Add the map index helper**

Create `MapPetIndex.lua`:

```lua
local addonName, GHP = ...

GHP = GHP or _G.GHP or {}

local pinSettingsTableOptions = {
    [1] = "allpets",
    [2] = "rarepets",
    [3] = "elitepets",
    [4] = "nopets",
}

function GHP.BuildMapPetIndex(pets)
    local index = {}

    for _, petData in ipairs(pets or {}) do
        if petData.zoneID then
            index[petData.zoneID] = index[petData.zoneID] or {}
            table.insert(index[petData.zoneID], petData)
        end
    end

    return index
end

function GHP.GetPetsForMap(index, mapID, settingValue)
    if not mapID or settingValue == 4 then
        return {}
    end

    local setting = pinSettingsTableOptions[settingValue or 1]
    local petsForMap = index and index[mapID] or {}
    local filteredPets = {}

    for _, petData in ipairs(petsForMap) do
        if setting == "allpets"
            or (setting == "rarepets" and petData.class == "Rare")
            or (setting == "elitepets" and petData.class == "Elite") then
            table.insert(filteredPets, petData)
        end
    end

    return filteredPets
end

function GHP.BuildTameableCreatureIndex(pets)
    local index = {}

    for _, petData in ipairs(pets or {}) do
        local npcId = petData.NpcId or petData.id
        if npcId then
            index[npcId] = true
        end
    end

    return index
end
```

- [ ] **Step 2: Run map index tests**

Run:

```bash
rtk lua tests/map_pet_index_test.lua
```

Expected: `PASS map_pet_index_test: map indexing and filtering`.

- [ ] **Step 3: Load map helper in TOC**

Modify `GiuiceHunterPets.toc`:

```toc
# Templates
GiuiceHunterPets.xml
StablePetList.lua
MapPetIndex.lua
GiuiceHunterPetListItemMixin.lua
GiuiceWorldMapButton.lua
```

- [ ] **Step 4: Initialize map indexes once**

In `GiuiceWorldMapButton.lua`, near the top after the hunter class guard, add:

```lua
GHP.mapPetIndex = GHP.mapPetIndex or GHP.BuildMapPetIndex(GHP.pet_by_zones)
GHP.tameableCreatureIndex = GHP.tameableCreatureIndex or GHP.BuildTameableCreatureIndex(GHP.pet_by_zones)
```

- [ ] **Step 5: Replace repeated world-map filtering**

Inside `DisplayPetIcons()`, replace the manual loop that builds `filteredPets` with:

```lua
    local filteredPets = GHP.GetPetsForMap(GHP.mapPetIndex, playerMapID, GHP_SavedVars.worldMapPins)
```

- [ ] **Step 6: Replace repeated minimap filtering**

Inside `UpdateMinimapPins()`, replace the manual loop that builds `filteredPets` with:

```lua
    local filteredPets = GHP.GetPetsForMap(GHP.mapPetIndex, playerMapID, GHP_SavedVars.worldMapPins or 1)
```

- [ ] **Step 7: Add a world-map rebuild guard**

Near `DisplayPetIcons()`, add:

```lua
local lastWorldMapPinKey
```

Inside `DisplayPetIcons()`, after `playerMapID` is known and before removing icons, add:

```lua
    local pinKey = tostring(playerMapID) .. ":" .. tostring(GHP_SavedVars.worldMapPins or 1)
    if lastWorldMapPinKey == pinKey then
        return
    end
    lastWorldMapPinKey = pinKey
```

When pins are disabled in `GHP.OnWorldMapPinsSettingChanged`, add:

```lua
        lastWorldMapPinKey = nil
```

- [ ] **Step 8: Guard world-map hooks so they register once**

Replace `ManageWorldMapEvents(value)` with:

```lua
local worldMapHooksRegistered = false

local function ManageWorldMapEvents(value)
    if value ~= 4 and not worldMapHooksRegistered then
        WorldMapFrame:HookScript("OnShow", DisplayPetIcons)
        WorldMapFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        WorldMapFrame:HookScript("OnEvent", function(_, event)
            if event == "ZONE_CHANGED_NEW_AREA" then
                lastWorldMapPinKey = nil
                DisplayPetIcons()
            end
        end)
        worldMapHooksRegistered = true
    elseif value == 4 then
        WorldMapFrame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
        lastWorldMapPinKey = nil
    end
end
```

- [ ] **Step 9: Use indexed tameable lookup in tooltip enhancement**

In `GiuiceTooltipEnhancement.lua`, replace `IsInTameableList(creatureID)` with:

```lua
local function IsInTameableList(creatureID)
    if not creatureID then
        return false
    end

    GHP.tameableCreatureIndex = GHP.tameableCreatureIndex or GHP.BuildTameableCreatureIndex(GHP.pet_by_zones)
    return GHP.tameableCreatureIndex[creatureID] == true
end
```

- [ ] **Step 10: Run local tests**

Run:

```bash
rtk lua tests/map_pet_index_test.lua
rtk lua tests/stable_list_state_test.lua
```

Expected:

```text
PASS map_pet_index_test: map indexing and filtering
PASS stable_list_state_test: 5 tests
```

- [ ] **Step 11: In-game map verification**

After `/reload`, verify:

```text
1. Open world map in a zone with hunter pets: pins render once.
2. Close and reopen world map on the same map/filter: no visible lag spike from duplicate rebuilds.
3. Change setting to Rare: only Rare pins remain.
4. Change setting to Elite: only Elite pins remain.
5. Change setting to Disable: world-map pins disappear.
6. Re-enable All: pins return.
7. Move zones: pins refresh for the new map.
8. Hover beast tooltip: tamable line still appears.
9. BugSack/BugGrabber reports no errors.
```

- [ ] **Step 12: Commit map performance work**

```bash
git add MapPetIndex.lua GiuiceHunterPets.toc GiuiceWorldMapButton.lua GiuiceTooltipEnhancement.lua tests/map_pet_index_test.lua
git commit -m "perf: cache hunter pet map lookups"
```

---

### Task 7: Final Verification And Release Notes

**Files:**
- Modify: `readme.md`
- Modify: `docs/research/stable-data-loading.md`

- [ ] **Step 1: Run static scans**

Run:

```bash
rtk rg -n "\b(PlayerModel|GetSpellInfo\(|GetStablePetInfo\(|SetPortraitToTexture\()" --glob '!Libs/**' --glob '!docs/outdated/**' --glob '!scrapper/**'
```

Expected:

```text
No PlayerModel.
No global GetSpellInfo.
No global GetStablePetInfo.
Only commented SetPortraitToTexture if the comment still exists.
```

- [ ] **Step 2: Run local tests**

Run:

```bash
rtk lua tests/stable_list_state_test.lua
rtk lua tests/map_pet_index_test.lua
```

Expected:

```text
PASS stable_list_state_test: 5 tests
PASS map_pet_index_test: map indexing and filtering
```

- [ ] **Step 3: Update README behavior notes**

Add this section to `readme.md`:

```markdown
## Stable Data Behavior

The pet list uses Blizzard's `C_StableInfo` APIs. If the game client has not loaded the full stable for the current hunter yet, GiuiceHunterPets shows a message instead of an empty silent list. Opening a stable master on that hunter loads the full stable data and the addon refreshes after the stable update events.
```

- [ ] **Step 4: Final in-game checklist**

Run this exact checklist in Retail target client:

```text
1. /reload on hunter with known stable data.
2. Click minimap button: window opens and lists pets.
3. /hunterpets: toggles the same window.
4. Search by name/family/level works.
5. Click a pet: details and model render.
6. Hover ability: spell tooltip opens.
7. Open world map: pins render without repeated visible lag.
8. Change pin settings: All/Rare/Elite/Disable behave correctly.
9. Hover map pin: tooltip opens without Lua errors.
10. Log into second hunter with unknown stable state: window shows either pets or stable-loading guidance, not a blank silent list.
11. Open a stable master on second hunter: list refreshes.
```

- [ ] **Step 5: Commit docs**

```bash
git add readme.md docs/research/stable-data-loading.md
git commit -m "docs: document stable data behavior"
```

- [ ] **Step 6: Inspect final diff**

Run:

```bash
git status --short
git log --oneline -5
```

Expected:

```text
Only intentional tracked changes are present.
Recent commits correspond to research, tests, stable fix, API modernization, map performance, and docs.
```

---

## Self-Review

- Spec coverage:
  - Stable blank window: Tasks 1-3.
  - Research alternative to visiting stable: Task 1.
  - Deprecated/risky APIs: Task 4 and Task 7 static scan.
  - Map lag: Tasks 5-6.
  - Verification: Tasks 2, 3, 5, 6, 7.
- Placeholder scan:
  - The plan contains no implementation placeholders. Task 1 intentionally starts as a research worksheet and requires replacing worksheet markers before its commit.
- Type consistency:
  - `GHP.utils.GetStablePetListState`, `GHP.utils.FilterStablePets`, `GHP.BuildMapPetIndex`, `GHP.GetPetsForMap`, and `GHP.BuildTameableCreatureIndex` are defined before use.
  - Test names and helper names match implementation snippets.
