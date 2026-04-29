from __future__ import annotations

import hashlib
import json
import shutil
import tempfile
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
            return self.read_text(normalized_url, role)

        self.cache_dir.mkdir(parents=True, exist_ok=True)
        try:
            text = self.fetcher(normalized_url)
        except Exception as error:
            self._record_error(normalized_url, role, cache_key, str(error))
            raise SourceFetchError(normalized_url, role, error) from error

        self._write_text_atomic(path, text)
        self._record_ok(normalized_url, role, cache_key, path)
        return SourceResult(
            url=normalized_url,
            role=role,
            cache_key=cache_key,
            path=path,
            text=text,
            from_cache=False,
        )

    def has_text(self, url: str) -> bool:
        return self.path_for(url).exists()

    def read_text(self, url: str, role: str) -> SourceResult:
        normalized_url = self._normalize_url(url)
        cache_key = self._cache_key(normalized_url)
        path = self.cache_dir / f"{cache_key}.html"
        if not path.exists():
            raise SourceFetchError(
                normalized_url,
                role,
                FileNotFoundError(f"missing cached source: {normalized_url}"),
            )
        return SourceResult(
            url=normalized_url,
            role=role,
            cache_key=cache_key,
            path=path,
            text=path.read_text(encoding="utf-8"),
            from_cache=True,
        )

    def store_text(self, url: str, role: str, text: str) -> SourceResult:
        normalized_url = self._normalize_url(url)
        cache_key = self._cache_key(normalized_url)
        path = self.cache_dir / f"{cache_key}.html"
        self._write_text_atomic(path, text)
        self._record_ok(normalized_url, role, cache_key, path)
        return SourceResult(
            url=normalized_url,
            role=role,
            cache_key=cache_key,
            path=path,
            text=text,
            from_cache=False,
        )

    def invalidate(self, url: str, role: str, error: str) -> None:
        self.record_semantic_error(url, role, "parse_error", error)

    def record_semantic_error(self, url: str, role: str, status: str, error: str) -> None:
        normalized_url = self._normalize_url(url)
        cache_key = self._cache_key(normalized_url)
        path = self.path_for(normalized_url)
        self._record_error(
            normalized_url,
            role,
            cache_key,
            error,
            status=status,
            path=path if path.exists() else None,
        )

    def path_for(self, url: str) -> Path:
        normalized_url = self._normalize_url(url)
        return self.cache_dir / f"{self._cache_key(normalized_url)}.html"

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

    def _record_error(
        self,
        url: str,
        role: str,
        cache_key: str,
        error: str,
        status: str = "error",
        path: Path | None = None,
    ) -> None:
        with self._manifest_lock:
            manifest = self._load_manifest()
            manifest["sources"][cache_key] = {
                "url": url,
                "cache_key": cache_key,
                "role": role,
                "status": status,
                "path": str(path) if path is not None else None,
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
        self._write_text_atomic(
            self.manifest_path,
            json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        )

    def _write_text_atomic(self, path: Path, text: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        temp_path = None
        try:
            with tempfile.NamedTemporaryFile(
                "w",
                encoding="utf-8",
                dir=path.parent,
                prefix=f".{path.name}.",
                suffix=".tmp",
                delete=False,
            ) as temp_file:
                temp_file.write(text)
                temp_path = Path(temp_file.name)
            temp_path.replace(path)
        finally:
            if temp_path is not None and temp_path.exists():
                temp_path.unlink()

    def _normalize_url(self, url: str) -> str:
        return url.strip()

    def _cache_key(self, url: str) -> str:
        return hashlib.sha256(url.encode("utf-8")).hexdigest()

    def _now(self) -> str:
        return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
