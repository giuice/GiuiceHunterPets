---
source_url: https://github.com/giuice/GiuiceHunterPets/blob/main/research.md
ingested: 2026-05-04
sha256: 67532ce25ec5618c2a7232e868196c12b78698a45e1172882fdad38e8e8a8477
---

## Corrections to your version map

Your overall map is good, but I would adjust it this way:

| Patch      | Migration relevance                                                                                                                                                                                                                    |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **11.0.7** | Your baseline is correct as `Interface: 110007`, but the release was **December 17, 2024**, not early 2025. ([Wowhead][1])                                                                                                             |
| **11.1.0** | February 25, 2025. Your TOC/security expectations are in the right area: category/grouping metadata, addon list changes, secure-environment changes. ([Wowhead][2])                                                                    |
| **11.1.5** | Worth adding. It introduced UI/API work around the user-configurable color override system. ([Warcraft Wiki][3])                                                                                                                       |
| **11.1.7** | June 17, 2025. Add **`AllowAddOnTableAccess`** and `C_AddOns.GetAddOnLocalTable(name)` to your checklist. ([blizzard.gamespress.com][4])                                                                                               |
| **11.2.0** | August 5, 2025. Add **`TextLocale`** and **`AllowLoadTextLocale`** TOC behavior. ([World of Warcraft][5])                                                                                                                              |
| **11.2.5** | Worth adding if the addon touches item sockets. Several socket APIs moved under `C_ItemSocketInfo`. ([Warcraft Wiki][6])                                                                                                               |
| **11.2.7** | Worth adding if the addon touches chat. ChatFrame functions were reorganized into `ChatFrameUtil` / mixins. ([Warcraft Wiki][7])                                                                                                       |
| **12.0.0** | Correct highest-priority breakpoint. Blizzard explicitly described “wide-reaching changes” to addon capabilities, mostly limiting combat automation, and said addons not updated for Midnight would not load. ([World of Warcraft][8]) |
| **12.0.1** | **Do not skip this.** Blizzard shifted a majority of remaining addon/API changes from the 12.0.0 PTR line into **12.0.1** Beta/RC builds. This is the missing migration hop in your list. ([Warcraft Wiki][9])                         |
| **12.0.5** | April 21, 2026. Correct current live target. Also note that Blizzard publicly acknowledged the 12.0.5 launch had stability/quality issues, so hotfix tracking matters for this exact target. ([Notícias Blizzard][10])                 |

---

# Ranked sources for a 11.0.7 → 12.0.5 migration

## 1. Warcraft Wiki: API change summaries and per-patch API pages

**Best entry points**

* **API change summaries**
* **Patch 12.0.0/API changes**
* **Patch 12.0.1/API changes**
* **Patch 12.0.5/API changes**
* Also inspect: 11.1.0, 11.1.5, 11.1.7, 11.2.0, 11.2.5, 11.2.7 API pages.

**What it covers**

This is the best first stop for migration planning. It tracks patch-level API changes including Lua globals, `C_*` namespaces, events, widget APIs, enum/API-documentation changes, and links out to diffs and source resources. The API summary index explicitly covers Lua functions and Widget API changes, and the 12.0.x pages are present for Midnight-era changes. ([Warcraft Wiki][11])

**How it is updated**

Community-maintained, but largely derived from generated API dumps, Blizzard UI source, PTR/live diffs, and contributor review.

**Retail / Classic**

Both exist on the site, but for this migration use the **Retail / Midnight** pages only.

**Maintenance confidence as of April 2026**

**High.** The 12.0.5 API page exists and is updated in the 2026 Midnight window. ([Warcraft Wiki][12])

**Usefulness**

Highest. Build your patch checklist from these pages first, then verify details against source dumps.

---

## 2. Ketho / BlizzardInterfaceResources

**Best entry point**

* GitHub repo: **Ketho/BlizzardInterfaceResources**

**What it covers**

Generated resource dumps for addon development: global API data, events, widget API, CVars, enums, top-level frames, FrameXML-derived mixins/templates, global strings, atlas info, and related interface resources. The repo itself reports current build data for **12.0.5**, build **67186**, dated April 23, 2026. ([GitHub][13])

