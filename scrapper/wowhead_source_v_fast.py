from __future__ import annotations

import gzip
import http.client
import ssl
import urllib.parse
import zlib
from typing import Optional

from scrapper.wowhead_source import (  # noqa: F401  -- re-exported for callers
    HUNTER_PETS_URL,
    STABLE_MASTER_SEARCH_URL,
    WOWHEAD_BASE,
    extract_js_assignment,
    extract_listview_data,
    extract_mapper_data,
    npc_url,
    pet_family_url,
)

try:
    import brotli  # type: ignore
    _HAS_BROTLI = True
except ImportError:
    _HAS_BROTLI = False


_USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)
_MAX_REDIRECTS = 3


def _browser_headers(referer: Optional[str], host: str) -> dict[str, str]:
    accept_encoding = "gzip, deflate, br" if _HAS_BROTLI else "gzip, deflate"
    headers = {
        "Host": host,
        "User-Agent": _USER_AGENT,
        "Accept": (
            "text/html,application/xhtml+xml,application/xml;q=0.9,"
            "image/avif,image/webp,image/apng,*/*;q=0.8"
        ),
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": accept_encoding,
        "Upgrade-Insecure-Requests": "1",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "same-origin" if referer else "none",
        "Sec-Fetch-User": "?1",
        "Sec-Ch-Ua": '"Chromium";v="124", "Google Chrome";v="124", "Not-A.Brand";v="99"',
        "Sec-Ch-Ua-Mobile": "?0",
        "Sec-Ch-Ua-Platform": '"Linux"',
        "Connection": "keep-alive",
    }
    if referer:
        headers["Referer"] = referer
    return headers


def _decode_body(body: bytes, encoding: Optional[str]) -> str:
    if not encoding:
        return body.decode("utf-8", errors="replace")
    encoding = encoding.lower().strip()
    if encoding == "gzip":
        body = gzip.decompress(body)
    elif encoding == "deflate":
        try:
            body = zlib.decompress(body)
        except zlib.error:
            body = zlib.decompress(body, -zlib.MAX_WBITS)
    elif encoding == "br" and _HAS_BROTLI:
        body = brotli.decompress(body)
    elif encoding == "identity":
        pass
    return body.decode("utf-8", errors="replace")


class FastFetcher:
    """HTTPS fetcher with keep-alive, gzip/brotli, referer chain, and full
    Chrome-like headers. Use as a callable: text = fetcher(url, referer=...).
    """

    def __init__(self, host: str = "www.wowhead.com", timeout: int = 60):
        self.host = host
        self.timeout = timeout
        self._conn: Optional[http.client.HTTPSConnection] = None
        self._last_url: Optional[str] = None

    def __call__(self, url: str, referer: Optional[str] = None) -> str:
        if referer is None:
            referer = self._last_url
        text = self._request(url, referer, depth=0)
        self._last_url = url
        return text

    def close(self) -> None:
        if self._conn is not None:
            try:
                self._conn.close()
            except Exception:
                pass
            self._conn = None

    def _request(self, url: str, referer: Optional[str], depth: int) -> str:
        parsed = urllib.parse.urlparse(url)
        if parsed.netloc and parsed.netloc != self.host:
            raise ValueError(f"FastFetcher bound to {self.host}, got {parsed.netloc}")
        path = parsed.path or "/"
        if parsed.query:
            path += "?" + parsed.query

        last_error: Optional[Exception] = None
        for attempt in (1, 2):
            try:
                conn = self._get_connection()
                conn.request("GET", path, headers=_browser_headers(referer, self.host))
                response = conn.getresponse()
                body = response.read()
                status = response.status
                if 300 <= status < 400:
                    location = response.getheader("Location")
                    if location and depth < _MAX_REDIRECTS:
                        next_url = urllib.parse.urljoin(url, location)
                        return self._request(next_url, referer, depth + 1)
                    raise IOError(f"HTTP {status} redirect without Location for {url}")
                if status >= 400:
                    raise IOError(f"HTTP {status} {response.reason} for {url}")
                encoding = response.getheader("Content-Encoding")
                return _decode_body(body, encoding)
            except (http.client.HTTPException, ConnectionError, OSError, ssl.SSLError) as error:
                last_error = error
                self.close()  # force fresh connection on retry
        raise IOError(f"fetch failed for {url}: {last_error}") from last_error

    def _get_connection(self) -> http.client.HTTPSConnection:
        if self._conn is None:
            ctx = ssl.create_default_context()
            self._conn = http.client.HTTPSConnection(
                self.host, timeout=self.timeout, context=ctx
            )
        return self._conn


def fetch_text(url: str, timeout: int = 60, referer: Optional[str] = None) -> str:
    """Stateless drop-in replacement for wowhead_source.fetch_text.

    For best performance, use FastFetcher() directly so connections stay alive
    across calls.
    """
    parsed = urllib.parse.urlparse(url)
    fetcher = FastFetcher(host=parsed.netloc or "www.wowhead.com", timeout=timeout)
    try:
        return fetcher(url, referer=referer)
    finally:
        fetcher.close()
