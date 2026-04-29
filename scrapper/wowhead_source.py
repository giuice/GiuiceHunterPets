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
