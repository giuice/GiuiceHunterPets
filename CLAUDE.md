# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GiuiceHunterPets is a World of Warcraft addon for hunters. It lists stabled pets in a custom frame, shows pet details with a 3D model viewer, enhances unit tooltips with tamability info, and displays tameable-pet pins on the world map and minimap.

There is no build system, package manager, or automated test suite. The addon is written entirely in Lua and XML, loaded directly by the WoW client.

## Development Workflow

- **No build step.** Changes are live after `/reload` in-game.
- **Verify Lua errors** in the WoW client error frame or via a bug-catching addon (e.g., BugSack).
- **Testing** is done manually in-game on a Hunter character. Many files early-return if the player is not a Hunter (`select(3, UnitClass("player")) ~= 3`).
- **VSCode setup:** The workspace uses the Ketho wow-api extension for Blizzard API annotations (`Lua.workspace.library` points to `~/.vscode/extensions/ketho.wow-api-*/Annotations/Core`).

## Architecture

### Load Order and TOC

`GiuiceHunterPets.toc` defines the exact load order. Every Lua/XML file must be listed there or it will not be loaded by the client. The addon targets multiple WoW versions (retail and classic eras), reflected in the multi-interface header.

Key sections in the TOC:
1. **Libraries** (`Libs/…`) – vendored Ace/Blizzard libraries (LibStub, CallbackHandler, AceLocale, LibDataBroker, LibDBIcon, HereBeDragons).
2. **Locales** (`locales/locales.xml`)
3. **Templates** (`GiuiceHunterPets.xml`, `GiuiceHunterPetListItemMixin.lua`, `GiuiceWorldMapButton.lua`)
4. **Core** (`Localization.lua`, `Data.lua`, `GiuiceHunterPets.lua`, `GiuiceBattlePets.lua`, `GiuiceTooltipEnhancement.lua`)

### Addon Namespace

All core Lua files receive the addon namespace via:

```lua
local addonName, GHP = ...
```

Shared state and utilities are stored on the `GHP` table (e.g., `GHP.utils`, `GHP.frames`, `GHP.FAMILY_DATA`, `GHP.pet_by_zones`).

Saved variables are stored in the global `GHP_SavedVars` table, declared in the TOC (`## SavedVariables: GHP_SavedVars`) and initialized in `Settings.lua`.

### UI Architecture

- **XML Templates** (`GiuiceHunterPets.xml`) define virtual frame/button templates with mixins.
- **Lua Mixins** (`GiuiceHunterPetListItemMixin.lua`) implement the template behavior (e.g., `GiuiceHunterPetListItemMixin:OnClick`, `GiuiceHunterActivePetListMixin:Refresh`).
- **Main Frame** (`GiuiceHunterPets.lua`) creates the primary window programmatically with `CreateFrame`, including the scroll list, search box, dropdown, and detail panel with a `ModelScene`.
- **Active Pet List** is rendered as a template (`GiuiceHunterActivePetListTemplate`) inside the detail panel; it shows the 5 call-pet slots plus a conditional Beast Mastery secondary-pet slot.

### Data Layer

- `Data.lua` contains large static lookup tables:
  - `GHP.FAMILY_DATA[familyID]` – diet, pet type, exotic flag, and ability list.
  - `GHP.pet_by_zones` – array of tameable pets with zone IDs, coordinates, classification, and display ID.
  - `GHP.specSkills` and `GHP.specColors` – mapping from specialization name to spells/color strings.
- `Localization.lua` builds `GHP.exoticFamilies` from a small localized name table to determine whether a family is exotic at runtime.

### Map Pins

`GiuiceWorldMapButton.lua` handles both world-map and minimap pins:
- Uses **HereBeDragons** (`LibStub("HereBeDragons-2.0")`) and **HereBeDragons-Pins-2.0** for coordinate translation and pin management.
- World-map pins are created on the `WorldMapFrame` canvas and filtered by a setting (All / Rare / Elite / Disabled).
- Minimap pins are created as frames parented to `Minimap` and updated on zone-change events.
- The tooltip for map pins embeds a `PlayerModel` (`GHPTooltipModel`) to preview the pet.

### Settings

`Settings.lua` registers a vertical-layout category in the WoW Settings panel:
- Uses `Settings.RegisterProxySetting` with getters/setters backed by `GHP_SavedVars`.
- Changing the world-map pin setting triggers `GHP.OnWorldMapPinsSettingChanged`, which adds/removes pins and hooks/unhooks `WorldMapFrame` events.

### Tooltip Enhancement

`GiuiceTooltipEnhancement.lua` hooks `TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, …)` to append lines showing:
- Creature family and classification
- Whether the beast is tameable (with exotic/Beast-Mastery gating)
- Creature ID

## Important Constraints

- **Library updates:** `important-readme.md` documents the safe process for updating vendored libraries. The folder structure inside `Libs/` must match the paths in the TOC exactly. Extra nested folders or embedded duplicate libraries will break loading.
- **Class guard:** Most files immediately return if the player is not a Hunter. This means some code paths are unreachable on non-Hunter characters.
- **Icon assets:** Pet family icons are expected at `icons/PetIcons/32x32/<FamilyName>.blp`. Missing textures fall back to Blizzard atlas names derived from the family name.

## External References

