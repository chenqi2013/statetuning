"""Load translations and resolve locale (mirrors Flutter app_locale + locale_prefs)."""

from __future__ import annotations

import json
from pathlib import Path

from PySide6.QtCore import QLocale, QSettings

LOCALES = ("en_US", "zh_CN", "zh_TW")
_FALLBACK = "en_US"

_MESSAGES: dict[str, dict[str, str]] | None = None


def _bundle_root() -> Path:
    return Path(__file__).resolve().parent


def load_messages() -> None:
    global _MESSAGES
    p = _bundle_root() / "locale" / "messages.json"
    if not p.exists():
        raise FileNotFoundError(f"Run tools/extract_translations.py — missing {p}")
    raw = json.loads(p.read_text(encoding="utf-8"))
    _MESSAGES = {k: v for k, v in raw.items() if isinstance(v, dict)}


def _table(locale_id: str) -> dict[str, str]:
    if _MESSAGES is None:
        load_messages()
    assert _MESSAGES is not None
    return _MESSAGES.get(locale_id) or _MESSAGES[_FALLBACK]


def resolve_locale_from_system(ql: QLocale | None) -> str:
    if ql is None:
        return _FALLBACK
    # Qt6: language() is QLocale.Language enum; use BCP-47 tag like Flutter locale tags.
    tag = (ql.bcp47Name() or "").lower()
    if not tag.startswith("zh"):
        return _FALLBACK
    if "tw" in tag or "hk" in tag or "mo" in tag or "hant" in tag:
        return "zh_TW"
    return "zh_CN"


def load_saved_locale() -> str | None:
    s = QSettings()
    v = s.value("ui/locale", "")
    if not v or not isinstance(v, str):
        return None
    return v if v in LOCALES else None


def save_locale(locale_id: str) -> None:
    QSettings().setValue("ui/locale", locale_id)


def current_locale() -> str:
    s = QSettings()
    v = s.value("ui/locale", "")
    if isinstance(v, str) and v in LOCALES:
        return v
    return resolve_locale_from_system(QLocale.system())


def set_locale(locale_id: str) -> None:
    if locale_id not in LOCALES:
        locale_id = _FALLBACK
    save_locale(locale_id)


def tr(key: str, locale_id: str | None = None, **params: str) -> str:
    loc = locale_id or current_locale()
    s = _table(loc).get(key)
    if s is None:
        s = _table(_FALLBACK).get(key, key)
    for name, val in params.items():
        s = s.replace(f"@{name}", str(val))
    return s