**How it is updated**

Community-maintained and generated from tooling. The repo notes that API data is dumped via **KethoDoc**, while atlas/global-string/template data is parsed or sourced from other datamining resources. ([GitHub][13])

**Retail / Classic**

Primarily useful here for **Retail / Mainline**. The repo exposes project/build identifiers, including `WOW_PROJECT_MAINLINE` and Midnight expansion constants. ([GitHub][13])

**Maintenance confidence as of April 2026**

**Very high.** The repo shows 12.0.5 build metadata from April 23, 2026. ([GitHub][13])

**Usefulness**

Use this to produce mechanical diffs: “which function/event/widget exists in 11.0.7 versus 12.0.5?”

---

## 3. KethoDoc

**Best entry point**

* GitHub repo: **Ketho/KethoDoc**

**What it covers**

Local addon/tooling for dumping WoW API data. It can dump global APIs, widget APIs, events by API system, CVars, Lua enums, top-level frames, FrameXML functions, and related structures. It is the dump source behind BlizzardInterfaceResources. ([GitHub][14])

**How it is updated**

Community-maintained. You run it against a client build to produce data for that build. The repo explicitly notes deprecated API may be omitted if `Blizzard_Deprecated` is disabled, which matters for your 11.x → 12.0.0 culling audit. ([GitHub][14])

**Retail / Classic**

Mostly useful for **Retail** in this workflow, but conceptually build-dependent. Run it against the specific client branch you care about.

**Maintenance confidence as of April 2026**

**High-to-medium.** It is actively tied to BlizzardInterfaceResources, which is current for 12.0.5, but treat the output as build-specific and verify.

**Usefulness**

Best when you want your own reproducible dump instead of relying only on published diffs.

---

## 4. Gethe / wow-ui-source

**Best entry point**

* GitHub repo: **Gethe/wow-ui-source**

**What it covers**

A Git mirror of Blizzard’s UI source: FrameXML, Blizzard_* addon source, XML templates, mixins, widget usage, and live/PTR/beta branch history. The repo describes branches such as `live`, `ptr`, `ptr2`, and `beta`, with tags for builds. ([GitHub][15])

**How it is updated**

Community mirror of exported Blizzard UI source.

**Retail / Classic**

Best for **Retail / Mainline** source diffs. Do not confuse it with old historical FrameXML mirrors.

**Maintenance confidence as of April 2026**

**High**, though verify the exact tag/build you compare against.

**Usefulness**

Critical for XML/template and Blizzard UI source changes. API dump pages tell you “what changed”; this repo often tells you “how Blizzard adapted its own UI.”

---

## 5. Blizzard in-game API documentation: `Blizzard_APIDocumentation` and `/api`

**Best entry point**

* In game: `/api`
* Blizzard addon: `Blizzard_APIDocumentation`

**What it covers**

Official current-client API documentation exposed inside the game. Warcraft Wiki notes that Blizzard’s API is officially documented through `Blizzard_APIDocumentation` and accessible via `/api`. ([Warcraft Wiki][16])

**How it is updated**

Official Blizzard client data.

**Retail / Classic**

Build-specific. Use it in the **Retail 12.0.5 client** for your target.

**Maintenance confidence as of April 2026**

**Very high**, but it is not historical by itself.

**Usefulness**

Use it to confirm the final 12.0.5 runtime contract after you have read the diffs. It is not enough for migration history.

---

## 6. Blizzard official patch notes and hotfix logs

**Best entry points**

* **Midnight pre-expansion / 12.0.0 official notes**
* **12.0.5 Lingering Shadows official notes**
* **Official hotfix / content update notes**

**What it covers**

Official policy-level and player-facing notes. For 12.0.0, Blizzard explicitly called out broad addon-interface changes aimed at limiting combat automation and said non-updated Midnight addons would not load. ([World of Warcraft][8])

For 12.0.5, the official notes cover UI/accessibility changes and link to support/bug-report channels, but they do not enumerate low-level Lua API diffs. ([Notícias Blizzard][10])

**How it is updated**

Official Blizzard.

**Retail / Classic**

