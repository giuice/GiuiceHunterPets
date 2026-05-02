from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from scrapper.data_records import PetRecord


_TABLE_START = re.compile(r"GHP\.pet_by_zones\s*=\s*\{")
_FAMILY = re.compile(r'\{\s*(?P<id>\d+)\s*,\s*"(?P<name>[^"]*)"\s*\}')
_COORD = re.compile(r"\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}")


@dataclass
class LoadSummary:
    loaded: int = 0
    dropped_no_zone: int = 0
    dropped_no_coords: int = 0
    salvaged_partial_coords: int = 0
    missing_file: bool = False


def load_existing_pet_records(
    data_lua_path: Path,
) -> tuple[dict[int, PetRecord], LoadSummary]:
    summary = LoadSummary()
    if not data_lua_path.exists():
        summary.missing_file = True
        return {}, summary

    text = data_lua_path.read_text(encoding="utf-8")
    match = _TABLE_START.search(text)
    if not match:
        return {}, summary

    body = _table_body(text, match.end() - 1)
    if body is None:
        return {}, summary

    records: dict[int, PetRecord] = {}
    for entry_text in _split_entries(body):
        record = _parse_entry(entry_text, summary)
        if record is None:
            continue
        records[record.npc_id] = record
        summary.loaded += 1
    return records, summary


def _table_body(text: str, open_brace: int) -> str | None:
    depth = 0
    for i in range(open_brace, len(text)):
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[open_brace + 1 : i]
    return None


def _split_entries(body: str) -> list[str]:
    entries: list[str] = []
    depth = 0
    start: int | None = None
    for i, ch in enumerate(body):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start is not None:
                entries.append(body[start + 1 : i])
                start = None
    return entries


def _parse_entry(entry_text: str, summary: LoadSummary) -> PetRecord | None:
    fields = _parse_fields(entry_text)
    if not fields:
        return None

    npc_id = _to_int(fields.get("NpcId"))
    if not npc_id:
        return None

    zone_id = _to_int(fields.get("zoneID"))
    if not zone_id:
        summary.dropped_no_zone += 1
        return None

    coords_raw = fields.get("coords", "")
    raw_pairs = _COORD.findall(coords_raw)
    raw_count = _count_coord_groups(coords_raw)
    coords = tuple((float(x), float(y)) for x, y in raw_pairs)
    if not coords:
        summary.dropped_no_coords += 1
        return None
    if raw_count > len(coords):
        summary.salvaged_partial_coords += 1

    family_match = _FAMILY.search(fields.get("family", ""))
    if family_match:
        family = (int(family_match.group("id")), family_match.group("name"))
    else:
        family = (0, "")

    return PetRecord(
        zone_name=_unquote(fields.get("zone_name", "")),
        zone_id=zone_id,
        name=_unquote(fields.get("name", "")),
        maxlevel=_to_int(fields.get("maxlevel")) or 0,
        minlevel=_to_int(fields.get("minlevel")) or 0,
        pet_class=_unquote(fields.get("class", "")) or "Normal",
        family=family,
        display_id=_to_int(fields.get("displayId")) or 0,
        npc_id=npc_id,
        coords=coords,
    )


def _parse_fields(entry_text: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    pattern = re.compile(
        r'\["(?P<key>[A-Za-z_]+)"\]\s*=\s*',
    )
    pos = 0
    while True:
        m = pattern.search(entry_text, pos)
        if not m:
            break
        key = m.group("key")
        value_start = m.end()
        value_end, value = _consume_value(entry_text, value_start)
        fields[key] = value.strip()
        pos = value_end
    return fields


def _consume_value(text: str, start: int) -> tuple[int, str]:
    i = start
    n = len(text)
    while i < n and text[i].isspace():
        i += 1
    if i >= n:
        return n, ""
    ch = text[i]
    if ch == '"':
        j = i + 1
        while j < n:
            if text[j] == "\\" and j + 1 < n:
                j += 2
                continue
            if text[j] == '"':
                value = text[i : j + 1]
                end = _skip_to_field_end(text, j + 1)
                return end, value
            j += 1
        return n, text[i:]
    if ch == "{":
        depth = 0
        j = i
        while j < n:
            if text[j] == "{":
                depth += 1
            elif text[j] == "}":
                depth -= 1
                if depth == 0:
                    value = text[i : j + 1]
                    end = _skip_to_field_end(text, j + 1)
                    return end, value
            j += 1
        return n, text[i:]
    j = i
    while j < n and text[j] != ",":
        j += 1
    value = text[i:j]
    end = _skip_to_field_end(text, j)
    return end, value


def _skip_to_field_end(text: str, pos: int) -> int:
    n = len(text)
    while pos < n and text[pos] in " \t\r\n":
        pos += 1
    if pos < n and text[pos] == ",":
        pos += 1
    return pos


def _count_coord_groups(coords_raw: str) -> int:
    depth = 0
    count = 0
    for ch in coords_raw:
        if ch == "{":
            if depth == 0:
                count += 1
            depth += 1
        elif ch == "}":
            depth -= 1
    return count


def _unquote(value: str) -> str:
    s = value.strip()
    if s.startswith('"') and s.endswith('"'):
        s = s[1:-1]
    return s.replace('\\"', '"').replace("\\\\", "\\")


def _to_int(value) -> int:
    if value is None:
        return 0
    s = str(value).strip()
    if not s:
        return 0
    try:
        return int(s)
    except ValueError:
        try:
            return int(float(s))
        except ValueError:
            return 0
