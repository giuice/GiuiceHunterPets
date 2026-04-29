from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class PetFamilySourceRow:
    id: int
    name: str


@dataclass(frozen=True)
class TameablePetSourceRow:
    id: int
    name: str
    family: int
    classification: int | None
    location: list[int]
    react: list[int]
    minlevel: int | None
    maxlevel: int | None


@dataclass(frozen=True)
class PetRecord:
    zone_name: str
    zone_id: int
    name: str
    maxlevel: int
    minlevel: int
    pet_class: str
    family: tuple[int, str]
    display_id: int
    npc_id: int
    coords: tuple[tuple[float, float], ...]


@dataclass(frozen=True)
class StableMasterRecord:
    npc_id: int
    name: str
    zone_name: str
    zone_id: int
    coords: tuple[tuple[float, float], ...]
    faction: str


def classification_label(value: int | None) -> str:
    labels = {
        0: "Normal",
        1: "Elite",
        2: "Rare Elite",
        3: "Boss",
        4: "Rare",
        5: "World Boss",
    }
    return labels.get(value, "Normal")


def faction_label(react: list[int] | tuple[int, int] | None) -> str:
    if react == [1, -1] or react == (1, -1):
        return "Alliance"
    if react == [-1, 1] or react == (-1, 1):
        return "Horde"
    return "Neutral"


def source_family_rows(rows: list[dict[str, Any]]) -> list[PetFamilySourceRow]:
    return [
        PetFamilySourceRow(id=int(row["id"]), name=str(row["name"]))
        for row in rows
        if "id" in row and "name" in row
    ]


def source_tameable_rows(rows: list[dict[str, Any]]) -> list[TameablePetSourceRow]:
    result = []
    for row in rows:
        if not row.get("id") or not row.get("name") or not row.get("location"):
            continue
        result.append(
            TameablePetSourceRow(
                id=int(row["id"]),
                name=str(row["name"]),
                family=int(row["family"]),
                classification=row.get("classification"),
                location=[int(value) for value in row.get("location", [])],
                react=[int(value) for value in row.get("react", [0, 0])],
                minlevel=row.get("minlevel"),
                maxlevel=row.get("maxlevel"),
            )
        )
    return result


def build_pet_record(
    family: PetFamilySourceRow,
    tameable: TameablePetSourceRow,
    mapper_data: dict[str, Any],
    display_id: int = 0,
) -> PetRecord | None:
    mapper_entry = _first_mapper_entry(tameable.location, mapper_data)
    if mapper_entry is None:
        return None
    coords = _coords(mapper_entry)
    if not coords:
        return None
    return PetRecord(
        zone_name=str(mapper_entry.get("uiMapName") or ""),
        zone_id=int(mapper_entry.get("uiMapId") or tameable.location[0]),
        name=tameable.name,
        maxlevel=int(tameable.maxlevel or 0),
        minlevel=int(tameable.minlevel or 0),
        pet_class=classification_label(tameable.classification),
        family=(family.id, family.name),
        display_id=int(display_id or 0),
        npc_id=tameable.id,
        coords=coords,
    )


def build_stable_master_record(
    row: dict[str, Any],
    mapper_data: dict[str, Any],
) -> StableMasterRecord | None:
    if row.get("tag") and "Stable Master" not in str(row["tag"]):
        return None
    locations = [int(value) for value in row.get("location", [])]
    mapper_entry = _first_mapper_entry(locations, mapper_data)
    if mapper_entry is None:
        return None
    coords = _coords(mapper_entry)
    if not coords:
        return None
    return StableMasterRecord(
        npc_id=int(row["id"]),
        name=str(row["name"]),
        zone_name=str(mapper_entry.get("uiMapName") or ""),
        zone_id=int(mapper_entry.get("uiMapId") or locations[0]),
        coords=coords,
        faction=faction_label(row.get("react")),
    )


def _first_mapper_entry(locations: list[int], mapper_data: dict[str, Any]) -> dict[str, Any] | None:
    for location_id in locations:
        entries = mapper_data.get(str(location_id)) or mapper_data.get(location_id)
        if entries:
            return entries[0]
    return None


def _coords(mapper_entry: dict[str, Any]) -> tuple[tuple[float, float], ...]:
    coords = []
    for value in mapper_entry.get("coords", []):
        if len(value) != 2:
            continue
        x = float(value[0])
        y = float(value[1])
        coords.append((x, y))
    return tuple(coords)
