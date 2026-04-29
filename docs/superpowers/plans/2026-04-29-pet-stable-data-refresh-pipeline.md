# Pet Stable Data Refresh Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reproducible data refresh pipeline that generates validated hunter pet data first, then generates stable master data in a separate file when the source data validates.

**Architecture:** Keep the existing addon runtime untouched except for replacing generated data files after validation. Add a new standard-library Python pipeline beside the old Playwright scraper so source extraction, normalization, Lua export, and validation are independently testable. Use Wowhead embedded listview/global JavaScript as the technical source shape discovered by `agent-browser`, while preserving the current `GHP.pet_by_zones` Lua shape.

**Tech Stack:** Python 3.14 standard library, `unittest`, `urllib.request`, JSON extraction from embedded JavaScript, Lua data files, existing addon `.toc`.

---

## File Structure

- Create: `scrapper/__init__.py`
  - Marks `scrapper` as an importable package for tests and CLI modules.
- Create: `scrapper/wowhead_source.py`
  - Fetches source HTML and extracts Wowhead JavaScript assignments such as `g_listviews.pets.data`, `g_listviews.tameable.data`, `g_mapperData`, and `g_listviews.npcs.data`.
- Create: `scrapper/data_records.py`
  - Defines normalized records and transforms raw Wowhead rows into project pet/stable master records.
- Create: `scrapper/lua_export.py`
  - Exports normalized records to Lua and validates required fields before production replacement.
- Create: `scrapper/refresh_data.py`
  - Command-line entry point for collecting, validating, and writing generated data under `scrapper/generated/`.
- Create: `tests/python/test_wowhead_source.py`
  - Unit tests for JavaScript data extraction from fixture HTML.
- Create: `tests/python/test_data_records.py`
  - Unit tests for pet and stable master normalization.
- Create: `tests/python/test_lua_export.py`
  - Unit tests for Lua string escaping, pet export, stable master export, and validation failures.
- Create: `docs/research/data-refresh-runbook.md`
  - Records the exact commands, source-shape assumptions, validation gates, and manual review checklist.
- Create conditionally after validation: `StableMastersData.lua`
  - Production stable master data table, separate from `GHP.pet_by_zones`.
- Modify only after generated pet output validates: `Data.lua`
  - Replace generated `GHP.pet_by_zones` entries while preserving addon header and family data.
- Modify only after stable master output validates: `GiuiceHunterPets.toc`
  - Load `StableMastersData.lua` after `Data.lua`; no map rendering changes in this phase.

## Success Criteria

- `python3 -m unittest discover -s tests/python -p 'test_*.py'` passes.
- `python3 -m scrapper.refresh_data pets --limit-families 1 --output scrapper/generated/Data.sample.lua` writes a valid sample output with non-empty coordinates.
- `python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua` writes validated pet data without touching checked-in `Data.lua`.
- `python3 -m scrapper.refresh_data stable-masters --output scrapper/generated/StableMastersData.lua` either writes validated stable master data or writes `scrapper/generated/stable-master-blockers.md` with concrete skipped/blocked reasons.
- Production `Data.lua` is replaced only after generated Lua validates and the diff is reviewed.
- `StableMastersData.lua` and `.toc` are changed only after stable master validation passes.

---

### Task 1: Add Wowhead Source Extraction Tests

**Files:**
- Create: `scrapper/__init__.py`
- Create: `tests/python/test_wowhead_source.py`
- Create later: `scrapper/wowhead_source.py`

- [ ] **Step 1: Create the package marker**

Create `scrapper/__init__.py` as an empty file.

- [ ] **Step 2: Write the failing extraction tests**

Create `tests/python/test_wowhead_source.py`:

