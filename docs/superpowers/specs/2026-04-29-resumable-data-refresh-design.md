# Resumable Data Refresh Design

## Goal

Make the Wowhead data refresh pipeline resumable and cache-safe for both pet data and stable master data.

The pipeline must preserve successfully downloaded source pages when later requests fail. A rerun must reuse cached pages indefinitely and retry only missing or failed URLs unless the user explicitly resets the cache.

## Context

The existing refresh pipeline can parse Wowhead embedded JavaScript, normalize pet and stable master source rows, validate records, and export Lua. It currently fetches source pages while generating output. If a later fetch fails, earlier successful source pages are lost because they were only held in process memory.

The immediate blocker is source access reliability. Wowhead may return HTTP 403 or otherwise fail after a partial refresh. This design does not attempt to bypass access controls or copy browser cookies. It makes refreshes recoverable.

## Success Criteria

- A failed full refresh leaves successful raw source pages on disk.
- A second run reuses successful cached pages and does not re-download them.
- Missing or failed URLs are retried and recorded explicitly.
- Generated Lua is written only after the complete required source set is available and validation passes.
- Production files are not replaced from partial data.
- Tests cover cache hits, cache misses, failed fetches, resume behavior, reset behavior, and both supported refresh commands.
- `docs/research/data-refresh-runbook.md` explains the resume and reset workflow.

## Architecture

Add a shared source cache layer, likely `scrapper/source_cache.py`, and keep the existing public CLI in `scrapper/refresh_data.py`.

The refresh flow becomes:

1. Discover required source URLs for the selected command.
2. Fetch each required URL through the cache layer.
3. Persist successful raw HTML immediately under `scrapper/generated/cache/`.
4. Persist metadata and failed attempts in `scrapper/generated/refresh-manifest.json`.
5. Extract and normalize from cached or newly collected source text.
6. Validate the complete record set.
7. Write Lua only after validation passes.

The cache layer is command-agnostic. It owns URL normalization, cache keys, raw HTML storage, metadata, error recording, and reset behavior. The pet and stable master commands own their own source discovery, parsing, validation, and output paths.

## Cache Layout

Raw source pages live under:

```text
scrapper/generated/cache/
```

Each URL gets a stable cache key from the normalized URL, using SHA-256:

```text
scrapper/generated/cache/<sha256>.html
```

Cache reuse is indefinite. A successful cached page remains valid until the user passes `--reset-cache`.

## Manifest

The manifest lives at:

```text
scrapper/generated/refresh-manifest.json
```

Each entry records the URL, cache key, source role, status, raw source path when available, fetch timestamp, and error text when applicable.

Example successful entry:

```json
{
  "url": "https://www.wowhead.com/npc=32517",
  "cache_key": "4f3d...",
  "role": "pet-npc",
  "status": "ok",
  "path": "scrapper/generated/cache/4f3d....html",
  "fetched_at": "2026-04-29T12:34:56Z",
  "error": null
}
```

Example failed entry:

```json
{
  "url": "https://www.wowhead.com/npc=32517",
  "cache_key": "4f3d...",
  "role": "pet-npc",
  "status": "error",
  "path": null,
  "fetched_at": "2026-04-29T12:35:12Z",
  "error": "HTTP Error 403: Forbidden"
}
```

If a URL has a previous successful cached file, normal resume behavior must keep using that source until `--reset-cache` intentionally discards it.

## CLI Behavior

Add cache controls to both refresh commands:

```bash
rtk python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua --resume
rtk python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua --reset-cache
rtk python3 -m scrapper.refresh_data stable-masters --output scrapper/generated/StableMastersData.lua --resume
rtk python3 -m scrapper.refresh_data stable-masters --output scrapper/generated/StableMastersData.lua --reset-cache
```

Resume behavior should be the safe default once cached sources exist. The `--resume` flag exists to make intent explicit in runbooks and manual refreshes.

`--reset-cache` deletes the cache directory and manifest before fetching. It is the only normal way to discard successful cached source data.

## Pet Refresh Source Graph

The pet refresh caches source pages in layers:

1. The hunter pets index page at `https://www.wowhead.com/hunter-pets`.
2. Each pet family page discovered from the index.
3. Each tameable NPC page discovered from family pages.

Family pages and NPC pages may still be fetched in parallel, but all fetches must go through the cache layer. Manifest updates must be safe. If direct concurrent manifest writes are too risky, worker threads should return source results to the main thread and the main thread should write manifest updates.

The command writes `scrapper/generated/pet-refresh-blockers.md` for source access failures, `scrapper/generated/pet-validation-errors.md` for validation failures, and `scrapper/generated/pet-skipped.md` for optional rows skipped because they lack mapper coordinates.

## Stable Master Refresh Source Graph

The stable master refresh caches:

1. The stable master search page at `https://www.wowhead.com/search?q=stable%20master`.
2. Each candidate stable master NPC page discovered from the search results.

The command writes `scrapper/generated/stable-master-blockers.md` for source access failures, `scrapper/generated/stable-master-validation-errors.md` for validation failures, and `scrapper/generated/stable-master-skipped.md` for optional rows skipped because they lack valid coordinates.

## Failure Rules

If any required URL cannot be fetched and has no successful cached source, the command must:

1. Exit non-zero.
2. Record the failed URL and error in the manifest.
3. Write the relevant blocker file.
4. Leave successful cached sources on disk.
5. Avoid writing the Lua output file.

If all required source pages are available but validation fails, the command must:

1. Exit non-zero.
2. Write the relevant validation error file.
3. Avoid writing the Lua output file.
4. Leave cached sources on disk.

Skipped records are not source access failures. They should continue to be written to the relevant skipped file after validation succeeds.

## Testing

Tests should stay in the existing `unittest` style and avoid live network calls.

Required coverage:

- Cache miss calls the fetch function, writes raw HTML, and writes manifest status `ok`.
- Cache hit returns saved HTML and does not call the fetch function.
- Failed fetch writes manifest status `error`.
- Failed fetch preserves any previous successful cached file.
- Reset removes the prior cache and manifest before fetching.
- Pet refresh can generate Lua from cached index, family, and NPC pages without live fetches.
- Pet refresh exits non-zero and does not write Lua when a required source page is unavailable.
- Stable master refresh uses the same cache layer.

## Documentation

Update `docs/research/data-refresh-runbook.md` with:

- Resume commands for pets and stable masters.
- Reset commands for pets and stable masters.
- How to inspect `scrapper/generated/refresh-manifest.json`.
- The rule that production `Data.lua` and `StableMastersData.lua` are only replaced after generated output validates and the diff is reviewed.

## Out Of Scope

- Bypassing Wowhead access controls.
- Copying browser cookies or session material into the Python client.
- Replacing production Lua files automatically.
- Adding freshness or TTL-based invalidation.
- Redesigning record normalization or Lua export formats.
