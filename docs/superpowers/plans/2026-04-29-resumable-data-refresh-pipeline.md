# Resumable Data Refresh Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a resumable Wowhead source cache so pet and stable master refreshes preserve successful downloads, retry missing or failed URLs, and only write Lua after complete validated source data is available.

**Architecture:** Add a focused `scrapper/source_cache.py` module that owns URL cache keys, raw HTML files, manifest writes, cache hits, fetch failures, and reset behavior. Update `scrapper/refresh_data.py` so both `pets` and `stable-masters` read all Wowhead HTML through that shared cache while keeping parsing, normalization, validation, and Lua export in the existing refresh command flow.

**Tech Stack:** Python 3 standard library, `unittest`, `pathlib`, `json`, `hashlib`, existing `scrapper.wowhead_source.fetch_text`, existing Lua export and validation modules.

---

## File Structure

- Create `scrapper/source_cache.py`
  - Single responsibility: cache raw source pages by URL and maintain `refresh-manifest.json`.
  - Public interface: `SourceCache`, `SourceResult`, `SourceFetchError`.
  - No Wowhead-specific parsing here.

- Create `tests/python/test_source_cache.py`
  - Unit tests for cache miss, cache hit, fetch failure, preserving previous successful cache, and reset behavior.
  - Uses fake fetch functions; no live network.

- Modify `scrapper/refresh_data.py`
  - Add `--resume` and `--reset-cache` flags to both subcommands.
  - Create one `SourceCache` per command invocation.
  - Route hunter pet index, family pages, tameable NPC pages, stable master search, and stable master NPC pages through cache.
  - Preserve existing blocker, skipped, validation, output, and progress behavior.

- Create `tests/python/test_refresh_data_cache.py`
  - Integration-style unit tests around `generate_pets` and `generate_stable_masters` with fake cached source pages.
  - Verifies cached pages are reused, failures do not write Lua, and both commands use the same cache layer.

- Modify `docs/research/data-refresh-runbook.md`
  - Document resume commands, reset commands, manifest inspection, and safe production replacement rules.

---

### Task 1: Source Cache Unit Tests

**Files:**
- Create: `tests/python/test_source_cache.py`
- Create later in Task 2: `scrapper/source_cache.py`

- [ ] **Step 1: Write failing tests for cache miss, cache hit, fetch failure, preserved success, and reset**

Create `tests/python/test_source_cache.py` with this content:

