"""Main window: mirrors lib/home_page.dart layout (dark theme, tabs)."""

from __future__ import annotations

import sys

from PySide6.QtCore import Qt, QTimer
from PySide6.QtGui import QFont
from PySide6.QtWidgets import (
    QComboBox,
    QDialog,
    QDialogButtonBox,
    QFileDialog,
    QFormLayout,
    QGridLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMainWindow,
    QMessageBox,
    QPlainTextEdit,
    QPushButton,
    QScrollArea,
    QTabWidget,
    QVBoxLayout,
    QWidget,
)

from . import i18n
from .controller import HomeController, TrainingPrecision, kCustomPresetLabel


def _ss() -> str:
    return """
    QMainWindow, QWidget { background: #1a1d21; color: #e5e7eb; }
    QGroupBox { font-weight: 600; border: 1px solid #3a3f47; border-radius: 10px;
                margin-top: 10px; padding: 16px; background: #252830; }
    QGroupBox::title { subcontrol-origin: margin; left: 12px; padding: 0 6px; }
    QLineEdit, QPlainTextEdit, QComboBox {
      background: #1a1d21; border: 1px solid #3a3f47; border-radius: 8px;
      padding: 8px 12px; selection-background-color: #3b82f6;
    }
    QPushButton {
      background: #3b82f6; color: white; border: none; border-radius: 10px;
      padding: 10px 16px;
    }
    QPushButton:hover { background: #2563eb; }
    QPushButton:disabled { background: #3b82f660; color: #ffffff80; }
    QPushButton#secondary { background: #3a3f47; }
    QPushButton#green { background: #22c55e; }
    QPushButton#red { background: #ef4444; }
    QTabWidget::pane { border: 1px solid #3a3f47; border-radius: 8px; top: -1px; }
    QTabBar::tab { background: #252830; padding: 12px 22px; margin-right: 2px; }
    QTabBar::tab:selected { border-bottom: 2px solid #3b82f6; color: #fff; font-weight: 600; }
    QTabBar::tab:!selected { color: #6b7280; }
    """


