"""Shim entry point for launching from inside the pyside_desktop directory."""

from __future__ import annotations

import importlib
import sys
from pathlib import Path


def main() -> None:
    project_root = Path(__file__).resolve().parents[2]
    sys.path.insert(0, str(project_root))

    # Replace this shim package with the real top-level package on project_root.
    sys.modules.pop("pyside_desktop", None)
    real_main = importlib.import_module("pyside_desktop.main")
    real_main.main()


if __name__ == "__main__":
    main()