```python
import unittest

from scrapper.wowhead_source import (
    extract_js_assignment,
    extract_mapper_data,
    extract_listview_data,
)


class WowheadSourceTest(unittest.TestCase):
    def test_extracts_listview_data_assignment(self):
        html = """
        <script>
        new Listview({
            template: 'pet',
            id: 'pets',
            data: [{"id":1,"name":"Wolf"},{"id":2,"name":"Cat"}]
        });
        </script>
        """

        rows = extract_listview_data(html, "pets")

        self.assertEqual(rows, [{"id": 1, "name": "Wolf"}, {"id": 2, "name": "Cat"}])

    def test_extracts_named_assignment(self):
        html = """
        <script>
        var g_mapperData = {"12":[{"uiMapId":37,"uiMapName":"Elwynn Forest","coords":[[72.4,65.0]]}]};
        </script>
        """

        data = extract_js_assignment(html, "g_mapperData")

        self.assertEqual(data["12"][0]["uiMapId"], 37)
        self.assertEqual(data["12"][0]["coords"], [[72.4, 65.0]])

    def test_extracts_mapper_data(self):
        html = """
        <script>
        g_mapperData={"13644":[{"uiMapId":2022,"uiMapName":"The Waking Shores","coords":[[48.2,83.4],[48.4,83.6]]}]};
        </script>
        """

        data = extract_mapper_data(html)

        self.assertEqual(data["13644"][0]["uiMapId"], 2022)
        self.assertEqual(len(data["13644"][0]["coords"]), 2)

    def test_missing_assignment_returns_none(self):
        self.assertIsNone(extract_js_assignment("<html></html>", "g_mapperData"))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
rtk python3 -m unittest tests.python.test_wowhead_source -v
```

Expected: FAIL with `ModuleNotFoundError: No module named 'scrapper.wowhead_source'`.

- [ ] **Step 4: Commit the failing tests**

```bash
git add scrapper/__init__.py tests/python/test_wowhead_source.py
git commit -m "test: cover wowhead source extraction"
```

---

### Task 2: Implement Wowhead Source Extraction

**Files:**
- Create: `scrapper/wowhead_source.py`
- Test: `tests/python/test_wowhead_source.py`

- [ ] **Step 1: Add minimal extraction implementation**

Create `scrapper/wowhead_source.py`:

```python
from __future__ import annotations

import json
import re
from typing import Any
from urllib.request import Request, urlopen


USER_AGENT = "GiuiceHunterPets data refresh research"


def fetch_text(url: str, timeout: int = 60) -> str:
    request = Request(url, headers={"User-Agent": USER_AGENT})
    with urlopen(request, timeout=timeout) as response:
        return response.read().decode("utf-8", errors="replace")


def extract_js_assignment(html: str, variable_name: str) -> Any | None:
    pattern = re.compile(r"(?:var\s+)?%s\s*=\s*" % re.escape(variable_name))
    match = pattern.search(html)
    if not match:
        return None
    return _parse_jsonish_value(html, match.end())


def extract_mapper_data(html: str) -> dict[str, Any]:
    return extract_js_assignment(html, "g_mapperData") or {}


def extract_listview_data(html: str, listview_id: str) -> list[dict[str, Any]]:
    for object_text in _iter_listview_objects(html):
        if _extract_string_property(object_text, "id") != listview_id:
            continue
        data_index = _find_property_value_start(object_text, "data")
        if data_index is None:
            return []
        return _parse_jsonish_value(object_text, data_index)
    return []


def _iter_listview_objects(html: str):
    marker = "new Listview("
    start = 0
    while True:
        index = html.find(marker, start)
        if index == -1:
            return
        object_start = html.find("{", index)
        if object_start == -1:
            return
        object_end = _find_matching_bracket(html, object_start, "{", "}")
        if object_end == -1:
            return
        yield html[object_start : object_end + 1]
        start = object_end + 1


def _extract_string_property(object_text: str, property_name: str) -> str | None:
    match = re.search(
        r"%s\s*:\s*(['\"])(.*?)\1" % re.escape(property_name),
        object_text,
        re.DOTALL,
    )
    if not match:
        return None
    return match.group(2)


def _find_property_value_start(object_text: str, property_name: str) -> int | None:
    match = re.search(r"%s\s*:" % re.escape(property_name), object_text)
    if not match:
        return None
    return match.end()


def _parse_jsonish_value(text: str, value_start: int):
    while value_start < len(text) and text[value_start].isspace():
        value_start += 1
    if value_start >= len(text):
        raise ValueError("missing JSON value")

    opener = text[value_start]
    if opener == "{":
        end = _find_matching_bracket(text, value_start, "{", "}")
    elif opener == "[":
        end = _find_matching_bracket(text, value_start, "[", "]")
    else:
        raise ValueError(f"unsupported JSON value opener: {opener}")

    if end == -1:
        raise ValueError("unterminated JSON value")

    return json.loads(text[value_start : end + 1])


def _find_matching_bracket(text: str, start: int, opener: str, closer: str) -> int:
    depth = 0
    in_string = False
    quote = ""
    escaped = False

    for index in range(start, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                in_string = False
            continue

        if char in ("'", '"'):
            in_string = True
            quote = char
            continue
        if char == opener:
            depth += 1
        elif char == closer:
            depth -= 1
            if depth == 0:
                return index

    return -1
```

