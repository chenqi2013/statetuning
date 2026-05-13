#!/usr/bin/env python3
"""Parse lib/l10n/app_translations.dart and emit locale JSON for PySide app."""

from __future__ import annotations

import json
import re
from pathlib import Path


def _parse_string(s: str, i: int) -> tuple[str, int]:
    if i >= len(s) or s[i] != "'":
        raise ValueError(f"expected quote at {i}")
    i += 1
    parts: list[str] = []
    while i < len(s):
        c = s[i]
        if c == "\\":
            i += 1
            if i >= len(s):
                break
            parts.append(s[i])
            i += 1
            continue
        if c == "'":
            return "".join(parts), i + 1
        parts.append(c)
        i += 1
    raise ValueError("unterminated string")


def _skip_ws(s: str, i: int) -> int:
    while i < len(s) and s[i] in " \t\n\r":
        i += 1
    return i


def _parse_raw_string(body: str, i: int) -> tuple[str, int]:
    """Dart raw string r'...' — backslashes are literal, only ' ends the string."""
    if i + 1 >= len(body) or body[i] != "r" or body[i + 1] != "'":
        raise ValueError("expected r'")
    i += 2
    start = i
    while i < len(body) and body[i] != "'":
        i += 1
    if i >= len(body):
        raise ValueError("unterminated raw string")
    return body[start:i], i + 1


def _parse_string_concat(body: str, i: int) -> tuple[str, int]:
    """Dart allows adjacent '...' '...' or r'..' '..' to concatenate."""
    parts: list[str] = []
    while True:
        i = _skip_ws(body, i)
        if i >= len(body):
            break
        if body[i] == "'":
            chunk, i = _parse_string(body, i)
            parts.append(chunk)
        elif i + 1 < len(body) and body[i] == "r" and body[i + 1] == "'":
            chunk, i = _parse_raw_string(body, i)
            parts.append(chunk)
        else:
            break
    if not parts:
        raise ValueError(f"expected string at {i}")
    return "".join(parts), i


def _strip_line_comments(body: str) -> str:
    """Remove full-line // comments (Dart maps may include section comments)."""
    lines_out: list[str] = []
    for line in body.splitlines():
        if line.strip().startswith("//"):
            continue
        lines_out.append(line)
    return "\n".join(lines_out)


def parse_map_body(body: str) -> dict[str, str]:
    body = _strip_line_comments(body)
    out: dict[str, str] = {}
    i = _skip_ws(body, 0)
    while i < len(body):
        if body[i] == "}":
            break
        key, i = _parse_string(body, i)
        i = _skip_ws(body, i)
        if i >= len(body) or body[i] != ":":
            raise ValueError(f"expected : after key {key!r} at {i}")
        i = _skip_ws(body, i + 1)
        val, i = _parse_string_concat(body, i)
        out[key] = val
        i = _skip_ws(body, i)
        if i < len(body) and body[i] == ",":
            i += 1
        i = _skip_ws(body, i)
    return out


def extract_map(text: str, name: str) -> str:
    pat = rf"const Map<String, String> {name} = \{{\n"
    m = re.search(pat, text)
    if not m:
        raise SystemExit(f"map {name} not found")
    start = m.end()
    depth = 1
    i = start
    while i < len(text) and depth:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    return text[start : i - 1]


def main() -> None:
    root = Path(__file__).resolve().parents[2]
    dart = root / "lib" / "l10n" / "app_translations.dart"
    text = dart.read_text(encoding="utf-8")
    en = parse_map_body(extract_map(text, "_enUs"))
    zhcn = parse_map_body(extract_map(text, "_zhCn"))
    zhtw = parse_map_body(extract_map(text, "_zhTw"))
    out = {
        "en_US": en,
        "zh_CN": zhcn,
        "zh_TW": zhtw,
    }
    dest = Path(__file__).resolve().parent.parent / "locale" / "messages.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {dest} ({len(en)} keys per locale)")


if __name__ == "__main__":
    main()
