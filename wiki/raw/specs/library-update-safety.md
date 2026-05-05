---
source_url: https://github.com/giuice/GiuiceHunterPets/blob/main/important-readme.md
ingested: 2026-05-04
sha256: 31c389e673003526fbff20e7736d539fa99a270bb87c732cd317acd331831cb5
---

# IMPORTANT: How To Update Libraries Safely

This file explains, step by step, how to update the libraries in this addon without breaking it.

If you are a beginner, follow the steps exactly in the same order.

## 1. Understand how this addon loads libraries

This addon loads libraries from these lines in [GiuiceHunterPets.toc](/home/giuice/desenv/GiuiceHunterPets/GiuiceHunterPets.toc):

- `Libs\LibStub\LibStub.lua`
- `Libs\CallbackHandler-1.0\CallbackHandler-1.0.lua`
- `Libs\AceLocale-3.0\AceLocale-3.0.lua`
- `Libs\LibDataBroker-1.1\LibDataBroker-1.1.lua`
- `Libs\LibDBIcon-1.0\LibDBIcon-1.0.lua`
- `Libs\HereBeDragons\HereBeDragons-2.0.lua`
- `Libs\HereBeDragons\HereBeDragons-Pins-2.0.lua`

This means:

- the addon does not auto-detect libraries;
- the file paths in the TOC must match the real files on disk;
- if a library zip comes with a different folder structure, you must fix that before testing in game.

## 2. Before updating anything

1. Close World of Warcraft.
2. Make a backup copy of the whole addon folder.
3. Keep the old library zip or old folder until the new version works.
4. Update one library at a time, not all at once.

Why this matters:

If something breaks, you will know exactly which library caused the problem.

## 3. Where to put the new files

Each library must end in the same root folder names used today inside [Libs](/home/giuice/desenv/GiuiceHunterPets/Libs):

- [Libs/AceLocale-3.0](/home/giuice/desenv/GiuiceHunterPets/Libs/AceLocale-3.0)
- [Libs/CallbackHandler-1.0](/home/giuice/desenv/GiuiceHunterPets/Libs/CallbackHandler-1.0)
- [Libs/HereBeDragons](/home/giuice/desenv/GiuiceHunterPets/Libs/HereBeDragons)
- [Libs/LibDBIcon-1.0](/home/giuice/desenv/GiuiceHunterPets/Libs/LibDBIcon-1.0)
- [Libs/LibDataBroker-1.1](/home/giuice/desenv/GiuiceHunterPets/Libs/LibDataBroker-1.1)
- [Libs/LibStub](/home/giuice/desenv/GiuiceHunterPets/Libs/LibStub)

Do not leave extra nested folders like this unless the TOC was also changed:

- wrong: `Libs/LibDBIcon-1.0/LibDBIcon-1.0/LibDBIcon-1.0.lua`
- correct: `Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua`

## 4. Safe update process

Use this process for every library.

1. Download the new library.
2. Extract it somewhere outside the addon first.
3. Open the extracted folder and inspect the real file structure.
4. Find the main `.lua`, `.xml`, or `.toc` files.
5. Compare that structure with the path used in [GiuiceHunterPets.toc](/home/giuice/desenv/GiuiceHunterPets/GiuiceHunterPets.toc).
6. Replace only the target library folder inside [Libs](/home/giuice/desenv/GiuiceHunterPets/Libs).
7. Confirm the file path in the TOC still exists exactly.
8. Open the game and test.

If the updated library comes with extra wrapper folders, flatten it first so the final file path matches the TOC.

## 5. Special case: LibDBIcon

`LibDBIcon` needs extra attention.

Today this project expects this exact file:

- [Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua](/home/giuice/desenv/GiuiceHunterPets/Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua)

And this folder is intentionally simple:

- `CHANGES.txt`
- `LibDBIcon-1.0.lua`
- `LibDBIcon-1.0.toc`

Important:

- if a new `LibDBIcon` zip contains embedded copies of `LibStub`, `CallbackHandler-1.0`, or `LibDataBroker-1.1`, do not keep those embedded duplicates in this addon unless you also redesign the load order;
- this addon already loads those libraries from the root [Libs](/home/giuice/desenv/GiuiceHunterPets/Libs) folder;
- duplicated embedded copies can create confusion during maintenance.

So for this addon, keep `LibDBIcon` flat and simple.

## 6. How to check if the update is correct

After replacing a library, verify these things:

1. The file path in [GiuiceHunterPets.toc](/home/giuice/desenv/GiuiceHunterPets/GiuiceHunterPets.toc) exists on disk.
2. There are no unexpected extra nested folders.
3. The addon loads without a startup error.
4. The feature that uses that library still works.

Examples:

- if you updated `LibDBIcon`, test the minimap icon;
- if you updated `HereBeDragons`, test map pins;
- if you updated `AceLocale-3.0`, test localized text;
- if you updated `LibDataBroker-1.1`, test the launcher object creation.

## 7. What to do if WoW shows an error

If WoW prints an error like `Error loading ...some/file.lua`, do this:

1. Read the full path in the error carefully.
2. Open the addon folder.
3. Check if that exact file really exists.
4. If it does not exist, the folder structure and the TOC are out of sync.
5. Fix the folders or fix the TOC path.

In most library update failures, the problem is not the Lua code itself.
The problem is usually one of these:

- wrong folder nesting;
- wrong filename;
- outdated TOC path;
- duplicate embedded libraries creating confusion.

## 8. Recommended rule for beginners

If you are unsure, use this rule:

1. Never update more than one library at a time.
2. Never trust the zip structure blindly.
3. Always compare the extracted files with [GiuiceHunterPets.toc](/home/giuice/desenv/GiuiceHunterPets/GiuiceHunterPets.toc).
4. Always test in game right after each library update.

## 9. Short version

If you want the fastest safe checklist, use this:

1. Backup the addon.
2. Download one new library.
3. Extract it outside the project.
4. Compare the extracted structure with the path used in [GiuiceHunterPets.toc](/home/giuice/desenv/GiuiceHunterPets/GiuiceHunterPets.toc).
5. Copy the files into [Libs](/home/giuice/desenv/GiuiceHunterPets/Libs).
6. Flatten extra folders if needed.
7. Keep `LibDBIcon` as [Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua](/home/giuice/desenv/GiuiceHunterPets/Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua).
8. Test in game.

If you follow that process, library updates should stay predictable and easy to debug.
