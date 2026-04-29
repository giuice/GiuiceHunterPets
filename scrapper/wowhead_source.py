from __future__ import annotations

import json
import re
from typing import Any
from urllib.request import Request, urlopen


USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
WOWHEAD_BASE = "https://www.wowhead.com"
HUNTER_PETS_URL = f"{WOWHEAD_BASE}/hunter-pets"
STABLE_MASTER_SEARCH_URL = f"{WOWHEAD_BASE}/search?q=stable%20master"


def pet_family_url(family_id: int, slug: str | None = None) -> str:
    suffix = f"/{slug}" if slug else ""
    return f"{WOWHEAD_BASE}/pet={family_id}{suffix}"


def npc_url(npc_id: int, slug: str | None = None) -> str:
    suffix = f"/{slug}" if slug else ""
    return f"{WOWHEAD_BASE}/npc={npc_id}{suffix}"


def fetch_text(url: str, timeout: int = 60) -> str:
    request = Request(
        url,
        headers={
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "User-Agent": USER_AGENT,
        },
    )
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

    return json.loads(_quote_unquoted_property_names(text[value_start : end + 1]))


def _quote_unquoted_property_names(value_text: str) -> str:
    result = []
    in_string = False
    quote = ""
    escaped = False
    index = 0

    while index < len(value_text):
        char = value_text[index]
        if in_string:
            result.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                in_string = False
            index += 1
            continue

        if char in ("'", '"'):
            in_string = True
            quote = char
            result.append(char)
            index += 1
            continue

        if char in "{,":
            result.append(char)
            index += 1
            while index < len(value_text) and value_text[index].isspace():
                result.append(value_text[index])
                index += 1
            name_start = index
            if index < len(value_text) and (value_text[index].isalpha() or value_text[index] in "_$"):
                index += 1
                while index < len(value_text) and (value_text[index].isalnum() or value_text[index] in "_$"):
                    index += 1
                probe = index
                while probe < len(value_text) and value_text[probe].isspace():
                    probe += 1
                if probe < len(value_text) and value_text[probe] == ":":
                    result.append(f'"{value_text[name_start:index]}"')
                    continue
            result.append(value_text[name_start:index])
            continue

        result.append(char)
        index += 1

    return "".join(result)


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
