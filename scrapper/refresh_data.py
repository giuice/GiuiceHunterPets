from __future__ import annotations

import argparse
import json
import math
import subprocess
import sys
import time
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
T = TypeVar("T")
SEMANTIC_SOURCE_ERRORS = (ValueError, TypeError, KeyError, AttributeError)


class PageBudget:
    def __init__(self, limit_pages: int, delay: float):
        if limit_pages < 1:
            raise ValueError("--limit-pages must be at least 1")
        if delay < 0:
            raise ValueError("--delay must be zero or greater")
        self.limit_pages = limit_pages
        self.delay = delay
        self.collected = 0

    def exhausted(self) -> bool:
        return self.collected >= self.limit_pages

    def mark_collected(self) -> None:
        self.collected += 1
        if not self.exhausted() and self.delay:
            time.sleep(self.delay)


class AgentBrowserFetcher:
    def __call__(self, url: str) -> str:
        self._run(["agent-browser", "open", url])
        raw_html = self._run(["agent-browser", "eval", "document.documentElement.outerHTML"])
        html = json.loads(raw_html)
        if not isinstance(html, str):
            raise ValueError(f"agent-browser returned {type(html).__name__}, expected HTML string")
        return html

    def close(self) -> None:
        subprocess.run(["agent-browser", "close"], check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def _run(self, command: list[str]) -> str:
        completed = subprocess.run(command, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return completed.stdout


def _fetcher_for_backend(backend: str):
    if backend == "agent-browser":
        return AgentBrowserFetcher()
    if backend == "python":
        return fetch_text
    raise ValueError(f"unknown backend: {backend}")


def collect_pets_sources(
    limit_pages: int,
    delay: float,
    backend: str,
    source_cache: SourceCache | None = None,
) -> int:
    source_cache = source_cache or SourceCache(GENERATED_DIR / "cache", MANIFEST_PATH)
    fetcher = _fetcher_for_backend(backend)
    budget = PageBudget(limit_pages, delay)
    try:
        if not _collect_one(source_cache, fetcher, HUNTER_PETS_URL, "pet-index", budget):
            return _finish_collection("pets", budget)

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
            if not _collect_one(source_cache, fetcher, family_url, "pet-family", budget):
                return _finish_collection("pets", budget)
            try:
                family_source = source_cache.read_text(family_url, "pet-family")
                tameable_ids = _tameable_npc_ids_from_source(source_cache, family_source, family.name)
            except (SourceFetchError, ValueError) as error:
                _write_pet_blockers(GENERATED_DIR, [str(error)])
                return 1
            for tameable_id in tameable_ids:
                if not _collect_one(source_cache, fetcher, npc_url(tameable_id), "pet-npc", budget):
                    return _finish_collection("pets", budget)
    except SourceFetchError as error:
        _write_pet_blockers(GENERATED_DIR, [str(error)])
        return 1
    finally:
        if isinstance(fetcher, AgentBrowserFetcher):
            fetcher.close()
    return _finish_collection("pets", budget)


def collect_stable_master_sources(
    limit_pages: int,
    delay: float,
    backend: str,
    source_cache: SourceCache | None = None,
) -> int:
    source_cache = source_cache or SourceCache(GENERATED_DIR / "cache", MANIFEST_PATH)
    fetcher = _fetcher_for_backend(backend)
    budget = PageBudget(limit_pages, delay)
    try:
        if not _collect_one(source_cache, fetcher, STABLE_MASTER_SEARCH_URL, "stable-master-search", budget):
            return _finish_collection("stable-masters", budget)
        try:
            search_source = source_cache.read_text(STABLE_MASTER_SEARCH_URL, "stable-master-search")
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
                npc_id = _stable_master_npc_id(row, index)
            except SEMANTIC_SOURCE_ERRORS as error:
                source_cache.record_semantic_error(
                    search_source.url,
                    search_source.role,
                    "parse_error",
                    f"Malformed stable master search source: {search_source.url}: {error}",
                )
                _write_stable_master_blockers(GENERATED_DIR, [str(error)])
                return 1
            if not _collect_one(source_cache, fetcher, npc_url(npc_id), "stable-master-npc", budget):
                return _finish_collection("stable-masters", budget)
    except SourceFetchError as error:
        _write_stable_master_blockers(GENERATED_DIR, [str(error)])
        return 1
    finally:
        if isinstance(fetcher, AgentBrowserFetcher):
            fetcher.close()
    return _finish_collection("stable-masters", budget)


def _collect_one(source_cache: SourceCache, fetcher, url: str, role: str, budget: PageBudget) -> bool:
    if source_cache.has_text(url):
        print(f"Cached {role}: {url}", flush=True)
        return True
    if budget.exhausted():
        return False
    try:
        text = fetcher(url)
    except Exception as error:
        source_cache.record_semantic_error(url, role, "error", str(error))
        raise SourceFetchError(url, role, error) from error
    result = source_cache.store_text(url, role, text)
    budget.mark_collected()
    print(f"Collected {budget.collected}/{budget.limit_pages} {role}: {result.path}", flush=True)
    return True


def _finish_collection(name: str, budget: PageBudget) -> int:
    if name == "pets":
        _clear_lines(GENERATED_DIR / "pet-refresh-blockers.md")
    elif name == "stable-masters":
        _clear_lines(GENERATED_DIR / "stable-master-blockers.md")
    print(f"Collected {budget.collected} new {name} source page(s).")
    if budget.exhausted():
        print("Page limit reached; rerun the collect command to continue.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Refresh GiuiceHunterPets generated data.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    collect_pets = subparsers.add_parser("collect-pets")
    collect_pets.add_argument("--limit-pages", type=int, required=True)
    collect_pets.add_argument("--delay", type=float, default=5.0)
    collect_pets.add_argument("--backend", choices=("agent-browser", "python"), default="agent-browser")
    collect_pets.add_argument("--reset-cache", action="store_true", help="Delete cached source pages before collecting.")

    build_pets = subparsers.add_parser("build-pets")
    build_pets.add_argument("--output", default=str(GENERATED_DIR / "Data.lua"))
    build_pets.add_argument("--limit-families", type=int, default=0)
    build_pets.add_argument("--from-cache", action="store_true", required=True)

    collect_stable = subparsers.add_parser("collect-stable-masters")
    collect_stable.add_argument("--limit-pages", type=int, required=True)
    collect_stable.add_argument("--delay", type=float, default=5.0)
    collect_stable.add_argument("--backend", choices=("agent-browser", "python"), default="agent-browser")
    collect_stable.add_argument("--reset-cache", action="store_true", help="Delete cached source pages before collecting.")

    build_stable = subparsers.add_parser("build-stable-masters")
    build_stable.add_argument("--output", default=str(GENERATED_DIR / "StableMastersData.lua"))
    build_stable.add_argument("--limit", type=int, default=0)
    build_stable.add_argument("--from-cache", action="store_true", required=True)

    pets = subparsers.add_parser("pets")
    pets.add_argument("--output", default=str(GENERATED_DIR / "Data.lua"))
    pets.add_argument("--limit-families", type=int, default=0)
    pets.add_argument("--resume", action="store_true", help="Deprecated alias for build-pets --from-cache.")
    pets.add_argument("--reset-cache", action="store_true", help="Deprecated; use collect-pets --reset-cache.")

    stable = subparsers.add_parser("stable-masters")
    stable.add_argument("--output", default=str(GENERATED_DIR / "StableMastersData.lua"))
    stable.add_argument("--limit", type=int, default=0)
    stable.add_argument("--resume", action="store_true", help="Deprecated alias for build-stable-masters --from-cache.")
    stable.add_argument("--reset-cache", action="store_true", help="Deprecated; use collect-stable-masters --reset-cache.")

    args = parser.parse_args()
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)
    source_cache = SourceCache(GENERATED_DIR / "cache", MANIFEST_PATH, fetcher=fetch_text)
    if getattr(args, "reset_cache", False):
        source_cache.reset()

    if args.command == "collect-pets":
        exit_code = collect_pets_sources(
            args.limit_pages,
            args.delay,
            args.backend,
            source_cache=source_cache,
        )
        _print_failure_report(exit_code, "pets", GENERATED_DIR)
        return exit_code
    if args.command == "collect-stable-masters":
        exit_code = collect_stable_master_sources(
            args.limit_pages,
            args.delay,
            args.backend,
            source_cache=source_cache,
        )
        _print_failure_report(exit_code, "stable-masters", GENERATED_DIR)
        return exit_code
    if args.command in {"build-pets", "pets"}:
        exit_code = generate_pets(
            Path(args.output),
            args.limit_families,
            source_cache=source_cache,
            generated_dir=GENERATED_DIR,
            from_cache=True,
        )
        _print_failure_report(exit_code, "pets", GENERATED_DIR)
        return exit_code
    if args.command in {"build-stable-masters", "stable-masters"}:
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


def generate_pets(
    output: Path,
    limit_families: int = 0,
    source_cache: SourceCache | None = None,
    generated_dir: Path = GENERATED_DIR,
    from_cache: bool = False,
) -> int:
    source_cache = source_cache or SourceCache(
        generated_dir / "cache",
        generated_dir / "refresh-manifest.json",
    )
    try:
        index_source = _source_text(source_cache, HUNTER_PETS_URL, "pet-index", from_cache)
    except SourceFetchError as error:
        _write_pet_blockers(generated_dir, [str(error)])
        return 1
    try:
        families = _listview_rows_from_source(
            source_cache,
            index_source,
            "pets",
            "Malformed pet index source",
            source_family_rows,
            row_validator=_validate_pet_family_rows,
        )
    except ValueError as semantic_error:
        error = str(semantic_error)
        _write_pet_blockers(generated_dir, [error])
        return 1
    if not families:
        error = f"No pet families found in pet index source: {index_source.url}"
        source_cache.invalidate(index_source.url, index_source.role, error)
        _write_pet_blockers(generated_dir, [error])
        return 1
    if limit_families:
        families = families[:limit_families]

    records = []
    skipped = []
    for family_index, family in enumerate(families, start=1):
        print(f"Reading family {family_index}/{len(families)}: {family.name}", flush=True)
        family_url = pet_family_url(family.id)
        try:
            family_source = _source_text(source_cache, family_url, "pet-family", from_cache)
        except SourceFetchError as error:
            _write_pet_blockers(generated_dir, [str(error)])
            return 1
        try:
            tameable_rows = _listview_rows_from_source(
                source_cache,
                family_source,
                "tameable",
                f"Malformed tameable pets source for family {family.name}",
                source_tameable_rows,
                row_validator=_validate_tameable_pet_rows,
            )
        except ValueError as semantic_error:
            error = str(semantic_error)
            _write_pet_blockers(generated_dir, [error])
            return 1
        if not tameable_rows:
            error = f"No tameable pets found for family {family.name}: {family_source.url}"
            source_cache.invalidate(family_source.url, family_source.role, error)
            _write_pet_blockers(generated_dir, [error])
            return 1
        for tameable in tameable_rows:
            try:
                tameable, record = _build_pet_record_from_source(family, tameable, source_cache, from_cache)
            except SourceFetchError as error:
                _write_pet_blockers(generated_dir, [str(error)])
                return 1
            if record is None:
                skipped.append(f"{tameable.id} {tameable.name}: no mapper coordinates")
                continue
            records.append(record)

    if not records:
        _write_pet_blockers(generated_dir, skipped or ["No pet records validated."])
        return 1

    errors = validate_pet_records(records)
    if errors:
        _write_pet_validation_errors(generated_dir, errors)
        return 1

    _clear_lines(generated_dir / "pet-refresh-blockers.md")
    _clear_lines(generated_dir / "pet-validation-errors.md")
    output.write_text(export_pet_data(records), encoding="utf-8")
    _write_lines(generated_dir / "pet-skipped.md", skipped)
    print(f"Wrote {len(records)} pet records to {output}")
    return 0


def _build_pet_record_from_source(family, tameable, source_cache: SourceCache, from_cache: bool = False):
    source_url = npc_url(tameable.id)
    source, mapper_data = _extract_mapper_data_from_source(source_cache, source_url, "pet-npc", from_cache)
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
    from_cache: bool = False,
) -> int:
    source_cache = source_cache or SourceCache(
        generated_dir / "cache",
        generated_dir / "refresh-manifest.json",
    )
    try:
        search_source = _source_text(source_cache, STABLE_MASTER_SEARCH_URL, "stable-master-search", from_cache)
    except SourceFetchError as error:
        _write_stable_master_blockers(generated_dir, [str(error)])
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
        _write_stable_master_blockers(generated_dir, [error])
        return 1
    if not raw_rows:
        error = f"No stable master rows found in search source: {search_source.url}"
        source_cache.invalidate(search_source.url, search_source.role, error)
        _write_stable_master_blockers(generated_dir, [error])
        return 1
    rows = [row for row in raw_rows if "Stable Master" in str(row.get("tag", ""))]
    if not rows:
        error = f"No stable master rows found in search source: {search_source.url}"
        source_cache.invalidate(search_source.url, search_source.role, error)
        _write_stable_master_blockers(generated_dir, [error])
        return 1
    try:
        rows_with_values = [
            (
                row,
                _stable_master_npc_id(row, index),
                _stable_master_name(row, index),
                _stable_master_location_ids(row, index),
                _required_react(row, index, "stable master"),
            )
            for index, row in enumerate(rows)
        ]
    except SEMANTIC_SOURCE_ERRORS as parse_error:
        error = f"Malformed stable master search source: {search_source.url}: {parse_error}"
        source_cache.invalidate(search_source.url, search_source.role, error)
        _write_stable_master_blockers(generated_dir, [error])
        return 1
    if limit:
        rows_with_values = rows_with_values[:limit]

    records = []
    skipped = []
    for row, npc_id, _name, locations, _react in rows_with_values:
        try:
            source, mapper_data = _extract_mapper_data_from_source(
                source_cache,
                npc_url(npc_id),
                "stable-master-npc",
                from_cache,
            )
            _validate_mapper_data_for_locations(mapper_data, locations)
            record = build_stable_master_record(row, mapper_data)
        except SourceFetchError as error:
            _write_stable_master_blockers(generated_dir, [str(error)])
            return 1
        except SEMANTIC_SOURCE_ERRORS as parse_error:
            error = _malformed_mapper_source_error(source_cache, source, parse_error)
            _write_stable_master_blockers(generated_dir, [str(error)])
            return 1
        if record is None:
            skipped.append(f"{row.get('id')} {row.get('name')}: no valid stable master coordinates")
            continue
        records.append(record)

    errors = validate_stable_master_records(records)
    if errors:
        _write_stable_master_validation_errors(generated_dir, errors)
        return 1

    if not records:
        _write_stable_master_blockers(generated_dir, skipped or ["No stable master records validated."])
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
    normalizer: Callable[[list[dict[str, Any]]], T],
    row_validator: Callable[[list[dict[str, Any]]], None] | None = None,
) -> T:
    try:
        rows = extract_listview_data(source.text, listview_id)
        _require_list_rows(rows, listview_id)
        if row_validator is not None:
            row_validator(rows)
        return normalizer(rows)
    except SEMANTIC_SOURCE_ERRORS as parse_error:
        error = f"{error_prefix}: {source.url}: {parse_error}"
        source_cache.invalidate(source.url, source.role, error)
        raise ValueError(error) from parse_error


