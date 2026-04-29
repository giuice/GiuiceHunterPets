# Smart Cache-First Wowhead Scraping Plan

## Summary

Use `agent-browser` as the first collection backend because it was proven against real Wowhead pages. Keep Firecrawl as an optional later spike, not a dependency for the recovery.

The pipeline must treat cached HTML as the primary artifact. Lua generation is offline and downstream.

## Key Changes

- Split refresh into:
  - `collect-pets`
  - `build-pets --from-cache`
  - `collect-stable-masters`
  - `build-stable-masters --from-cache`
- Collection runs one URL at a time with explicit `--limit-pages` and `--delay`.
- Each successful page is saved immediately before parsing or moving to the next URL.
- Use `agent-browser eval "document.documentElement.outerHTML"` and decode the JSON string before writing `.html`.
- Preserve URL, role, cache path, status, and timestamp in the manifest after every page.
- Remove parallel Wowhead fetching.
- Treat missing `minlevel` / `maxlevel` as a real Wowhead shape variant to normalize, not as a fatal cache invalidation.

## Backend Policy

- Default backend: `agent-browser`.
- Python HTTP backend: optional only for cautious one-page probes, not full refresh.
- Firecrawl: optional future spike only if installed/authenticated; test one URL first and require raw HTML compatibility before adoption.
- Do not use automatic `crawl`, high concurrency, proxy rotation, cookie copying, or CAPTCHA bypass flows.

## Verification

- Before implementation, keep using `/tmp` probes for new page types.
- Acceptance checks:
  - index page parses families;
  - family page parses tameable rows;
  - NPC page parses `g_mapperData`;
  - no repo files change during probes;
  - build command can run offline from saved cache.
- Avoid broad mock-heavy tests. Add only small checks for cache preservation and offline build failure messages.

## Assumptions

- Current branch is the working branch; no worktrees.
- Every expensive successful page fetch must be persisted immediately.
- `Data.sample.lua` is not cache and must never be treated as source.
