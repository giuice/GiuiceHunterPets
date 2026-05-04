---
type: concept
id: CONCEPT-001
title: WoW Addon API Migration (11.0.7 to 12.0.5)
created: 2026-05-04
updated: 2026-05-04
tags: [architecture, concept]
sources: [wiki/raw/specs/wow-api-migration-research.md]
confidence: high
contested: false
contradictions: []
verified_by: human
approved: true
---

# WoW Addon API Migration (11.0.7 to 12.0.5)

## Definition

The migration path from WoW patch 11.0.7 (The War Within baseline) through 12.0.5 (Midnight live) involves 10 patch hops where Blizzard introduced progressively stricter addon API restrictions. The key architectural insight is that **12.0.0 and 12.0.1 must be treated as a single breaking wave**, not separate milestones.

## Breaking Wave: 12.0.0 + 12.0.1

Blizzard's WoWUIDev communications and Wowhead-archived notes confirm that most of the final addon API restrictions — secret values, protected information, whitelisted spells, aura/cooldown visibility limits, action-bar API restrictions, and unit identity restrictions — landed in **12.0.1** rather than 12.0.0. Treating them as separate milestones creates a false sense of stability at 12.0.0.

Key changes in this wave:
- Addons not updated for Midnight will not load at all
- `Blizzard_Deprecated` aliases are the primary culling surface — old 11.x compat paths disappear here
- Secret values resist `tonumber` conversion and equality comparisons
- Creature info blocked in instances; unit identity restrictions
- Aura vectors and `auraInstanceID` changes
- Action-bar API fallout (March 2026 WoWUIDev notes)

## Critical Audit Points

1. **`Blizzard_Deprecated`**: Search aggressively. Any API reachable only through a deprecated alias in 11.x is at risk of removal in the 12.0.x wave.

2. **Secure-value behavior**: Generated API diffs will not explain why a function now returns a secret value or refuses conversion. This knowledge lives in WoWUIDev Discord and Wowhead-archived Blizzard dev posts, not in mechanical diffs.

3. **Official notes are coarse**: Blizzard patch notes and hotfix logs convey intent and policy but do not enumerate low-level Lua API changes. Use them for risk framing, not for refactoring.

4. **12.0.5 launch instability**: Blizzard acknowledged quality issues at 12.0.5 launch. Hotfix tracking matters — runtime behavior on live may differ from PTR/API dumps.

## Related Pages

- [[wow-api-migration-sources]] — ranked source catalog for this migration

## Open Questions

- Which specific `C_StableInfo` APIs survive the 12.0.x wave unchanged? Not yet audited against the patch ledger.
- Are there `Blizzard_Deprecated` aliases in the current addon code that need proactive replacement?