- [ ] **Step 2: Run extraction tests**

Run:

```bash
rtk python3 -m unittest tests.python.test_wowhead_source -v
```

Expected: PASS all 4 tests.

- [ ] **Step 3: Commit extraction implementation**

```bash
git add scrapper/wowhead_source.py tests/python/test_wowhead_source.py
git commit -m "feat: extract wowhead embedded source data"
```

---

### Task 3: Add Normalization Tests

**Files:**
- Create: `tests/python/test_data_records.py`
- Create later: `scrapper/data_records.py`

- [ ] **Step 1: Write failing normalization tests**

Create `tests/python/test_data_records.py`:

```python
import unittest

from scrapper.data_records import (
    PetFamilySourceRow,
    TameablePetSourceRow,
    build_pet_record,
    build_stable_master_record,
    classification_label,
    faction_label,
)


class DataRecordsTest(unittest.TestCase):
    def test_classification_label(self):
        self.assertEqual(classification_label(0), "Normal")
        self.assertEqual(classification_label(1), "Elite")
        self.assertEqual(classification_label(4), "Rare")
        self.assertEqual(classification_label(2), "Rare Elite")
        self.assertEqual(classification_label(None), "Normal")

    def test_faction_label(self):
        self.assertEqual(faction_label([1, -1]), "Alliance")
        self.assertEqual(faction_label([-1, 1]), "Horde")
        self.assertEqual(faction_label([1, 1]), "Neutral")
        self.assertEqual(faction_label([0, 0]), "Neutral")

    def test_build_pet_record_uses_mapper_ui_map_id_and_coords(self):
        family = PetFamilySourceRow(id=1, name="Wolf")
        tameable = TameablePetSourceRow(
            id=226296,
            name="Adolescent Darkwolf",
            family=1,
            classification=0,
            location=[2248],
            react=[-1, -1],
            minlevel=70,
            maxlevel=80,
        )
        mapper_data = {
            "2248": [
                {
                    "uiMapId": 2248,
                    "uiMapName": "Isle of Dorn",
                    "coords": [[59.4, 34.6], [59.6, 34.4]],
                }
            ]
        }

        record = build_pet_record(family, tameable, mapper_data)

        self.assertEqual(record.zone_name, "Isle of Dorn")
        self.assertEqual(record.zone_id, 2248)
        self.assertEqual(record.name, "Adolescent Darkwolf")
        self.assertEqual(record.npc_id, 226296)
        self.assertEqual(record.family, (1, "Wolf"))
        self.assertEqual(record.pet_class, "Normal")
        self.assertEqual(record.coords, ((59.4, 34.6), (59.6, 34.4)))

    def test_build_stable_master_record(self):
        row = {
            "id": 185561,
            "name": "Kaestrasz",
            "tag": "Stable Master",
            "react": [1, 1],
            "location": [13862],
        }
        mapper_data = {
            "13862": [
                {
                    "uiMapId": 2112,
                    "uiMapName": "Valdrakken",
                    "coords": [[62.0, 13.2]],
                }
            ]
        }

        record = build_stable_master_record(row, mapper_data)

        self.assertEqual(record.npc_id, 185561)
        self.assertEqual(record.name, "Kaestrasz")
        self.assertEqual(record.zone_id, 2112)
        self.assertEqual(record.zone_name, "Valdrakken")
        self.assertEqual(record.coords, ((62.0, 13.2),))
        self.assertEqual(record.faction, "Neutral")


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
rtk python3 -m unittest tests.python.test_data_records -v
```

Expected: FAIL with `ModuleNotFoundError: No module named 'scrapper.data_records'`.

- [ ] **Step 3: Commit failing tests**

```bash
git add tests/python/test_data_records.py
git commit -m "test: cover data normalization"
```

---

### Task 4: Implement Normalized Data Records

**Files:**
- Create: `scrapper/data_records.py`
- Test: `tests/python/test_data_records.py`