def _tameable_npc_ids_from_source(source_cache: SourceCache, source, family_name: str) -> list[int]:
    try:
        rows = extract_listview_data(source.text, "tameable")
        _require_list_rows(rows, "tameable")
        npc_ids = []
        for index, row in enumerate(rows):
            npc_ids.append(_required_positive_int(row, index, "tameable pet", "id"))
        return npc_ids
    except SEMANTIC_SOURCE_ERRORS as parse_error:
        error = f"Malformed tameable pets source for family {family_name}: {source.url}: {parse_error}"
        source_cache.invalidate(source.url, source.role, error)
        raise ValueError(error) from parse_error


def _require_list_rows(rows, listview_id: str) -> None:
    if not isinstance(rows, list):
        raise ValueError(f"listview {listview_id} data must be a list of objects, got {type(rows).__name__}")
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            raise ValueError(f"listview {listview_id} row {index} must be an object, got {type(row).__name__}")


def _validate_pet_family_rows(rows: list[dict[str, Any]]) -> None:
    for index, row in enumerate(rows):
        _required_positive_int(row, index, "pet family", "id")
        _required_name(row, index, "pet family")


def _validate_tameable_pet_rows(rows: list[dict[str, Any]]) -> None:
    for index, row in enumerate(rows):
        _required_positive_int(row, index, "tameable pet", "id")
        _required_name(row, index, "tameable pet")
        _optional_int(row, index, "tameable pet", "classification")
        _optional_positive_int_list(row, index, "tameable pet", "location")
        _required_react(row, index, "tameable pet")
        _optional_int(row, index, "tameable pet", "minlevel")
        _optional_int(row, index, "tameable pet", "maxlevel")


