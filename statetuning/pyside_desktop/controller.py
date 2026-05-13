"""State and actions for State-Tuning Studio (ported from lib/home_controller.dart)."""

from __future__ import annotations

import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import zipfile
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Any, Dict, List, Optional

from PySide6.QtCore import QObject, QProcess, QProcessEnvironment, QTimer, Signal

from . import i18n

kCustomPresetLabel = "__custom__"


class TrainingPrecision(str, Enum):
    bf16 = "bf16"
    fp16 = "fp16"
    fp32 = "fp32"


@dataclass
class Rwkv7Preset:
    label: str
    n_embd: int
    n_layer: int


UTF8_ALLOW = "utf-8"
_WINGET_UPDATE_NOT_APPLICABLE = -1978335189

_ENV_PACKAGES = [
    "torch>=2.0.0",
    "transformers>=4.30.0",
    "tqdm>=4.65.0",
    "huggingface-hub",
    "ninja",
    "einops",
]
_ENV_CHECK_PACKAGES = [
    "torch",
    "transformers",
    "tqdm",
    "huggingface_hub",
    "ninja",
    "einops",
]


def project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def asset_zip_path() -> Path:
    return project_root() / "assets" / "statetuning_repo.zip"


def is_windows() -> bool:
    return platform.system() == "Windows"


def tr(key: str, **params: str) -> str:
    return i18n.tr(key, **params)


def _run_bg(fn, *args, **kwargs) -> None:
    """Run *fn* in a daemon thread so the Qt event loop stays responsive."""
    t = threading.Thread(target=fn, args=args, kwargs=kwargs, daemon=True)
    t.start()