- [ ] **Step 1: Add normalized record implementation**

Create `scrapper/data_records.py`:

```python
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
```

- [ ] **Step 2: Run normalization tests**

Run:

```bash
rtk python3 -m unittest tests.python.test_data_records -v
```

Expected: PASS all 4 tests.

- [ ] **Step 3: Commit normalization implementation**

```bash
git add scrapper/data_records.py tests/python/test_data_records.py
git commit -m "feat: normalize pet and stable master records"
```

---

### Task 5: Add Lua Export And Validation Tests

**Files:**
- Create: `tests/python/test_lua_export.py`
- Create later: `scrapper/lua_export.py`

- [ ] **Step 1: Write failing Lua export tests**

Create `tests/python/test_lua_export.py`:

```python
import unittest

from scrapper.data_records import PetRecord, StableMasterRecord
from scrapper.lua_export import (
    export_pet_data,
    export_stable_master_data,
    lua_quote,
    validate_pet_records,
    validate_stable_master_records,
)


class LuaExportTest(unittest.TestCase):
    def test_lua_quote_escapes_strings(self):
        self.assertEqual(lua_quote('A "Wolf"'), '"A \\"Wolf\\""')

    def test_export_pet_data_preserves_pet_by_zones_shape(self):
        records = [
            PetRecord(
                zone_name="Isle of Dorn",
                zone_id=2248,
                name="Adolescent Darkwolf",
                maxlevel=80,
                minlevel=70,
                pet_class="Normal",
                family=(1, "Wolf"),
                display_id=70178,
                npc_id=226296,
                coords=((59.4, 34.6),),
            )
        ]

        lua = export_pet_data(records)

        self.assertIn("GHP.pet_by_zones = {", lua)
        self.assertIn('["zone_name"] = "Isle of Dorn"', lua)
        self.assertIn('["NpcId"] = 226296', lua)
        self.assertIn('["coords"] = { { 59.4, 34.6 } }', lua)

    def test_validate_pet_records_rejects_missing_coords(self):
        records = [
            PetRecord(
                zone_name="Bad Zone",
                zone_id=1,
                name="Bad Pet",
                maxlevel=1,
                minlevel=1,
                pet_class="Normal",
                family=(1, "Wolf"),
                display_id=0,
                npc_id=1,
                coords=(),
            )
        ]

        errors = validate_pet_records(records)

        self.assertEqual(errors, ["pet 1 Bad Pet has no coords"])

    def test_export_stable_master_data(self):
        records = [
            StableMasterRecord(
                npc_id=185561,
                name="Kaestrasz",
                zone_name="Valdrakken",
                zone_id=2112,
                coords=((62.0, 13.2),),
                faction="Neutral",
            )
        ]

        lua = export_stable_master_data(records)

        self.assertIn("GHP.stable_masters = {", lua)
        self.assertIn('["npcID"] = 185561', lua)
        self.assertIn('["faction"] = "Neutral"', lua)

    def test_validate_stable_master_records_rejects_bad_faction(self):
        records = [
            StableMasterRecord(
                npc_id=1,
                name="Bad Stable",
                zone_name="Bad Zone",
                zone_id=1,
                coords=((1.0, 2.0),),
                faction="Unknown",
            )
        ]

        errors = validate_stable_master_records(records)

        self.assertEqual(errors, ["stable master 1 Bad Stable has invalid faction Unknown"])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
rtk python3 -m unittest tests.python.test_lua_export -v
```

Expected: FAIL with `ModuleNotFoundError: No module named 'scrapper.lua_export'`.

- [ ] **Step 3: Commit failing Lua export tests**

```bash
git add tests/python/test_lua_export.py
git commit -m "test: cover lua data export"
```

---

### Task 6: Implement Lua Export And Validation

**Files:**
- Create: `scrapper/lua_export.py`
- Test: `tests/python/test_lua_export.py`

- [ ] **Step 1: Add Lua export implementation**

Create `scrapper/lua_export.py`:

```python
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
```

- [ ] **Step 2: Run Lua export tests**

Run:

```bash
rtk python3 -m unittest tests.python.test_lua_export -v
```

Expected: PASS all 5 tests.

- [ ] **Step 3: Run all Python tests**

Run:

```bash
rtk python3 -m unittest discover -s tests/python -p 'test_*.py' -v
```

