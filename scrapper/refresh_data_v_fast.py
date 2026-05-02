"""V-fast Wowhead refresh CLI.

Differences from scrapper.refresh_data:
- Uses FastFetcher (gzip/brotli, keep-alive, full Chrome-like headers).
- Tracks Referer chain so requests look like natural browser navigation.
- Adds random jitter to delays so timing is not perfectly periodic.
- Default --delay reduced from 5s to 2s.

Build commands delegate to the original generate_pets / generate_stable_masters,
so output format and contracts are identical.
"""

from __future__ import annotations

import argparse
import random
import sys
import time
from pathlib import Path

from scrapper.data_records import source_family_rows
from scrapper.existing_pet_data import load_existing_pet_records
from scrapper.refresh_data import (
    GENERATED_DIR,
    MANIFEST_PATH,
    PageBudget,
    SEMANTIC_SOURCE_ERRORS,
    _listview_rows_from_source,
    _print_failure_report,
    _stable_master_npc_id,
    _tameable_npc_ids_from_source,
    _validate_pet_family_rows,
    _write_pet_blockers,
    _write_stable_master_blockers,
    generate_pets,
    generate_stable_masters,
)
from scrapper.source_cache import SourceCache, SourceFetchError
from scrapper.wowhead_source import (
    HUNTER_PETS_URL,
    STABLE_MASTER_SEARCH_URL,
    npc_url,
    pet_family_url,
)
from scrapper.wowhead_source_v_fast import FastFetcher


class JitteredPageBudget(PageBudget):
    """PageBudget with random jitter applied to the inter-request delay."""

    def __init__(self, limit_pages: int, delay: float, jitter_ratio: float = 0.4):
        super().__init__(limit_pages, delay)
        self.jitter_ratio = jitter_ratio

    def mark_collected(self) -> None:
        self.collected += 1
        if not self.exhausted() and self.delay:
            spread = self.delay * self.jitter_ratio
            actual = max(0.2, self.delay + random.uniform(-spread, spread * 1.5))
            time.sleep(actual)


def _finish(name: str, budget: PageBudget) -> int:
    suffix = {
        "pets": "pet-refresh-blockers.md",
        "stable-masters": "stable-master-blockers.md",
    }[name]
    blocker = GENERATED_DIR / suffix
    if blocker.exists():
        blocker.unlink()
    print(f"Collected {budget.collected} new {name} source page(s).")
    if budget.exhausted():
        print("Page limit reached; rerun the collect command to continue.")
    return 0


def _collect_one(
    source_cache: SourceCache,
    fetcher: FastFetcher,
    url: str,
    role: str,
    budget: JitteredPageBudget,
    referer: str | None = None,
) -> bool:
    if source_cache.has_text(url):
        print(f"Cached {role}: {url}", flush=True)
        return True
    if budget.exhausted():
        return False
    try:
        text = fetcher(url, referer=referer)
    except Exception as error:
        source_cache.record_semantic_error(url, role, "error", str(error))
        print(f"Skipped {role} {url}: {error}", flush=True)
        return True
    source_cache.store_text(url, role, text)
    budget.mark_collected()
    print(f"Collected {budget.collected}/{budget.limit_pages} {role}: {url}", flush=True)
    return True


def collect_pets_sources_v_fast(
    limit_pages: int,
    delay: float,
    source_cache: SourceCache | None = None,
) -> int:
    source_cache = source_cache or SourceCache(GENERATED_DIR / "cache", MANIFEST_PATH)
    fetcher = FastFetcher()
    budget = JitteredPageBudget(limit_pages, delay)
    try:
        if not _collect_one(source_cache, fetcher, HUNTER_PETS_URL, "pet-index", budget):
            return _finish("pets", budget)

        try:
            index_source = source_cache.read_text(HUNTER_PETS_URL, "pet-index")
            families = _listview_rows_from_source(
                source_cache,
                index_source,
                "pets",
                "Malformed pet index source",
                source_family_rows,
                row_validator=_validate_pet_family_rows,
            )
        except (SourceFetchError, ValueError) as error:
            _write_pet_blockers(GENERATED_DIR, [str(error)])
            return 1

        for family in families:
            family_url = pet_family_url(family.id)
            if not _collect_one(
                source_cache, fetcher, family_url, "pet-family", budget,
                referer=HUNTER_PETS_URL,
            ):
                return _finish("pets", budget)
            try:
                family_source = source_cache.read_text(family_url, "pet-family")
                tameable_ids = _tameable_npc_ids_from_source(
                    source_cache, family_source, family.name
                )
            except (SourceFetchError, ValueError) as error:
                # Family page malformed -> skip family but keep going (resilient).
                print(f"Skipped family {family.name}: {error}", flush=True)
                continue
            for tameable_id in tameable_ids:
                if not _collect_one(
                    source_cache, fetcher, npc_url(tameable_id), "pet-npc", budget,
                    referer=family_url,
                ):
                    return _finish("pets", budget)
    finally:
        fetcher.close()
    return _finish("pets", budget)


