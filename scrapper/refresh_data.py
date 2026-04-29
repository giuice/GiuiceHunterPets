from __future__ import annotations

import argparse
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


def main() -> int:
    parser = argparse.ArgumentParser(description="Refresh GiuiceHunterPets generated data.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    pets = subparsers.add_parser("pets")
    pets.add_argument("--output", default=str(GENERATED_DIR / "Data.lua"))
    pets.add_argument("--limit-families", type=int, default=0)

    stable = subparsers.add_parser("stable-masters")
    stable.add_argument("--output", default=str(GENERATED_DIR / "StableMastersData.lua"))
    stable.add_argument("--limit", type=int, default=0)

    args = parser.parse_args()
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)

    if args.command == "pets":
        return generate_pets(Path(args.output), args.limit_families)
    if args.command == "stable-masters":
        return generate_stable_masters(Path(args.output), args.limit)
    raise AssertionError(args.command)


def generate_pets(output: Path, limit_families: int = 0) -> int:
    index_html = fetch_text(HUNTER_PETS_URL)
    families = source_family_rows(extract_listview_data(index_html, "pets"))
    if limit_families:
        families = families[:limit_families]

    records = []
    skipped = []
    for family_index, family in enumerate(families, start=1):
        print(f"Fetching family {family_index}/{len(families)}: {family.name}", flush=True)
        family_html = fetch_text(pet_family_url(family.id))
        tameable_rows = source_tameable_rows(extract_listview_data(family_html, "tameable"))
        for tameable in tameable_rows:
            npc_html = fetch_text(npc_url(tameable.id))
            mapper_data = extract_mapper_data(npc_html)
            record = build_pet_record(family, tameable, mapper_data)
            if record is None:
                skipped.append(f"{tameable.id} {tameable.name}: no mapper coordinates")
                continue
            records.append(record)

    errors = validate_pet_records(records)
    if errors:
        _write_lines(GENERATED_DIR / "pet-validation-errors.md", errors)
        return 1

    output.write_text(export_pet_data(records), encoding="utf-8")
    _write_lines(GENERATED_DIR / "pet-skipped.md", skipped)
    print(f"Wrote {len(records)} pet records to {output}")
    return 0


def generate_stable_masters(output: Path, limit: int = 0) -> int:
    search_html = fetch_text(STABLE_MASTER_SEARCH_URL)
    rows = extract_listview_data(search_html, "npcs")
    rows = [row for row in rows if "Stable Master" in str(row.get("tag", ""))]
    if limit:
        rows = rows[:limit]

    records = []
    skipped = []
    for row in rows:
        html = fetch_text(npc_url(int(row["id"])))
        record = build_stable_master_record(row, extract_mapper_data(html))
        if record is None:
            skipped.append(f"{row.get('id')} {row.get('name')}: no valid stable master coordinates")
            continue
        records.append(record)

    errors = validate_stable_master_records(records)
    if errors:
        _write_lines(GENERATED_DIR / "stable-master-validation-errors.md", errors)
        return 1

    if not records:
        _write_lines(GENERATED_DIR / "stable-master-blockers.md", skipped or ["No stable master records validated."])
        return 1

    output.write_text(export_stable_master_data(records), encoding="utf-8")
    _write_lines(GENERATED_DIR / "stable-master-skipped.md", skipped)
    print(f"Wrote {len(records)} stable master records to {output}")
    return 0


def _write_lines(path: Path, lines: list[str]) -> None:
    if not lines:
        path.write_text("", encoding="utf-8")
        return
    path.write_text("\n".join(f"- {line}" for line in lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
