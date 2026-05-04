---
type: lesson
id: LESSON-003
title: Library Update Safety
created: 2026-05-04
updated: 2026-05-04
tags: [lesson, release]
sources: [wiki/raw/specs/library-update-safety.md]
confidence: high
contested: false
contradictions: []
verified_by: human
approved: true
linked_issues: []
---

# LESSON-003: Library Update Safety

## Trigger

When updating any vendored library in the `Libs/` directory of the addon.

## Verified Lesson

The addon does not auto-detect libraries — it loads them from explicit paths in `GiuiceHunterPets.toc`. If the file paths in the TOC do not match real files on disk, the addon will fail to load with no useful diagnostics beyond `Error loading ...some/file.lua`.

### Core Rules

1. **One library at a time.** Never update multiple libraries in one batch. If something breaks, you need to know exactly which library caused it.
2. **Never trust the zip structure.** Extract outside the project first, inspect the real file structure, then compare with the TOC paths.
3. **Flatten extra wrapper folders.** If a library zip nests the actual `.lua` file inside extra directories, flatten it so the path matches the TOC.
4. **Close WoW before updating.** Then backup the entire addon folder.

### Library Load Order (from TOC)

```
Libs\LibStub\LibStub.lua
Libs\CallbackHandler-1.0\CallbackHandler-1.0.lua
Libs\AceLocale-3.0\AceLocale-3.0.lua
Libs\LibDataBroker-1.1\LibDataBroker-1.1.lua
Libs\LibDBIcon-1.0\LibDBIcon-1.0.lua
Libs\HereBeDragons\HereBeDragons-2.0.lua
Libs\HereBeDragons\HereBeDragons-Pins-2.0.lua
```

### Special Case: LibDBIcon

`LibDBIcon` must stay flat and simple:

```
Libs/LibDBIcon-1.0/
  CHANGES.txt
  LibDBIcon-1.0.lua
  LibDBIcon-1.0.toc
```

If a new `LibDBIcon` zip contains embedded copies of `LibStub`, `CallbackHandler-1.0`, or `LibDataBroker-1.1`, **do not keep those duplicates**. This addon already loads those libraries from the root `Libs/` folder. Duplicate embedded copies create load-order confusion.

### Common Failure Modes

| Symptom | Usual Cause |
|---------|-------------|
| `Error loading .../file.lua` | File path in TOC doesn't exist on disk |
| Wrong folder nesting | Extra wrapper directory from library zip |
| Wrong filename | Library renamed a file between versions |
| Outdated TOC path | Library restructured its internal layout |
| Duplicate embedded libraries | `LibDBIcon` or similar bundling `LibStub` etc. inside itself |

## Evidence

Derived from `important-readme.md` which documents the exact step-by-step process verified through multiple library updates in this addon.

## Future Guidance

### Feature-Specific Test Targets

After updating a library, test the feature that depends on it:

| Library | What to Test |
|---------|-------------|
| `LibDBIcon` | Minimap icon |
| `HereBeDragons` | Map pins (world map and minimap) |
| `AceLocale-3.0` | Localized text display |
| `LibDataBroker-1.1` | Launcher object creation |

### Quick Checklist

1. Backup the addon
2. Download one new library
3. Extract outside the project
4. Compare extracted structure with TOC paths
5. Copy files into `Libs/`
6. Flatten extra folders if needed
7. Keep `LibDBIcon` flat at `Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua`
8. Test in game