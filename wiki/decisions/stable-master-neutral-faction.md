---
type: decision
id: ADR-001
title: Stable Master Neutral Faction Handling
status: accepted
created: 2026-05-04
updated: 2026-05-04
date: 2026-05-04
deciders: [Giuice, Codex]
tags: [decision, release]
sources:
  - .codewiki/tasks/0001-prd-stable-master-pins.md
  - .codewiki/tasks/tasks-0001-prd-stable-master-pins.md
  - StableMasterPins.lua
  - tests/stable_master_pins_settings_test.lua
confidence: medium
contested: false
contradictions: []
verified_by: human
approved: true
---

# ADR-001: Stable Master Neutral Faction Handling

## Context

Stable master records include a `faction` field with values such as `Alliance`, `Horde`, and `Neutral`. The PRD required filtering out opposing-faction stable masters and called out Neutral handling as a decision point because the current source context did not fully prove whether `Neutral` always means usable by both factions.

The renderer needs a deterministic v1 rule so map pins can ship without showing all records to every character.

## Decision

For v1, `faction = "Neutral"` stable master records are visible to both Alliance and Horde Hunters.

`StableMasterPins.lua` implements this by returning visible when `stableMasterData.faction == "Neutral"`, otherwise requiring the record faction to match `UnitFactionGroup("player")`.

## Consequences

Alliance Hunters see Alliance and Neutral stable masters. Horde Hunters see Horde and Neutral stable masters. Opposing-faction stable masters are hidden.

This keeps the map useful without adding a separate Neutral review workflow to the first release. If the data source later proves that `Neutral` means reaction ambiguity rather than usability by both factions, this decision should be revisited before promoting a new stable master dataset.

## Alternatives Considered

- Hide Neutral records until manually validated. This is more conservative but risks omitting useful stable masters from v1.
- Show all stable master records regardless of faction. This conflicts with the product requirement to hide opposing-faction stable masters.
- Add a separate settings filter for Neutral records. This was rejected because per-faction or per-map stable master settings are a non-goal for the first version.