```python
import json
import tempfile
import unittest
from pathlib import Path
from urllib.error import HTTPError

from scrapper.source_cache import SourceCache, SourceFetchError


class SourceCacheTest(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.cache_dir = self.root / "cache"
        self.manifest_path = self.root / "refresh-manifest.json"

    def tearDown(self):
        self.tempdir.cleanup()

    def test_cache_miss_fetches_and_writes_manifest(self):
        calls = []

        def fetcher(url):
            calls.append(url)
            return "<html>fresh</html>"

        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)

        result = cache.get_text("https://www.wowhead.com/npc=1", "pet-npc")

        self.assertEqual(result.text, "<html>fresh</html>")
        self.assertFalse(result.from_cache)
        self.assertEqual(calls, ["https://www.wowhead.com/npc=1"])
        self.assertTrue(result.path.exists())
        self.assertEqual(result.path.read_text(encoding="utf-8"), "<html>fresh</html>")

        manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        entry = manifest["sources"][result.cache_key]
        self.assertEqual(entry["url"], "https://www.wowhead.com/npc=1")
        self.assertEqual(entry["role"], "pet-npc")
        self.assertEqual(entry["status"], "ok")
        self.assertEqual(entry["path"], str(result.path))
        self.assertIsNone(entry["error"])

    def test_cache_hit_reuses_file_without_fetching(self):
        calls = []

        def fetcher(url):
            calls.append(url)
            return "<html>first</html>"

        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)
        first = cache.get_text("https://www.wowhead.com/npc=2", "pet-npc")

        def failing_fetcher(url):
            raise AssertionError("fetcher should not be called on cache hit")

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=failing_fetcher)
        second = resumed_cache.get_text("https://www.wowhead.com/npc=2", "pet-npc")

        self.assertEqual(first.cache_key, second.cache_key)
        self.assertEqual(second.text, "<html>first</html>")
        self.assertTrue(second.from_cache)
        self.assertEqual(calls, ["https://www.wowhead.com/npc=2"])

    def test_failed_fetch_records_error_and_raises_source_fetch_error(self):
        def fetcher(url):
            raise HTTPError(url, 403, "Forbidden", hdrs=None, fp=None)

        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)

        with self.assertRaises(SourceFetchError) as context:
            cache.get_text("https://www.wowhead.com/npc=3", "pet-npc")

        self.assertEqual(context.exception.url, "https://www.wowhead.com/npc=3")
        self.assertIn("HTTP Error 403: Forbidden", str(context.exception))

        manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        entry = next(iter(manifest["sources"].values()))
        self.assertEqual(entry["status"], "error")
        self.assertEqual(entry["url"], "https://www.wowhead.com/npc=3")
        self.assertEqual(entry["role"], "pet-npc")
        self.assertIsNone(entry["path"])
        self.assertIn("HTTP Error 403: Forbidden", entry["error"])

    def test_previous_success_is_preserved_because_cache_hit_does_not_refetch(self):
        def initial_fetcher(url):
            return "<html>saved</html>"

        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=initial_fetcher)
        first = cache.get_text("https://www.wowhead.com/npc=4", "pet-npc")

        def blocked_fetcher(url):
            raise HTTPError(url, 403, "Forbidden", hdrs=None, fp=None)

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=blocked_fetcher)
        second = resumed_cache.get_text("https://www.wowhead.com/npc=4", "pet-npc")

        self.assertTrue(second.from_cache)
        self.assertEqual(second.text, "<html>saved</html>")
        self.assertEqual(first.path.read_text(encoding="utf-8"), "<html>saved</html>")

    def test_reset_removes_cache_files_and_manifest(self):
        def fetcher(url):
            return "<html>saved</html>"

        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)
        result = cache.get_text("https://www.wowhead.com/npc=5", "pet-npc")
        self.assertTrue(result.path.exists())
        self.assertTrue(self.manifest_path.exists())

        cache.reset()

        self.assertFalse(result.path.exists())
        self.assertFalse(self.manifest_path.exists())
        self.assertTrue(self.cache_dir.exists())


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run tests to verify they fail because the module is missing**

Run:

```bash
rtk python3 -m unittest tests.python.test_source_cache -v
```

Expected: FAIL or ERROR with `ModuleNotFoundError: No module named 'scrapper.source_cache'`.

- [ ] **Step 3: Commit the failing tests**

```bash
rtk git add tests/python/test_source_cache.py
rtk git commit -m "test: cover source cache behavior"
```

---

### Task 2: Source Cache Implementation

**Files:**
- Create: `scrapper/source_cache.py`
- Test: `tests/python/test_source_cache.py`

- [ ] **Step 1: Implement the source cache module**

Create `scrapper/source_cache.py` with this content:

```python
from __future__ import annotations

import hashlib
import json
import shutil
import threading
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable

from scrapper.wowhead_source import fetch_text


FetchText = Callable[[str], str]


@dataclass(frozen=True)
class SourceResult:
    url: str
    role: str
    cache_key: str
    path: Path
    text: str
    from_cache: bool


class SourceFetchError(Exception):
    def __init__(self, url: str, role: str, error: Exception):
        self.url = url
        self.role = role
        self.error = error
        super().__init__(f"{url}: {error}")