def _required_int(row: dict[str, Any], index: int, row_name: str, field: str) -> int:
    raw_value = row.get(field)
    if raw_value is None:
        raise ValueError(f"{row_name} row {index} is missing {field}")
    if not _is_json_int(raw_value):
        raise ValueError(f"{row_name} row {index} {field} must be an integer")
    return raw_value


def _optional_int(row: dict[str, Any], index: int, row_name: str, field: str) -> int | None:
    raw_value = row.get(field)
    if raw_value is None:
        return None
    if not _is_json_int(raw_value):
        raise ValueError(f"{row_name} row {index} {field} must be an integer when present")
    return raw_value


def _required_positive_int(row: dict[str, Any], index: int, row_name: str, field: str) -> int:
    value = _required_int(row, index, row_name, field)
    if value <= 0:
        raise ValueError(f"{row_name} row {index} {field} must be a positive integer")
    return value


def _required_name(row: dict[str, Any], index: int, row_name: str) -> str:
    raw_name = row.get("name")
    if not isinstance(raw_name, str) or not raw_name.strip():
        raise ValueError(f"{row_name} row {index} is missing name")
    return raw_name


def _required_int_list(row: dict[str, Any], index: int, row_name: str, field: str) -> list[int]:
    raw_values = row.get(field)
    if not isinstance(raw_values, list) or not raw_values:
        raise ValueError(f"{row_name} row {index} {field} must be a non-empty list")
    if not all(_is_json_int(value) for value in raw_values):
        raise ValueError(f"{row_name} row {index} {field} values must be integers")
    return raw_values