def tr(k: str, **p: str) -> str:
    return i18n.tr(k, **p)


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self._ctrl = HomeController()
        self._ctrl.changed.connect(self.refresh)
        self._ctrl.toast.connect(self._on_toast)

        self.setWindowTitle(tr("app_title"))
        self.setMinimumSize(1040, 720)
        self.setStyleSheet(_ss())

        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.setContentsMargins(0, 0, 0, 0)
        root.setSpacing(0)

        self._inputs: dict[str, QLineEdit] = {}

        self._build_top_bar(root)

        self.tabs = QTabWidget()
        self.tabs.setDocumentMode(True)
        root.addWidget(self.tabs, 1)

        self._tab_model = self._wrap_scroll(self._page_model())
        self._tab_data = self._wrap_scroll(self._page_data())
        self._tab_train = self._wrap_scroll(self._page_train())
        self._tab_monitor = self._page_monitor()
        self._tab_export = self._wrap_scroll(self._page_export())
        self._tab_settings = self._wrap_scroll(self._page_settings())
        self._tab_test = self._wrap_scroll(self._page_test())

        self.tabs.addTab(self._tab_model, tr("tab_model"))
        self.tabs.addTab(self._tab_data, tr("tab_data"))
        self.tabs.addTab(self._tab_train, tr("tab_train"))
        self.tabs.addTab(self._tab_monitor, tr("tab_monitor"))
        self.tabs.addTab(self._tab_export, tr("tab_export"))
        self.tabs.addTab(self._tab_settings, tr("tab_settings"))
        self.tabs.addTab(self._tab_test, tr("tab_test"))

        self.tabs.currentChanged.connect(self._on_tab_changed)

        self._overlay = QLabel(self)
        self._overlay.setAlignment(Qt.AlignCenter)
        self._overlay.setStyleSheet("background: rgba(0,0,0,0.55); color: white; font-size: 16px;")
        self._overlay.hide()

        QTimer.singleShot(0, self._boot)
        self._sync_all_inputs_from_ctrl()
        self.refresh()

    def resizeEvent(self, e):  # noqa: N802
        super().resizeEvent(e)
        self._overlay.setGeometry(self.rect())

    def _boot(self) -> None:
        self._ctrl.ensure_repo_extracted()
        self._ctrl.detect_winget()
        self._ctrl.detect_nvidia_driver()
        self._ctrl.detect_uv()
        self._ctrl.detect_cuda_home()
        QTimer.singleShot(100, self._ctrl.check_environment)

    def _sync_all_inputs_from_ctrl(self) -> None:
        c = self._ctrl
        for attr in (
            "repo_path",
            "model_path",
            "data_path",
            "output_dir",
            "batch_size",
            "num_steps",
            "num_epochs",
            "ctx_len",
            "learning_rate",
        ):
            if attr in self._inputs:
                le = self._inputs[attr]
                v = getattr(c, attr)
                le.blockSignals(True)
                le.setText(str(v))
                le.blockSignals(False)

    def _on_tab_changed(self, idx: int) -> None:
        self._ctrl.set_tab_index(int(idx))

    def _on_toast(self, title: str, msg: str) -> None:
        QMessageBox.information(self, title, msg)

    def _update_summary_labels(self) -> None:
        if not hasattr(self, "sum_labels"):
            return
        c = self._ctrl

        def ns(x: str) -> str:
            return tr("value_not_set") if not x.strip() else x

        self.sum_labels["repo"].setText(ns(c.repo_path))
        self.sum_labels["model"].setText(ns(c.model_path))
        self.sum_labels["data"].setText(ns(c.data_path))
        self.sum_labels["out"].setText(c.output_dir)
        self.sum_labels["prec"].setText(c.precision_string.upper())
        pre = c.selected_preset
        self.sum_labels["spec"].setText(tr("preset_custom") if pre == kCustomPresetLabel else pre)
        self.sum_labels["embd"].setText(f"{c.n_embd} / {c.n_layer}")
        self.sum_labels["ctx"].setText(str(c.ctx_len))
        self.sum_labels["bse"].setText(f"{c.batch_size} / {c.num_steps} / {c.num_epochs}")
        self.sum_labels["lr"].setText(c.learning_rate)

    def _build_top_bar(self, parent_layout: QVBoxLayout) -> None:
        bar = QWidget()
        bar.setStyleSheet("background: #252830; padding: 8px 20px;")
        h = QHBoxLayout(bar)

        title = QLabel(tr("app_title"))
        title.setStyleSheet("font-size: 20px; font-weight: 600; color: white;")
        h.addWidget(title)
        h.addStretch()

        self.lang_combo = QComboBox()
        self.lang_combo.addItem("English", "en_US")
        self.lang_combo.addItem("简体中文", "zh_CN")
        self.lang_combo.addItem("繁體中文", "zh_TW")
        cur = i18n.current_locale()
        idx = max(0, self.lang_combo.findData(cur))
        self.lang_combo.setCurrentIndex(idx)
        self.lang_combo.currentIndexChanged.connect(self._on_lang)
        h.addWidget(self.lang_combo)

        self.gpu_label = QLabel()
        self.gpu_label.setStyleSheet("color: #b0b5bc; font-size: 13px;")
        self.status_label = QLabel()
        self.status_label.setStyleSheet("color: #b0b5bc; font-size: 13px;")

        h.addWidget(self.gpu_label)
        h.addWidget(self.status_label)
        parent_layout.addWidget(bar)

    def _on_lang(self) -> None:
        loc = self.lang_combo.currentData()
        if loc:
            i18n.set_locale(str(loc))
            self._ctrl.reload_strings()
            self.refresh()

    def _wrap_scroll(self, inner: QWidget) -> QWidget:
        w = QScrollArea()
        w.setWidgetResizable(True)
        w.setFrameShape(QScrollArea.NoFrame)
        w.setWidget(inner)
        return w

    def _line(self, label: str, attr: str, browse: str | None = None) -> QHBoxLayout:
        row = QHBoxLayout()
        le = QLineEdit()
        le.setPlaceholderText(label)
        self._inputs[attr] = le

        def sync(text: str) -> None:
            setattr(self._ctrl, attr, text)
            if attr == "model_path":
                self._ctrl.schedule_model_detect(text)

        le.textChanged.connect(sync)
        row.addWidget(le, 1)
        if browse:
            b = QPushButton("…")
            b.setFixedWidth(44)
            b.setObjectName("secondary")
            if browse == "file_pth":
                b.clicked.connect(self._pick_pth)
            elif browse == "file_jsonl":
                b.clicked.connect(self._pick_jsonl)
            elif browse == "dir":
                b.clicked.connect(self._pick_repo)
            elif browse == "out_dir":
                b.clicked.connect(self._pick_out)
            row.addWidget(b)
        return row

    def _page_model(self) -> QWidget:
        w = QWidget()
        v = QVBoxLayout(w)
        v.setSpacing(16)

        presets = QGroupBox(tr("model_specs_preset"))
        pv = QHBoxLayout(presets)
        self._preset_buttons = []
        for p in self._ctrl.presets:
            if p.n_embd == 0:
                lab = tr("preset_custom")
            else:
                lab = p.label
            btn = QPushButton(lab)
            btn.setCheckable(True)
            btn.setObjectName("secondary")
            btn.clicked.connect(lambda _=False, pl=p.label: self._apply_preset(pl))
            self._preset_buttons.append((p.label, btn))
            pv.addWidget(btn)
        pv.addStretch()
        v.addWidget(presets)

        fp = QGroupBox(tr("model_file_path"))
        fl = QVBoxLayout(fp)
        fl.addWidget(QLabel(tr("label_pretrained_pth")))
        fl.addLayout(self._line(tr("hint_model_path"), "model_path", "file_pth"))
        self.detect_lbl = QLabel()
        self.detect_lbl.setStyleSheet("color: #9ca3af; font-size: 13px;")
        fl.addWidget(self.detect_lbl)
        v.addWidget(fp)

        adv = QGroupBox(tr("modelargs_advanced"))
        g = QGridLayout(adv)
        g.addWidget(QLabel(tr("label_vocab_size")), 0, 0)
        self.vocab_e = QLineEdit()
        self.vocab_e.setReadOnly(True)
        g.addWidget(self.vocab_e, 0, 1)
        g.addWidget(QLabel(tr("label_n_embd")), 0, 2)
        self.n_embd_e = QLineEdit()
        self.n_embd_e.setReadOnly(True)
        g.addWidget(self.n_embd_e, 0, 3)
        g.addWidget(QLabel(tr("label_n_layer")), 1, 0)
        self.n_layer_e = QLineEdit()
        self.n_layer_e.setReadOnly(True)
        g.addWidget(self.n_layer_e, 1, 1)
        v.addWidget(adv)

        nx = QPushButton(tr("next_data_config"))
        nx.clicked.connect(lambda: self.tabs.setCurrentIndex(1))
        v.addWidget(nx)
        v.addStretch()
        return w

    def _apply_preset(self, label: str) -> None:
        self._ctrl.apply_preset(label)
        for pl, btn in self._preset_buttons:
            btn.setChecked(pl == label)
        self.refresh_model_fields()

    def refresh_model_fields(self) -> None:
        c = self._ctrl
        self.vocab_e.setText(str(c.vocab_size))
        self.n_embd_e.setText(str(c.n_embd))
        self.n_layer_e.setText(str(c.n_layer))
        self.detect_lbl.setText(tr("reading_model_dims") if c.is_detecting_model else "")

    def _pick_pth(self) -> None:
        p, _ = QFileDialog.getOpenFileName(self, tr("dialog_pick_model_pth"), "", "*.pth;;All (*)")
        if p:
            self._ctrl.model_path = p
            if "model_path" in self._inputs:
                self._inputs["model_path"].setText(p)
                self._ctrl.schedule_model_detect(p)

    def _pick_jsonl(self) -> None:
        p, _ = QFileDialog.getOpenFileName(
            self, tr("dialog_pick_train_jsonl"), "", "*.jsonl *.json;;All (*)"
        )
        if p:
            self._ctrl.data_path = p
            if "data_path" in self._inputs:
                self._inputs["data_path"].setText(p)

    def _pick_repo(self) -> None:
        p = QFileDialog.getExistingDirectory(self, tr("dialog_pick_repo"))
        if p:
            self._ctrl.repo_path = p
            if "repo_path" in self._inputs:
                self._inputs["repo_path"].setText(p)
            self._ctrl.check_repo()

    def _pick_out(self) -> None:
        p = QFileDialog.getExistingDirectory(self, tr("dialog_pick_output_dir"))
        if p:
            self._ctrl.output_dir = p
            if "output_dir" in self._inputs:
                self._inputs["output_dir"].setText(p)

    def _page_data(self) -> QWidget:
        w = QWidget()
        v = QVBoxLayout(w)
        v.addWidget(QLabel(tr("train_repo_desc")))

        repo = QGroupBox(tr("train_repo"))
        rl = QVBoxLayout(repo)
        rl.addWidget(QLabel(tr("label_repo_path")))
        rl.addLayout(self._line(tr("hint_repo_path_default"), "repo_path", "dir"))
        hb = QHBoxLayout()
        chk = QPushButton(tr("btn_check_path"))
        chk.setObjectName("secondary")
        chk.clicked.connect(self._ctrl.check_repo)
        hb.addWidget(chk)
        ex = QPushButton(tr("btn_extract_here"))
        ex.clicked.connect(lambda: self._ctrl.extract_bundle_to(self._ctrl.repo_path or ""))
        hb.addWidget(ex)
        hb.addStretch()
        rl.addLayout(hb)
        self.repo_log_view = QPlainTextEdit()
        self.repo_log_view.setReadOnly(True)
        self.repo_log_view.setMaximumHeight(120)
        self.repo_log_view.setPlaceholderText(tr("repo_log_placeholder"))
        rl.addWidget(self.repo_log_view)
        v.addWidget(repo)

        dt = QGroupBox(tr("train_data"))
        dl = QVBoxLayout(dt)
        dl.addWidget(QLabel(tr("label_jsonl_path")))
        dl.addLayout(self._line(tr("hint_jsonl_pick"), "data_path", "file_jsonl"))
        dl.addWidget(QLabel(tr("data_format_title")))
        fmt = QPlainTextEdit()
        fmt.setReadOnly(True)
        fmt.setMaximumHeight(72)
        fmt.setPlainText(tr("data_format_example_line"))
        fmt.setStyleSheet("color: #86efac; font-family: monospace;")
        dl.addWidget(fmt)
        v.addWidget(dt)

        od = QGroupBox(tr("output_dir_section"))
        ol = QVBoxLayout(od)
        ol.addWidget(QLabel(tr("label_output_dir")))
        ol.addLayout(self._line(tr("hint_output_dir"), "output_dir", "out_dir"))
        v.addWidget(od)

        nx = QPushButton(tr("next_train_params"))
        nx.clicked.connect(lambda: self.tabs.setCurrentIndex(2))
        v.addWidget(nx)
        return w

    def _page_train(self) -> QWidget:
        w = QWidget()
        v = QVBoxLayout(w)

        hp = QGroupBox(tr("train_hyperparams"))
        g = QGridLayout(hp)
        self._add_num_row(g, 0, 0, tr("label_batch_size"), "batch_size")
        self._add_num_row(g, 0, 2, tr("label_num_steps"), "num_steps")
        self._add_num_row(g, 1, 0, tr("label_num_epochs"), "num_epochs")
        self._add_text_row(g, 1, 2, tr("label_lr"), "learning_rate")
        self._add_num_row(g, 2, 0, tr("label_ctx_len"), "ctx_len")

        prec = QGroupBox(tr("label_train_precision"))
        ph = QHBoxLayout(prec)
        self._prec_buttons: list[tuple[TrainingPrecision, QPushButton]] = []
        for p in TrainingPrecision:
            b = QPushButton(p.value.upper())
            b.setObjectName("secondary")
            b.setCheckable(True)
            b.clicked.connect(lambda _=False, x=p: self._set_prec(x))
            self._prec_buttons.append((p, b))
            ph.addWidget(b)
        ph.addStretch()
        g.addWidget(prec, 3, 0, 1, 4)
        v.addWidget(hp)

        sm = QGroupBox(tr("config_summary"))
        sf = QFormLayout(sm)
        self.sum_labels = {}
        for key, lab in [
            ("repo", tr("summary_repo")),
            ("model", tr("summary_model_file")),
            ("data", tr("summary_data_file")),
            ("out", tr("summary_output_dir")),
            ("prec", tr("summary_precision")),
            ("spec", tr("summary_model_spec")),
            ("embd", tr("summary_embd_layer")),
            ("ctx", tr("summary_ctx_len")),
            ("bse", tr("summary_batch_steps_epochs")),
            ("lr", tr("summary_lr")),
        ]:
            lb = QLabel("")
            sf.addRow(lab + ":", lb)
            self.sum_labels[key] = lb
        v.addWidget(sm)

        row = QHBoxLayout()
        self.train_btn = QPushButton(tr("train_start"))
        self.train_btn.setObjectName("green")
        self.train_btn.clicked.connect(self._ctrl.start_training)
        self.stop_btn = QPushButton(tr("train_btn_stop"))
        self.stop_btn.setObjectName("red")
        self.stop_btn.clicked.connect(self._ctrl.stop_training)
        row.addWidget(self.train_btn, 3)
        row.addWidget(self.stop_btn, 1)
        v.addLayout(row)
        v.addWidget(QLabel(tr("train_hint_footer")))
        return w

    def _add_num_row(self, g: QGridLayout, r: int, c: int, title: str, attr: str) -> None:
        g.addWidget(QLabel(title), r, c)
        le = QLineEdit()
        self._inputs[attr] = le
        le.textChanged.connect(
            lambda t, a=attr: self._set_num_from_line(a, t)
        )
        g.addWidget(le, r, c + 1)

    def _add_text_row(self, g: QGridLayout, r: int, c: int, title: str, attr: str) -> None:
        g.addWidget(QLabel(title), r, c)
        le = QLineEdit()
        self._inputs[attr] = le
        le.textChanged.connect(lambda t, a=attr: setattr(self._ctrl, a, t))
        g.addWidget(le, r, c + 1)

    def _set_num_from_line(self, attr: str, text: str) -> None:
        try:
            v = int(text)
            if v > 0:
                setattr(self._ctrl, attr, v)
        except ValueError:
            pass

    def _set_prec(self, p: TrainingPrecision) -> None:
        self._ctrl.set_precision(p)
        for pr, btn in getattr(self, "_prec_buttons", []):
            btn.setChecked(pr == p)

    def _page_monitor(self) -> QWidget:
        w = QWidget()
        v = QVBoxLayout(w)
        hb = QHBoxLayout()
        self.mon_badge = QLabel()
        hb.addWidget(self.mon_badge)
        hb.addStretch()
        self.mon_stop_btn = QPushButton(tr("train_btn_stop"))
        self.mon_stop_btn.setObjectName("red")
        self.mon_stop_btn.clicked.connect(self._ctrl.stop_training)
        hb.addWidget(self.mon_stop_btn)
        self.mon_export_btn = QPushButton(tr("monitor_export_loss_jsonl"))
        self.mon_export_btn.clicked.connect(self._export_loss)
        hb.addWidget(self.mon_export_btn)
        self.mon_chart_btn = QPushButton(tr("monitor_view_loss_chart"))
        self.mon_chart_btn.clicked.connect(self._loss_chart)
        hb.addWidget(self.mon_chart_btn)
        cl = QPushButton(tr("monitor_clear_log"))
        cl.setObjectName("secondary")
        cl.clicked.connect(self._clear_train_log)
        hb.addWidget(cl)
        v.addLayout(hb)
        self.log_view = QPlainTextEdit()
        self.log_view.setReadOnly(True)
        self.log_view.setPlaceholderText(tr("monitor_log_placeholder"))
        self.log_view.setFont(QFont("Menlo", 11) if sys.platform == "darwin" else QFont("Consolas", 10))
        v.addWidget(self.log_view, 1)
        return w

    def _clear_train_log(self) -> None:
        self._ctrl.training_log = ""
        self._ctrl._log_lines.clear()
        self._ctrl._log_current_line = ""
        self.refresh()

    def _export_loss(self) -> None:
        d = QFileDialog.getExistingDirectory(self, tr("dialog_pick_export_dir"))
        if d:
            self._ctrl.export_loss_log(d)

    def _loss_chart(self) -> None:
        try:
            from PySide6.QtCharts import QChart, QChartView, QLineSeries, QValueAxis
        except ImportError:
            QMessageBox.information(self, tr("tip"), "QtCharts not available.")
            return

        losses = self._ctrl.loss_history
        dlg = QDialog(self)
        dlg.setWindowTitle(tr("monitor_loss_curve_title"))
        dlg.resize(720, 460)
        lay = QVBoxLayout(dlg)
        series = QLineSeries()
        step = max(1, len(losses) // 400)
        for i in range(0, len(losses), step):
            series.append(i, losses[i])
        chart = QChart()
        chart.addSeries(series)
        chart.createDefaultAxes()
        chart.legend().hide()
        v = QChartView(chart)
        lay.addWidget(v)
        bb = QDialogButtonBox(QDialogButtonBox.Close)
        bb.rejected.connect(dlg.close)
        lay.addWidget(bb)
        dlg.exec()

    def _page_export(self) -> QWidget:
        w = QWidget()
        v = QVBoxLayout(w)
        self.exp_dir_lbl = QLabel()
        v.addWidget(self.exp_dir_lbl)

        hb = QHBoxLayout()
        rf = QPushButton(tr("export_refresh_list"))
        rf.clicked.connect(self._ctrl.refresh_output_files)
        hb.addWidget(rf)
        self.exp_export_btn = QPushButton(tr("monitor_export_loss_jsonl"))
        self.exp_export_btn.clicked.connect(self._export_loss)
        hb.addWidget(self.exp_export_btn)
        hb.addStretch()
        v.addLayout(hb)

        self.file_list = QPlainTextEdit()
        self.file_list.setReadOnly(True)
        self.file_list.setPlaceholderText(tr("export_no_files_hint") if hasattr(i18n, "tr") else "No output files yet.")
        self.file_list.setFont(QFont("Menlo", 10) if sys.platform == "darwin" else QFont("Consolas", 9))
        v.addWidget(self.file_list, 1)

        usage_box = QGroupBox(tr("export_usage_title"))
        ul = QVBoxLayout(usage_box)
        ul.addWidget(QLabel(tr("export_usage_body")))
        v.addWidget(usage_box)
        return w

    def _page_settings(self) -> QWidget:
        w = QWidget()
        v = QVBoxLayout(w)
        v.addWidget(QLabel(tr("settings_system_intro")))

        # ── System Basics ─────────────────────────────────────────────────────
        sb = QGroupBox(tr("settings_system_basics"))
        sg = QVBoxLayout(sb)

        # winget row
        wh = QHBoxLayout()
        self.winget_lbl = QLabel()
        wh.addWidget(self.winget_lbl, 1)
        wh.addStretch()
        sg.addLayout(wh)

        # UV row
        uh = QHBoxLayout()
        self.uv_lbl = QLabel()
        uh.addWidget(self.uv_lbl, 1)
        self.uv_install_btn = QPushButton(tr("btn_install"))
        self.uv_install_btn.setObjectName("secondary")
        self.uv_install_btn.clicked.connect(self._ctrl.install_uv)
        uh.addWidget(self.uv_install_btn)
        sg.addLayout(uh)

        # NVIDIA driver row
        nh = QHBoxLayout()
        self.nvidia_lbl = QLabel()
        nh.addWidget(self.nvidia_lbl, 1)
        self.nvidia_install_btn = QPushButton(tr("btn_install"))
        self.nvidia_install_btn.setObjectName("secondary")
        self.nvidia_install_btn.clicked.connect(self._ctrl.install_nvidia_driver)
        nh.addWidget(self.nvidia_install_btn)
        sg.addLayout(nh)

        self.sys_log = QPlainTextEdit()
        self.sys_log.setReadOnly(True)
        self.sys_log.setMaximumHeight(80)
        sg.addWidget(self.sys_log)
        v.addWidget(sb)

        # ── CUDA ──────────────────────────────────────────────────────────────
        cg = QGroupBox(tr("cuda_section_title"))
        cl = QVBoxLayout(cg)
        self._cuda_home_le = QLineEdit(self._ctrl.cuda_home)
        self._cuda_home_le.setPlaceholderText(tr("cuda_dir_label"))
        self._cuda_home_le.textChanged.connect(lambda t: setattr(self._ctrl, "cuda_home", t))
        cl.addWidget(QLabel(tr("cuda_dir_label")))
        cl.addWidget(self._cuda_home_le)
        brow = QHBoxLayout()
        ad = QPushButton(tr("btn_auto_detect"))
        ad.clicked.connect(self._ctrl.detect_cuda_home)
        brow.addWidget(ad)
        self.cuda_install_btn = QPushButton(tr("btn_install_cuda"))
        self.cuda_install_btn.setObjectName("secondary")
        self.cuda_install_btn.clicked.connect(self._ctrl.install_cuda_winget)
        brow.addWidget(self.cuda_install_btn)
        brow.addStretch()
        cl.addLayout(brow)
        self.cuda_log = QPlainTextEdit()
        self.cuda_log.setReadOnly(True)
        self.cuda_log.setMaximumHeight(100)
        cl.addWidget(self.cuda_log)
        v.addWidget(cg)

        # ── Environment ───────────────────────────────────────────────────────
        eg = QGroupBox(tr("env_section_title"))
        el = QVBoxLayout(eg)
        ebrow = QHBoxLayout()
        chk = QPushButton(tr("env_check_env"))
        chk.clicked.connect(self._ctrl.check_environment)
        ebrow.addWidget(chk)
        self.env_install_btn = QPushButton(tr("btn_install_env"))
        self.env_install_btn.clicked.connect(self._ctrl.install_environment)
        ebrow.addWidget(self.env_install_btn)
        ebrow.addStretch()
        el.addLayout(ebrow)
        self.env_log = QPlainTextEdit()
        self.env_log.setReadOnly(True)
        el.addWidget(self.env_log)
        v.addWidget(eg)

        # ── Build Tools (Windows only) ────────────────────────────────────────
        btg = QGroupBox(tr("build_tools_section"))
        btl = QVBoxLayout(btg)
        bth = QHBoxLayout()
        self.ninja_lbl = QLabel()
        self.msvc_lbl = QLabel()
        bth.addWidget(self.ninja_lbl)
        bth.addWidget(self.msvc_lbl)
        bth.addStretch()
        self.bt_install_btn = QPushButton(tr("btn_install_build_tools"))
        self.bt_install_btn.setObjectName("secondary")
        self.bt_install_btn.clicked.connect(self._ctrl.install_build_tools)
        bth.addWidget(self.bt_install_btn)
        btl.addLayout(bth)
        self.build_tools_log_view = QPlainTextEdit()
        self.build_tools_log_view.setReadOnly(True)
        self.build_tools_log_view.setMaximumHeight(80)
        btl.addWidget(self.build_tools_log_view)
        v.addWidget(btg)

        v.addStretch()
        return w

    def _page_test(self) -> QWidget:
        w = QWidget()
        v = QVBoxLayout(w)

        load_grp = QGroupBox(tr("test_model_load_title"))
        lg = QVBoxLayout(load_grp)

        # model .pth
        lg.addWidget(QLabel(tr("label_pretrained_pth")))
        mh = QHBoxLayout()
        self._test_model_le = QLineEdit()
        self._test_model_le.setPlaceholderText(tr("hint_model_path"))
        self._test_model_le.textChanged.connect(lambda t: setattr(self._ctrl, "test_model_path", t))
        mh.addWidget(self._test_model_le, 1)
        mb = QPushButton("…")
        mb.setFixedWidth(44)
        mb.setObjectName("secondary")
        mb.clicked.connect(self._pick_test_model)
        mh.addWidget(mb)
        lg.addLayout(mh)

        # tokenizer
        lg.addWidget(QLabel(tr("label_tokenizer_path")))
        th = QHBoxLayout()
        self._test_tok_le = QLineEdit()
        self._test_tok_le.setPlaceholderText("tokenizer.json / vocab file")
        self._test_tok_le.textChanged.connect(lambda t: setattr(self._ctrl, "test_tokenizer_path", t))
        th.addWidget(self._test_tok_le, 1)
        tb = QPushButton("…")
        tb.setFixedWidth(44)
        tb.setObjectName("secondary")
        tb.clicked.connect(self._pick_test_tokenizer)
        th.addWidget(tb)
        lg.addLayout(th)

        # state file
        lg.addWidget(QLabel(tr("label_state_path")))
        sh = QHBoxLayout()
        self._test_state_le = QLineEdit()
        self._test_state_le.setPlaceholderText("state.pth (optional)")
        self._test_state_le.textChanged.connect(lambda t: setattr(self._ctrl, "test_state_path", t))
        sh.addWidget(self._test_state_le, 1)
        stb = QPushButton("…")
        stb.setFixedWidth(44)
        stb.setObjectName("secondary")
        stb.clicked.connect(self._pick_test_state)
        sh.addWidget(stb)
        lg.addLayout(sh)

        brow = QHBoxLayout()
        load_btn = QPushButton(tr("btn_load_model"))
        load_btn.clicked.connect(self._ctrl.load_rwkv_test_model)
        brow.addWidget(load_btn)
        clr = QPushButton(tr("monitor_clear_log"))
        clr.setObjectName("secondary")
        clr.clicked.connect(self._ctrl.clear_rwkv_chat)
        brow.addWidget(clr)
        brow.addStretch()
        self.test_status_lbl = QLabel(self._ctrl.rwkv_status)
        self.test_status_lbl.setStyleSheet("color: #9ca3af;")
        brow.addWidget(self.test_status_lbl)
        lg.addLayout(brow)
        v.addWidget(load_grp)

        chat_grp = QGroupBox(tr("test_chat_title"))
        cl = QVBoxLayout(chat_grp)
        self.test_chat_view = QPlainTextEdit()
        self.test_chat_view.setReadOnly(True)
        self.test_chat_view.setPlaceholderText(tr("test_chat_empty"))
        self.test_chat_view.setFont(QFont("Menlo", 11) if sys.platform == "darwin" else QFont("Consolas", 10))
        cl.addWidget(self.test_chat_view, 1)

        ph = QHBoxLayout()
        self.test_prompt_le = QLineEdit()
        self.test_prompt_le.setPlaceholderText(tr("test_prompt_hint"))
        self.test_prompt_le.returnPressed.connect(self._send_test_prompt)
        ph.addWidget(self.test_prompt_le, 1)
        send_btn = QPushButton(tr("btn_send"))
        send_btn.clicked.connect(self._send_test_prompt)
        ph.addWidget(send_btn)
        cl.addLayout(ph)
        v.addWidget(chat_grp, 1)
        return w

    def _pick_test_model(self) -> None:
        p, _ = QFileDialog.getOpenFileName(self, tr("dialog_pick_model_pth"), "", "*.pth;;All (*)")
        if p:
            self._ctrl.test_model_path = p
            self._test_model_le.setText(p)

    def _pick_test_tokenizer(self) -> None:
        p, _ = QFileDialog.getOpenFileName(self, "Pick tokenizer", "", "*.json *.txt;;All (*)")
        if p:
            self._ctrl.test_tokenizer_path = p
            self._test_tok_le.setText(p)

    def _pick_test_state(self) -> None:
        p, _ = QFileDialog.getOpenFileName(self, "Pick state file", "", "*.pth;;All (*)")
        if p:
            self._ctrl.test_state_path = p
            self._test_state_le.setText(p)

    def _send_test_prompt(self) -> None:
        txt = self.test_prompt_le.text().strip()
        if not txt:
            return
        self.test_prompt_le.clear()
        self._ctrl.rwkv_messages.append({"role": "user", "content": txt})
        self._ctrl.send_rwkv_prompt()
        self.refresh()

    def refresh(self) -> None:
        c = self._ctrl
        self.setWindowTitle(tr("app_title"))
        self.gpu_label.setText(tr("gpu_chip", v=c.gpu_info) if c.env_ready else c.gpu_info)
        self.status_label.setText(c.status)

        # ── CUDA log ──────────────────────────────────────────────────────────
        if hasattr(self, "cuda_log"):
            self.cuda_log.setPlainText((c.cuda_detect_log + "\n" + c.cuda_install_log).strip())
        if hasattr(self, "_cuda_home_le"):
            le = self._cuda_home_le
            if le.text() != c.cuda_home:
                le.blockSignals(True)
                le.setText(c.cuda_home)
                le.blockSignals(False)

        # ── System basics labels ───────────────────────────────────────────────
        if hasattr(self, "winget_lbl"):
            ok = "✓" if c.winget_installed else "✗"
            self.winget_lbl.setText(f"winget  {ok}")
        if hasattr(self, "uv_lbl"):
            ok = "✓" if c.uv_installed else "✗"
            self.uv_lbl.setText(f"uv  {ok}")
            self.uv_install_btn.setEnabled(not c.uv_installed and not c.is_uv_installing)
        if hasattr(self, "nvidia_lbl"):
            ok = "✓" if c.nvidia_driver_installed else "✗"
            self.nvidia_lbl.setText(f"NVIDIA Driver  {ok}")
        if hasattr(self, "sys_log"):
            self.sys_log.setPlainText(c.uv_install_log)
        if hasattr(self, "cuda_install_btn"):
            self.cuda_install_btn.setEnabled(not c.is_cuda_installing)

        # ── Build tools ───────────────────────────────────────────────────────
        if hasattr(self, "ninja_lbl"):
            self.ninja_lbl.setText(f"ninja  {'✓' if c.ninja_on_path else '✗'}")
        if hasattr(self, "msvc_lbl"):
            self.msvc_lbl.setText(f"MSVC cl  {'✓' if c.msvc_cl_on_path else '✗'}")
        if hasattr(self, "build_tools_log_view"):
            self.build_tools_log_view.setPlainText(c.build_tools_log)
        if hasattr(self, "bt_install_btn"):
            self.bt_install_btn.setEnabled(not c.is_build_tools_installing)

        # ── Env log ───────────────────────────────────────────────────────────
        if hasattr(self, "env_log"):
            self.env_log.setPlainText((c.check_log + "\n" + c.install_log).strip())
        if hasattr(self, "env_install_btn"):
            self.env_install_btn.setEnabled(not c.is_installing and not c.is_checking)

        # ── Export ────────────────────────────────────────────────────────────
        if hasattr(self, "exp_dir_lbl"):
            self.exp_dir_lbl.setText(tr("export_output_dir_label", path=c.output_dir))
        if hasattr(self, "file_list"):
            self.file_list.setPlainText("\n".join(c.output_files))
        if hasattr(self, "exp_export_btn"):
            self.exp_export_btn.setEnabled(bool(c.loss_history))

        # ── Monitor ───────────────────────────────────────────────────────────
        if hasattr(self, "mon_badge"):
            self.mon_badge.setText(
                tr("monitor_badge_training") if c.is_training else tr("monitor_badge_idle")
            )
        if hasattr(self, "mon_stop_btn"):
            self.mon_stop_btn.setVisible(c.is_training)
        if hasattr(self, "mon_export_btn"):
            self.mon_export_btn.setEnabled(bool(c.loss_history))
        if hasattr(self, "mon_chart_btn"):
            self.mon_chart_btn.setEnabled(bool(c.loss_history))

        # ── Train tab buttons ─────────────────────────────────────────────────
        if hasattr(self, "train_btn"):
            self.train_btn.setEnabled(not c.is_training)
            self.stop_btn.setEnabled(c.is_training)
            self.train_btn.setText(tr("train_in_progress") if c.is_training else tr("train_start"))

        self.refresh_model_fields()
        self._update_summary_labels()
        if hasattr(self, "_prec_buttons"):
            for p, btn in self._prec_buttons:
                btn.setChecked(p == c.precision)

        # ── Log view ──────────────────────────────────────────────────────────
        if hasattr(self, "log_view"):
            cur = self.log_view.toPlainText()
            if cur != c.training_log:
                self.log_view.setPlainText(c.training_log)
                sb = self.log_view.verticalScrollBar()
                sb.setValue(sb.maximum())
        if hasattr(self, "repo_log_view"):
            self.repo_log_view.setPlainText(c.repo_log)

        # ── Test tab ──────────────────────────────────────────────────────────
        if hasattr(self, "test_status_lbl"):
            self.test_status_lbl.setText(c.rwkv_status)
        if hasattr(self, "test_chat_view"):
            lines = []
            for msg in c.rwkv_messages:
                role = msg.get("role", "")
                content = msg.get("content", "")
                lines.append(f"[{role.upper()}] {content}")
            self.test_chat_view.setPlainText("\n\n".join(lines))

        # ── Overlay ───────────────────────────────────────────────────────────
        if c.is_cloning_repo:
            self._overlay.setText(tr("clone_repo_initializing"))
            self._overlay.show()
            self._overlay.raise_()
        else:
            self._overlay.hide()