The official hotfix feed covers multiple products, including Retail and Classic variants. Filter for **Retail / Midnight**. ([World of Warcraft][17])

**Maintenance confidence as of April 2026**

**Very high**, but low granularity for addon API.

**Usefulness**

Use for intent, risk framing, launch instability, and UI-facing changes. Do not use it as your primary API diff.

---

## 7. WoWUIDev Discord, plus Wowhead articles that archive Blizzard dev statements

**Best entry points**

* **WoWUIDev Discord**
* Wowhead articles quoting or summarizing Blizzard UI dev posts from WoWUIDev:

  * June 2025 future addon changes statement
  * November 2025 Alpha/Beta addon API restriction updates
  * December 2025 12.0.1 migration/API finalization notes
  * February 2026 secret aura / healer spell whitelist notes
  * March 2026 action-bar API fallout notes

**What it covers**

This is the most important source family for the “addon apocalypse” context: secret values, protected information, whitelisted spells, aura/cooldown visibility, action-bar API restrictions, unit identity restrictions, combat-information limits, and last-minute API changes.

Examples:

* Blizzard communicated future addon changes through WoWUIDev in June 2025. ([Wowhead][18])
* November 2025 notes discussed blocked creature info in instances, unit identity secrets, spellcast/power relaxations, equality comparisons on secret values, `tonumber` restrictions, and aura-vector/auraInstanceID changes. ([Wowhead][19])
* December 2025 notes said most remaining addon changes were moving into **12.0.1**, not 12.0.0, and documented whitelist/duration-object changes. ([Wowhead][20])
* February 2026 notes covered healer spell aura secrecy changes and future spellbook hide/emphasize buff systems. ([Wowhead][21])

**How it is updated**

Community Discord with Blizzard developer participation; Wowhead republishes and archives many major posts.

**Retail / Classic**

The Midnight addon-apocalypse discussion is **Retail**.

**Maintenance confidence as of April 2026**

**High**, but Discord itself is less archival. Prefer Wowhead reposts for durable citations and use Discord for current discussion.

**Usefulness**

Essential for secure environment, secret values, combat-addon restrictions, and migration behavior not captured cleanly in generated API diffs.

---

## 8. wago.tools and Marlamin / wow.tools.local

**Best entry points**

* **wago.tools**
* GitHub repo: **Marlamin/wow.tools.local**

**What it covers**

Datamining and build-diff tooling. Useful for files, manifests, DB2/hotfix data, UI files, and build-to-build diffs. The AddOn Studio reference describes wago.tools as the current up-to-date collection of WoW game data and the successor to old wow.tools. ([AddOn Studio][22])

`wow.tools.local` can run locally, accepts parameters such as WoW folder, product, region, locale, listfile, and supports build diffs, DB2 diffs, and hotfix data. Its latest GitHub release shown was March 31, 2026. ([GitHub][23])

**How it is updated**

wago.tools is a hosted datamining resource. `wow.tools.local` is a local/community tool.

**Retail / Classic**

Potentially both, depending on product/build selected. For your task, target Retail/Mainline.

**Maintenance confidence as of April 2026**

**High** for `wow.tools.local`; wago.tools appears current but is more UI/JS-driven.

**Usefulness**

Best for datamining and file/build diffs, not for human-readable addon migration guidance.

---

## 9. Built-in `ExportInterfaceFiles code` plus local Git

**Best entry point**

* WoW console command: `exportInterfaceFiles code`
* Optional: `exportInterfaceFiles art`

**What it covers**

Extracts the Blizzard UI code from your installed client into local files. This is the most direct way to snapshot the exact 12.0.5 client you have installed and compare it with older source mirrors or another exported build. AddOn Studio and Blizzard forum references both point to `ExportInterfaceFiles code` as the modern replacement for the old AddOn Kit. ([AddOn Studio][22])

**How it is updated**

Official client output, but you must archive snapshots yourself.

**Retail / Classic**

Current installed product. Use the Retail client for this migration.

**Maintenance confidence as of April 2026**

**High** as a client capability; documentation pages around it are older.

**Usefulness**

Good for local verification. Less useful if you need historical 11.0.7 source unless you already have that client or a tagged mirror.

---