class HomeController(QObject):
    """Central UI state + training/environment actions."""

    changed = Signal()
    toast = Signal(str, str)  # title, message

    def __init__(self) -> None:
        super().__init__()
        self.current_tab_index = 0

        self.gpu_info = tr("gpu_detecting")
        self.status = tr("status_idle")

        self.presets: List[Rwkv7Preset] = [
            Rwkv7Preset("RWKV7-0.1B", 768, 12),
            Rwkv7Preset("RWKV7-0.4B", 1024, 24),
            Rwkv7Preset("RWKV7-1.5B", 2048, 24),
            Rwkv7Preset("RWKV7-3B", 2560, 32),
            Rwkv7Preset("RWKV7-7B", 4096, 32),
            Rwkv7Preset(kCustomPresetLabel, 0, 0),
        ]
        self.selected_preset = "RWKV7-0.4B"

        self.vocab_size = 65536
        self.n_embd = 1024
        self.n_layer = 24
        self.ctx_len = 512

        self.model_path = ""
        self.data_path = ""
        self.output_dir = "./outmodel"
        self.repo_path = ""

        self.precision = TrainingPrecision.bf16
        self.batch_size = 4
        self.num_steps = 1000
        self.num_epochs = 1
        self.learning_rate = "1e-5"

        self.cuda_home = ""
        self.cuda_detect_log = ""
        self.cuda_installed = False
        self.is_cuda_installing = False
        self.cuda_install_log = ""

        self.is_training = False
        self.training_log = ""
        self._loss_map: Dict[int, float] = {}
        self._loss_written_steps: set[int] = set()
        self.loss_history: List[float] = []
        self._loss_log_file_name = "loss_log.txt"
        self._train_loss_file_name = "train_loss.jsonl"
        self._loss_log_path: Optional[str] = None

        self._proc: Optional[QProcess] = None
        self._log_lines: List[str] = []
        self._log_current_line = ""
        self._loss_parse_buffer = ""
        self._log_flush_timer: Optional[QTimer] = None

        self.is_cloning_repo = False
        self.repo_log = ""
        self.repo_cloned = False

        self.winget_installed = False
        self.nvidia_driver_installed = False
        self._winget_dir_for_path: Optional[str] = None

        self.output_files: List[str] = []

        self.is_installing = False
        self.is_detecting_model = False
        self.install_log = ""
        self.is_checking = False
        self.env_ready = False
        self.check_log = ""
        self._has_guided_to_settings = False

        # Test tab — no rwkv_mobile on desktop
        self.test_model_path = ""
        self.test_tokenizer_path = ""
        self.test_state_path = ""
        self.is_rwkv_loading = False
        self.is_rwkv_generating = False
        self.rwkv_status = tr("rwkv_status_uninit")
        self.rwkv_test_log = ""
        self.rwkv_messages: List[Dict[str, str]] = []

        self.uv_installed = False
        self.is_uv_installing = False
        self.uv_install_log = ""

        self.python_installed = False
        self.is_build_tools_installing = False
        self.build_tools_log = ""
        self.ninja_on_path = False
        self.msvc_cl_on_path = False
        self.build_tools_fully_ready = False

        self._model_detect_timer: Optional[QTimer] = None

        self._log_flush_timer = QTimer(self)
        self._log_flush_timer.setInterval(800)
        self._log_flush_timer.timeout.connect(self._flush_log_display)

    def _emit(self) -> None:
        self.changed.emit()

    def _toast(self, title: str, msg: str) -> None:
        self.toast.emit(title, msg)

    def set_tab_index(self, idx: int) -> None:
        self.current_tab_index = idx
        # Tab order matches Flutter: … 4=Export 5=Settings 6=Test
        if idx == 5:
            self.detect_winget()
            self.detect_nvidia_driver()
            self.detect_uv()
            if not self.is_checking:
                self.check_environment()
            self.detect_cuda_home()
        if idx == 6 and is_windows():
            self.detect_build_tools()
        self._emit()

    def set_precision(self, p: TrainingPrecision) -> None:
        self.precision = p
        self._emit()

    @property
    def precision_string(self) -> str:
        return self.precision.value

    def _venv_python_path(self) -> Optional[Path]:
        if not self.repo_path:
            return None
        r = Path(self.repo_path)
        if is_windows():
            p = r / "python_venv" / "Scripts" / "python.exe"
        else:
            p = r / "python_venv" / "bin" / "python"
        return p if p.exists() else None

    def _env_with_torch_runtime(self) -> Dict[str, str]:
        env = dict(os.environ)
        vpy = self._venv_python_path()
        if vpy is None or not self.repo_path:
            return env
        sep = os.pathsep
        r = Path(self.repo_path)
        if is_windows():
            venv_scripts = str(r / "python_venv" / "Scripts")
            torch_lib = str(
                r / "python_venv" / "Lib" / "site-packages" / "torch" / "lib"
            )
        else:
            venv_scripts = str(r / "python_venv" / "bin")
            torch_lib = str(
                r / "python_venv" / "lib" / "site-packages" / "torch" / "lib"
            )
        env["PATH"] = venv_scripts + sep + torch_lib + sep + env.get("PATH", "")
        if self.cuda_home:
            cuda_bin = str(Path(self.cuda_home) / "bin")
            env["PATH"] = cuda_bin + sep + env["PATH"]
        return env

    def _resolved_output_dir(self) -> str:
        od = self.output_dir.strip()
        if od.startswith("./") or od == ".":
            return str(Path(self.repo_path) / od)
        return od

    # --- locale refresh (call when UI language changes) ---
    def reload_strings(self) -> None:
        self._emit()

    # --- GPU ---
    def _detect_gpu(self) -> None:
        vpy = self._venv_python_path()
        py = str(vpy) if vpy else "python3"
        try:
            r = subprocess.run(
                [
                    py,
                    "-c",
                    "import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'No CUDA GPU')",
                ],
                cwd=self.repo_path or None,
                env=self._env_with_torch_runtime(),
                capture_output=True,
                text=True,
                timeout=60,
            )
            if r.returncode == 0:
                out = (r.stdout or "").strip()
                self.gpu_info = out or tr("gpu_none")
            else:
                self.gpu_info = tr("gpu_not_found")
        except Exception:
            self.gpu_info = tr("gpu_not_found")
        self._emit()

    # --- CUDA ---
    def _set_cuda_home(self, path: str) -> None:
        self.cuda_home = path
        self.cuda_installed = True

    def detect_cuda_home(self) -> None:
        _run_bg(self._detect_cuda_home_bg)

    def _detect_cuda_home_bg(self) -> None:
        self.cuda_detect_log = tr("log_cuda_detect_start")
        env_cuda = os.environ.get("CUDA_HOME") or os.environ.get("CUDA_PATH")
        if env_cuda:
            nvcc = Path(env_cuda) / "bin" / ("nvcc.exe" if is_windows() else "nvcc")
            if nvcc.exists():
                self._set_cuda_home(env_cuda)
                self.cuda_detect_log += tr("log_cuda_found_env", path=env_cuda)
                self._emit()
                return
        if is_windows():
            roots = [
                r"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA",
                r"C:\CUDA",
            ]
            for root in roots:
                d = Path(root)
                if not d.is_dir():
                    continue
                versions = sorted([p for p in d.iterdir() if p.is_dir()], key=lambda p: p.name)
                if not versions:
                    continue
                for latest in reversed(versions):
                    nvcc = latest / "bin" / "nvcc.exe"
                    if nvcc.exists():
                        self._set_cuda_home(str(latest))
                        self.cuda_detect_log += tr("log_cuda_found_auto", path=str(latest))
                        self._emit()
                        return
        try:
            cmd = "where" if is_windows() else "which"
            r = subprocess.run(
                [cmd, "nvcc"],
                capture_output=True,
                text=True,
                shell=is_windows(),
            )
            if r.returncode == 0:
                line = (r.stdout or "").strip().splitlines()[0].strip()
                home = str(Path(line).parent.parent)
                self._set_cuda_home(home)
                self.cuda_detect_log += tr("log_cuda_found_nvcc", path=home)
                self._emit()
                return
        except Exception:
            pass
        self.cuda_detect_log += tr("log_cuda_not_found")
        self.cuda_installed = bool(self.cuda_home)
        self._emit()

    def pick_cuda_home_dir(self, path: str) -> None:
        if path:
            self._set_cuda_home(path)
            self.cuda_detect_log += tr("log_cuda_manual_set", path=path)
            self._emit()

    def _get_cuda_wheel_tag(self) -> str:
        home = self.cuda_home
        if not home:
            return "cu128"
        for seg in reversed(Path(home).as_posix().split("/")):
            m = re.match(r"^[vV]?(\d+)\.(\d+)", seg)
            if m:
                major, minor = int(m.group(1)), int(m.group(2))
                if major == 12:
                    if minor <= 1:
                        return "cu121"
                    if minor <= 4:
                        return "cu124"
                    if minor <= 6:
                        return "cu126"
                    if minor <= 8:
                        return "cu128"
                    return "cu128"
                if major >= 13:
                    return "cu130"
        return "cu128"

    # --- winget / uv / nvidia ---
    def _env_with_path_prepend(self, d: str) -> Dict[str, str]:
        env = dict(os.environ)
        sep = os.pathsep
        env["PATH"] = d + sep + env.get("PATH", "")
        return env

    def _env_for_winget(self) -> Dict[str, str]:
        if self._winget_dir_for_path:
            return self._env_with_path_prepend(self._winget_dir_for_path)
        return dict(os.environ)

    def detect_winget(self) -> None:
        _run_bg(self._detect_winget_bg)

    def _detect_winget_bg(self) -> None:
        if not is_windows():
            self.winget_installed = False
            self._winget_dir_for_path = None
            self._emit()
            return
        self._winget_dir_for_path = None
        try:
            r = subprocess.run(
                ["winget", "--version"],
                capture_output=True,
                text=True,
                shell=True,
            )
            if r.returncode == 0:
                self.winget_installed = True
                self._emit()
                return
        except Exception:
            pass
        # common paths (simplified from Dart)
        candidates: List[str] = []
        lad = os.environ.get("LOCALAPPDATA", "")
        if lad:
            wa = Path(lad) / "Microsoft" / "WindowsApps"
            if (wa / "winget.exe").exists():
                candidates.append(str(wa))
        for d in candidates:
            r = subprocess.run(
                ["winget", "--version"],
                capture_output=True,
                text=True,
                shell=True,
                env=self._env_with_path_prepend(d),
            )
            if r.returncode == 0:
                self._winget_dir_for_path = d
                self.winget_installed = True
                self._emit()
                return
        self.winget_installed = False
        self._emit()

    def detect_nvidia_driver(self) -> None:
        _run_bg(self._detect_nvidia_driver_bg)

    def _detect_nvidia_driver_bg(self) -> None:
        try:
            r = subprocess.run(
                ["nvidia-smi"],
                capture_output=True,
                text=True,
                timeout=20,
            )
            self.nvidia_driver_installed = r.returncode == 0
        except Exception:
            self.nvidia_driver_installed = False
        self._emit()

    def detect_uv(self) -> None:
        _run_bg(self._detect_uv_bg)

    def _detect_uv_bg(self) -> None:
        try:
            r = subprocess.run(
                ["uv", "--version"],
                capture_output=True,
                text=True,
            )
            self.uv_installed = r.returncode == 0
        except Exception:
            self.uv_installed = False
        self._emit()

    def open_url(self, url: str) -> None:
        import urllib.request

        try:
            if platform.system() == "Darwin":
                subprocess.run(["open", url], check=False)
            elif platform.system() == "Windows":
                os.startfile(url)  # type: ignore[attr-defined]
            else:
                subprocess.run(["xdg-open", url], check=False)
        except Exception:
            pass

    # --- repo ---
    def _default_repo_path(self) -> Path:
        # script run: bundle beside project / statetuning_repo
        return project_root() / "statetuning_repo"

    def check_repo(self) -> None:
        if not self.repo_path:
            self._toast(tr("tip"), tr("snackbar_pick_repo_first"))
            return
        train = Path(self.repo_path) / "train.py"
        if train.is_file():
            self.repo_cloned = True
            self.repo_log = tr("log_repo_ready", path=self.repo_path)
            self.detect_build_tools()
        else:
            self.repo_cloned = False
            self.repo_log = tr("log_repo_no_train_py")
        self._emit()

    def extract_bundle_to(self, target: str) -> None:
        zip_path = asset_zip_path()
        if not zip_path.is_file():
            self.repo_log += tr("log_repo_error", e=f"missing {zip_path}")
            self._emit()
            return
        self.repo_cloned = False
        self.repo_log = tr("log_repo_extracting", path=target)
        self._emit()
        try:
            tdir = Path(target)
            tdir.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(zip_path, "r") as zf:
                zf.extractall(tdir)
            self.repo_log += tr("log_repo_ready_done")
            self.repo_cloned = True
            self.check_repo()
        except Exception as e:
            self.repo_log += tr("log_repo_error", e=str(e))
        self._emit()

    def ensure_repo_extracted(self) -> None:
        _run_bg(self._ensure_repo_extracted_bg)

    def _ensure_repo_extracted_bg(self) -> None:
        self.is_cloning_repo = True
        self._emit()
        try:
            dp = self._default_repo_path()
            if (dp / "train.py").is_file():
                self.repo_path = str(dp)
                self.repo_cloned = True
                self.repo_log = tr("log_repo_ready", path=str(dp))
                self.detect_build_tools()
            else:
                self.repo_path = str(dp)
                self.extract_bundle_to(str(dp))
        finally:
            self.is_cloning_repo = False
            self._emit()

    # --- model preset ---
    def apply_preset(self, label: str) -> None:
        self.selected_preset = label
        for p in self.presets:
            if p.label == label and p.n_embd > 0:
                self.n_embd = p.n_embd
                self.n_layer = p.n_layer
                break
        self._emit()

    def auto_detect_model_shape(self, pth_path: str) -> None:
        if self.is_detecting_model:
            return
        if not Path(pth_path).is_file():
            return
        self.is_detecting_model = True
        self._emit()
        _run_bg(self._auto_detect_model_shape_bg, pth_path)

    def _auto_detect_model_shape_bg(self, pth_path: str) -> None:
        """Background worker; sets self.is_detecting_model = False when done."""
        py = self._venv_python_path()
        exe = str(py) if py else sys.executable
        script = (
            "import torch, re, sys\n"
            "path = sys.argv[1]\n"
            "try:\n"
            "    ckpt = torch.load(path, map_location='cpu', weights_only=True)\n"
            "except Exception:\n"
            "    ckpt = torch.load(path, map_location='cpu', weights_only=False)\n"
            'n_embd = ckpt["head.weight"].shape[1] if "head.weight" in ckpt else -1\n'
            'vocab  = ckpt["head.weight"].shape[0] if "head.weight" in ckpt else -1\n'
            "layers = max(\n"
            '    (int(re.match(r"blocks\\.(\\d+)\\.", k).group(1)) for k in ckpt if re.match(r"blocks\\.(\\d+)\\.", k)),\n'
            "    default=-1\n"
            ") + 1\n"
            'print(f"{n_embd},{vocab},{layers}")\n'
        )
        try:
            with tempfile.NamedTemporaryFile(
                "w", suffix=".py", delete=False, encoding="utf-8"
            ) as tf:
                tf.write(script)
                sp = tf.name
            r = subprocess.run(
                [exe, "-X", "utf8", sp, pth_path],
                capture_output=True,
                text=True,
                timeout=120,
            )
            os.unlink(sp)
            if r.returncode != 0:
                err = (r.stderr or r.stdout or "").strip()
                self._toast(
                    tr("snackbar_model_shape_fail"),
                    err or tr("snackbar_model_cannot_read"),
                )
                return
            parts = (r.stdout or "").strip().split(",")
            if len(parts) < 3:
                return
            de, dv, dl = (int(x) if x.strip().lstrip("-").isdigit() else -1 for x in parts[:3])
            if de > 0:
                self.n_embd = de
            if dv > 0:
                self.vocab_size = dv
            if dl > 0:
                self.n_layer = dl
            if de > 0 or dv > 0 or dl > 0:
                self.selected_preset = kCustomPresetLabel
                self._toast(
                    tr("snackbar_model_shape_ok"),
                    tr("snackbar_model_shape_ok_detail", e=str(de), l=str(dl), v=str(dv)),
                )
        except Exception as e:
            self._toast(tr("snackbar_model_shape_error"), str(e))
        finally:
            self.is_detecting_model = False
            self._emit()

    def schedule_model_detect(self, path: str) -> None:
        if self._model_detect_timer:
            self._model_detect_timer.stop()
        if not path.lower().endswith(".pth"):
            return
        self._model_detect_timer = QTimer(self)
        self._model_detect_timer.setSingleShot(True)

        def fire() -> None:
            self.auto_detect_model_shape(path)

        self._model_detect_timer.timeout.connect(fire)
        self._model_detect_timer.start(800)

    # --- training ---
    def _append_log_data(self, data: str) -> None:
        for i, ch in enumerate(data):
            if ch == "\r":
                if i + 1 < len(data) and data[i + 1] == "\n":
                    self._log_lines.append(self._log_current_line)
                    self._log_current_line = ""
                else:
                    self._log_current_line = ""
            elif ch == "\n":
                self._log_lines.append(self._log_current_line)
                self._log_current_line = ""
            else:
                self._log_current_line += ch

    def _build_log_display(self, extra: str = "") -> str:
        max_lines = 300
        lines = (
            self._log_lines[-max_lines:]
            if len(self._log_lines) > max_lines
            else self._log_lines
        )
        s = "\n".join(lines)
        if self._log_current_line:
            s += self._log_current_line
        return s + extra

    def _flush_log_display(self) -> None:
        new_s = self._build_log_display()
        if new_s != self.training_log:
            self.training_log = new_s
            self._emit()

    def _parse_loss(self, data: str) -> None:
        self._loss_parse_buffer += data
        if len(self._loss_parse_buffer) > 8000:
            self._loss_parse_buffer = self._loss_parse_buffer[-8000:]
        pat = re.compile(r"\|\s*(\d+)/\d+.*?loss=([\d.]+)")
        changed = False
        for m in pat.finditer(self._loss_parse_buffer):
            shown = int(m.group(1)) if m.group(1) else 0
            loss = float(m.group(2)) if m.group(2) else 0.0
            step = shown - 1 if shown > 0 else 0
            if step >= 0 and loss > 0:
                self._loss_map[step] = loss
                if step not in self._loss_written_steps:
                    self._loss_written_steps.add(step)
                    self._append_loss_line(step, loss)
                changed = True
        if changed:
            ordered = sorted(self._loss_map.items(), key=lambda x: x[0])
            self.loss_history = [v for _, v in ordered]
            self._emit()

    def _append_loss_line(self, step: int, loss: float) -> None:
        if self._loss_log_path:
            try:
                with open(self._loss_log_path, "a", encoding="utf-8") as f:
                    f.write(f"{step},{loss:.6f}\n")
            except OSError:
                pass

    def _init_loss_log(self) -> None:
        if not self.repo_path:
            return
        out = Path(self._resolved_output_dir())
        out.mkdir(parents=True, exist_ok=True)
        self._loss_log_path = str(out / self._loss_log_file_name)
        Path(self._loss_log_path).write_text("step,loss\n", encoding="utf-8")

    def start_training(self) -> None:
        if self.is_training:
            return
        if not self.repo_path:
            self._toast(tr("error"), tr("snackbar_train_set_repo"))
            return
        if not self.model_path:
            self._toast(tr("error"), tr("snackbar_train_set_model"))
            return
        if not self.data_path:
            self._toast(tr("error"), tr("snackbar_train_set_data"))
            return
        train_py = Path(self.repo_path) / "train.py"
        if not train_py.is_file():
            self._toast(tr("error"), tr("snackbar_train_no_train_py"))
            return

        self.is_training = True
        self.status = tr("status_training")
        self.training_log = ""
        self._log_lines.clear()
        self._log_current_line = ""
        self._loss_parse_buffer = ""
        self._loss_map.clear()
        self._loss_written_steps.clear()
        self.loss_history = []
        self._init_loss_log()
        self.current_tab_index = 3
        self._emit()

        vpy = self._venv_python_path()
        py = str(vpy) if vpy else ("python" if is_windows() else "python3")
        try:
            train_text = train_py.read_text(encoding="utf-8")
            supports_num_steps = "--num_steps" in train_text
        except OSError:
            supports_num_steps = False

        full_args = [
            "-u",
            "-X",
            "utf8",
            "train.py",
            "--load_model",
            self.model_path,
            "--data_path",
            self.data_path,
            "--output_dir",
            self.output_dir,
            "--vocab_size",
            str(self.vocab_size),
            "--n_embd",
            str(self.n_embd),
            "--n_layer",
            str(self.n_layer),
            "--precision",
            self.precision_string,
            "--batch_size",
            str(self.batch_size),
            "--num_epochs",
            str(self.num_epochs),
            "--learning_rate",
            self.learning_rate,
            "--ctx_len",
            str(self.ctx_len),
        ]
        if supports_num_steps:
            full_args.extend(["--num_steps", str(self.num_steps)])

        env = self._env_with_torch_runtime()
        env["VSLANG"] = "1033"
        env["TQDM_MININTERVAL"] = "0"
        env["TQDM_MINITERS"] = "1"

        intro = (
            tr("log_train_run_intro")
            + tr("log_train_cmd", cmd=f"{py} {' '.join(full_args)}")
            + (tr("log_train_vcvars_hint") if is_windows() else "")
            + (
                tr("log_train_note_num_steps_yes")
                if supports_num_steps
                else tr("log_train_note_num_steps_no")
            )
            + ("=" * 50)
            + "\n\n"
        )
        self._append_log_data(intro)
        self.training_log = self._build_log_display()
        self._emit()

        self._proc = QProcess(self)
        self._proc.setProcessChannelMode(QProcess.MergedChannels)
        qe = QProcessEnvironment.systemEnvironment()
        for k, val in env.items():
            qe.insert(k, val)
        self._proc.setProcessEnvironment(qe)
        self._proc.setWorkingDirectory(self.repo_path)
        self._proc.readyReadStandardOutput.connect(self._on_train_stdout)
        self._proc.finished.connect(self._on_train_finished)

        if is_windows():
            vc = self._find_vcvarsall()
            if vc:
                launcher = Path(self.repo_path) / "_pyside_train.cmd"
                sep_dirs = [
                    str(Path(self.cuda_home) / "bin") if self.cuda_home else "",
                    str(
                        Path(self.repo_path)
                        / "python_venv"
                        / "Lib"
                        / "site-packages"
                        / "torch"
                        / "lib"
                    ),
                    str(Path(self.repo_path) / "python_venv" / "Scripts"),
                ]
                cmd_prefix = ";".join(x for x in sep_dirs if x)
                quoted_py = f'"{py}"' if " " in py else py
                argline = " ".join(
                    a if all(c not in a for c in " \t") else f'"{a}"' for a in full_args
                )
                bat = (
                    "@echo off\r\n"
                    'set "VSLANG=1033"\r\n'
                    f'call "{vc}" x64\r\n'
                    "if errorlevel 1 exit /b %errorlevel%\r\n"
                    f'set "PATH={cmd_prefix};%PATH%"\r\n'
                    f"{quoted_py} {argline}\r\n"
                )
                launcher.write_text(bat, encoding="utf-8")
                self._append_log_data(tr("log_train_windows_launcher", path=str(launcher)))
                self.training_log = self._build_log_display()
                self._emit()
                self._proc.start(str(launcher), [])
            else:
                self._append_log_data(tr("log_train_vcvars_missing"))
                self.training_log = self._build_log_display()
                self._emit()
                self._proc.start(py, full_args)
        else:
            self._proc.start(py, full_args)

        self._log_flush_timer.start()

    def _find_vcvarsall(self) -> Optional[str]:
        if not is_windows():
            return None
        roots = [
            Path(r"C:\Program Files\Microsoft Visual Studio"),
            Path(r"C:\Program Files (x86)\Microsoft Visual Studio"),
        ]
        for root in roots:
            if not root.is_dir():
                continue
            years = sorted(root.iterdir(), key=lambda p: p.name, reverse=True)
            for y in years:
                if not y.is_dir():
                    continue
                eds = sorted(y.iterdir(), key=lambda p: p.name, reverse=True)
                for ed in eds:
                    cand = (
                        ed
                        / "VC"
                        / "Auxiliary"
                        / "Build"
                        / "vcvarsall.bat"
                    )
                    if cand.is_file():
                        return str(cand)
        return None

    def _on_train_stdout(self) -> None:
        if not self._proc:
            return
        data = bytes(self._proc.readAllStandardOutput()).decode("utf-8", errors="replace")
        self._append_log_data(data)
        self._parse_loss(data)

    def _on_train_finished(self, exit_code: int, exit_status: QProcess.ExitStatus) -> None:
        self._log_flush_timer.stop()
        suffix = (
            tr("log_train_success_footer")
            if exit_code == 0
            else tr("log_train_fail_exit", code=str(exit_code))
        )
        self._append_log_data(suffix)
        self.training_log = self._build_log_display()
        self.is_training = False
        self.status = tr("status_done" if exit_code == 0 else "status_failed")
        self._emit()
        if exit_code == 0:
            self._load_loss_jsonl()
            self._toast(tr("snackbar_train_done"), tr("snackbar_train_done_body", path=self.output_dir))
            self.refresh_output_files()
        else:
            self._toast(tr("snackbar_train_failed"), tr("snackbar_train_failed_hint"))
        self._proc = None

    def _load_loss_jsonl(self) -> None:
        path = Path(self._resolved_output_dir()) / self._train_loss_file_name
        if not path.is_file():
            return
        pts: List[tuple[int, float]] = []
        try:
            for line in path.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if not line:
                    continue
                try:
                    o = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if not isinstance(o, dict):
                    continue
                st = o.get("step", -1)
                ls = o.get("loss", -1.0)
                si = int(st) if isinstance(st, (int, float)) else -1
                lf = float(ls) if isinstance(ls, (int, float)) else -1.0
                if si >= 0 and lf >= 0:
                    pts.append((si, lf))
            pts.sort(key=lambda x: x[0])
            self._loss_map = {a: b for a, b in pts}
            self.loss_history = [b for _, b in pts]
        except OSError:
            pass
        self._emit()

    def stop_training(self) -> None:
        self._log_flush_timer.stop()
        if self._proc and self._proc.state() != QProcess.NotRunning:
            self._proc.kill()
            self._proc = None
        self._append_log_data(tr("log_train_stopped_manual"))
        self.training_log = self._build_log_display()
        self.is_training = False
        self.status = tr("status_stopped")
        self._emit()

    def refresh_output_files(self) -> None:
        od = Path(self._resolved_output_dir())
        if not od.is_dir():
            self.output_files = []
            self._emit()
            return
        self.output_files = sorted(str(p) for p in od.iterdir() if p.is_file())
        self._emit()

    def export_loss_log(self, dest_dir: str) -> None:
        src = Path(self._resolved_output_dir()) / self._train_loss_file_name
        if not self.repo_path or not src.is_file():
            self._toast(tr("tip"), tr("snackbar_export_missing_run"))
            return
        dest = Path(dest_dir) / self._train_loss_file_name
        try:
            shutil.copy2(src, dest)
            self._toast(tr("export_done"), tr("snackbar_export_copied", path=str(dest)))
        except OSError as e:
            self._toast(tr("export_failed"), str(e))

    # --- environment (abbreviated install flows; same subprocesses as Flutter) ---
    def detect_python(self) -> None:
        """Synchronous version used internally (called from bg thread)."""
        vpy = self._venv_python_path()
        if vpy:
            try:
                r = subprocess.run([str(vpy), "--version"], capture_output=True, timeout=10)
                self.python_installed = r.returncode == 0
                self._emit()
                return
            except Exception:
                pass
        try:
            r = subprocess.run(
                ["python3", "--version"],
                capture_output=True,
                timeout=10,
            )
            self.python_installed = r.returncode == 0
        except Exception:
            self.python_installed = False
        self._emit()

    def detect_build_tools(self) -> None:
        if is_windows():
            ninja_ok = False
            try:
                r = subprocess.run(
                    ["where", "ninja"],
                    capture_output=True,
                    text=True,
                    shell=True,
                )
                ninja_ok = r.returncode == 0
            except Exception:
                pass
            if not ninja_ok and self.repo_path:
                vn = Path(self.repo_path) / "python_venv" / "Scripts" / "ninja.exe"
                ninja_ok = vn.is_file()
            self.ninja_on_path = ninja_ok
            try:
                cl = subprocess.run(
                    ["where", "cl"], capture_output=True, text=True, shell=True
                )
                self.msvc_cl_on_path = cl.returncode == 0
            except Exception:
                self.msvc_cl_on_path = False
        else:
            ninja_ok = shutil.which("ninja") is not None
            if not ninja_ok and self.repo_path:
                vn = Path(self.repo_path) / "python_venv" / "bin" / "ninja"
                ninja_ok = vn.is_file()
            self.ninja_on_path = ninja_ok
            self.msvc_cl_on_path = False
        self.build_tools_fully_ready = is_windows() and self.ninja_on_path and self.msvc_cl_on_path
        self._emit()

    def check_environment(self) -> None:
        if self.is_checking:
            return
        _run_bg(self._check_environment_bg)

    def _check_environment_bg(self) -> None:
        if self.is_checking:
            return
        self.is_checking = True
        self.check_log = tr("log_env_checking")
        self.env_ready = False
        self._emit()

        self._detect_uv_bg()
        self.detect_python()
        py = self._venv_python_path()
        py_exe = str(py) if py else ("python3" if not is_windows() else "python")

        if not self.python_installed:
            self.check_log += tr("log_env_no_python")
            self._toast(tr("snackbar_env_check"), tr("snackbar_env_use_install"))
            self.is_checking = False
            self._emit()
            return

        missing: List[str] = []
        use_uv = py is not None and self.uv_installed
        for pkg in _ENV_CHECK_PACKAGES:
            pip_name = pkg.replace("_", "-")
            try:
                if use_uv:
                    r = subprocess.run(
                        ["uv", "pip", "show", "--python", str(py), pip_name],
                        capture_output=True,
                        text=True,
                    )
                else:
                    r = subprocess.run(
                        [py_exe, "-m", "pip", "show", pkg],
                        capture_output=True,
                        text=True,
                    )
                if r.returncode != 0:
                    missing.append(pkg)
                    self.check_log += tr("log_env_pkg_missing", pkg=pkg)
                else:
                    self.check_log += tr("log_env_pkg_installed", pkg=pkg)
            except Exception:
                missing.append(pkg)

        if not missing:
            # torch cuda check
            try:
                chk = subprocess.run(
                    [
                        py_exe,
                        "-c",
                        "import torch; import sys; "
                        "sys.exit(0 if torch.cuda.is_available() else 1)",
                    ],
                    cwd=self.repo_path or None,
                    env=self._env_with_torch_runtime(),
                    capture_output=True,
                    timeout=60,
                )
                if chk.returncode != 0:
                    missing.append("torch(CUDA)")
                    self.check_log += tr("log_env_torch_no_cuda")
                else:
                    self.check_log += tr("log_env_torch_cuda_ok", detail="ok")
            except Exception:
                missing.append("torch(CUDA)")

        if not missing:
            self.env_ready = True
            self.check_log += tr("log_env_all_ready")
            self._detect_gpu()
            self._toast(tr("snackbar_env_check"), tr("snackbar_env_ready"))
        else:
            self.check_log += tr("log_env_missing_reinstall", list=",".join(missing))

        self.is_checking = False
        self.detect_build_tools()
        self._emit()

    # --- one-click install flows (mirrors Flutter's winget / uv logic) ---

    def install_uv(self) -> None:
        if not is_windows():
            self._toast(tr("tip"), tr("snackbar_windows_only_uv"))
            return
        if not self.winget_installed:
            self._toast(tr("tip"), tr("snackbar_winget_required"))
            return
        _run_bg(self._install_uv_bg)

    def _install_uv_bg(self) -> None:
        self.is_uv_installing = True
        self.uv_install_log = tr("log_uv_install_start")
        self._emit()
        try:
            r = subprocess.run(
                ["winget", "install", "--id", "astral-sh.uv", "-e", "--accept-source-agreements", "--accept-package-agreements"],
                capture_output=True, text=True, shell=True,
                env=self._env_for_winget(), timeout=300,
            )
            out = ((r.stdout or "") + (r.stderr or "")).strip()
            self.uv_install_log += "\n" + out
            if r.returncode in (0, _WINGET_UPDATE_NOT_APPLICABLE):
                self.uv_installed = True
                self.uv_install_log += "\n" + tr("log_uv_install_done")
            else:
                self.uv_install_log += "\n" + tr("log_uv_install_fail", code=str(r.returncode))
        except Exception as e:
            self.uv_install_log += "\n" + str(e)
        finally:
            self.is_uv_installing = False
            self._emit()

    def install_nvidia_driver(self) -> None:
        if not is_windows():
            self._toast(tr("tip"), tr("snackbar_windows_only_nvidia"))
            return
        if not self.winget_installed:
            self._toast(tr("tip"), tr("snackbar_winget_required"))
            return
        _run_bg(self._install_nvidia_driver_bg)

    def _install_nvidia_driver_bg(self) -> None:
        self.install_log += tr("log_nvidia_install_start")
        self._emit()
        try:
            r = subprocess.run(
                ["winget", "install", "--id", "Nvidia.GeForceExperience", "-e",
                 "--accept-source-agreements", "--accept-package-agreements"],
                capture_output=True, text=True, shell=True,
                env=self._env_for_winget(), timeout=600,
            )
            out = ((r.stdout or "") + (r.stderr or "")).strip()
            self.install_log += "\n" + out
            if r.returncode in (0, _WINGET_UPDATE_NOT_APPLICABLE):
                self.nvidia_driver_installed = True
                self.install_log += "\n" + tr("log_nvidia_install_done")
            else:
                self.install_log += "\n" + tr("log_nvidia_install_fail", code=str(r.returncode))
        except Exception as e:
            self.install_log += "\n" + str(e)
        self._emit()

    def install_cuda_winget(self) -> None:
        if not is_windows():
            self._toast(tr("tip"), tr("snackbar_windows_only_cuda"))
            return
        if not self.winget_installed:
            self._toast(tr("tip"), tr("snackbar_winget_required"))
            return
        _run_bg(self._install_cuda_winget_bg)

    def _install_cuda_winget_bg(self) -> None:
        self.is_cuda_installing = True
        self.cuda_install_log = tr("log_cuda_install_start")
        self._emit()
        try:
            r = subprocess.run(
                ["winget", "install", "--id", "Nvidia.CUDA", "-e",
                 "--accept-source-agreements", "--accept-package-agreements"],
                capture_output=True, text=True, shell=True,
                env=self._env_for_winget(), timeout=600,
            )
            out = ((r.stdout or "") + (r.stderr or "")).strip()
            self.cuda_install_log += "\n" + out
            if r.returncode in (0, _WINGET_UPDATE_NOT_APPLICABLE):
                self.cuda_installed = True
                self.cuda_install_log += "\n" + tr("log_cuda_install_done")
                self._detect_cuda_home_bg()
            else:
                self.cuda_install_log += "\n" + tr("log_cuda_install_fail", code=str(r.returncode))
        except Exception as e:
            self.cuda_install_log += "\n" + str(e)
        finally:
            self.is_cuda_installing = False
            self._emit()

    def install_environment(self) -> None:
        if not self.repo_path:
            self._toast(tr("tip"), tr("snackbar_wait_repo"))
            return
        _run_bg(self._install_environment_bg)

    def _install_environment_bg(self) -> None:
        """Install torch + deps into python_venv via uv or pip."""
        self.is_installing = True
        self.install_log = tr("log_env_install_start")
        self._emit()
        try:
            vpy = self._venv_python_path()
            use_uv = vpy is not None and self.uv_installed
            rp = Path(self.repo_path)
            venv_dir = rp / "python_venv"
            # create venv if missing
            if not vpy:
                if self.uv_installed:
                    subprocess.run(["uv", "venv", str(venv_dir)], capture_output=True)
                else:
                    subprocess.run([sys.executable, "-m", "venv", str(venv_dir)], capture_output=True)
                vpy = self._venv_python_path()
                if vpy is None:
                    self.install_log += "\n" + tr("log_env_venv_fail")
                    self.is_installing = False
                    self._emit()
                    return

            cuda_tag = self._get_cuda_wheel_tag()
            torch_index = f"https://download.pytorch.org/whl/{cuda_tag}"
            pkgs = list(_ENV_PACKAGES) + [f"torch --index-url {torch_index}"]

            for pkg in pkgs:
                self.install_log += "\n" + tr("log_env_installing_pkg", pkg=pkg.split()[0])
                self._emit()
                if use_uv:
                    cmd = ["uv", "pip", "install", "--python", str(vpy)] + pkg.split()
                else:
                    cmd = [str(vpy), "-m", "pip", "install"] + pkg.split()
                r = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
                out = ((r.stdout or "") + (r.stderr or "")).strip()
                if r.returncode != 0:
                    self.install_log += "\n" + out[-500:]
                else:
                    self.install_log += " ✓"
                self._emit()

            self.install_log += "\n" + tr("log_env_install_done")
            self._check_environment_bg()
        except Exception as e:
            self.install_log += "\n" + str(e)
        finally:
            self.is_installing = False
            self._emit()

    def install_build_tools(self) -> None:
        if not is_windows():
            self._toast(tr("tip"), "Build tools (MSVC + ninja) are only required on Windows.")
            return
        if not self.winget_installed:
            self._toast(tr("tip"), tr("snackbar_winget_required"))
            return
        _run_bg(self._install_build_tools_bg)

    def _install_build_tools_bg(self) -> None:
        self.is_build_tools_installing = True
        self.build_tools_log = tr("log_buildtools_install_start")
        self._emit()
        pkgs = [
            ("Microsoft.VisualStudio.2022.BuildTools", "MSVC Build Tools"),
            ("Ninja-build.Ninja", "Ninja"),
        ]
        try:
            for pkg_id, name in pkgs:
                self.build_tools_log += f"\nInstalling {name}…"
                self._emit()
                r = subprocess.run(
                    ["winget", "install", "--id", pkg_id, "-e",
                     "--accept-source-agreements", "--accept-package-agreements"],
                    capture_output=True, text=True, shell=True,
                    env=self._env_for_winget(), timeout=900,
                )
                out = ((r.stdout or "") + (r.stderr or "")).strip()
                self.build_tools_log += "\n" + out[-300:]
                if r.returncode in (0, _WINGET_UPDATE_NOT_APPLICABLE):
                    self.build_tools_log += f"\n{name} installed ✓"
                else:
                    self.build_tools_log += f"\n{name} failed (code={r.returncode})"
                self._emit()
            self.detect_build_tools()
        except Exception as e:
            self.build_tools_log += "\n" + str(e)
        finally:
            self.is_build_tools_installing = False
            self._emit()

    # --- RWKV test (placeholder) ---
    def load_rwkv_test_model(self) -> None:
        self._toast(tr("tip"), "RWKV chat test: use Flutter build or Python CLI; not bundled in PySide.")

    def clear_rwkv_chat(self) -> None:
        self.rwkv_messages.clear()
        self.rwkv_test_log = ""
        self._emit()

    def send_rwkv_prompt(self) -> None:
        pass
