import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.error import HTTPError

from scrapper import refresh_data
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


def pet_family_two_pets_html():
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
        },{
            "id":99999,
            "name":"Retry Cat",
            "family":46,
            "classification":0,
            "location":[3712],
            "react":[-1,-1],
            "minlevel":20,
            "maxlevel":20
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


def npc_mapper_html_for(location_id, zone_name):
    return f"""
    <script>
    var g_mapperData = {{"{location_id}":[{{"uiMapId":119,"uiMapName":"{zone_name}","coords":[[36.6,30.8]]}}]}};
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


def stable_search_without_stable_masters_html():
    return """
    <script>
    new Listview({
        id: 'npcs',
        data: [{
            "id":12345,
            "name":"Repair Vendor",
            "tag":"Repair",
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


def mapper_array_html():
    return """
    <script>
    var g_mapperData = [];
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

        exit_code = generate_pets(
            output,
            limit_families=0,
            source_cache=resumed_cache,
            generated_dir=self.root,
        )

        self.assertEqual(exit_code, 0)
        lua = output.read_text(encoding="utf-8")
        self.assertIn("Loque'nahak", lua)
        self.assertIn("Sholazar Basin", lua)

    def test_generate_pets_blocks_empty_pet_index_source(self):
        pages = {
            HUNTER_PETS_URL: "<html><title>blocked</title></html>",
        }
        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: pages[url])
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
        self.assertIn("pet index", blockers)
        self.assertIn(HUNTER_PETS_URL, blockers)

    def test_blocked_pet_index_is_invalidated_and_retried_on_rerun(self):
        first_cache = SourceCache(
            self.cache_dir,
            self.manifest_path,
            fetcher=lambda url: "<html><title>blocked</title></html>",
        )
        first_output = self.root / "Data.lua"

        first_exit_code = generate_pets(
            first_output,
            limit_families=0,
            source_cache=first_cache,
            generated_dir=self.root,
        )

        self.assertEqual(first_exit_code, 1)
        self.assertFalse(first_output.exists())
        manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        index_entry = next(entry for entry in manifest["sources"].values() if entry["url"] == HUNTER_PETS_URL)
        self.assertEqual(index_entry["status"], "error")
        self.assertIsNone(index_entry["path"])

        pages = {
            HUNTER_PETS_URL: pets_index_html(),
            pet_family_url(46): pet_family_html(),
            npc_url(32517): npc_mapper_html(),
        }
        calls = []

        def fetcher(url):
            calls.append(url)
            return pages[url]

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)
        second_output = self.root / "Data.second.lua"

        second_exit_code = generate_pets(
            second_output,
            limit_families=0,
            source_cache=resumed_cache,
            generated_dir=self.root,
        )

        self.assertEqual(second_exit_code, 0)
        self.assertIn(HUNTER_PETS_URL, calls)
        self.assertIn("Loque'nahak", second_output.read_text(encoding="utf-8"))

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

    def test_generate_pets_blocks_empty_tameable_family_source(self):
        pages = {
            HUNTER_PETS_URL: pets_index_html(),
            pet_family_url(46): """
            <script>
            new Listview({
                id: 'tameable',
                data: []
            });
            </script>
            """,
        }
        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: pages[url])
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
        self.assertIn("No tameable pets found", blockers)
        self.assertIn(pet_family_url(46), blockers)

    def test_blocked_pet_family_is_invalidated_and_retried_on_rerun(self):
        family_url = pet_family_url(46)
        first_pages = {
            HUNTER_PETS_URL: pets_index_html(),
            family_url: """
            <script>
            new Listview({
                id: 'tameable',
                data: []
            });
            </script>
            """,
        }
        first_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: first_pages[url])
        first_output = self.root / "Data.lua"

        first_exit_code = generate_pets(
            first_output,
            limit_families=0,
            source_cache=first_cache,
            generated_dir=self.root,
        )

        self.assertEqual(first_exit_code, 1)
        self.assertFalse(first_output.exists())
        manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        family_entry = next(entry for entry in manifest["sources"].values() if entry["url"] == family_url)
        self.assertEqual(family_entry["status"], "error")
        self.assertIsNone(family_entry["path"])

        second_pages = {
            HUNTER_PETS_URL: pets_index_html(),
            family_url: pet_family_html(),
            npc_url(32517): npc_mapper_html(),
        }
        calls = []

        def fetcher(url):
            calls.append(url)
            return second_pages[url]

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)
        second_output = self.root / "Data.second.lua"

        second_exit_code = generate_pets(
            second_output,
            limit_families=0,
            source_cache=resumed_cache,
            generated_dir=self.root,
        )

        self.assertEqual(second_exit_code, 0)
        self.assertIn(family_url, calls)
        self.assertIn("Loque'nahak", second_output.read_text(encoding="utf-8"))

    def test_generate_pets_blocks_all_skipped_records(self):
        pages = {
            HUNTER_PETS_URL: pets_index_html(),
            pet_family_url(46): pet_family_html(),
            npc_url(32517): """
            <script>
            var g_mapperData = {"3711":[{"uiMapId":119,"uiMapName":"Sholazar Basin","coords":[]}]};
            </script>
            """,
        }
        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: pages[url])
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
        self.assertIn("32517 Loque'nahak: no mapper coordinates", blockers)

    def test_blocked_pet_npc_mapper_is_invalidated_and_retried_on_rerun(self):
        blocked_npc_url = npc_url(99999)
        first_pages = {
            HUNTER_PETS_URL: pets_index_html(),
            pet_family_url(46): pet_family_two_pets_html(),
            npc_url(32517): npc_mapper_html_for(3711, "Sholazar Basin"),
            blocked_npc_url: "<html><title>blocked</title></html>",
        }
        first_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: first_pages[url])
        first_output = self.root / "Data.lua"

        first_exit_code = generate_pets(
            first_output,
            limit_families=0,
            source_cache=first_cache,
            generated_dir=self.root,
        )

        self.assertEqual(first_exit_code, 1)
        self.assertFalse(first_output.exists())
        blockers = (self.root / "pet-refresh-blockers.md").read_text(encoding="utf-8")
        self.assertIn(blocked_npc_url, blockers)
        self.assertIn("g_mapperData", blockers)
        manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        npc_entry = next(entry for entry in manifest["sources"].values() if entry["url"] == blocked_npc_url)
        self.assertEqual(npc_entry["status"], "error")
        self.assertIsNone(npc_entry["path"])

        second_pages = {
            HUNTER_PETS_URL: pets_index_html(),
            pet_family_url(46): pet_family_two_pets_html(),
            npc_url(32517): npc_mapper_html_for(3711, "Sholazar Basin"),
            blocked_npc_url: npc_mapper_html_for(3712, "Retry Zone"),
        }
        calls = []

        def fetcher(url):
            calls.append(url)
            return second_pages[url]

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)
        second_output = self.root / "Data.second.lua"

        second_exit_code = generate_pets(
            second_output,
            limit_families=0,
            source_cache=resumed_cache,
            generated_dir=self.root,
        )

        self.assertEqual(second_exit_code, 0)
        self.assertIn(blocked_npc_url, calls)
        lua = second_output.read_text(encoding="utf-8")
        self.assertIn("Loque'nahak", lua)
        self.assertIn("Retry Cat", lua)

    def test_wrong_shape_pet_npc_mapper_is_invalidated_and_retried_on_rerun(self):
        bad_npc_url = npc_url(32517)
        first_pages = {
            HUNTER_PETS_URL: pets_index_html(),
            pet_family_url(46): pet_family_html(),
            bad_npc_url: mapper_array_html(),
        }
        first_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: first_pages[url])
        first_output = self.root / "Data.lua"

        first_exit_code = generate_pets(
            first_output,
            limit_families=0,
            source_cache=first_cache,
            generated_dir=self.root,
        )

        self.assertEqual(first_exit_code, 1)
        self.assertFalse(first_output.exists())
        blockers = (self.root / "pet-refresh-blockers.md").read_text(encoding="utf-8")
        self.assertIn(bad_npc_url, blockers)
        self.assertIn("g_mapperData", blockers)
        manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        npc_entry = next(entry for entry in manifest["sources"].values() if entry["url"] == bad_npc_url)
        self.assertEqual(npc_entry["status"], "error")
        self.assertIsNone(npc_entry["path"])

        second_pages = {
            HUNTER_PETS_URL: pets_index_html(),
            pet_family_url(46): pet_family_html(),
            bad_npc_url: npc_mapper_html(),
        }
        calls = []

        def fetcher(url):
            calls.append(url)
            return second_pages[url]

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)
        second_output = self.root / "Data.second.lua"

        second_exit_code = generate_pets(
            second_output,
            limit_families=0,
            source_cache=resumed_cache,
            generated_dir=self.root,
        )

        self.assertEqual(second_exit_code, 0)
        self.assertIn(bad_npc_url, calls)
        self.assertIn("Loque'nahak", second_output.read_text(encoding="utf-8"))

    def test_successful_pet_resume_clears_stale_failure_artifacts(self):
        (self.root / "pet-refresh-blockers.md").write_text("- stale blocker\n", encoding="utf-8")
        (self.root / "pet-validation-errors.md").write_text("- stale validation\n", encoding="utf-8")
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

        exit_code = generate_pets(
            self.root / "Data.lua",
            limit_families=0,
            source_cache=resumed_cache,
            generated_dir=self.root,
        )

        self.assertEqual(exit_code, 0)
        self.assertFalse((self.root / "pet-refresh-blockers.md").exists())
        self.assertFalse((self.root / "pet-validation-errors.md").exists())

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

    def test_blocked_stable_master_search_is_invalidated_and_retried_on_rerun(self):
        first_cache = SourceCache(
            self.cache_dir,
            self.manifest_path,
            fetcher=lambda url: "<html><title>blocked</title></html>",
        )
        first_output = self.root / "StableMastersData.lua"

        first_exit_code = generate_stable_masters(
            first_output,
            limit=0,
            source_cache=first_cache,
            generated_dir=self.root,
        )

        self.assertEqual(first_exit_code, 1)
        self.assertFalse(first_output.exists())
        manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        search_entry = next(
            entry for entry in manifest["sources"].values() if entry["url"] == STABLE_MASTER_SEARCH_URL
        )
        self.assertEqual(search_entry["status"], "error")
        self.assertIsNone(search_entry["path"])

        pages = {
            STABLE_MASTER_SEARCH_URL: stable_search_html(),
            npc_url(185561): stable_mapper_html(),
        }
        calls = []

        def fetcher(url):
            calls.append(url)
            return pages[url]

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)
        second_output = self.root / "StableMastersData.second.lua"

        second_exit_code = generate_stable_masters(
            second_output,
            limit=0,
            source_cache=resumed_cache,
            generated_dir=self.root,
        )

        self.assertEqual(second_exit_code, 0)
        self.assertIn(STABLE_MASTER_SEARCH_URL, calls)
        self.assertIn("Kaestrasz", second_output.read_text(encoding="utf-8"))

    def test_non_stable_master_search_rows_are_invalidated_and_retried_on_rerun(self):
        first_cache = SourceCache(
            self.cache_dir,
            self.manifest_path,
            fetcher=lambda url: stable_search_without_stable_masters_html(),
        )
        first_output = self.root / "StableMastersData.lua"

        first_exit_code = generate_stable_masters(
            first_output,
            limit=0,
            source_cache=first_cache,
            generated_dir=self.root,
        )

        self.assertEqual(first_exit_code, 1)
        self.assertFalse(first_output.exists())
        blockers = (self.root / "stable-master-blockers.md").read_text(encoding="utf-8")
        self.assertIn("No stable master rows found", blockers)
        self.assertIn(STABLE_MASTER_SEARCH_URL, blockers)
        manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        search_entry = next(
            entry for entry in manifest["sources"].values() if entry["url"] == STABLE_MASTER_SEARCH_URL
        )
        self.assertEqual(search_entry["status"], "error")
        self.assertIsNone(search_entry["path"])

        pages = {
            STABLE_MASTER_SEARCH_URL: stable_search_html(),
            npc_url(185561): stable_mapper_html(),
        }
        calls = []

        def fetcher(url):
            calls.append(url)
            return pages[url]

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)
        second_output = self.root / "StableMastersData.second.lua"

        second_exit_code = generate_stable_masters(
            second_output,
            limit=0,
            source_cache=resumed_cache,
            generated_dir=self.root,
        )

        self.assertEqual(second_exit_code, 0)
        self.assertIn(STABLE_MASTER_SEARCH_URL, calls)
        self.assertIn("Kaestrasz", second_output.read_text(encoding="utf-8"))

    def test_blocked_stable_master_npc_is_invalidated_and_retried_on_rerun(self):
        stable_npc_url = npc_url(185561)
        first_pages = {
            STABLE_MASTER_SEARCH_URL: stable_search_html(),
            stable_npc_url: "<html><title>blocked</title></html>",
        }
        first_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: first_pages[url])
        first_output = self.root / "StableMastersData.lua"

        first_exit_code = generate_stable_masters(
            first_output,
            limit=0,
            source_cache=first_cache,
            generated_dir=self.root,
        )

        self.assertEqual(first_exit_code, 1)
        self.assertFalse(first_output.exists())
        blockers = (self.root / "stable-master-blockers.md").read_text(encoding="utf-8")
        self.assertIn(stable_npc_url, blockers)
        self.assertIn("g_mapperData", blockers)
        manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        npc_entry = next(entry for entry in manifest["sources"].values() if entry["url"] == stable_npc_url)
        self.assertEqual(npc_entry["status"], "error")
        self.assertIsNone(npc_entry["path"])

        second_pages = {
            STABLE_MASTER_SEARCH_URL: stable_search_html(),
            stable_npc_url: stable_mapper_html(),
        }
        calls = []

        def fetcher(url):
            calls.append(url)
            return second_pages[url]

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=fetcher)
        second_output = self.root / "StableMastersData.second.lua"

        second_exit_code = generate_stable_masters(
            second_output,
            limit=0,
            source_cache=resumed_cache,
            generated_dir=self.root,
        )

        self.assertEqual(second_exit_code, 0)
        self.assertIn(stable_npc_url, calls)
        self.assertIn("Kaestrasz", second_output.read_text(encoding="utf-8"))

    def test_successful_stable_master_resume_clears_stale_failure_artifacts(self):
        (self.root / "stable-master-blockers.md").write_text("- stale blocker\n", encoding="utf-8")
        (self.root / "stable-master-validation-errors.md").write_text("- stale validation\n", encoding="utf-8")
        pages = {
            STABLE_MASTER_SEARCH_URL: stable_search_html(),
            npc_url(185561): stable_mapper_html(),
        }
        seed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: pages[url])
        for url, role in (
            (STABLE_MASTER_SEARCH_URL, "stable-master-search"),
            (npc_url(185561), "stable-master-npc"),
        ):
            seed_cache.get_text(url, role)

        def blocked_fetcher(url):
            raise AssertionError("stable master refresh should reuse cached source")

        resumed_cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=blocked_fetcher)

        exit_code = generate_stable_masters(
            self.root / "StableMastersData.lua",
            limit=0,
            source_cache=resumed_cache,
            generated_dir=self.root,
        )

        self.assertEqual(exit_code, 0)
        self.assertFalse((self.root / "stable-master-blockers.md").exists())
        self.assertFalse((self.root / "stable-master-validation-errors.md").exists())

    def test_main_reset_cache_clears_existing_sources_before_refresh(self):
        stale_pages = {
            HUNTER_PETS_URL: """
            <script>
            new Listview({
                id: 'pets',
                data: [{"id":999,"name":"Stale Family"}]
            });
            </script>
            """,
        }
        pages = {
            HUNTER_PETS_URL: pets_index_html(),
            pet_family_url(46): pet_family_html(),
            npc_url(32517): npc_mapper_html(),
        }
        cache = SourceCache(self.cache_dir, self.manifest_path, fetcher=lambda url: stale_pages[url])
        cached = cache.get_text(HUNTER_PETS_URL, "pet-index")
        self.assertTrue(cached.path.exists())

        class TrackingSourceCache(SourceCache):
            def __init__(self, cache_dir, manifest_path, fetcher):
                super().__init__(cache_dir, manifest_path, fetcher)
                self.reset_called = False

            def reset(self):
                self.reset_called = True
                super().reset()

        created_caches = []

        def cache_factory(cache_dir, manifest_path, fetcher):
            created = TrackingSourceCache(cache_dir, manifest_path, fetcher=lambda url: pages[url])
            created_caches.append(created)
            return created

        original_generate_pets = refresh_data.generate_pets

        def generate_pets_in_temp(output, limit_families, source_cache):
            return original_generate_pets(
                output,
                limit_families,
                source_cache=source_cache,
                generated_dir=self.root,
            )

        argv = [
            "refresh_data.py",
            "pets",
            "--output",
            str(self.root / "Data.lua"),
            "--reset-cache",
        ]
        with patch.object(refresh_data, "GENERATED_DIR", self.root):
            with patch.object(refresh_data, "MANIFEST_PATH", self.manifest_path):
                with patch.object(refresh_data, "SourceCache", side_effect=cache_factory):
                    with patch.object(refresh_data, "generate_pets", side_effect=generate_pets_in_temp):
                        with patch("sys.argv", argv):
                            exit_code = refresh_data.main()

        self.assertEqual(exit_code, 0)
        self.assertEqual(len(created_caches), 1)
        self.assertTrue(created_caches[0].reset_called)
        self.assertTrue(self.manifest_path.exists())
        self.assertIn("Loque'nahak", (self.root / "Data.lua").read_text(encoding="utf-8"))
        self.assertIn(pets_index_html(), cached.path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
