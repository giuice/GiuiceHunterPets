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