Expected: PASS all Python tests.

- [ ] **Step 4: Commit Lua export implementation**

```bash
git add scrapper/lua_export.py tests/python/test_lua_export.py
git commit -m "feat: export validated lua data"
```

---

### Task 7: Add Data Refresh CLI

**Files:**
- Create: `scrapper/refresh_data.py`
- Modify: `scrapper/wowhead_source.py`
- Test: all Python tests

- [ ] **Step 1: Extend source helpers with page URL constants**

Add these constants near the top of `scrapper/wowhead_source.py`:

```python
WOWHEAD_BASE = "https://www.wowhead.com"
HUNTER_PETS_URL = f"{WOWHEAD_BASE}/hunter-pets"
STABLE_MASTER_SEARCH_URL = f"{WOWHEAD_BASE}/search?q=stable%20master"


def pet_family_url(family_id: int, slug: str | None = None) -> str:
    suffix = f"/{slug}" if slug else ""
    return f"{WOWHEAD_BASE}/pet={family_id}{suffix}"


def npc_url(npc_id: int, slug: str | None = None) -> str:
    suffix = f"/{slug}" if slug else ""
    return f"{WOWHEAD_BASE}/npc={npc_id}{suffix}"
```

- [ ] **Step 2: Add the CLI implementation**

Create `scrapper/refresh_data.py`:

```python
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
    for family in families:
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
```

- [ ] **Step 3: Run all Python tests**

Run:

```bash
rtk python3 -m unittest discover -s tests/python -p 'test_*.py' -v
```

Expected: PASS all Python tests.

- [ ] **Step 4: Run a one-family pet sample**

Run:

```bash
rtk python3 -m scrapper.refresh_data pets --limit-families 1 --output scrapper/generated/Data.sample.lua
```

Expected: command exits `0` and prints `Wrote <N> pet records to scrapper/generated/Data.sample.lua`, where `<N>` is greater than `0`.

- [ ] **Step 5: Commit CLI implementation**

```bash
git add scrapper/wowhead_source.py scrapper/refresh_data.py scrapper/generated/Data.sample.lua scrapper/generated/pet-skipped.md
git commit -m "feat: add data refresh cli"
```

---

### Task 8: Add Full Pet Generation Runbook

**Files:**
- Create: `docs/research/data-refresh-runbook.md`
- Test: documentation command checks

- [ ] **Step 1: Write the runbook**

Create `docs/research/data-refresh-runbook.md`:

```markdown
# Data Refresh Runbook

## Source Shape

Validated with `agent-browser 0.26.0` on 2026-04-28/2026-04-29:

- `https://www.wowhead.com/hunter-pets` exposes pet families through `g_listviews.pets.data`.
- `https://www.wowhead.com/pet=<family-id>` exposes tameable NPC rows through `g_listviews.tameable.data`.
- `https://www.wowhead.com/npc=<npc-id>` exposes coordinates through `g_mapperData` when Wowhead has mapped locations.
- `https://www.wowhead.com/search?q=stable%20master` exposes stable master candidates through `g_listviews.npcs.data`.

## Pet Sample

```bash
rtk python3 -m scrapper.refresh_data pets --limit-families 1 --output scrapper/generated/Data.sample.lua
```

Expected:

- Exit code `0`.
- `scrapper/generated/Data.sample.lua` exists.
- `scrapper/generated/Data.sample.lua` contains `GHP.pet_by_zones = {`.
- `scrapper/generated/Data.sample.lua` contains at least one `["coords"] = { {`.

## Full Pet Refresh

```bash
rtk python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua
```

Before replacing production `Data.lua`:

```bash
rtk rg -n 'GHP.pet_by_zones = \\{|\\["NpcId"\\]|\\["coords"\\]' scrapper/generated/Data.lua
rtk git diff --no-index Data.lua scrapper/generated/Data.lua
```

Review requirements:

- Generated pet count is plausible compared with checked-in `Data.lua`.
- Sample current expansion pets appear in the generated output.
- `scrapper/generated/pet-validation-errors.md` is empty or absent.
- Coordinate-heavy diffs are expected; missing-coordinate records are not accepted into generated output.

## Stable Master Feasibility

```bash
rtk python3 -m scrapper.refresh_data stable-masters --output scrapper/generated/StableMastersData.lua
```