## 10. Runtime inspection tools: `/etrace`, DevTool, BugSack/BugGrabber

**Best entry points**

* In game: `/etrace`
* Addon: **DevTool**
* Addons: **BugSack / BugGrabber**

**What it covers**

Runtime event tracing, payload inspection, Lua error capture, table inspection, and live-client verification. DevTool’s Wago page describes event monitoring similar to `/etrace`. ([Wago Addons][24])

**How it is updated**

Community addons, updated through addon repositories/Wago/CurseForge depending on project.

**Retail / Classic**

Usually both, depending on addon support and flavor packaging.

**Maintenance confidence as of April 2026**

**Medium-to-high** for DevTool and BugSack-class tooling, but verify the addon flavor supports 12.0.5.

**Usefulness**

Not canonical for patch history, but very useful once you start running the refactored addon.

---

# Sources to treat as historical or degraded

## Townlong-Yak FrameXML browser

Historically excellent for FrameXML archives and version comparison, but forum discussion described it as “apparently gone” and no longer available as the go-to source. Do not base a 2026 workflow on it. ([Fóruns Blizzard][25])

## Old wow.tools

The old wow.tools should be considered legacy/degraded. Use **wago.tools** or **wow.tools.local** instead. AddOn Studio explicitly points to wago.tools as the continuation. ([AddOn Studio][22])

## Blizzard Interface AddOn Kit

Do not use this as a modern source. Blizzard forum guidance says the AddOn Kit had not been updated for years and recommends `ExportInterfaceFiles code` instead. ([Fóruns Blizzard][26])

## Tekkub’s old FrameXML mirror

Useful historically, not for this migration. AddOn Studio identifies older mirrors and notes old update levels around 7.x-era builds. ([AddOn Studio][22])

---

# Recommended migration-research workflow

1. **Create a patch ledger** from Warcraft Wiki pages:
   `11.0.7 → 11.1.0 → 11.1.5 → 11.1.7 → 11.2.0 → 11.2.5 → 11.2.7 → 12.0.0 → 12.0.1 → 12.0.5`.

2. **Treat 12.0.0 and 12.0.1 as one breaking wave**, not just 12.0.0. Blizzard’s own WoWUIDev/Wowhead-archived notes indicate that much of the final addon API work landed in 12.0.1. ([Wowhead][20])

3. **Use Warcraft Wiki for the human-readable API delta**, then verify mechanically with **BlizzardInterfaceResources**.

4. **Use `wow-ui-source` for Blizzard UI source, XML, templates, mixins, and Blizzard addon rewrites.** This is where you will see how Blizzard migrated its own UI.

5. **Search `Blizzard_Deprecated` and deprecated aliases aggressively.** The 12.0.0 wave is exactly where old 11.x compatibility paths are likely to disappear or become non-loadable.

6. **Use WoWUIDev/Wowhead for secure-value behavior.** Generated API diffs will not always explain why a function now returns a secret value, refuses conversion, hides unit identity, or behaves differently in combat/instances.

7. **Use official Blizzard notes and hotfixes only as policy and stability context.** They are reliable, but too coarse for addon refactoring.

8. **When development starts, verify on live 12.0.5 with `/api`, `/etrace`, DevTool, and BugSack/BugGrabber.** The final runtime behavior matters more than any single community diff, especially after the turbulent 12.0.5 launch.

