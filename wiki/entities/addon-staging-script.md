---
type: entity
id: ENTITY-003
title: Addon Staging Script
name: Addon Staging Script
created: 2026-05-07
updated: 2026-05-07
tags: [cli, release]
sources:
  - scripts/stage-addon.sh
  - GiuiceHunterPets.toc
status: active
key_files:
  - scripts/stage-addon.sh
  - GiuiceHunterPets.toc
file_hashes: {}
linked_issues: []
linked_lessons:
  - lessons/library-update-safety.md
confidence: high
contested: false
contradictions: []
verified_by: human
approved: true
---

# ENTITY-003: Addon Staging Script

## Purpose

`scripts/stage-addon.sh` creates or syncs a clean runtime copy of GiuiceHunterPets into a WoW AddOns folder or a staging directory. It reduces release mistakes caused by copying repository-only files, tests, generated cache files, or planning artifacts into the live addon folder.

## Current Behavior

The script defaults to syncing into:

```text
/mnt/M2Flash/Games/World of Warcraft/_retail_/Interface/AddOns/GiuiceHunterPets
```

If the caller passes a parent AddOns directory, the script appends `GiuiceHunterPets`. If the caller passes a path already ending in `GiuiceHunterPets`, it treats that path as the addon folder. It strips an `admin://` prefix from paths copied from GUI file managers.

The `--stage` mode writes a clean addon folder under a provided staging parent, defaulting to `~/Downloads`.

## Safety Rules

The script requires `rsync`, checks that the destination parent is writable, and refuses to sync into a non-empty directory that does not look like a GiuiceHunterPets addon folder. Runtime sync includes the `.toc`, root Lua/XML files, locales, icons, selected libraries, and the addon icon. It excludes library tests and library documentation files from the staged runtime copy.

This script complements [[library-update-safety]] because both workflows depend on keeping `GiuiceHunterPets.toc` paths aligned with the files actually shipped to WoW.

## Verification

Use `scripts/stage-addon.sh --help` to confirm invocation syntax. Before release, run the script into a staging directory and inspect that the resulting folder contains `GiuiceHunterPets.toc`, runtime Lua/XML files, locales, icons, and vendored libraries, without repo planning files or test folders.

## Related Pages

- [[library-update-safety]] — vendored library update and release compatibility checks
- [[hunter-only-runtime-initialization]] — runtime behavior that should be validated from the staged addon in-game