def _required_positive_int_list(row: dict[str, Any], index: int, row_name: str, field: str) -> list[int]:
    values = _required_int_list(row, index, row_name, field)
    if not all(value > 0 for value in values):
        raise ValueError(f"{row_name} row {index} {field} values must be positive integers")
    return values


def _optional_positive_int_list(row: dict[str, Any], index: int, row_name: str, field: str) -> list[int] | None:
    raw_values = row.get(field)
    if raw_values is None or raw_values == []:
        return None
    values = _required_int_list(row, index, row_name, field)
    if not all(value > 0 for value in values):
        raise ValueError(f"{row_name} row {index} {field} values must be positive integers")
    return values


def _required_react(row: dict[str, Any], index: int, row_name: str) -> None:
    react = row.get("react", [0, 0])
    if not isinstance(react, list) or len(react) != 2:
        raise ValueError(f"{row_name} row {index} react must be a list with exactly two values")
    if not all(value is None or _is_json_int(value) for value in react):
        raise ValueError(f"{row_name} row {index} react values must be integers or null")
    if not all(value is None or value in {-1, 0, 1} for value in react):
        raise ValueError(f"{row_name} row {index} react values must be -1, 0, 1, or null")


def _stable_master_npc_id(row: dict, index: int) -> int:
    return _required_positive_int(row, index, "stable master", "id")