def collect_stable_master_sources_v_fast(
    limit_pages: int,
    delay: float,
    source_cache: SourceCache | None = None,
) -> int:
    source_cache = source_cache or SourceCache(GENERATED_DIR / "cache", MANIFEST_PATH)
    fetcher = FastFetcher()
    budget = JitteredPageBudget(limit_pages, delay)
    try:
        if not _collect_one(
            source_cache, fetcher, STABLE_MASTER_SEARCH_URL, "stable-master-search", budget,
        ):
            return _finish("stable-masters", budget)
        try:
            search_source = source_cache.read_text(
                STABLE_MASTER_SEARCH_URL, "stable-master-search"
            )
            raw_rows = _listview_rows_from_source(
                source_cache,
                search_source,
                "npcs",
                "Malformed stable master search source",
                lambda rows: rows,
            )
            rows = [row for row in raw_rows if "Stable Master" in str(row.get("tag", ""))]
        except (SourceFetchError, ValueError) as error:
            _write_stable_master_blockers(GENERATED_DIR, [str(error)])
            return 1
        for index, row in enumerate(rows):
            try:
                target_id = _stable_master_npc_id(row, index)
            except SEMANTIC_SOURCE_ERRORS as error:
                source_cache.record_semantic_error(
                    search_source.url,
                    search_source.role,
                    "parse_error",
                    f"Malformed stable master search source: {search_source.url}: {error}",
                )
                _write_stable_master_blockers(GENERATED_DIR, [str(error)])
                return 1
            if not _collect_one(
                source_cache, fetcher, npc_url(target_id), "stable-master-npc", budget,
                referer=STABLE_MASTER_SEARCH_URL,
            ):
                return _finish("stable-masters", budget)
    finally:
        fetcher.close()
    return _finish("stable-masters", budget)


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "V-fast Wowhead refresh: gzip/brotli, full browser headers, referer "
            "chain, keep-alive, jittered delays."
        ),
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    cp = subparsers.add_parser("collect-pets")
    cp.add_argument("--limit-pages", type=int, required=True)
    cp.add_argument("--delay", type=float, default=2.0)
    cp.add_argument("--reset-cache", action="store_true")

    cs = subparsers.add_parser("collect-stable-masters")
    cs.add_argument("--limit-pages", type=int, required=True)
    cs.add_argument("--delay", type=float, default=2.0)
    cs.add_argument("--reset-cache", action="store_true")

    bp = subparsers.add_parser("build-pets")
    bp.add_argument("--output", default=str(GENERATED_DIR / "Data.lua"))
    bp.add_argument("--limit-families", type=int, default=0)
    bp.add_argument("--from-cache", action="store_true", required=True)

    bs = subparsers.add_parser("build-stable-masters")
    bs.add_argument("--output", default=str(GENERATED_DIR / "StableMastersData.lua"))
    bs.add_argument("--limit", type=int, default=0)
    bs.add_argument("--from-cache", action="store_true", required=True)

    args = parser.parse_args()
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)
    source_cache = SourceCache(GENERATED_DIR / "cache", MANIFEST_PATH)
    if getattr(args, "reset_cache", False):
        source_cache.reset()

    if args.command == "collect-pets":
        exit_code = collect_pets_sources_v_fast(
            args.limit_pages, args.delay, source_cache=source_cache
        )
        _print_failure_report(exit_code, "pets", GENERATED_DIR)
        return exit_code
    if args.command == "collect-stable-masters":
        exit_code = collect_stable_master_sources_v_fast(
            args.limit_pages, args.delay, source_cache=source_cache
        )
        _print_failure_report(exit_code, "stable-masters", GENERATED_DIR)
        return exit_code
    if args.command == "build-pets":
        fallback, summary = load_existing_pet_records(Path("Data.lua"))
        if summary.missing_file:
            print("No Data.lua baseline found; running without fallback.", flush=True)
        else:
            print(
                f"Loaded {summary.loaded} baseline pet records from Data.lua "
                f"(dropped {summary.dropped_no_zone} no-zone, "
                f"{summary.dropped_no_coords} no-coords).",
                flush=True,
            )
        exit_code = generate_pets(
            Path(args.output),
            args.limit_families,
            source_cache=source_cache,
            generated_dir=GENERATED_DIR,
            from_cache=True,
            fallback_records=fallback,
        )
        _print_failure_report(exit_code, "pets", GENERATED_DIR)
        return exit_code
    if args.command == "build-stable-masters":
        exit_code = generate_stable_masters(
            Path(args.output),
            args.limit,
            source_cache=source_cache,
            generated_dir=GENERATED_DIR,
            from_cache=True,
        )
        _print_failure_report(exit_code, "stable-masters", GENERATED_DIR)
        return exit_code
    raise AssertionError(args.command)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print(
            "\nInterrupted by user. Cache and manifest were preserved; "
            "rerun the same command to resume.",
            file=sys.stderr,
        )
        raise SystemExit(130)
