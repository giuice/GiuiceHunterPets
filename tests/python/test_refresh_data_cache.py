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