- `important-readme.md` – step-by-step guide for updating libraries without breaking the addon.
- `AGENTS.md` – behavioral guidelines for coding in this repository (simplicity, surgical changes, goal-driven execution).


<!-- codewiki:start -->
## CodeWiki

This project uses [CodeWiki](https://github.com/user/codewiki) for AI-maintained project knowledge.

CodeWiki is not query-time RAG. It maintains a persistent, human-reviewed markdown wiki that compounds project knowledge across sessions. Use it as durable project memory: read/query the wiki before answering questions that depend on project history, and keep the wiki current when sources or substantial code changes add durable knowledge.

### Operating Flow
- At session start for wiki work: read `.codewiki/config.yml`, `wiki/SCHEMA.md`, `wiki/index.md`, and recent `wiki/log.md` before ingest/query/lint/absorb.
- New external source in `wiki/raw/` or user asks to process docs: use `codewiki-ingest`. Raw sources are immutable; wiki edits are proposed for review.
- User asks how the project works, why a decision was made, or where knowledge lives: use `codewiki-query` and cite wiki pages rather than inventing answers.
- User asks what to do next, resumes a session, starts a feature, or needs routing across CodeWiki workflows: use `codewiki-flow` to choose the next focused skill.
- New feature or larger change: use `codewiki-prd`, then `codewiki-tasks`, then `codewiki-process` to work one task at a time inside the generated phases.
- After a substantial coding session: run `codewiki-absorb` deliberately to capture durable lessons, entities, decisions, and issues from recent changes.
- Periodically or when drift is suspected: run `codewiki-lint` and `codewiki-breakdown` to find contradictions, stale claims, orphan pages, and missing high-signal pages.
- When setting up or auditing Obsidian usage: use `codewiki-obsidian` to keep vault structure, attachments, wikilinks, Dataview-ready frontmatter, and graph navigation compatible with CodeWiki.
- When `.codewiki/state/pending-absorb.jsonl` exists, treat it as a pending follow-up signal: invoke `codewiki-wiki-updater` for durable wiki-relevant changes, or explicitly defer the same work to `codewiki-absorb` at the next completed phase or explicit user request.
- After `codewiki-wiki-updater` proposes a non-trivial wiki change, invoke `codewiki-verifier` for read-only contradiction, reference, frontmatter, index, log, and backlink review before applying approved wiki edits.
- Hooks provide optional context and persistent change signals; they do not replace deliberate ingest/query/absorb/lint work or human approval of wiki writes.

### Schema Discipline
- Treat `wiki/SCHEMA.md` as the routing contract for page types, frontmatter, tag taxonomy, page thresholds, archive policy, index metadata, and log format.
- Raw markdown sources should preserve provenance fields such as `source_url`, `ingested`, and `sha256`; use `codewiki-ingest`/`codewiki-lint` to detect unchanged sources or source drift.
- Wiki pages should make uncertainty visible with `confidence`, `contested`, `contradictions`, and `sources` frontmatter instead of presenting weak claims as settled facts.
- New tags must be added to the schema taxonomy before use. Do not create pages for passing mentions; prefer updating existing pages unless the schema thresholds justify a new page.
- Substantial query answers can be proposed as durable pages under `wiki/queries/` or `wiki/comparisons/`; trivial lookups should stay in chat.
- Use `codewiki-verifier` for read-only review of proposed wiki changes that touch frontmatter, tags, confidence, contradictions, archive moves, index/log updates, or backlinks.

### CodeWiki Skills
- `codewiki-ingest` — Digest a raw source into the wiki
- `codewiki-query` — Search the wiki and synthesize an answer
- `codewiki-lint` — Check the wiki for contradictions, orphan pages, stale claims, and structural drift
- `codewiki-absorb` — Extract durable knowledge from recent git changes
- `codewiki-breakdown` — Find undocumented entities ranked by backlink importance
- `codewiki-obsidian` — Configure and audit the wiki as an Obsidian-compatible vault
- `codewiki-prd` — Create a product requirements document
- `codewiki-tasks` — Generate tasks from a PRD
- `codewiki-process` — Process a phase plan one task at a time
- `codewiki-flow` — Choose the right CodeWiki skill for setup, ingest, query, feature work, change-context follow-up, absorb, breakdown, and lint

Claude Code discovers these from `.claude/skills/codewiki-<name>/SKILL.md` and can invoke them through its native skill system.

### Wiki Location
- Wiki pages: `wiki/`
- Backlinks index: `wiki/_backlinks.json`
- Schema: `wiki/SCHEMA.md`
- Raw sources: `wiki/raw/`
- PRD/task workflow: `.codewiki/tasks/`
- Config: `.codewiki/config.yml`
- Pending absorb state: `.codewiki/state/pending-absorb.jsonl`

### Hooks
Shared CodeWiki hook scripts are installed under `.codewiki/hooks/`. Claude Code wires them through `.claude/settings.json`.

- `PreToolUse` and `PostToolUse` run on `Write|Edit` for short optional context and persistent pending-absorb signals. Hook output is advisory and may not be delivered by every host/runtime; pending signals are deduped in shared state.
- `.codewiki/hooks/session-end.sh` ships as a shared asset but is not wired automatically in v1. Use `codewiki-absorb` deliberately at the end of a substantial session.
<!-- codewiki:end -->
