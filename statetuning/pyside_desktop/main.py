#!/usr/bin/env python3
"""Entry point for the PySide desktop app.

Supported launches:
- python -m pyside_desktop.main   (from project root, while the folder keeps this name)
- python -m main                  (from this folder, even if the folder is renamed)
- python main.py                  (from this folder, even if the folder is renamed)
"""

from __future__ import annotations

import importlib
import subprocess
import sys
import types
from pathlib import Path


_DYNAMIC_PACKAGE = "_statetuning_desktop_app"


def _install_pyside6() -> None:
    requirements = Path(__file__).with_name("requirements.txt")
    cmd = [sys.executable, "-m", "pip", "install", "-r", str(requirements)]
    print("PySide6 is not installed. Installing pyside_desktop requirements...")
    subprocess.check_call(cmd)


def _import_pyside6():
    try:
        from PySide6.QtCore import QLocale, Qt
        from PySide6.QtWidgets import QApplication
    except ModuleNotFoundError as exc:
        if exc.name != "PySide6":
            raise
        _install_pyside6()
        from PySide6.QtCore import QLocale, Qt
        from PySide6.QtWidgets import QApplication
    return QApplication, QLocale, Qt


def _import_app_modules():
    """Import sibling modules without depending on this folder's name."""
    if __package__ not in (None, ""):
        from . import i18n
        from .main_window import MainWindow

        return i18n, MainWindow

    package = types.ModuleType(_DYNAMIC_PACKAGE)
    package.__path__ = [str(Path(__file__).resolve().parent)]  # type: ignore[attr-defined]
    package.__package__ = _DYNAMIC_PACKAGE
    sys.modules[_DYNAMIC_PACKAGE] = package
    i18n = importlib.import_module(f"{_DYNAMIC_PACKAGE}.i18n")
    main_window = importlib.import_module(f"{_DYNAMIC_PACKAGE}.main_window")
    return i18n, main_window.MainWindow


def main() -> None:
    QApplication, QLocale, Qt = _import_pyside6()
    i18n, MainWindow = _import_app_modules()

    QApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )
    app = QApplication(sys.argv)
    # macOS native style ignores much of QSS and leaves awkward grey chrome on tab bars;
    # Fusion paints widgets consistently so our dark theme applies everywhere.
    app.setStyle("Fusion")
    app.setOrganizationName("StateTuning")
    app.setApplicationName("pyside_desktop")
    i18n.load_messages()
    saved = i18n.load_saved_locale()
    i18n.set_locale(saved or i18n.resolve_locale_from_system(QLocale.system()))
    win = MainWindow()
    win.show()
    raise SystemExit(app.exec())


if __name__ == "__main__":
    main()