def _stable_master_name(row: dict, index: int) -> str:
    raw_name = row.get("name")
    if not isinstance(raw_name, str) or not raw_name.strip():
        raise ValueError(f"stable master row {index} is missing name")
    return raw_name


def _stable_master_location_ids(row: dict, index: int) -> list[int]:
    raw_locations = row.get("location", [])
    if not isinstance(raw_locations, list):
        raise ValueError(
            f"stable master row {index} location must be a list, got {type(raw_locations).__name__}"
        )
    if not all(_is_json_int(value) for value in raw_locations):
        raise ValueError(f"stable master row {index} location values must be integers")
    if not all(value > 0 for value in raw_locations):
        raise ValueError(f"stable master row {index} location values must be positive integers")
    return raw_locations


def _is_json_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _source_text(source_cache: SourceCache, url: str, role: str, from_cache: bool):
    if from_cache:
        return source_cache.read_text(url, role)
    return source_cache.get_text(url, role)


def _extract_mapper_data_from_source(source_cache: SourceCache, url: str, role: str, from_cache: bool = False):
    source = _source_text(source_cache, url, role, from_cache)
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
        if not _is_finite_real_number(x) or not _is_finite_real_number(y):
            raise ValueError(
                f"mapper location {location_id} entry {key} coords {index} must have finite numeric x/y values"
            )
        if not _is_percentage_coordinate(x) or not _is_percentage_coordinate(y):
            raise ValueError(
                f"mapper location {location_id} entry {key} coords {index} x/y values must be between 0 and 100"
            )


