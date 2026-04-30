# Testing Patterns

**Analysis Date:** 2026-04-29

## Test Framework

**Runner:**
- Python: standard-library `unittest`; no pytest configuration is detected. Tests live in `tests/python/`.
- Lua: standalone Lua scripts run directly with the Lua interpreter; no Busted, LuaUnit, or WoW test framework is detected. Tests live in `tests/`.
- Config: Not detected. No `pytest.ini`, `pyproject.toml`, `tox.ini`, `setup.cfg`, or Lua test config is present.

**Assertion Library:**
- Python: `unittest.TestCase` assertions such as `self.assertEqual`, `self.assertIn`, `self.assertFalse`, `self.assertTrue`, `self.assertIsNone`, and `self.assertRaises` in `tests/python/test_source_cache.py`, `tests/python/test_data_records.py`, and `tests/python/test_refresh_data_cache.py`.
- Lua: local assertion helpers call `error(..., 2)` with contextual labels in `tests/stable_list_state_test.lua` and `tests/map_pet_index_test.lua`.

**Run Commands:**
```bash
rtk python3 -m unittest discover -s tests/python -p 'test_*.py' -v    # Run all Python tests
rtk python3 -m unittest tests.python.test_source_cache -v             # Run one Python test module
rtk lua tests/stable_list_state_test.lua                              # Run stable-list Lua script test
rtk lua tests/map_pet_index_test.lua                                  # Run map pet index Lua script test
```

## Test File Organization

**Location:**
- Python tests are separated under `tests/python/` and import code from `scrapper/`.
- Lua tests are separated under `tests/` and load root-level addon utility files with `dofile`.
- Vendored library tests exist under `Libs/LibStub/tests/`; treat those as vendor-owned tests, not project test patterns.

**Naming:**
- Python files use `test_*.py`: `tests/python/test_wowhead_source.py`, `tests/python/test_data_records.py`, `tests/python/test_lua_export.py`, `tests/python/test_source_cache.py`, and `tests/python/test_refresh_data_cache.py`.
- Python classes end with `Test`: `WowheadSourceTest`, `DataRecordsTest`, `LuaExportTest`, `SourceCacheTest`, and `RefreshDataCacheTest`.
- Python methods start with `test_` and describe behavior: `test_cache_hit_reuses_file_without_fetching`, `test_failed_fetch_records_error_and_raises_source_fetch_error`, and `test_generate_pets_records_source_failure_and_does_not_write_lua`.
- Lua files use `*_test.lua`: `tests/stable_list_state_test.lua` and `tests/map_pet_index_test.lua`.
- Lua table-driven test names use descriptive snake_case keys in `tests/stable_list_state_test.lua`, such as `tests.nil_stabled_list_is_unloaded` and `tests.filters_by_name_family_and_level_safely`.

**Structure:**
```text
tests/
├── map_pet_index_test.lua          # Direct Lua script test for `MapPetIndex.lua`
├── stable_list_state_test.lua      # Direct Lua script test for `StablePetList.lua`
└── python/
    ├── test_data_records.py        # Dataclass normalization and record builders
    ├── test_lua_export.py          # Lua export formatting and validation
    ├── test_refresh_data_cache.py  # Refresh pipeline cache, retry, blocker behavior
    ├── test_source_cache.py        # Source cache storage, manifest, invalidation
    └── test_wowhead_source.py      # Wowhead HTML/JS extraction helpers
```

## Test Structure

**Suite Organization:**
```python
import unittest

from scrapper.source_cache import SourceCache, SourceFetchError


class SourceCacheTest(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def test_failed_fetch_records_error_and_raises_source_fetch_error(self):
        with self.assertRaises(SourceFetchError) as context:
            cache.get_text("https://www.wowhead.com/npc=3", "pet-npc")
        self.assertIn("HTTP Error 403: Forbidden", str(context.exception))
```

**Patterns:**
- Keep Python unit tests inside `unittest.TestCase` classes and end each file with `if __name__ == "__main__": unittest.main()`.
- Use `setUp` / `tearDown` with `tempfile.TemporaryDirectory()` for tests that write cache, manifest, generated Lua, or blocker files, as in `tests/python/test_source_cache.py` and `tests/python/test_refresh_data_cache.py`.
- Use inline HTML fixture functions for Wowhead and mapper source shapes in `tests/python/test_refresh_data_cache.py`, such as `pets_index_html`, `pet_family_html`, `npc_mapper_html`, `stable_search_html`, and `stable_mapper_html`.
- Assert both return codes and file effects for pipeline behavior. `tests/python/test_refresh_data_cache.py` checks `exit_code`, missing output files, blocker text, manifest invalidation, rerun calls, and generated Lua contents.
- Lua tests initialize a minimal global addon table before loading the module under test:
```lua
package.path = "./?.lua;" .. package.path

local GHP = { utils = {} }
_G.GHP = GHP

dofile("StablePetList.lua")
```
- Lua test scripts should fail with `error(..., 2)` and print PASS lines only after assertions pass.

