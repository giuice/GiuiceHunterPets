from __future__ import annotations

from scrapper.data_records import PetRecord, StableMasterRecord


VALID_FACTIONS = {"Alliance", "Horde", "Neutral"}


def lua_quote(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def export_pet_data(records: list[PetRecord]) -> str:
    lines = ["GHP.pet_by_zones = {"]
    for record in sorted(records, key=lambda item: (item.zone_id, item.family[0], item.npc_id)):
        lines.extend(
            [
                "    {",
                f'        ["zone_name"] = {lua_quote(record.zone_name)},',
                f'        ["zoneID"] = {record.zone_id},',
                f'        ["name"] = {lua_quote(record.name)},',
                f'        ["maxlevel"] = {record.maxlevel},',
                f'        ["minlevel"] = {record.minlevel},',
                f'        ["class"] = {lua_quote(record.pet_class)},',
                f'        ["family"] = {{ {record.family[0]}, {lua_quote(record.family[1])} }},',
                f'        ["displayId"] = {record.display_id},',
                f'        ["NpcId"] = {record.npc_id},',
                f'        ["coords"] = {{ {_format_coords(record.coords)} }},',
                "    },",
            ]
        )
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def export_stable_master_data(records: list[StableMasterRecord]) -> str:
    lines = [
        "-- StableMastersData.lua",
        "local addonName, GHP = ...",
        "",
        "GHP.stable_masters = {",
    ]
    for record in sorted(records, key=lambda item: (item.zone_id, item.npc_id)):
        lines.extend(
            [
                "    {",
                f'        ["npcID"] = {record.npc_id},',
                f'        ["name"] = {lua_quote(record.name)},',
                f'        ["zone_name"] = {lua_quote(record.zone_name)},',
                f'        ["zoneID"] = {record.zone_id},',
                f'        ["coords"] = {{ {_format_coords(record.coords)} }},',
                f'        ["faction"] = {lua_quote(record.faction)},',
                "    },",
            ]
        )
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def validate_pet_records(records: list[PetRecord]) -> list[str]:
    errors = []
    seen = set()
    for record in records:
        label = f"pet {record.npc_id} {record.name}"
        if record.npc_id in seen:
            errors.append(f"{label} is duplicated")
        seen.add(record.npc_id)
        if not record.name:
            errors.append(f"pet {record.npc_id} has no name")
        if not record.zone_id:
            errors.append(f"{label} has no zoneID")
        if not record.family or not record.family[0] or not record.family[1]:
            errors.append(f"{label} has no family")
        if not record.pet_class:
            errors.append(f"{label} has no class")
        if not record.coords:
            errors.append(f"{label} has no coords")
        errors.extend(_coord_errors(label, record.coords))
    return errors


def validate_stable_master_records(records: list[StableMasterRecord]) -> list[str]:
    errors = []
    seen = set()
    for record in records:
        label = f"stable master {record.npc_id} {record.name}"
        if record.npc_id in seen:
            errors.append(f"{label} is duplicated")
        seen.add(record.npc_id)
        if not record.name:
            errors.append(f"stable master {record.npc_id} has no name")
        if not record.zone_id:
            errors.append(f"{label} has no zoneID")
        if not record.coords:
            errors.append(f"{label} has no coords")
        if record.faction not in VALID_FACTIONS:
            errors.append(f"{label} has invalid faction {record.faction}")
        errors.extend(_coord_errors(label, record.coords))
    return errors


def _format_coords(coords: tuple[tuple[float, float], ...]) -> str:
    return ", ".join(f"{{ {_format_number(x)}, {_format_number(y)} }}" for x, y in coords)


def _format_number(value: float) -> str:
    text = f"{value:.2f}".rstrip("0").rstrip(".")
    return text or "0"


def _coord_errors(label: str, coords: tuple[tuple[float, float], ...]) -> list[str]:
    errors = []
    for x, y in coords:
        if x < 0 or x > 100 or y < 0 or y > 100:
            errors.append(f"{label} has out-of-range coord {x}, {y}")
    return errors
