from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any, Callable, TypeVar

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
    extract_js_assignment,
    extract_listview_data,
    fetch_text,
    npc_url,
    pet_family_url,
)


GENERATED_DIR = Path("scrapper/generated")
MANIFEST_PATH = GENERATED_DIR / "refresh-manifest.json"
FETCH_WORKERS = 4
T = TypeVar("T")
SEMANTIC_SOURCE_ERRORS = (ValueError, TypeError, KeyError, AttributeError)


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
        index_source = source_cache.get_text(HUNTER_PETS_URL, "pet-index")
    except SourceFetchError as error:
        _write_lines(generated_dir / "pet-refresh-blockers.md", [str(error)])
        return 1
    try:
        families = _listview_rows_from_source(
            source_cache,
            index_source,
            "pets",
            "Malformed pet index source",
            source_family_rows,
        )
    except ValueError as semantic_error:
        error = str(semantic_error)
        _write_lines(generated_dir / "pet-refresh-blockers.md", [error])
        return 1
    if not families:
        error = f"No pet families found in pet index source: {index_source.url}"
        source_cache.invalidate(index_source.url, index_source.role, error)
        _write_lines(
            generated_dir / "pet-refresh-blockers.md",
            [error],
        )
        return 1
    if limit_families:
        families = families[:limit_families]

    records = []
    skipped = []
    with ThreadPoolExecutor(max_workers=FETCH_WORKERS) as executor:
        for family_index, family in enumerate(families, start=1):
            print(f"Fetching family {family_index}/{len(families)}: {family.name}", flush=True)
            family_url = pet_family_url(family.id)
            try:
                family_source = source_cache.get_text(family_url, "pet-family")
            except SourceFetchError as error:
                _write_lines(
                    generated_dir / "pet-refresh-blockers.md",
                    [str(error)],
                )
                return 1
            try:
                tameable_rows = _listview_rows_from_source(
                    source_cache,
                    family_source,
                    "tameable",
                    f"Malformed tameable pets source for family {family.name}",
                    source_tameable_rows,
                )
            except ValueError as semantic_error:
                error = str(semantic_error)
                _write_lines(generated_dir / "pet-refresh-blockers.md", [error])
                return 1
            if not tameable_rows:
                error = f"No tameable pets found for family {family.name}: {family_source.url}"
                source_cache.invalidate(family_source.url, family_source.role, error)
                _write_lines(
                    generated_dir / "pet-refresh-blockers.md",
                    [error],
                )
                return 1
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

    if not records:
        _write_lines(generated_dir / "pet-refresh-blockers.md", skipped or ["No pet records validated."])
        return 1

    errors = validate_pet_records(records)
    if errors:
        _write_lines(generated_dir / "pet-validation-errors.md", errors)
        return 1

    _clear_lines(generated_dir / "pet-refresh-blockers.md")
    _clear_lines(generated_dir / "pet-validation-errors.md")
    output.write_text(export_pet_data(records), encoding="utf-8")
    _write_lines(generated_dir / "pet-skipped.md", skipped)
    print(f"Wrote {len(records)} pet records to {output}")
    return 0


def _build_pet_record_from_source(family, tameable, source_cache: SourceCache):
    source_url = npc_url(tameable.id)
    source, mapper_data = _extract_mapper_data_from_source(source_cache, source_url, "pet-npc")
    try:
        _validate_mapper_data_for_locations(mapper_data, tameable.location)
        record = build_pet_record(family, tameable, mapper_data)
    except SEMANTIC_SOURCE_ERRORS as parse_error:
        raise _malformed_mapper_source_error(source_cache, source, parse_error) from parse_error
    return tameable, record


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
        search_source = source_cache.get_text(STABLE_MASTER_SEARCH_URL, "stable-master-search")
    except SourceFetchError as error:
        _write_lines(generated_dir / "stable-master-blockers.md", [str(error)])
        return 1
    try:
        raw_rows = _listview_rows_from_source(
            source_cache,
            search_source,
            "npcs",
            "Malformed stable master search source",
            lambda rows: rows,
        )
    except ValueError as semantic_error:
        error = str(semantic_error)
        _write_lines(generated_dir / "stable-master-blockers.md", [error])
        return 1
    if not raw_rows:
        error = f"No stable master rows found in search source: {search_source.url}"
        source_cache.invalidate(search_source.url, search_source.role, error)
        _write_lines(generated_dir / "stable-master-blockers.md", [error])
        return 1
    rows = [row for row in raw_rows if "Stable Master" in str(row.get("tag", ""))]
    if not rows:
        error = f"No stable master rows found in search source: {search_source.url}"
        source_cache.invalidate(search_source.url, search_source.role, error)
        _write_lines(generated_dir / "stable-master-blockers.md", [error])
        return 1
    try:
        rows_with_values = [
            (row, _stable_master_npc_id(row, index), _stable_master_location_ids(row, index))
            for index, row in enumerate(rows)
        ]
    except SEMANTIC_SOURCE_ERRORS as parse_error:
        error = f"Malformed stable master search source: {search_source.url}: {parse_error}"
        source_cache.invalidate(search_source.url, search_source.role, error)
        _write_lines(generated_dir / "stable-master-blockers.md", [error])
        return 1
    if limit:
        rows_with_values = rows_with_values[:limit]

    records = []
    skipped = []
    for row, npc_id, locations in rows_with_values:
        try:
            source, mapper_data = _extract_mapper_data_from_source(
                source_cache,
                npc_url(npc_id),
                "stable-master-npc",
            )
            _validate_mapper_data_for_locations(mapper_data, locations)
            record = build_stable_master_record(row, mapper_data)
        except SourceFetchError as error:
            _write_lines(generated_dir / "stable-master-blockers.md", [str(error)])
            return 1
        except SEMANTIC_SOURCE_ERRORS as parse_error:
            error = _malformed_mapper_source_error(source_cache, source, parse_error)
            _write_lines(generated_dir / "stable-master-blockers.md", [str(error)])
            return 1
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

    _clear_lines(generated_dir / "stable-master-blockers.md")
    _clear_lines(generated_dir / "stable-master-validation-errors.md")
    output.write_text(export_stable_master_data(records), encoding="utf-8")
    _write_lines(generated_dir / "stable-master-skipped.md", skipped)
    print(f"Wrote {len(records)} stable master records to {output}")
    return 0


