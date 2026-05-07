---
type: entity
id: ENTITY-002
title: Pet Map Pins
name: Pet Map Pins
created: 2026-05-07
updated: 2026-05-07
tags: [architecture, testing, release]
sources:
  - MapPetIndex.lua
  - GiuiceWorldMapButton.lua
  - Settings.lua
  - Data.lua
  - tests/map_pet_index_test.lua
status: active
key_files:
  - MapPetIndex.lua
  - GiuiceWorldMapButton.lua
  - Settings.lua
  - Data.lua
  - tests/map_pet_index_test.lua
file_hashes: {}
linked_issues: []
linked_lessons:
  - lessons/data-refresh-pipeline.md
confidence: high
contested: false
contradictions: []
verified_by: human
approved: true
---

# ENTITY-002: Pet Map Pins

## Purpose

Pet Map Pins show tameable beast locations on the world map and minimap for Hunter characters. The feature is driven by the shipped `GHP.pet_by_zones` data and is separate from [[stable-master-pins]].

## Key Files

- `Data.lua` defines `GHP.pet_by_zones`, the shipped tameable pet dataset.
- `MapPetIndex.lua` builds a zone-indexed pet lookup and a tameable creature lookup.
- `GiuiceWorldMapButton.lua` renders pet pins, minimap pins, tooltip previews, and family detail windows.
- `Settings.lua` exposes world map and minimap pin controls.
- `tests/map_pet_index_test.lua` verifies map indexing and classification filtering.

## Current Behavior

`MapPetIndex.lua` maps setting values to these modes:

- `1`: all pet pins
- `2`: rare pet pins
- `3`: elite pet pins
- `4`: disabled
- `5`: rare and elite pet pins

The `Rare and Elite` mode includes pets classified as `Rare`, `Elite`, or `Rare Elite`. This matters because the UI label describes a combined filter, not only the exact `Rare Elite` classification.

The map index ignores pet rows without a `zoneID`. `GHP.BuildTameableCreatureIndex` indexes `NpcId` or `id` so tooltip enhancement can identify tameable beasts without scanning the full pet table repeatedly.

## Runtime Scope

Pet map pin modules are covered by [[hunter-only-runtime-initialization]]. Non-Hunter characters should not initialize the pet dataset, settings, map indexes, map pins, minimap pins, or tooltip hooks.

## Verification

Automated coverage:

- `tests/map_pet_index_test.lua` verifies all, rare, elite, rare-and-elite, disabled, and missing-map filtering behavior.

Manual in-game checks remain required for world map rendering, minimap rendering, tooltip preview models, and settings panel behavior.

## Related Pages

- [[hunter-only-runtime-initialization]] — class guard behavior for `.toc`-loaded modules
- [[stable-master-pins]] — separate map pin system for stable master NPCs
- [[data-refresh-pipeline]] — pet dataset refresh and release checks
