from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from scrapper.data_records import (
    build_pet_record,
    build_stable_master_record,
    source_family_rows,
    source_tameable_rows,
)
from scrapper.lua_export import (
    export_pet_data,
    export_stable_master_data,
    validate_pet_records,
    validate_stable_master_records,
)
from scrapper.source_cache import SourceCache, SourceFetchError
from scrapper.wowhead_source import (
    HUNTER_PETS_URL,
    STABLE_MASTER_SEARCH_URL,
    extract_listview_data,
    extract_mapper_data,
    fetch_text,
    npc_url,
    pet_family_url,
)


GENERATED_DIR = Path("scrapper/generated")
MANIFEST_PATH = GENERATED_DIR / "refresh-manifest.json"
FETCH_WORKERS = 4


def main() -> int:
    parser = argparse.ArgumentParser(description="Refresh GiuiceHunterPets generated data.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    pets = subparsers.add_parser("pets")
    pets.add_argument("--output", default=str(GENERATED_DIR / "Data.lua"))
    pets.add_argument("--limit-families", type=int, default=0)
    pets.add_argument("--resume", action="store_true", help="Reuse cached source pages when available.")
    pets.add_argument("--reset-cache", action="store_true", help="Delete cached source pages before fetching.")

    stable = subparsers.add_parser("stable-masters")
    stable.add_argument("--output", default=str(GENERATED_DIR / "StableMastersData.lua"))
    stable.add_argument("--limit", type=int, default=0)
    stable.add_argument("--resume", action="store_true", help="Reuse cached source pages when available.")
    stable.add_argument("--reset-cache", action="store_true", help="Delete cached source pages before fetching.")

    args = parser.parse_args()
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)
    source_cache = SourceCache(GENERATED_DIR / "cache", MANIFEST_PATH, fetcher=fetch_text)
    if args.reset_cache:
        source_cache.reset()

    if args.command == "pets":
        return generate_pets(Path(args.output), args.limit_families, source_cache=source_cache)
    if args.command == "stable-masters":
        return generate_stable_masters(Path(args.output), args.limit, source_cache=source_cache)
    raise AssertionError(args.command)


def generate_pets(
    output: Path,
    limit_families: int = 0,
    source_cache: SourceCache | None = None,
    generated_dir: Path = GENERATED_DIR,
) -> int:
    source_cache = source_cache or SourceCache(
        generated_dir / "cache",
        generated_dir / "refresh-manifest.json",
    )
    try:
        index_html = source_cache.get_text(HUNTER_PETS_URL, "pet-index").text
    except SourceFetchError as error:
        _write_lines(generated_dir / "pet-refresh-blockers.md", [str(error)])
        return 1
    families = source_family_rows(extract_listview_data(index_html, "pets"))
    if limit_families:
        families = families[:limit_families]

    records = []
    skipped = []
    with ThreadPoolExecutor(max_workers=FETCH_WORKERS) as executor:
        for family_index, family in enumerate(families, start=1):
            print(f"Fetching family {family_index}/{len(families)}: {family.name}", flush=True)
            family_url = pet_family_url(family.id)
            try:
                family_html = source_cache.get_text(family_url, "pet-family").text
            except SourceFetchError as error:
                _write_lines(
                    generated_dir / "pet-refresh-blockers.md",
                    [str(error)],
                )
                return 1
            tameable_rows = source_tameable_rows(extract_listview_data(family_html, "tameable"))
            futures = [
                executor.submit(_build_pet_record_from_source, family, tameable, source_cache)
                for tameable in tameable_rows
            ]
            for future in as_completed(futures):
                try:
                    tameable, record = future.result()
                except SourceFetchError as error:
                    _write_lines(generated_dir / "pet-refresh-blockers.md", [str(error)])
                    return 1
                if record is None:
                    skipped.append(f"{tameable.id} {tameable.name}: no mapper coordinates")
                    continue
                records.append(record)

    errors = validate_pet_records(records)
    if errors:
        _write_lines(generated_dir / "pet-validation-errors.md", errors)
        return 1

    output.write_text(export_pet_data(records), encoding="utf-8")
    _write_lines(generated_dir / "pet-skipped.md", skipped)
    print(f"Wrote {len(records)} pet records to {output}")
    return 0


def _build_pet_record_from_source(family, tameable, source_cache: SourceCache):
    source_url = npc_url(tameable.id)
    npc_html = source_cache.get_text(source_url, "pet-npc").text
    mapper_data = extract_mapper_data(npc_html)
    return tameable, build_pet_record(family, tameable, mapper_data)


def generate_stable_masters(
    output: Path,
    limit: int = 0,
    source_cache: SourceCache | None = None,
    generated_dir: Path = GENERATED_DIR,
) -> int:
    source_cache = source_cache or SourceCache(
        generated_dir / "cache",
        generated_dir / "refresh-manifest.json",
    )
    try:
        search_html = source_cache.get_text(STABLE_MASTER_SEARCH_URL, "stable-master-search").text
    except SourceFetchError as error:
        _write_lines(generated_dir / "stable-master-blockers.md", [str(error)])
        return 1
    rows = extract_listview_data(search_html, "npcs")
    rows = [row for row in rows if "Stable Master" in str(row.get("tag", ""))]
    if limit:
        rows = rows[:limit]

    records = []
    skipped = []
    for row in rows:
        try:
            html = source_cache.get_text(npc_url(int(row["id"])), "stable-master-npc").text
        except SourceFetchError as error:
            _write_lines(generated_dir / "stable-master-blockers.md", [str(error)])
            return 1
        record = build_stable_master_record(row, extract_mapper_data(html))
        if record is None:
            skipped.append(f"{row.get('id')} {row.get('name')}: no valid stable master coordinates")
            continue
        records.append(record)

    errors = validate_stable_master_records(records)
    if errors:
        _write_lines(generated_dir / "stable-master-validation-errors.md", errors)
        return 1

    if not records:
        _write_lines(generated_dir / "stable-master-blockers.md", skipped or ["No stable master records validated."])
        return 1

    output.write_text(export_stable_master_data(records), encoding="utf-8")
    _write_lines(generated_dir / "stable-master-skipped.md", skipped)
    print(f"Wrote {len(records)} stable master records to {output}")
    return 0


def _write_lines(path: Path, lines: list[str]) -> None:
    if not lines:
        path.write_text("", encoding="utf-8")
        return
    path.write_text("\n".join(f"- {line}" for line in lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