def _listview_rows_from_source(
    source_cache: SourceCache,
    source,
    listview_id: str,
    error_prefix: str,
    normalizer: Callable[[list[dict]], T],
) -> T:
    try:
        rows = extract_listview_data(source.text, listview_id)
        _require_list_rows(rows, listview_id)
        return normalizer(rows)
    except SEMANTIC_SOURCE_ERRORS as parse_error:
        error = f"{error_prefix}: {source.url}: {parse_error}"
        source_cache.invalidate(source.url, source.role, error)
        raise ValueError(error) from parse_error


def _require_list_rows(rows, listview_id: str) -> None:
    if not isinstance(rows, list):
        raise ValueError(f"listview {listview_id} data must be a list of objects, got {type(rows).__name__}")
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            raise ValueError(f"listview {listview_id} row {index} must be an object, got {type(row).__name__}")


def _stable_master_npc_id(row: dict, index: int) -> int:
    raw_id = row.get("id")
    if raw_id is None or raw_id == "":
        raise ValueError(f"stable master row {index} is missing id")
    return int(raw_id)


def _stable_master_location_ids(row: dict, index: int) -> list[int]:
    raw_locations = row.get("location", [])
    if not isinstance(raw_locations, list):
        raise ValueError(
            f"stable master row {index} location must be a list, got {type(raw_locations).__name__}"
        )
    return [int(value) for value in raw_locations]


def _extract_mapper_data_from_source(source_cache: SourceCache, url: str, role: str):
    source = source_cache.get_text(url, role)
    try:
        mapper_data = extract_js_assignment(source.text, "g_mapperData")
    except ValueError as parse_error:
        error = f"Malformed g_mapperData assignment in source: {source.url}: {parse_error}"
        source_cache.invalidate(source.url, source.role, error)
        raise SourceFetchError(source.url, source.role, ValueError(error)) from parse_error
    if mapper_data is None:
        error = f"Missing g_mapperData assignment in source: {source.url}"
        source_cache.invalidate(source.url, source.role, error)
        raise SourceFetchError(source.url, source.role, ValueError(error))
    if not isinstance(mapper_data, dict):
        error = (
            f"Invalid g_mapperData assignment in source: {source.url}: "
            f"expected object, got {type(mapper_data).__name__}"
        )
        source_cache.invalidate(source.url, source.role, error)
        raise SourceFetchError(source.url, source.role, ValueError(error))
    return source, mapper_data


def _validate_mapper_data_for_locations(mapper_data: dict[str, Any], locations: list[int]) -> None:
    for location_id in locations:
        for key in (str(location_id), location_id):
            if key in mapper_data:
                _validate_mapper_entries(location_id, mapper_data[key])


def _validate_mapper_entries(location_id: int, entries: Any) -> None:
    if isinstance(entries, list):
        for index, entry in enumerate(entries):
            _validate_mapper_entry(location_id, index, entry)
        return
    if isinstance(entries, dict):
        for key, entry in entries.items():
            _validate_mapper_entry(location_id, key, entry)
        return
    raise ValueError(
        f"mapper location {location_id} entries must be a list or object, got {type(entries).__name__}"
    )


def _validate_mapper_entry(location_id: int, key: Any, entry: Any) -> None:
    if not isinstance(entry, dict):
        raise ValueError(
            f"mapper location {location_id} entry {key} must be an object, got {type(entry).__name__}"
        )
    if "coords" in entry:
        _validate_mapper_coords(location_id, key, entry["coords"])


def _validate_mapper_coords(location_id: int, key: Any, coords: Any) -> None:
    if not isinstance(coords, list):
        raise ValueError(
            f"mapper location {location_id} entry {key} coords must be a list, got {type(coords).__name__}"
        )
    for index, coord in enumerate(coords):
        if not isinstance(coord, (list, tuple)):
            raise ValueError(
                f"mapper location {location_id} entry {key} coords {index} must be a coordinate pair, "
                f"got {type(coord).__name__}"
            )
        if len(coord) < 2:
            raise ValueError(
                f"mapper location {location_id} entry {key} coords {index} must have at least two values"
            )
        x, y = coord[0], coord[1]
        if not isinstance(x, (int, float)) or not isinstance(y, (int, float)):
            raise ValueError(
                f"mapper location {location_id} entry {key} coords {index} must have numeric x/y values"
            )


def _malformed_mapper_source_error(source_cache: SourceCache, source, parse_error: Exception) -> SourceFetchError:
    error = f"Malformed g_mapperData values in source: {source.url}: {parse_error}"
    source_cache.invalidate(source.url, source.role, error)
    return SourceFetchError(source.url, source.role, ValueError(error))


def _clear_lines(path: Path) -> None:
    path.unlink(missing_ok=True)


def _write_lines(path: Path, lines: list[str]) -> None:
    if not lines:
        path.write_text("", encoding="utf-8")
        return
    path.write_text("\n".join(f"- {line}" for line in lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