## Mocking

**Framework:** Python uses manual dependency injection and limited `unittest.mock.patch`; Lua uses hand-built globals and fixtures.

**Patterns:**
```python
calls = []

def fetcher(url):
    calls.append(url)
    return pages[url]

cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)
exit_code = generate_pets(output, limit_families=0, source_cache=cache, generated_dir=self.root)
```

```python
def blocked_fetcher(url):
    raise AssertionError("cached pet refresh should not fetch live source")

resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=blocked_fetcher)
```

**What to Mock:**
- Mock network/source access through `SourceCache(..., fetcher=...)` instead of patching `urllib.request.urlopen` directly. This pattern is used throughout `tests/python/test_source_cache.py` and `tests/python/test_refresh_data_cache.py`.
- Mock external fetch failures by raising `HTTPError` from injected fetchers, as in `tests/python/test_source_cache.py` and `tests/python/test_refresh_data_cache.py`.
- Patch command-line arguments, stdout, or stderr only for CLI-surface tests. `tests/python/test_refresh_data_cache.py` imports `StringIO` and `patch` for this purpose.
- For Lua modules, provide only the minimal `_G.GHP` table needed by the file under test, then call pure helper functions from `GHP` or `GHP.utils`.

**What NOT to Mock:**
- Do not perform live Wowhead requests in tests. Current tests use static HTML snippets in `tests/python/test_wowhead_source.py` and `tests/python/test_refresh_data_cache.py`.
- Do not mock pure transformation functions such as `classification_label`, `faction_label`, `export_pet_data`, `validate_pet_records`, `GHP.GetPetsForMap`, or `GHP.utils.FilterStablePets`; call them directly.
- Do not load full WoW UI runtime for Lua tests. Keep utility code testable by isolating pure logic in files like `StablePetList.lua` and `MapPetIndex.lua`.

## Fixtures and Factories

**Test Data:**
```python
def pet_family_html():
    return """
    <script>
    new Listview({
        id: 'tameable',
        data: [{
            "id":32517,
            "name":"Loque'nahak",
            "family":46,
            "classification":4,
            "location":[3711],
            "react":[-1,-1],
            "minlevel":30,
            "maxlevel":30
        }]
    });
    </script>
    """
```

```lua
local pets = {
    { zoneID = 1, name = "Common Cat", class = "Normal", family = { 1, "Cat" }, coords = { { 10, 20 } } },
    { zoneID = 1, name = "Rare Wolf", class = "Rare", family = { 2, "Wolf" }, coords = { { 30, 40 } } },
}
```

**Location:**
- Inline Python fixtures live at the top of `tests/python/test_refresh_data_cache.py` because many tests share small HTML variants.
- Smaller Python record fixtures are created inside individual test methods in `tests/python/test_data_records.py` and `tests/python/test_lua_export.py`.
- Lua fixtures are inline tables in `tests/stable_list_state_test.lua` and `tests/map_pet_index_test.lua`.
- Temporary filesystem fixtures use `tempfile.TemporaryDirectory()` with `Path` objects in `tests/python/test_source_cache.py` and `tests/python/test_refresh_data_cache.py`.

## Coverage

**Requirements:** No numeric coverage target or coverage tool configuration is detected.

**View Coverage:**
```bash
# Not configured. No coverage command is present in repository config.
```

## Test Types

**Unit Tests:**
- Python unit tests cover parser helpers in `scrapper/wowhead_source.py`, data normalization/builders in `scrapper/data_records.py`, Lua export formatting/validation in `scrapper/lua_export.py`, and source cache behavior in `scrapper/source_cache.py`.
- Lua unit tests cover pure addon helpers in `StablePetList.lua` and `MapPetIndex.lua`.

**Integration Tests:**
- `tests/python/test_refresh_data_cache.py` acts as a filesystem-backed integration suite for `scrapper/refresh_data.py`, `scrapper/source_cache.py`, `scrapper/wowhead_source.py`, `scrapper/data_records.py`, and `scrapper/lua_export.py`.
- These tests verify multi-step behavior including cache reuse, source invalidation, rerun behavior, blocker file output, validation failures, and generated Lua output.

**E2E Tests:**
- Not used. No browser, WoW client, or addon UI automation test suite is detected.

## Common Patterns

**Async Testing:**
```python
# Not applicable. Current Python and Lua code paths are synchronous.
exit_code = generate_pets(output, limit_families=0, source_cache=cache, generated_dir=self.root)
self.assertEqual(exit_code, 0)
```

**Error Testing:**
```python
def fetcher(url):
    raise HTTPError(url, 403, "Forbidden", hdrs=None, fp=None)

cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)

with self.assertRaises(SourceFetchError) as context:
    cache.get_text("https://www.wowhead.com/npc=3", "pet-npc")

self.assertEqual(context.exception.url, "https://www.wowhead.com/npc=3")
self.assertIn("HTTP Error 403: Forbidden", str(context.exception))
```

```lua
local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)), 2)
    end
end
```

---

*Testing analysis: 2026-04-29*
