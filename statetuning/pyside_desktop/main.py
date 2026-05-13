#!/usr/bin/env python3
"""Entry: python -m pyside_desktop.main (from repo root: statetuning/statetuning)."""

from __future__ import annotations

import sys

from PySide6.QtCore import QLocale, Qt
from PySide6.QtWidgets import QApplication

from . import i18n
from .main_window import MainWindow


def main() -> None:
    QApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )
    app = QApplication(sys.argv)
    i18n.load_messages()
    saved = i18n.load_saved_locale()
    i18n.set_locale(saved or i18n.resolve_locale_from_system(QLocale.system()))
    win = MainWindow()
    win.show()
    raise SystemExit(app.exec())


if __name__ == "__main__":
    main()
