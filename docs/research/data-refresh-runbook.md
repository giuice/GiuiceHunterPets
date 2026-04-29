# Data Refresh Runbook

## Guia Rapido Em Portugues

Rode a partir da raiz do repositorio:

```bash
rtk python3 -m scrapper.refresh_data collect-pets --limit-pages 10 --delay 5
rtk python3 -m scrapper.refresh_data build-pets --from-cache --output scrapper/generated/Data.lua
```

O primeiro comando coleta HTML e salva em cache. O segundo comando gera Lua somente a partir do cache local, sem bater no Wowhead.

Se falhar, o comando imprime o arquivo de diagnostico. Para pets, leia:

```bash
rtk sed -n '1,120p' scrapper/generated/pet-refresh-blockers.md
rtk sed -n '1,120p' scrapper/generated/pet-validation-errors.md
```

O erro `HTTP Error 403: Forbidden` quer dizer que o Wowhead bloqueou a coleta antes de baixar os dados. Nesse caso o pipeline nao escreve `Data.lua`, de proposito, para evitar trocar dados bons por uma coleta incompleta.

Para stable masters:

```bash
rtk python3 -m scrapper.refresh_data collect-stable-masters --limit-pages 10 --delay 5
rtk python3 -m scrapper.refresh_data build-stable-masters --from-cache --output scrapper/generated/StableMastersData.lua
rtk sed -n '1,120p' scrapper/generated/stable-master-blockers.md
rtk sed -n '1,120p' scrapper/generated/stable-master-validation-errors.md
```

O cache/progresso fica em:

- `scrapper/generated/cache/`
- `scrapper/generated/refresh-manifest.json`

Use `--reset-cache` somente quando quiser descartar o cache e tentar tudo do zero. Nao use durante investigacao normal.

## Source Shape

Validated with `agent-browser 0.26.0` on 2026-04-28/2026-04-29:

- `https://www.wowhead.com/hunter-pets` exposes pet families through `g_listviews.pets.data`.
- `https://www.wowhead.com/pet=<family-id>` exposes tameable NPC rows through `g_listviews.tameable.data`.
- `https://www.wowhead.com/npc=<npc-id>` exposes coordinates through `g_mapperData` when Wowhead has mapped locations.
- `https://www.wowhead.com/search?q=stable%20master` exposes stable master candidates through `g_listviews.npcs.data`.

## Pet Sample

```bash
rtk python3 -m scrapper.refresh_data collect-pets --limit-pages 10 --delay 5
rtk python3 -m scrapper.refresh_data build-pets --from-cache --limit-families 1 --output scrapper/generated/Data.sample.lua
```

Expected:

- Exit code `0`.
- `scrapper/generated/Data.sample.lua` exists.
- `scrapper/generated/Data.sample.lua` contains `GHP.pet_by_zones = {`.
- `scrapper/generated/Data.sample.lua` contains at least one `["coords"] = { {`.

## Full Pet Refresh

```bash
rtk python3 -m scrapper.refresh_data collect-pets --limit-pages 10 --delay 5
rtk python3 -m scrapper.refresh_data build-pets --from-cache --output scrapper/generated/Data.lua
```

Before replacing production `Data.lua`:

```bash
rtk rg -n 'GHP.pet_by_zones = \{|\["NpcId"\]|\["coords"\]' scrapper/generated/Data.lua
rtk git diff --no-index Data.lua scrapper/generated/Data.lua
```

Review requirements:

- Generated pet count is plausible compared with checked-in `Data.lua`.
- Sample current expansion pets appear in the generated output.
- `scrapper/generated/pet-validation-errors.md` is empty or absent.
- If Wowhead blocks source fetches, `scrapper/generated/pet-refresh-blockers.md` records the HTTP error and production `Data.lua` must not be replaced.
- Coordinate-heavy diffs are expected; missing-coordinate records are not accepted into generated output.

## Resume And Cache Workflow

Full refreshes are resumable. The pipeline persists fetched Wowhead pages under `scrapper/generated/cache/` and records progress in `scrapper/generated/refresh-manifest.json`.

Collection is cache-first and resumable. Rerun the collect command to continue from the existing manifest and fetch only missing pages:

```bash
rtk python3 -m scrapper.refresh_data collect-pets --limit-pages 10 --delay 5
rtk python3 -m scrapper.refresh_data collect-stable-masters --limit-pages 10 --delay 5
```

Build commands are offline and must use cache only:

```bash
rtk python3 -m scrapper.refresh_data build-pets --from-cache --output scrapper/generated/Data.lua
rtk python3 -m scrapper.refresh_data build-stable-masters --from-cache --output scrapper/generated/StableMastersData.lua
```

Use `--reset-cache` only when intentionally discarding saved source pages:

```bash
rtk python3 -m scrapper.refresh_data collect-pets --limit-pages 1 --delay 5 --reset-cache
rtk python3 -m scrapper.refresh_data collect-stable-masters --limit-pages 1 --delay 5 --reset-cache
```

Inspect the manifest when a refresh fails:

```bash
rtk sed -n '1,200p' scrapper/generated/refresh-manifest.json
rtk sed -n '1,120p' scrapper/generated/pet-refresh-blockers.md
rtk sed -n '1,120p' scrapper/generated/stable-master-blockers.md
```

Required behavior:

- Successful cached pages are reused indefinitely.
- Missing or failed URLs are retried on rerun.
- Every successful page is written to `scrapper/generated/cache/` before parsing the next page.
- Parser or validation failures keep the cached HTML and record the local path in the manifest.
- `--reset-cache` removes saved pages and starts a fresh collection.
- Generated Lua is written only from a complete validated cached source set.
- Production `Data.lua` and `StableMastersData.lua` are replaced only after generated output validates and the diff is reviewed.

## Stable Master Feasibility

```bash
rtk python3 -m scrapper.refresh_data collect-stable-masters --limit-pages 10 --delay 5
rtk python3 -m scrapper.refresh_data build-stable-masters --from-cache --output scrapper/generated/StableMastersData.lua
```

If the command exits `0`, review:

```bash
rtk rg -n 'GHP.stable_masters = \{|\["npcID"\]|\["faction"\]' scrapper/generated/StableMastersData.lua
rtk sed -n '1,80p' scrapper/generated/stable-master-skipped.md
```

If the command exits non-zero, review:

```bash
rtk sed -n '1,120p' scrapper/generated/stable-master-blockers.md
rtk sed -n '1,120p' scrapper/generated/stable-master-validation-errors.md
```

## Production Replacement

Only replace `Data.lua` after the generated pet file validates and the diff is reviewed.

Only add `StableMastersData.lua` and `GiuiceHunterPets.toc` after stable master validation passes. This phase loads data only; it does not render stable master pins.