If the command exits `0`, review:

```bash
rtk rg -n 'GHP.stable_masters = \\{|\\["npcID"\\]|\\["faction"\\]' scrapper/generated/StableMastersData.lua
rtk sed -n '1,80p' scrapper/generated/stable-master-skipped.md
```

If the command exits non-zero, review:

```bash
rtk sed -n '1,120p' scrapper/generated/stable-master-blockers.md
rtk sed -n '1,120p' scrapper/generated/stable-master-validation-errors.md
```

## Production Replacement

Only replace `Data.lua` after the generated pet file validates and the diff is reviewed.

Only add `StableMastersData.lua` and `GiuiceHunterPets.toc` after stable master validation passes. This phase loads data only; it does not render stable master pins.
```

- [ ] **Step 2: Verify runbook commands are discoverable**

Run:

```bash
rtk rg -n "refresh_data pets|refresh_data stable-masters|Production Replacement" docs/research/data-refresh-runbook.md
```

Expected: three or more matches.

- [ ] **Step 3: Commit runbook**

```bash
git add docs/research/data-refresh-runbook.md
git commit -m "docs: add data refresh runbook"
```

---

### Task 9: Generate And Review Full Pet Data

**Files:**
- Create: `scrapper/generated/Data.lua`
- Create/update: `scrapper/generated/pet-skipped.md`
- Modify after review: `Data.lua`
- Test: Python tests and generated data checks

- [ ] **Step 1: Run all Python tests before full generation**

Run:

```bash
rtk python3 -m unittest discover -s tests/python -p 'test_*.py' -v
```

Expected: PASS all Python tests.

- [ ] **Step 2: Generate full pet data**

Run:

```bash
rtk python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua
```

Expected: exit code `0` and output like `Wrote <N> pet records to scrapper/generated/Data.lua`.

- [ ] **Step 3: Inspect generated output markers**

Run:

```bash
rtk rg -n 'GHP.pet_by_zones = \{|\\["NpcId"\\]|\\["coords"\\]' scrapper/generated/Data.lua
```

Expected: matches for table start, NPC IDs, and coordinates.

- [ ] **Step 4: Inspect skipped pet records**

Run:

```bash
rtk sed -n '1,120p' scrapper/generated/pet-skipped.md
```

Expected: skipped rows, if any, all explain `no mapper coordinates`.

- [ ] **Step 5: Review generated diff without replacing production**

Run:

```bash
rtk git diff --no-index Data.lua scrapper/generated/Data.lua
```

Expected: command exits `1` when files differ. Review the diff manually; do not treat exit code `1` as failure.

- [ ] **Step 6: Replace production pet data after review**

Run:

```bash
rtk cp scrapper/generated/Data.lua Data.lua
```

Expected: `Data.lua` is replaced with the validated generated pet data.

- [ ] **Step 7: Commit generated pet data**

```bash
git add Data.lua scrapper/generated/Data.lua scrapper/generated/pet-skipped.md
git commit -m "data: refresh hunter pet records"
```

---

### Task 10: Generate Stable Master Data Or Record Blocker

**Files:**
- Create: `scrapper/generated/StableMastersData.lua`
- Create/update: `scrapper/generated/stable-master-skipped.md`
- Create if blocked: `scrapper/generated/stable-master-blockers.md`
- Create after validation: `StableMastersData.lua`
- Modify after validation: `GiuiceHunterPets.toc`

- [ ] **Step 1: Run stable master generation**

Run:

```bash
rtk python3 -m scrapper.refresh_data stable-masters --output scrapper/generated/StableMastersData.lua
```

Expected if viable: exit code `0` and output like `Wrote <N> stable master records to scrapper/generated/StableMastersData.lua`.

Expected if blocked: non-zero exit and `scrapper/generated/stable-master-blockers.md` or `scrapper/generated/stable-master-validation-errors.md` contains concrete reasons.

- [ ] **Step 2: If blocked, commit blocker note and stop this task**

Run:

```bash
rtk sed -n '1,160p' scrapper/generated/stable-master-blockers.md
rtk sed -n '1,160p' scrapper/generated/stable-master-validation-errors.md
```

Expected: one of the files explains why stable master extraction is not production-ready.

Commit:

```bash
git add scrapper/generated/stable-master-blockers.md scrapper/generated/stable-master-validation-errors.md
git commit -m "docs: record stable master data blocker"
```

- [ ] **Step 3: If viable, inspect generated stable master data**

Run:

```bash
rtk rg -n 'GHP.stable_masters = \{|\\["npcID"\\]|\\["coords"\\]|\\["faction"\\]' scrapper/generated/StableMastersData.lua
```

Expected: matches for table start, NPC IDs, coordinates, and faction fields.

- [ ] **Step 4: If viable, copy production stable master data**

Run:

```bash
rtk cp scrapper/generated/StableMastersData.lua StableMastersData.lua
```

Expected: `StableMastersData.lua` exists at repo root.

- [ ] **Step 5: If viable, add stable data to the TOC**

Modify `GiuiceHunterPets.toc` so the core files section becomes:

```toc
# Core files
Localization.lua
Data.lua
StableMastersData.lua
GiuiceHunterPets.lua
GiuiceBattlePets.lua
GiuiceTooltipEnhancement.lua
```

- [ ] **Step 6: If viable, commit stable master data**

```bash
git add StableMastersData.lua GiuiceHunterPets.toc scrapper/generated/StableMastersData.lua scrapper/generated/stable-master-skipped.md
git commit -m "data: add stable master records"
```

---

### Task 11: Final Verification

**Files:**
- Verify: `Data.lua`
- Verify conditionally: `StableMastersData.lua`
- Verify: `GiuiceHunterPets.toc`
- Verify: `docs/research/data-refresh-runbook.md`

- [ ] **Step 1: Run all Python tests**

Run:

```bash
rtk python3 -m unittest discover -s tests/python -p 'test_*.py' -v
```

Expected: PASS all Python tests.

- [ ] **Step 2: Run existing Lua helper tests**

Run:

```bash
rtk lua tests/stable_list_state_test.lua
rtk lua tests/map_pet_index_test.lua
```

Expected: both commands print `PASS`.

- [ ] **Step 3: Verify production pet data markers**

Run:

```bash
rtk rg -n 'GHP.pet_by_zones = \{|\\["NpcId"\\]|\\["coords"\\]' Data.lua
```

Expected: matches for table start, NPC IDs, and coordinates.

- [ ] **Step 4: Verify stable master outcome**

If `StableMastersData.lua` exists, run:

```bash
rtk rg -n 'GHP.stable_masters = \{|\\["npcID"\\]|\\["faction"\\]' StableMastersData.lua
rtk rg -n 'StableMastersData.lua' GiuiceHunterPets.toc
```

Expected: stable master table markers exist and `.toc` loads the file.

If `StableMastersData.lua` does not exist, run:

```bash
rtk sed -n '1,160p' scrapper/generated/stable-master-blockers.md
```

Expected: blocker note explains why stable master data needs follow-up.

- [ ] **Step 5: Review final git diff**

Run:

```bash
rtk git status --short
rtk git diff --stat
```

Expected: only data pipeline, generated data, runbook, and optional stable master production files changed.

- [ ] **Step 6: Commit final verification note if needed**

If verification requires a small docs update, edit `docs/research/data-refresh-runbook.md` with the observed command results and commit:

```bash
git add docs/research/data-refresh-runbook.md
git commit -m "docs: record data refresh verification"
```

## Self-Review

- Spec coverage:
  - Diagnose/repair pipeline: Tasks 1-7 replace the broken Playwright collection layer with a standard-library source extractor and CLI.
  - Validate local/source state: prior research is consumed, and Task 8 records the runbook.
  - Browser/source discovery: recorded in `docs/research/hunter-pet-and-stable-master-data-sources.md`; the plan implements the discovered HTTP/listview path.
  - Generate updated `Data.lua`: Task 9.
  - Validate generated pet data before replacement: Tasks 5, 6, 9, 11.
  - Stable master feasibility/data file: Task 10.
  - Out-of-scope UI/map rendering/defaults: no task changes rendering, settings UI, or map pin defaults.
- Placeholder scan:
  - No placeholder markers or open-ended validation steps remain.
- Type consistency:
  - `PetFamilySourceRow`, `TameablePetSourceRow`, `PetRecord`, `StableMasterRecord`, `build_pet_record`, `build_stable_master_record`, `export_pet_data`, and `export_stable_master_data` are defined before use in later tasks.