def _is_finite_real_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def _is_percentage_coordinate(value: int | float) -> bool:
    return 0 <= value <= 100


def _malformed_mapper_source_error(source_cache: SourceCache, source, parse_error: Exception) -> SourceFetchError:
    error = f"Malformed g_mapperData values in source: {source.url}: {parse_error}"
    source_cache.invalidate(source.url, source.role, error)
    return SourceFetchError(source.url, source.role, ValueError(error))


def _clear_lines(path: Path) -> None:
    path.unlink(missing_ok=True)


def _print_failure_report(exit_code: int, command: str, generated_dir: Path) -> None:
    if exit_code == 0:
        return
    report_paths = {
        "pets": [
            generated_dir / "pet-refresh-blockers.md",
            generated_dir / "pet-validation-errors.md",
        ],
        "stable-masters": [
            generated_dir / "stable-master-blockers.md",
            generated_dir / "stable-master-validation-errors.md",
        ],
    }[command]
    existing_reports = [path for path in report_paths if path.exists()]
    if not existing_reports:
        print("Refresh failed. No failure report was written.", file=sys.stderr)
        return
    print("Refresh failed. See:", file=sys.stderr)
    for path in existing_reports:
        print(f"- {path}", file=sys.stderr)
        summary = path.read_text(encoding="utf-8").strip()
        if summary:
            print(summary, file=sys.stderr)


def _write_pet_blockers(generated_dir: Path, lines: list[str]) -> None:
    _clear_lines(generated_dir / "pet-validation-errors.md")
    _write_lines(generated_dir / "pet-refresh-blockers.md", lines)


def _write_pet_validation_errors(generated_dir: Path, lines: list[str]) -> None:
    _clear_lines(generated_dir / "pet-refresh-blockers.md")
    _write_lines(generated_dir / "pet-validation-errors.md", lines)


def _write_stable_master_blockers(generated_dir: Path, lines: list[str]) -> None:
    _clear_lines(generated_dir / "stable-master-validation-errors.md")
    _write_lines(generated_dir / "stable-master-blockers.md", lines)


def _write_stable_master_validation_errors(generated_dir: Path, lines: list[str]) -> None:
    _clear_lines(generated_dir / "stable-master-blockers.md")
    _write_lines(generated_dir / "stable-master-validation-errors.md", lines)


def _write_lines(path: Path, lines: list[str]) -> None:
    if not lines:
        path.write_text("", encoding="utf-8")
        return
    path.write_text("\n".join(f"- {line}" for line in lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