class SourceCache:
    def __init__(
        self,
        cache_dir: Path,
        manifest_path: Path,
        fetcher: FetchText = fetch_text,
    ):
        self.cache_dir = cache_dir
        self.manifest_path = manifest_path
        self.fetcher = fetcher
        self._manifest_lock = threading.Lock()

    def reset(self) -> None:
        if self.cache_dir.exists():
            shutil.rmtree(self.cache_dir)
        if self.manifest_path.exists():
            self.manifest_path.unlink()
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def get_text(self, url: str, role: str) -> SourceResult:
        normalized_url = self._normalize_url(url)
        cache_key = self._cache_key(normalized_url)
        path = self.cache_dir / f"{cache_key}.html"

        if path.exists():
            return SourceResult(
                url=normalized_url,
                role=role,
                cache_key=cache_key,
                path=path,
                text=path.read_text(encoding="utf-8"),
                from_cache=True,
            )

        self.cache_dir.mkdir(parents=True, exist_ok=True)
        try:
            text = self.fetcher(normalized_url)
        except Exception as error:
            self._record_error(normalized_url, role, cache_key, str(error))
            raise SourceFetchError(normalized_url, role, error) from error

        path.write_text(text, encoding="utf-8")
        self._record_ok(normalized_url, role, cache_key, path)
        return SourceResult(
            url=normalized_url,
            role=role,
            cache_key=cache_key,
            path=path,
            text=text,
            from_cache=False,
        )

    def _record_ok(self, url: str, role: str, cache_key: str, path: Path) -> None:
        with self._manifest_lock:
            manifest = self._load_manifest()
            manifest["sources"][cache_key] = {
                "url": url,
                "cache_key": cache_key,
                "role": role,
                "status": "ok",
                "path": str(path),
                "fetched_at": self._now(),
                "error": None,
            }
            self._write_manifest(manifest)

    def _record_error(self, url: str, role: str, cache_key: str, error: str) -> None:
        with self._manifest_lock:
            manifest = self._load_manifest()
            manifest["sources"][cache_key] = {
                "url": url,
                "cache_key": cache_key,
                "role": role,
                "status": "error",
                "path": None,
                "fetched_at": self._now(),
                "error": error,
            }
            self._write_manifest(manifest)

    def _load_manifest(self) -> dict:
        if not self.manifest_path.exists():
            return {"sources": {}}
        return json.loads(self.manifest_path.read_text(encoding="utf-8"))

    def _write_manifest(self, manifest: dict) -> None:
        self.manifest_path.parent.mkdir(parents=True, exist_ok=True)
        self.manifest_path.write_text(
            json.dumps(manifest, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    def _normalize_url(self, url: str) -> str:
        return url.strip()

    def _cache_key(self, url: str) -> str:
        return hashlib.sha256(url.encode("utf-8")).hexdigest()

    def _now(self) -> str:
        return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
```

- [ ] **Step 2: Run source cache tests**

Run:

```bash
rtk python3 -m unittest tests.python.test_source_cache -v
```

Expected: PASS for all five `SourceCacheTest` tests.

- [ ] **Step 3: Run all Python tests**

Run:

```bash
rtk python3 -m unittest discover -s tests/python -p 'test_*.py' -v
```

Expected: all existing tests plus `test_source_cache.py` pass.

- [ ] **Step 4: Commit source cache implementation**

```bash
rtk git add scrapper/source_cache.py tests/python/test_source_cache.py
rtk git commit -m "feat: add resumable source cache"
```

---

### Task 3: Refresh CLI Cache Wiring Tests

**Files:**
- Create: `tests/python/test_refresh_data_cache.py`
- Modify later in Task 4: `scrapper/refresh_data.py`

- [ ] **Step 1: Write failing tests for pet resume, pet source failure, and stable master cache usage**

Create `tests/python/test_refresh_data_cache.py` with this content:

```python
import tempfile
import unittest
from pathlib import Path
from urllib.error import HTTPError

from scrapper.refresh_data import generate_pets, generate_stable_masters
from scrapper.source_cache import SourceCache
from scrapper.wowhead_source import HUNTER_PETS_URL, STABLE_MASTER_SEARCH_URL, npc_url, pet_family_url


def pets_index_html():
    return """
    <script>
    new Listview({
        id: 'pets',
        data: [{"id":46,"name":"Spirit Beast"}]
    });
    </script>
    """


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


def npc_mapper_html():
    return """
    <script>
    var g_mapperData = {"3711":[{"uiMapId":119,"uiMapName":"Sholazar Basin","coords":[[36.6,30.8]]}]};
    </script>
    """


def stable_search_html():
    return """
    <script>
    new Listview({
        id: 'npcs',
        data: [{
            "id":185561,
            "name":"Kaestrasz",
            "tag":"Stable Master",
            "react":[1,1],
            "location":[13862]
        }]
    });
    </script>
    """


def stable_mapper_html():
    return """
    <script>
    var g_mapperData = {"13862":[{"uiMapId":2112,"uiMapName":"Valdrakken","coords":[[62.0,13.2]]}]};
    </script>
    """


class RefreshDataCacheTest(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.cache_dir = self.root / "cache"
        self.manifest_path = self.root / "refresh-manifest.json"

    def tearDown(self):
        self.tempdir.cleanup()

    def test_generate_pets_reuses_cached_sources_without_fetching(self):
        pages = {
            HUNTER_PETS_URL: pets_index_html(),
            pet_family_url(46): pet_family_html(),
            npc_url(32517): npc_mapper_html(),
        }
        seed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: pages[url])
        for url, role in (
            (HUNTER_PETS_URL, "pet-index"),
            (pet_family_url(46), "pet-family"),
            (npc_url(32517), "pet-npc"),
        ):
            seed_cache.get_text(url, role)

        def blocked_fetcher(url):
            raise AssertionError("cached pet refresh should not fetch live source")

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=blocked_fetcher)
        output = self.root / "Data.lua"

        exit_code = generate_pets(output, limit_families=0, source_cache=resumed_cache)

        self.assertEqual(exit_code, 0)
        lua = output.read_text(encoding="utf-8")
        self.assertIn("Loque'nahak", lua)
        self.assertIn("Sholazar Basin", lua)

    def test_generate_pets_records_source_failure_and_does_not_write_lua(self):
        def fetcher(url):
            if url == HUNTER_PETS_URL:
                return pets_index_html()
            raise HTTPError(url, 403, "Forbidden", hdrs=None, fp=None)

        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)
        output = self.root / "Data.lua"

        exit_code = generate_pets(
            output,
            limit_families=0,
            source_cache=cache,
            generated_dir=self.root,
        )

        self.assertEqual(exit_code, 1)
        self.assertFalse(output.exists())
        blockers = (self.root / "pet-refresh-blockers.md").read_text(encoding="utf-8")
        self.assertIn(pet_family_url(46), blockers)
        self.assertIn("HTTP Error 403: Forbidden", blockers)

    def test_generate_stable_masters_uses_source_cache(self):
        pages = {
            STABLE_MASTER_SEARCH_URL: stable_search_html(),
            npc_url(185561): stable_mapper_html(),
        }
        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: pages[url])
        output = self.root / "StableMastersData.lua"

        exit_code = generate_stable_masters(output, limit=0, source_cache=cache, generated_dir=self.root)

        self.assertEqual(exit_code, 0)
        lua = output.read_text(encoding="utf-8")
        self.assertIn("Kaestrasz", lua)
        self.assertIn("Valdrakken", lua)

        def blocked_fetcher(url):
            raise AssertionError("stable master refresh should reuse cached source")

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=blocked_fetcher)
        second_output = self.root / "StableMastersData.second.lua"

        second_exit_code = generate_stable_masters(
            second_output,
            limit=0,
            source_cache=resumed_cache,
            generated_dir=self.root,
        )

        self.assertEqual(second_exit_code, 0)
        self.assertIn("Kaestrasz", second_output.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run tests to verify they fail on missing function parameters**

Run:

```bash
rtk python3 -m unittest tests.python.test_refresh_data_cache -v
```

Expected: FAIL with `TypeError` because `generate_pets` and `generate_stable_masters` do not yet accept `source_cache` or `generated_dir`.

- [ ] **Step 3: Commit failing refresh cache tests**

```bash
rtk git add tests/python/test_refresh_data_cache.py
rtk git commit -m "test: cover cached refresh flows"
```

---

### Task 4: Refresh CLI Cache Integration

**Files:**
- Modify: `scrapper/refresh_data.py`
- Test: `tests/python/test_refresh_data_cache.py`
- Test: `tests/python/test_source_cache.py`

- [ ] **Step 1: Update imports and constants in `scrapper/refresh_data.py`**

Modify the import section so it includes the cache module:

```python
from scrapper.source_cache import SourceCache, SourceFetchError
```

Keep the existing `fetch_text` import for constructing the default cache fetcher:

```python
from scrapper.wowhead_source import (
    HUNTER_PETS_URL,
    STABLE_MASTER_SEARCH_URL,
    extract_listview_data,
    extract_mapper_data,
    fetch_text,
    npc_url,
    pet_family_url,
)
```

Add this constant near `GENERATED_DIR`:

```python
MANIFEST_PATH = GENERATED_DIR / "refresh-manifest.json"
```

- [ ] **Step 2: Add CLI flags and construct a cache per command**

Replace the parser setup and command dispatch in `main()` with this shape:

```python
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
```

Note: `--resume` is intentionally accepted but not checked. Resume is the safe default whenever cached files exist.

- [ ] **Step 3: Update `generate_pets` to accept cache dependencies**

Change the signature and first fetch:

```python
def generate_pets(
    output: Path,
    limit_families: int = 0,
    source_cache: SourceCache | None = None,
    generated_dir: Path = GENERATED_DIR,
) -> int:
    source_cache = source_cache or SourceCache(generated_dir / "cache", generated_dir / "refresh-manifest.json")
    try:
        index_html = source_cache.get_text(HUNTER_PETS_URL, "pet-index").text
    except SourceFetchError as error:
        _write_lines(generated_dir / "pet-refresh-blockers.md", [str(error)])
        return 1
```

Inside the family loop, replace `fetch_text(pet_family_url(family.id))` with:

```python
            family_source_url = pet_family_url(family.id)
            try:
                family_html = source_cache.get_text(family_source_url, "pet-family").text
            except SourceFetchError as error:
                _write_lines(generated_dir / "pet-refresh-blockers.md", [str(error)])
                return 1
```

Change future submission from:

```python
executor.submit(_build_pet_record_from_source, family, tameable)
```

to:

```python
executor.submit(_build_pet_record_from_source, family, tameable, source_cache)
```

Change the `future.result()` error handler from:

```python
                except (HTTPError, URLError) as error:
                    _write_lines(GENERATED_DIR / "pet-refresh-blockers.md", [str(error)])
                    return 1
```

to:

```python
                except SourceFetchError as error:
                    _write_lines(generated_dir / "pet-refresh-blockers.md", [str(error)])
                    return 1
```

Change all generated file writes in this function to use `generated_dir`:

```python
_write_lines(generated_dir / "pet-refresh-blockers.md", [str(error)])
_write_lines(generated_dir / "pet-validation-errors.md", errors)
_write_lines(generated_dir / "pet-skipped.md", skipped)
```

- [ ] **Step 4: Update pet NPC source helper**

Replace `_build_pet_record_from_source` with:

```python
def _build_pet_record_from_source(family, tameable, source_cache: SourceCache):
    source_url = npc_url(tameable.id)
    npc_html = source_cache.get_text(source_url, "pet-npc").text
    mapper_data = extract_mapper_data(npc_html)
    return tameable, build_pet_record(family, tameable, mapper_data)
```

The existing `except SourceFetchError as error` block in `generate_pets` should write `str(error)` to `pet-refresh-blockers.md` and return `1`.

- [ ] **Step 5: Update `generate_stable_masters` to accept cache dependencies**

Change the signature and search fetch:

```python
def generate_stable_masters(
    output: Path,
    limit: int = 0,
    source_cache: SourceCache | None = None,
    generated_dir: Path = GENERATED_DIR,
) -> int:
    source_cache = source_cache or SourceCache(generated_dir / "cache", generated_dir / "refresh-manifest.json")
    try:
        search_html = source_cache.get_text(STABLE_MASTER_SEARCH_URL, "stable-master-search").text
    except SourceFetchError as error:
        _write_lines(generated_dir / "stable-master-blockers.md", [str(error)])
        return 1
```

Replace each stable master NPC fetch with:

```python
    for row in rows:
        try:
            html = source_cache.get_text(npc_url(int(row["id"])), "stable-master-npc").text
        except SourceFetchError as error:
            _write_lines(generated_dir / "stable-master-blockers.md", [str(error)])
            return 1
        record = build_stable_master_record(row, extract_mapper_data(html))
```

Change all generated file writes in this function to use `generated_dir`:

```python
_write_lines(generated_dir / "stable-master-validation-errors.md", errors)
_write_lines(generated_dir / "stable-master-blockers.md", skipped or ["No stable master records validated."])
_write_lines(generated_dir / "stable-master-skipped.md", skipped)
```

- [ ] **Step 6: Run refresh cache tests**

Run:

```bash
rtk python3 -m unittest tests.python.test_refresh_data_cache -v
```

Expected: PASS for all three `RefreshDataCacheTest` tests.

- [ ] **Step 7: Run all Python tests**

Run:

```bash
rtk python3 -m unittest discover -s tests/python -p 'test_*.py' -v
```

Expected: all Python tests pass.

- [ ] **Step 8: Commit refresh cache integration**

```bash
rtk git add scrapper/refresh_data.py tests/python/test_refresh_data_cache.py
rtk git commit -m "feat: resume refreshes from cached source"
```

---

### Task 5: Reset CLI Coverage

**Files:**
- Modify: `tests/python/test_refresh_data_cache.py`
- Modify if needed: `scrapper/refresh_data.py`

- [ ] **Step 1: Add a unit test for `--reset-cache` command dispatch**

Append this import near the top of `tests/python/test_refresh_data_cache.py`:

```python
from unittest.mock import patch

from scrapper import refresh_data
```

Add this test method to `RefreshDataCacheTest`:

```python
    def test_main_reset_cache_clears_existing_sources_before_refresh(self):
        pages = {
            HUNTER_PETS_URL: pets_index_html(),
            pet_family_url(46): pet_family_html(),
            npc_url(32517): npc_mapper_html(),
        }
        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: pages[url])
        cached = cache.get_text(HUNTER_PETS_URL, "pet-index")
        self.assertTrue(cached.path.exists())

        created_caches = []

        def cache_factory(cache_dir, manifest_path, fetcher):
            created = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: pages[url])
            created_caches.append(created)
            return created

        argv = [
            "refresh_data.py",
            "pets",
            "--output",
            str(self.root / "Data.lua"),
            "--reset-cache",
        ]
        with patch.object(refresh_data, "SourceCache", side_effect=cache_factory):
            with patch("sys.argv", argv):
                exit_code = refresh_data.main()

        self.assertEqual(exit_code, 0)
        self.assertEqual(len(created_caches), 1)
        self.assertTrue(self.manifest_path.exists())
        self.assertIn("Loque'nahak", (self.root / "Data.lua").read_text(encoding="utf-8"))
```

- [ ] **Step 2: Run reset CLI test**

Run:

```bash
rtk python3 -m unittest tests.python.test_refresh_data_cache.RefreshDataCacheTest.test_main_reset_cache_clears_existing_sources_before_refresh -v
```

Expected: PASS. If it fails because `main()` constructs paths before patching, keep the production code simple and adjust only the test patching target; do not add extra production abstractions for this test.

- [ ] **Step 3: Run all Python tests**

Run:

```bash
rtk python3 -m unittest discover -s tests/python -p 'test_*.py' -v
```

Expected: all Python tests pass.

- [ ] **Step 4: Commit reset CLI coverage**

```bash
rtk git add tests/python/test_refresh_data_cache.py scrapper/refresh_data.py
rtk git commit -m "test: cover refresh cache reset flag"
```

---

### Task 6: Runbook Update

**Files:**
- Modify: `docs/research/data-refresh-runbook.md`

- [ ] **Step 1: Update the existing Resume And Cache Requirements section**

Replace the current `## Resume And Cache Requirements` section with:

```markdown
## Resume And Cache Workflow

Full refreshes are resumable. The pipeline persists fetched Wowhead pages under `scrapper/generated/cache/` and records progress in `scrapper/generated/refresh-manifest.json`.

Resume is the safe default when cached pages exist. Use `--resume` in manual commands to make intent explicit:

```bash
rtk python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua --resume
rtk python3 -m scrapper.refresh_data stable-masters --output scrapper/generated/StableMastersData.lua --resume
```

Use `--reset-cache` only when intentionally discarding saved source pages:

```bash
rtk python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua --reset-cache
rtk python3 -m scrapper.refresh_data stable-masters --output scrapper/generated/StableMastersData.lua --reset-cache
```

Inspect the manifest when a refresh fails:

```bash
rtk sed -n '1,200p' scrapper/generated/refresh-manifest.json
rtk sed -n '1,120p' scrapper/generated/pet-refresh-blockers.md
rtk sed -n '1,120p' scrapper/generated/stable-master-blockers.md
```

Required behavior:

- Successful cached pages are reused indefinitely.
- Missing or failed URLs are retried on rerun.
- `--reset-cache` removes saved pages and starts a fresh collection.
- Generated Lua is written only from a complete validated source set.
- Production `Data.lua` and `StableMastersData.lua` are replaced only after generated output validates and the diff is reviewed.
```

- [ ] **Step 2: Update command examples to include `--resume`**

In `## Full Pet Refresh`, change:

```bash
rtk python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua
```

to:

```bash
rtk python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua --resume
```

In `## Stable Master Feasibility`, change:

```bash
rtk python3 -m scrapper.refresh_data stable-masters --output scrapper/generated/StableMastersData.lua
```

to:

```bash
rtk python3 -m scrapper.refresh_data stable-masters --output scrapper/generated/StableMastersData.lua --resume
```

- [ ] **Step 3: Review the runbook diff**

Run:

```bash
rtk git diff -- docs/research/data-refresh-runbook.md
```

Expected: the diff documents resume, reset, manifest inspection, and safe replacement without changing unrelated research content.

- [ ] **Step 4: Commit runbook update**

```bash
rtk git add docs/research/data-refresh-runbook.md
rtk git commit -m "docs: document resumable refresh workflow"
```

---

### Task 7: Final Verification

**Files:**
- Verify: `scrapper/source_cache.py`
- Verify: `scrapper/refresh_data.py`
- Verify: `tests/python/test_source_cache.py`
- Verify: `tests/python/test_refresh_data_cache.py`
- Verify: `docs/research/data-refresh-runbook.md`

- [ ] **Step 1: Run the full Python test suite**

Run:

```bash
rtk python3 -m unittest discover -s tests/python -p 'test_*.py' -v
```

Expected: all Python tests pass, including source cache and cached refresh tests.

- [ ] **Step 2: Run existing Lua tests**

Run:

```bash
rtk lua tests/stable_list_state_test.lua
rtk lua tests/map_pet_index_test.lua
```

Expected: `stable_list_state_test.lua` reports its existing passing tests, and `map_pet_index_test.lua` reports `PASS`.

- [ ] **Step 3: Verify CLI help exposes cache flags**

Run:

```bash
rtk python3 -m scrapper.refresh_data pets --help
rtk python3 -m scrapper.refresh_data stable-masters --help
```

Expected: both help outputs include `--resume` and `--reset-cache`.

- [ ] **Step 4: Inspect final git status**

Run:

```bash
rtk git status --short
```

Expected: clean worktree after the final docs/test/code commits.

- [ ] **Step 5: Record final verification in the implementation chat**

Include this summary in the final response of the implementation chat:

```text
Implemented resumable source caching for pets and stable masters.
Verified with:
- rtk python3 -m unittest discover -s tests/python -p 'test_*.py' -v
- rtk lua tests/stable_list_state_test.lua
- rtk lua tests/map_pet_index_test.lua
- rtk python3 -m scrapper.refresh_data pets --help
- rtk python3 -m scrapper.refresh_data stable-masters --help
```

---

## Self-Review Notes

- Spec coverage: cache files, manifest, indefinite reuse, reset, pet source graph, stable master source graph, source access blockers, validation blockers, tests, and runbook updates are all covered by tasks above.
- Scope check: one shared cache design serves both refresh commands; this is not split further because the spec intentionally treats pets and stable masters as two users of the same cache mechanism.
- Red-flag scan: this plan avoids unfinished markers and intentionally vague implementation steps.
- Type consistency: `SourceCache.get_text(url, role)` returns `SourceResult`; refresh code catches `SourceFetchError`; tests use the same names and signatures.

## Execution Handoff

Start execution in a new chat from this plan:

```text
docs/superpowers/plans/2026-04-29-resumable-data-refresh-pipeline.md
```

Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` in that new chat, then work task-by-task from the checkboxes.
