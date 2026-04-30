# Pitfalls Research

| Pitfall | Warning Sign | Prevention Strategy | Phase |
|---------|--------------|---------------------|-------|
| Shipped-baseline fallback records fail Lua export validation | Fallback rows have `zone_id == 0` or no valid coords | Drop missing/zero `zoneID`, salvage valid coordinate pairs, and drop a row only when no valid coordinates remain | 1 |
| DB is accidentally treated as the authority | New work uses `scrapper/wow_pets.db` instead of production `Data.lua` as the fallback baseline | Keep `Data.lua` as the v1 trusted baseline; use DB only for optional comparison/audit until explicitly reviewed | 1 |
| Fallback accidentally carries removed pets | Records appear for NPCs not listed in current Wowhead tameable rows | Use fallback only inside the current tameable-row loop | 2 |
| Family classification drifts between baseline and Wowhead | Fallback record has historical family while current page lists a different one | Override fallback family with current Wowhead family and log the recovery | 2 |
| Build still fails fast after isolated pet errors | One bad NPC page returns exit code 1 even with many good records | Replace per-pet fatal returns with skipped/fallback flow; fail only when zero records or validation fails | 2 |
| Diff reporting blocks useful output | Zone/coord mismatch prevents export even though a record is valid | Keep diff report informational and audit-oriented | 2 |
| Locationless tameable rows waste fetches | Collector downloads NPC pages that `source_tameable_rows` later discards | Filter rows with missing `location` before appending NPC IDs | 3 |
| Collection errors consume successful page budget | Failed fetch increments `PageBudget.collected` | Do not call `mark_collected()` on fetch error path | 5 |
| Manifest self-healing hides real parse errors | Error entry becomes `ok` after only partial parsing | Call `mark_ok` only after full parse and validation succeeds | 6 |
| Existing red tests obscure new regressions | Test suite remains broadly failing after changes | Update old fail-fast assertions in place and keep new tests focused on changed contracts | All |
