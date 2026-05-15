#!/usr/bin/env python3
"""Entry: python -m pyside_desktop.main (from repo root: statetuning/statetuning)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

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


def main() -> None:
    QApplication, QLocale, Qt = _import_pyside6()
    from . import i18n
    from .main_window import MainWindow

    QApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )
    app = QApplication(sys.argv)
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