[1]: https://www.wowhead.com/guide/the-war-within/patch-11-0-7-overview?utm_source=chatgpt.com "The War Within Patch 11.0.7 Overview"
[2]: https://www.wowhead.com/news/patch-11-1-undermine-d-release-date-is-february-25-370014?utm_source=chatgpt.com "Patch 11.1 Undermine(d) Release Date is February 25"
[3]: https://warcraft.wiki.gg/wiki/Patch_11.1.5/API_changes?utm_source=chatgpt.com "Patch 11.1.5/API changes - Warcraft Wiki - wiki.gg"
[4]: https://blizzard.gamespress.com/pt-BR/World-of-Warcraft?utm_source=chatgpt.com "World of Warcraft - Elementos"
[5]: https://worldofwarcraft.blizzard.com/news/24226698/ghosts-of-karesh-content-update-notes?utm_source=chatgpt.com "Ghosts of K'aresh Content Update Notes - World of Warcraft"
[6]: https://warcraft.wiki.gg/wiki/Patch_11.2.5/API_changes?utm_source=chatgpt.com "Patch 11.2.5/API changes - Warcraft Wiki - wiki.gg"
[7]: https://warcraft.wiki.gg/wiki/Patch_11.2.7/API_changes?utm_source=chatgpt.com "Patch 11.2.7/API changes - Warcraft Wiki - wiki.gg"
[8]: https://worldofwarcraft.blizzard.com/news/24244455/midnight-pre-expansion-content-update-notes "Midnight Pre-Expansion Content Update Notes"
[9]: https://warcraft.wiki.gg/wiki/Patch_12.0.1/API_changes?utm_source=chatgpt.com "Patch 12.0.1/API changes - Warcraft Wiki - wiki.gg"
[10]: https://news.blizzard.com/en-us/article/24271855/12-0-5-content-update-notes "12.0.5 Content Update Notes — World of Warcraft — Blizzard News"
[11]: https://warcraft.wiki.gg/wiki/API_change_summaries?utm_source=chatgpt.com "API change summaries - Warcraft Wiki"
[12]: https://warcraft.wiki.gg/wiki/Patch_12.0.5/API_changes?utm_source=chatgpt.com "Patch 12.0.5/API changes - Warcraft Wiki - wiki.gg"
[13]: https://github.com/Ketho/BlizzardInterfaceResources "GitHub - Ketho/BlizzardInterfaceResources: Development resources from World of Warcraft · GitHub"
[14]: https://github.com/ketho-wow/KethoDoc "GitHub - ketho-wow/KethoDoc: Dumps the WoW API · GitHub"
[15]: https://github.com/Gethe/wow-ui-source "GitHub - Gethe/wow-ui-source: git mirror of the user interface source code for World of Warcraft · GitHub"
[16]: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API?utm_source=chatgpt.com "World of Warcraft API"
[17]: https://worldofwarcraft.blizzard.com/en-us/content-update-notes?utm_source=chatgpt.com "Content Update Notes - World of Warcraft"
[18]: https://www.wowhead.com/news/many-healer-spells-no-longer-secret-aura-n-midnight-launch-380525?page=5&utm_source=chatgpt.com "Healer Spells No Longer Secret Aura on Midnight Launch"
[19]: https://www.wowhead.com/tw/news/blizzard-is-considering-improving-aura-filtering-in-midnight-379138 "Blizzard is Considering Improving Aura Filtering in Midnight—wowhead新聞"
[20]: https://www.wowhead.com/news/majority-of-addon-changes-finalized-for-midnight-pre-patch-whitelisted-spells-379738 "Majority of Addon Changes Finalized for Midnight Pre-Patch - Whitelisted Spells Detailed - Wowhead News"
[21]: https://www.wowhead.com/news/many-healer-spells-no-longer-secret-aura-n-midnight-launch-380525?page=5 "Many Healer Spells No Longer Secret Aura on Midnight Launch - Wowhead News"
[22]: https://addonstudio.org/wiki/WoW%3AViewing_Blizzard%27s_WoW_user_interface_code "WoW:Viewing Blizzard's WoW user interface code - AddOn Studio"
[23]: https://github.com/Marlamin/wow.tools.local "GitHub - Marlamin/wow.tools.local: Locally runnable version of the wow.tools website and some of its features · GitHub"
[24]: https://addons.wago.io/addons/devtool?utm_source=chatgpt.com "DevTool - Wago Addons"
[25]: https://us.forums.blizzard.com/en/wow/t/now-that-townlong-yak-is-apparently-gone-where-do-we-get-framexml-from/1262702 "Now that Townlong-Yak is apparently gone, where do we get FrameXML from - UI and Macro - World of Warcraft Forums"
[26]: https://us.forums.blizzard.com/en/wow/t/world-of-warcraft-interface-addon-kit-where-can-i-find-please/1798954 "World of Warcraft Interface AddOn Kit Where can i find! PLEASE! - UI and Macro - World of Warcraft Forums"
