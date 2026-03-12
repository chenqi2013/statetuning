import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum TrainingPrecision { bf16, fp16, fp32 }

// RWKV7 model size presets
class Rwkv7Preset {
  final String label;
  final int nEmbd;
  final int nLayer;

  const Rwkv7Preset(this.label, this.nEmbd, this.nLayer);
}

class HomeController extends GetxController {
  // --- Tab ---
  final currentTabIndex = 0.obs;

  // --- GPU / Status ---
  final gpuInfo = '检测中...'.obs;
  final status = '空闲'.obs;

  // --- RWKV7 Model Presets ---
  static const presets = [
    Rwkv7Preset('RWKV7-0.1B', 768, 12),
    Rwkv7Preset('RWKV7-0.4B', 1024, 24),
    Rwkv7Preset('RWKV7-1.5B', 2048, 24),
    Rwkv7Preset('RWKV7-3B', 2560, 32),
    Rwkv7Preset('RWKV7-7B', 4096, 32),
    Rwkv7Preset('自定义', 0, 0),
  ];
  final selectedPreset = 'RWKV7-0.4B'.obs;

  // --- RWKV7 ModelArgs ---
  final vocabSize = 65536.obs;
  final nEmbd = 1024.obs;
  final nLayer = 24.obs;
  final ctxLen = 512.obs;

  // --- File Paths ---
  final modelPath = ''.obs;
  final dataPath = ''.obs;
  final outputDir = './outmodel'.obs;
  final repoPath = ''.obs;

  // --- Training Args ---
  final precision = TrainingPrecision.bf16.obs;
  final batchSize = 4.obs;
  final numSteps = 1000.obs;
  final numEpochs = 1.obs;
  final learningRate = '1e-5'.obs;

  // --- CUDA ---
  final cudaHome = ''.obs;
  final cudaDetectLog = ''.obs;

  // --- Training State ---
  final isTraining = false.obs;
  final trainingLog = ''.obs;
  // step → loss，用于去重（每步 tqdm 会打两次）
  final _lossMap = <int, double>{};
  final lossHistory = <double>[].obs;
  Process? _trainingProcess;

  // --- Repo State ---
  final isCloningRepo = false.obs;
  final repoLog = ''.obs;
  final repoCloned = false.obs;

  // --- Output Files ---
  final outputFiles = <String>[].obs;

  // --- Environment (statetuning deps) ---
  static const _envPackages = [
    'torch>=2.0.0',
    'transformers>=4.30.0',
    'tqdm>=4.65.0',
    'huggingface-hub',
    'ninja',
  ];
  static const _envCheckPackages = [
    'torch',
    'transformers',
    'tqdm',
    'huggingface_hub',
    'ninja',
  ];
  final isInstalling = false.obs;
  final installLog = ''.obs;
  final isChecking = false.obs;
  final envReady = false.obs;
  final checkLog = ''.obs;

  // --- Build Tools (MSVC + ninja) ---
  final isBuildToolsInstalling = false.obs;
  final buildToolsLog = ''.obs;

  // --- Text Controllers ---
  late final TextEditingController vocabSizeController;
  late final TextEditingController nEmbdController;
  late final TextEditingController nLayerController;
  late final TextEditingController ctxLenController;
  late final TextEditingController modelPathController;
  late final TextEditingController dataPathController;
  late final TextEditingController outputDirController;
  late final TextEditingController repoPathController;
  late final TextEditingController batchSizeController;
  late final TextEditingController numStepsController;
  late final TextEditingController numEpochsController;
  late final TextEditingController learningRateController;
  late final TextEditingController cudaHomeController;

  @override
  void onInit() {
    super.onInit();
    vocabSizeController = TextEditingController(
      text: vocabSize.value.toString(),
    );
    nEmbdController = TextEditingController(text: nEmbd.value.toString());
    nLayerController = TextEditingController(text: nLayer.value.toString());
    ctxLenController = TextEditingController(text: ctxLen.value.toString());
    modelPathController = TextEditingController(text: modelPath.value);
    dataPathController = TextEditingController(text: dataPath.value);
    outputDirController = TextEditingController(text: outputDir.value);
    repoPathController = TextEditingController(text: repoPath.value);
    batchSizeController = TextEditingController(
      text: batchSize.value.toString(),
    );
    numStepsController = TextEditingController(text: numSteps.value.toString());
    numEpochsController = TextEditingController(
      text: numEpochs.value.toString(),
    );
    learningRateController = TextEditingController(text: learningRate.value);
    cudaHomeController = TextEditingController(text: cudaHome.value);

    vocabSizeController.addListener(() {
      final v = int.tryParse(vocabSizeController.text);
      if (v != null && v > 0) vocabSize.value = v;
    });
    nEmbdController.addListener(() {
      final v = int.tryParse(nEmbdController.text);
      if (v != null && v > 0) nEmbd.value = v;
    });
    nLayerController.addListener(() {
      final v = int.tryParse(nLayerController.text);
      if (v != null && v > 0) nLayer.value = v;
    });
    ctxLenController.addListener(() {
      final v = int.tryParse(ctxLenController.text);
      if (v != null && v > 0) ctxLen.value = v;
    });
    modelPathController.addListener(
      () => modelPath.value = modelPathController.text,
    );
    dataPathController.addListener(
      () => dataPath.value = dataPathController.text,
    );
    outputDirController.addListener(
      () => outputDir.value = outputDirController.text,
    );
    repoPathController.addListener(
      () => repoPath.value = repoPathController.text,
    );
    batchSizeController.addListener(() {
      final v = int.tryParse(batchSizeController.text);
      if (v != null && v > 0) batchSize.value = v;
    });
    numStepsController.addListener(() {
      final v = int.tryParse(numStepsController.text);
      if (v != null && v > 0) numSteps.value = v;
    });
    numEpochsController.addListener(() {
      final v = int.tryParse(numEpochsController.text);
      if (v != null && v > 0) numEpochs.value = v;
    });
    learningRateController.addListener(
      () => learningRate.value = learningRateController.text,
    );
    cudaHomeController.addListener(
      () => cudaHome.value = cudaHomeController.text,
    );

    _detectGpu();
    detectCudaHome();
    // 启动时静默检测一次环境
    checkEnvironment();
    // 切换到设置 tab（index 4）时自动重新检测
    ever(currentTabIndex, (idx) {
      if (idx == 4 && !isChecking.value) checkEnvironment();
    });
  }

  @override
  void onClose() {
    for (final c in [
      vocabSizeController,
      nEmbdController,
      nLayerController,
      ctxLenController,
      modelPathController,
      dataPathController,
      outputDirController,
      repoPathController,
      batchSizeController,
      numStepsController,
      numEpochsController,
      learningRateController,
      cudaHomeController,
    ]) {
      c.dispose();
    }
    _trainingProcess?.kill();
    super.onClose();
  }

  void setTabIndex(int index) => currentTabIndex.value = index;

  void setPrecision(TrainingPrecision p) => precision.value = p;

  void applyPreset(String presetLabel) {
    selectedPreset.value = presetLabel;
    final preset = presets.firstWhereOrNull((p) => p.label == presetLabel);
    if (preset == null || preset.nEmbd == 0) return;
    nEmbd.value = preset.nEmbd;
    nLayer.value = preset.nLayer;
    nEmbdController.text = preset.nEmbd.toString();
    nLayerController.text = preset.nLayer.toString();
  }

  String get precisionString {
    switch (precision.value) {
      case TrainingPrecision.bf16:
        return 'bf16';
      case TrainingPrecision.fp16:
        return 'fp16';
      case TrainingPrecision.fp32:
        return 'fp32';
    }
  }

  Future<void> _detectGpu() async {
    try {
      final result = await Process.run(
        'python',
        [
          '-c',
          'import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else "No CUDA GPU")',
        ],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (result.exitCode == 0) {
        final out = (result.stdout as String).trim();
        gpuInfo.value = out.isNotEmpty ? out : 'No GPU';
      } else {
        gpuInfo.value = '未检测到 GPU';
      }
    } catch (_) {
      gpuInfo.value = '未检测到 GPU';
    }
  }

  // --- CUDA Detection ---

  /// 自动查找 CUDA 安装路径（Windows 常见位置 + 环境变量）
  Future<void> detectCudaHome() async {
    cudaDetectLog.value = '▶ 正在检测 CUDA 安装路径...\n';

    // 1. 先读系统环境变量
    final envCuda =
        Platform.environment['CUDA_HOME'] ?? Platform.environment['CUDA_PATH'];
    if (envCuda != null && envCuda.isNotEmpty) {
      final nvcc = File(
        '$envCuda${Platform.pathSeparator}bin${Platform.pathSeparator}nvcc.exe',
      );
      if (await nvcc.exists()) {
        _setCudaHome(envCuda);
        cudaDetectLog.value += '✓ 从环境变量检测到: $envCuda\n';
        return;
      }
    }

    // 2. 扫描 Windows 默认安装目录
    final searchRoots = [
      r'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA',
      r'C:\CUDA',
    ];
    for (final root in searchRoots) {
      final dir = Directory(root);
      if (!await dir.exists()) continue;
      final versions = <String>[];
      await for (final entry in dir.list()) {
        if (entry is Directory) versions.add(entry.path);
      }
      if (versions.isNotEmpty) {
        // 取版本号最大的
        versions.sort();
        final latest = versions.last;
        final nvcc = File(
          '$latest${Platform.pathSeparator}bin${Platform.pathSeparator}nvcc.exe',
        );
        if (await nvcc.exists()) {
          _setCudaHome(latest);
          cudaDetectLog.value += '✓ 自动检测到: $latest\n';
          return;
        }
      }
    }

    // 3. 尝试从 nvcc 命令反推路径
    try {
      final r = await Process.run(
        'where',
        ['nvcc'],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (r.exitCode == 0) {
        final nvccPath = (r.stdout as String).trim().split('\n').first.trim();
        // nvccPath = C:\...\CUDA\v12.x\bin\nvcc.exe  → 取上两级
        final home = File(nvccPath).parent.parent.path;
        _setCudaHome(home);
        cudaDetectLog.value += '✓ 从 nvcc 命令检测到: $home\n';
        return;
      }
    } catch (_) {}

    cudaDetectLog.value +=
        '✗ 未自动检测到 CUDA，请手动选择安装目录\n'
        '  常见路径: C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\v12.x\n';
  }

  void _setCudaHome(String path) {
    cudaHome.value = path;
    cudaHomeController.text = path;
  }

  /// 从 cudaHome 路径中提取 CUDA 版本并返回对应 PyTorch wheel tag（如 cu124）。
  /// 若无法解析则返回默认值 'cu124'。
  String _getCudaWheelTag() {
    final home = cudaHome.value;
    if (home.isNotEmpty) {
      final segments = home.replaceAll('\\', '/').split('/');
      for (final seg in segments.reversed) {
        final m = RegExp(r'^[vV]?(\d+)\.(\d+)').firstMatch(seg);
        if (m != null) {
          final major = m.group(1)!;
          final minor = m.group(2)!;
          return 'cu$major$minor'; // e.g., cu124
        }
      }
    }
    return 'cu124';
  }

  Future<void> pickCudaHomeDir() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择 CUDA 安装目录（包含 bin/nvcc.exe 的上级目录）',
    );
    if (path != null) {
      _setCudaHome(path);
      cudaDetectLog.value = '✓ 手动设置: $path\n';
    }
  }

  // --- File / Folder Pickers ---

  Future<void> pickRepoDir() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择 statetuning 仓库目录',
    );
    if (path != null) {
      repoPath.value = path;
      repoPathController.text = path;
      await checkRepo();
    }
  }

  Future<void> pickModelFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择 RWKV7 模型文件 (.pth)',
      type: FileType.custom,
      allowedExtensions: ['pth'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      modelPath.value = path;
      modelPathController.text = path;
      await _autoDetectModelShape(path);
    }
  }

  /// 读取 .pth checkpoint，自动检测并更新模型尺寸参数。
  Future<void> _autoDetectModelShape(String pthPath) async {
    try {
      final result = await Process.run(
        'python',
        [
          '-X', 'utf8', '-c',
          'import torch, re, sys\n'
          'ckpt = torch.load(sys.argv[1], map_location="cpu", weights_only=True)\n'
          'n_embd = ckpt["head.weight"].shape[1] if "head.weight" in ckpt else -1\n'
          'vocab  = ckpt["head.weight"].shape[0] if "head.weight" in ckpt else -1\n'
          'layers = max((int(re.match(r"blocks\\.(\\d+)\\.", k).group(1)) for k in ckpt if re.match(r"blocks\\.(\\d+)\\.", k)), default=-1) + 1\n'
          'print(f"{n_embd},{vocab},{layers}")',
          pthPath,
        ],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (result.exitCode != 0) return;
      final parts = (result.stdout as String).trim().split(',');
      if (parts.length < 3) return;
      final detectedEmbd   = int.tryParse(parts[0]) ?? -1;
      final detectedVocab  = int.tryParse(parts[1]) ?? -1;
      final detectedLayers = int.tryParse(parts[2]) ?? -1;
      if (detectedEmbd > 0) {
        nEmbd.value = detectedEmbd;
        nEmbdController.text = '$detectedEmbd';
      }
      if (detectedVocab > 0) {
        vocabSize.value = detectedVocab;
        vocabSizeController.text = '$detectedVocab';
      }
      if (detectedLayers > 0) {
        nLayer.value = detectedLayers;
        nLayerController.text = '$detectedLayers';
      }
      if (detectedEmbd > 0) {
        // 自动匹配预设名称（仅更新标签，不强制）
        selectedPreset.value = '自定义';
        Get.snackbar(
          '模型尺寸已自动检测',
          'n_embd=$detectedEmbd  n_layer=$detectedLayers  vocab=$detectedVocab',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (_) {}
  }

  Future<void> pickDataFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择训练数据文件 (.jsonl)',
      type: FileType.custom,
      allowedExtensions: ['jsonl', 'json'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      dataPath.value = path;
      dataPathController.text = path;
    }
  }

  Future<void> pickOutputDir() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择输出目录',
    );
    if (path != null) {
      outputDir.value = path;
      outputDirController.text = path;
    }
  }

  // --- Repo Management ---

  Future<void> checkRepo() async {
    if (repoPath.value.isEmpty) {
      Get.snackbar('提示', '请先输入仓库路径');
      return;
    }
    final trainFile = File(
      '${repoPath.value}${Platform.pathSeparator}train.py',
    );
    if (await trainFile.exists()) {
      repoCloned.value = true;
      repoLog.value = '✓ 仓库已就绪: ${repoPath.value}';
    } else {
      repoCloned.value = false;
      repoLog.value = '✗ 路径下未找到 train.py，请克隆仓库';
    }
  }

  Future<void> cloneRepo() async {
    if (isCloningRepo.value) return;
    if (repoPath.value.isEmpty) {
      Get.snackbar('提示', '请先输入目标路径');
      return;
    }
    isCloningRepo.value = true;
    repoCloned.value = false;
    repoLog.value = '正在克隆仓库 https://github.com/Joluck/statetuning ...\n';
    try {
      final dir = Directory(repoPath.value);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final process = await Process.start(
        'git',
        ['clone', 'https://github.com/Joluck/statetuning', '.'],
        workingDirectory: repoPath.value,
        runInShell: true,
      );
      process.stdout.transform(utf8.decoder).listen((d) => repoLog.value += d);
      process.stderr.transform(utf8.decoder).listen((d) => repoLog.value += d);
      final exitCode = await process.exitCode;
      if (exitCode == 0) {
        repoCloned.value = true;
        repoLog.value += '\n✓ 仓库克隆成功！';
        Get.snackbar('克隆成功', '仓库已克隆到 ${repoPath.value}');
      } else {
        repoLog.value += '\n✗ 克隆失败 (exit: $exitCode)';
        Get.snackbar('克隆失败', '请检查路径和网络连接');
      }
    } catch (e) {
      repoLog.value += '异常: $e';
      Get.snackbar('克隆失败', '$e');
    } finally {
      isCloningRepo.value = false;
    }
  }

  // --- Training ---

  /// Generates a complete, self-contained Python training script based on the
  /// user's current configuration. The script mirrors train.py from the repo
  /// but with all config values injected by Flutter.
  String _buildTrainingScript() {
    final p = precisionString;
    final cudaHomeStr = cudaHome.value;
    return '''import os, sys, glob, shutil
sys.path.insert(0, r"${repoPath.value}")
os.chdir(r"${repoPath.value}")

# ── CUDA_HOME 强制设置（覆盖系统变量，避免旧值干扰）──────────────────
_cuda_home = r"$cudaHomeStr"
if not _cuda_home:
    for _root in [
        r"C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA",
        r"C:\\CUDA",
    ]:
        _candidates = sorted(glob.glob(f"{_root}\\\\v*"), reverse=True)
        if _candidates:
            _cuda_home = _candidates[0]
            break
if _cuda_home:
    os.environ["CUDA_HOME"] = _cuda_home
    os.environ["CUDA_PATH"] = _cuda_home
    # 把 CUDA bin 加进 PATH，保证 nvcc 可用
    _cuda_bin = os.path.join(_cuda_home, "bin")
    if _cuda_bin not in os.environ.get("PATH", ""):
        os.environ["PATH"] = _cuda_bin + os.pathsep + os.environ.get("PATH", "")
    print(f"[BUILD] CUDA_HOME = {_cuda_home}")
else:
    print("[BUILD] WARNING: CUDA_HOME not found, CUDA kernel compilation may fail")

# ── MSVC 环境完整初始化 ───────────────────────────────────────────
# 仅把 cl.exe 加入 PATH 不够；必须运行 vcvarsall.bat x64 才能设置
# INCLUDE / LIB / LIBPATH 等变量，否则 ninja 调 cl.exe 找不到头文件。
import pathlib as _pathlib
import subprocess as _sp2

def _setup_msvc_env():
    # 1. 先确定 cl.exe 路径（已在 PATH 或扫描常见目录）
    cl_path = shutil.which("cl")
    if not cl_path:
        patterns = [
            r"C:\\Program Files\\Microsoft Visual Studio\\*\\*\\VC\\Tools\\MSVC\\*\\bin\\Hostx64\\x64",
            r"C:\\Program Files (x86)\\Microsoft Visual Studio\\*\\*\\VC\\Tools\\MSVC\\*\\bin\\Hostx64\\x64",
        ]
        for pat in patterns:
            matches = sorted(glob.glob(pat), reverse=True)
            if matches:
                cl_dir = matches[0]
                os.environ["PATH"] = cl_dir + os.pathsep + os.environ.get("PATH", "")
                cl_path = os.path.join(cl_dir, "cl.exe")
                break
    if not cl_path:
        return False

    print(f"[BUILD] cl.exe: {cl_path}")

    # 2. 从 cl.exe 向上查找 vcvarsall.bat
    #    cl.exe 位于 VC/Tools/MSVC/<ver>/bin/Hostx64/x64/
    #    vcvarsall.bat 位于 VC/Auxiliary/Build/
    p = _pathlib.Path(cl_path).resolve()
    vcvars = None
    for _ in range(10):
        p = p.parent
        candidate = p / "Auxiliary" / "Build" / "vcvarsall.bat"
        if candidate.exists():
            vcvars = candidate
            break

    if not vcvars:
        print("[BUILD] WARNING: vcvarsall.bat not found, INCLUDE/LIB may be missing")
        return True  # cl.exe 在 PATH，尽力而为

    # 3. 运行 vcvarsall.bat x64 并把它导出的环境变量应用到当前进程
    print(f"[BUILD] 初始化 MSVC 环境: {vcvars}")
    try:
        result = _sp2.run(
            f'"{vcvars}" x64 > nul 2>&1 && set',
            capture_output=True, text=True, shell=True, timeout=60,
        )
        applied = 0
        for line in result.stdout.splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                os.environ[k] = v
                applied += 1
        print(f"[BUILD] MSVC 环境变量已应用（{applied} 条）")
    except Exception as _e:
        print(f"[BUILD] WARNING: vcvarsall.bat 执行失败: {_e}")
    return True

if not _setup_msvc_env():
    print("[BUILD] WARNING: MSVC cl.exe not found!")
    print("[BUILD]   请在设置页点击「安装编译工具」按钮安装轻量版编译工具")

# ── ninja 检测 ────────────────────────────────────────────────────
if shutil.which("ninja"):
    print(f"[BUILD] ninja found: {shutil.which('ninja')}")
else:
    print("[BUILD] WARNING: ninja not found, falling back to make/MSBuild")

# ── 诊断摘要 ──────────────────────────────────────────────────────
try:
    _nvcc = _sp2.run(["nvcc", "--version"], capture_output=True, text=True, timeout=10)
    print(f"[BUILD] nvcc: {_nvcc.stdout.strip().splitlines()[-1] if _nvcc.stdout else 'not found'}")
except Exception as _e:
    print(f"[BUILD] nvcc not reachable: {_e}")

os.environ["WKV"] = "CUDA"
os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "max_split_size_mb:512,garbage_collection_threshold:0.8"
os.environ["VSLANG"] = "1033"  # 强制 MSVC cl.exe 输出英文，避免 GBK 乱码
os.environ["FUSED_KERNEL"] = "0"
os.environ["RWKV_TRAIN_TYPE"] = "none"
os.environ["RWKV_HEAD_SIZE_A"] = "64"
os.environ["RWKV_MY_TESTING"] = "x070"
os.environ["RWKV_TRAIN_TYPE"] = "state"
os.environ["RWKV_FLOAT_MODE"] = "$p"

# ── 修复 rwkvop.py 中错误的 nvcc 标志，并清理失败的编译缓存 ─────────
# 问题："-Xptxas -O3" 作为单一字符串传给 nvcc，nvcc 不识别带空格的参数。
# 修复：改为 "-Xptxas=-O3"（等号连接），nvcc 可正确解析。
import pathlib as _pl2
import shutil as _shu2

_rwkvop = _pl2.Path(r"${repoPath.value}") / "model" / "rwkv7" / "operator" / "rwkvop.py"
if _rwkvop.exists():
    _txt = _rwkvop.read_text(encoding="utf-8")
    _fixed = _txt
    _changes = []
    if '"-Xptxas -O3"' in _fixed or "'-Xptxas -O3'" in _fixed:
        _fixed = _fixed.replace('"-Xptxas -O3"', '"-Xptxas=-O3"').replace("'-Xptxas -O3'", "'-Xptxas=-O3'")
        _changes.append("-Xptxas -O3 → -Xptxas=-O3")
    if '--allow-unsupported-compiler' not in _fixed:
        _fixed = _fixed.replace('extra_cuda_cflags=flags', 'extra_cuda_cflags=flags + ["--allow-unsupported-compiler"]')
        _changes.append("added --allow-unsupported-compiler")
    if _changes:
        _rwkvop.write_text(_fixed, encoding="utf-8")
        print(f"[BUILD] 已修复 rwkvop.py: {', '.join(_changes)}")
    else:
        print("[BUILD] rwkvop.py 标志检查通过（无需修复）")
else:
    print(f"[BUILD] WARNING: rwkvop.py 未找到: {_rwkvop}")

# 清除上次失败留下的损坏编译缓存，避免 ninja 直接使用坏的中间文件
_cache_root = _pl2.Path(os.environ.get("LOCALAPPDATA", "")) / "torch_extensions" / "torch_extensions" / "Cache"
for _stale in _cache_root.glob("*/rwkv7_state_clampw"):
    _shu2.rmtree(_stale, ignore_errors=True)
    print(f"[BUILD] 已清理旧编译缓存: {_stale}")

import torch
import torch.nn as nn
from torch.optim import Adam
from model.rwkv7.model import RWKV7
from dataset import JSONLDataset
from tqdm import tqdm


class ModelArgs:
    vocab_size = ${vocabSize.value}
    n_embd = ${nEmbd.value}
    n_layer = ${nLayer.value}
    ctx_len = ${ctxLen.value}
    head_size_a = 64
    head_size_divisor = 8


class TrainArgs:
    load_model = r"${modelPath.value}"
    data_path = r"${dataPath.value}"
    output_dir = r"${outputDir.value}"
    precision = "$p"
    batch_size = ${batchSize.value}
    num_steps = ${numSteps.value}
    num_epochs = ${numEpochs.value}
    learning_rate = ${learningRate.value}


model_args = ModelArgs()
train_args = TrainArgs()

# ── 从 checkpoint 自动检测模型尺寸，避免 UI 配置与权重不匹配 ─────────
print(f"Loading model from: {train_args.load_model}")
_ckpt = torch.load(train_args.load_model, map_location="cpu", weights_only=True)
if "head.weight" in _ckpt:
    _detected_vocab = _ckpt["head.weight"].shape[0]
    _detected_embd  = _ckpt["head.weight"].shape[1]
    if _detected_embd != model_args.n_embd or _detected_vocab != model_args.vocab_size:
        print(f"[AUTO] 检测到模型尺寸与 UI 配置不符，自动修正：")
        print(f"[AUTO]   n_embd:    {model_args.n_embd} → {_detected_embd}")
        print(f"[AUTO]   vocab_size: {model_args.vocab_size} → {_detected_vocab}")
        model_args.n_embd    = _detected_embd
        model_args.vocab_size = _detected_vocab
import re as _re
_detected_layers = max(
    (int(_re.match(r"blocks\.(\d+)\.", k).group(1)) for k in _ckpt if _re.match(r"blocks\.(\d+)\.", k)),
    default=model_args.n_layer - 1
) + 1
if _detected_layers != model_args.n_layer:
    print(f"[AUTO]   n_layer:   {model_args.n_layer} → {_detected_layers}")
    model_args.n_layer = _detected_layers
model_args.dim_att = model_args.n_embd
model_args.dim_ffn = model_args.n_embd * 4

device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Device: {device}")
model = RWKV7(model_args)
model = model.to(device)
model.load_state_dict(_ckpt, strict=False)
del _ckpt

if train_args.precision == "bf16":
    model = model.to(torch.bfloat16)
elif train_args.precision == "fp16":
    model = model.to(torch.float16)

for name, param in model.named_parameters():
    if "state" not in name.lower():
        param.requires_grad = False

total_params = sum(p.numel() for p in model.parameters())
trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
print("=" * 60)
print(f"Total params:     {total_params:,}")
print(f"Frozen params:    {total_params - trainable_params:,}")
print(f"Trainable params: {trainable_params:,}")
print("=" * 60)

optimizer = Adam(
    filter(lambda p: p.requires_grad, model.parameters()),
    lr=train_args.learning_rate,
)

dataset = JSONLDataset(train_args.data_path)


def get_batch():
    return dataset.get_batch(train_args.batch_size, model_args.ctx_len, model_args.vocab_size)


def chunked_cross_entropy(logits, labels, chunk=512):
    """分块计算 cross_entropy，避免大词表下 fp32 中间量撑爆显存。
    每块只需 chunk * vocab * 4 bytes 临时显存，而非全序列一次性分配。"""
    flat_logits = logits.view(-1, logits.size(-1))
    flat_labels = labels.view(-1)
    n = flat_logits.size(0)
    total_loss = flat_logits.new_zeros(())
    for i in range(0, n, chunk):
        cl = nn.functional.cross_entropy(flat_logits[i:i+chunk], flat_labels[i:i+chunk])
        total_loss = total_loss + cl * (flat_labels[i:i+chunk].size(0) / n)
    return total_loss


model.train()
pbar = tqdm(range(train_args.num_steps), desc="Training", ncols=100)
for step in pbar:
    input_ids, labels = get_batch()
    logits = model(input_ids)
    loss = chunked_cross_entropy(logits, labels)
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()
    pbar.set_postfix({"loss": f"{loss.item():.4f}"})
    sys.stdout.flush()

print("\\nTraining completed!")

os.makedirs(train_args.output_dir, exist_ok=True)
model_name = os.path.basename(train_args.load_model).replace(".pth", ".state")
save_path = os.path.join(train_args.output_dir, model_name)
state_dict_to_save = {
    name.replace("model.", ""): param.cpu()
    for name, param in model.named_parameters()
    if "state" in name.lower()
}
torch.save(state_dict_to_save, save_path)
print(f"Saved {len(state_dict_to_save)} state weights to: {save_path}")
''';
  }

  Future<void> startTraining() async {
    if (isTraining.value) return;
    if (repoPath.value.isEmpty) {
      Get.snackbar('错误', '请先在「数据」标签页设置仓库路径');
      return;
    }
    if (modelPath.value.isEmpty) {
      Get.snackbar('错误', '请设置模型文件路径 (.pth)');
      return;
    }
    if (dataPath.value.isEmpty) {
      Get.snackbar('错误', '请设置训练数据路径 (.jsonl)');
      return;
    }

    isTraining.value = true;
    status.value = '训练中';
    trainingLog.value = '';
    _lossMap.clear();
    lossHistory.value = [];
    currentTabIndex.value = 3;

    try {
      final scriptPath =
          '${repoPath.value}${Platform.pathSeparator}_flutter_train.py';
      await File(scriptPath).writeAsString(_buildTrainingScript());
      trainingLog.value += '✓ 训练脚本已生成: $scriptPath\n';
      trainingLog.value += '${'=' * 50}\n\n';

      _trainingProcess = await Process.start(
        'python',
        // -X utf8 强制 Python 以 UTF-8 输出，避免 Windows 系统编码（GBK）混入
        ['-u', '-X', 'utf8', '_flutter_train.py'],
        workingDirectory: repoPath.value,
        runInShell: true,
      );

      // allowMalformed:true 防止偶发的非 UTF-8 字节（如 tqdm 进度条特殊字符）
      // 导致 FormatException 崩溃、stream listener 中断
      const _dec = Utf8Codec(allowMalformed: true);
      _trainingProcess!.stdout.transform(_dec.decoder).listen((data) {
        trainingLog.value += data;
        _parseLoss(data);
      });
      _trainingProcess!.stderr.transform(_dec.decoder).listen((data) {
        trainingLog.value += data;
        _parseLoss(data);
      });

      _trainingProcess!.exitCode.then((code) {
        isTraining.value = false;
        status.value = code == 0 ? '训练完成' : '训练异常';
        if (code == 0) {
          trainingLog.value += '\n${'=' * 50}\n✓ 训练成功完成！\n';
          Get.snackbar('训练完成', '模型已保存到 ${outputDir.value}');
          refreshOutputFiles();
        } else {
          trainingLog.value += '\n✗ 训练异常退出 (exit: $code)\n';
          Get.snackbar('训练失败', '请查看监控日志');
        }
      });
    } catch (e) {
      trainingLog.value += '启动失败: $e\n';
      isTraining.value = false;
      status.value = '空闲';
      Get.snackbar('启动失败', '$e');
    }
  }

  /// 从 tqdm 日志片段中提取 (step, loss) 并更新 lossHistory。
  /// tqdm 格式: | 12/1000 [..., loss=2.3456]
  void _parseLoss(String data) {
    final re = RegExp(r'\|\s*(\d+)/\d+.*?loss=([\d.]+)');
    bool changed = false;
    for (final m in re.allMatches(data)) {
      final step = int.tryParse(m.group(1)!) ?? 0;
      final loss = double.tryParse(m.group(2)!) ?? 0;
      if (step > 0 && loss > 0) {
        _lossMap[step] = loss;
        changed = true;
      }
    }
    if (changed) {
      final sorted = _lossMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      lossHistory.value = sorted.map((e) => e.value).toList();
    }
  }

  Future<void> stopTraining() async {
    if (_trainingProcess != null) {
      final pid = _trainingProcess!.pid;
      // Windows 上 runInShell:true 会在 cmd.exe 里启动 Python，
      // 直接 kill() 只杀掉壳进程，Python 子进程仍在运行。
      // taskkill /F /T 强制终止整个进程树（含所有子进程）。
      await Process.run(
        'taskkill', ['/F', '/T', '/PID', '$pid'],
        runInShell: true,
      );
      _trainingProcess = null;
    }
    isTraining.value = false;
    status.value = '已停止';
    trainingLog.value += '\n⏹ 训练已手动停止\n';
  }

  Future<void> refreshOutputFiles() async {
    final resolvedPath =
        outputDir.value.startsWith('./') || outputDir.value == '.'
        ? '${repoPath.value}${Platform.pathSeparator}${outputDir.value}'
        : outputDir.value;
    final dir = Directory(resolvedPath);
    if (!await dir.exists()) {
      outputFiles.value = [];
      return;
    }
    final files = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File) files.add(entity.path);
    }
    outputFiles.value = files;
  }

  // --- Environment ---

  Future<void> installEnvironment() async {
    if (isInstalling.value) return;
    isInstalling.value = true;
    installLog.value = '';

    try {
      // ── 1. 检测 pip ───────────────────────────────────────────────
      installLog.value += '▶ 检测 Python / pip 环境...\n';
      final pipResult = await Process.run(
        'pip',
        ['--version'],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (pipResult.exitCode != 0) {
        installLog.value += '✗ 未找到 pip，请先安装 Python 并确保已添加到 PATH\n';
        Get.snackbar('安装失败', '未找到 pip，请先安装 Python');
        return;
      }
      installLog.value += '✓ ${(pipResult.stdout as String).trim()}\n';

      // ── 2. 显示 pip 源（方便排查网络问题）──────────────────────────
      final indexResult = await Process.run(
        'pip',
        ['config', 'get', 'global.index-url'],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final indexUrl = (indexResult.stdout as String).trim();
      installLog.value +=
          '  pip 源: ${indexUrl.isNotEmpty ? indexUrl : "(默认 PyPI)"}\n\n';

      // ── 3. 确定 torch GPU CUDA wheel 源 ──────────────────────────
      final torchWheelTag = _getCudaWheelTag();
      final torchIndexUrl = 'https://download.pytorch.org/whl/$torchWheelTag';
      installLog.value +=
          '▶ 将安装 GPU (CUDA) 版本 torch\n'
          '  CUDA wheel tag : $torchWheelTag\n'
          '  PyTorch 镜像源 : $torchIndexUrl\n\n';

      // ── 4. 逐包安装 ───────────────────────────────────────────────
      final failed = <String>[];
      for (final pkg in _envPackages) {
        installLog.value += '─' * 50 + '\n';
        installLog.value += '▶ 安装 $pkg ...\n';

        if (pkg.startsWith('torch')) {
          // ── torch：先卸载旧版本，再用 Process.run 从 GPU wheel 源安装 ──
          // 使用 Process.run（阻塞式）而非 Process.start，避免 Windows 上
          // 异步流监听器与 exitCode 之间的竞态导致 stderr 输出丢失。
          installLog.value += '  先卸载已安装的 torch（避免 CPU/GPU 版本冲突）...\n';
          final uninstall = await Process.run(
            'pip',
            ['uninstall', 'torch', '-y'],
            runInShell: true,
            stdoutEncoding: utf8,
            stderrEncoding: utf8,
          );
          final uninstallLines = [
            (uninstall.stdout as String).trim(),
            (uninstall.stderr as String).trim(),
          ].where((s) => s.isNotEmpty).join('\n');
          if (uninstallLines.isNotEmpty) {
            installLog.value += '  $uninstallLines\n';
          }

          installLog.value += '  正在从 PyTorch GPU 源下载，文件约 1–2 GB，请耐心等待...\n';

          final torchResult = await Process.run(
            'pip',
            [
              'install',
              pkg,
              '--index-url',
              torchIndexUrl,
              '--no-warn-script-location',
              '--timeout',
              '300',
            ],
            runInShell: true,
            stdoutEncoding: utf8,
            stderrEncoding: utf8,
          );
          final torchOut = (torchResult.stdout as String).trim();
          final torchErr = (torchResult.stderr as String).trim();
          if (torchOut.isNotEmpty) installLog.value += '$torchOut\n';
          if (torchErr.isNotEmpty) installLog.value += '$torchErr\n';

          if (torchResult.exitCode == 0) {
            installLog.value += '✓ $pkg 安装成功\n\n';
          } else {
            failed.add(pkg);
            installLog.value +=
                '\n✗ $pkg 安装失败 (exit: ${torchResult.exitCode})\n\n';
          }
          continue; // 跳过下方通用安装逻辑
        }

        // ── 其余包：保持原有流式安装方式 ─────────────────────────────────
        final pipArgs = ['install', pkg, '--no-warn-script-location'];

        final process = await Process.start('pip', pipArgs, runInShell: true);

        // 同时等待 stdout/stderr 流耗尽，避免输出截断
        final stdoutBuf = StringBuffer();
        final stderrBuf = StringBuffer();
        await Future.wait([
          process.stdout.transform(utf8.decoder).forEach((d) {
            stdoutBuf.write(d);
            installLog.value += d;
          }),
          process.stderr.transform(utf8.decoder).forEach((d) {
            stderrBuf.write(d);
            installLog.value += d;
          }),
        ]);

        final code = await process.exitCode;
        if (code == 0) {
          installLog.value += '✓ $pkg 安装成功\n\n';
        } else {
          failed.add(pkg);
          installLog.value += '\n✗ $pkg 安装失败 (exit: $code)\n\n';
        }
      }

      // ── 4. 汇总结果 ───────────────────────────────────────────────
      installLog.value += '=' * 50 + '\n';
      if (failed.isEmpty) {
        installLog.value += '✓ 全部依赖安装完成！\n';
        Get.snackbar('安装成功', '全部依赖已安装完成');
        await checkEnvironment();
      } else {
        installLog.value += '✗ 以下包安装失败，请查看上方日志：\n';
        for (final f in failed) {
          installLog.value += '   • $f\n';
        }
        Get.snackbar(
          '安装部分失败',
          '${failed.join("、")} 安装失败，请查看日志',
          duration: const Duration(seconds: 6),
        );
      }
    } catch (e) {
      installLog.value += '\n异常: $e';
      Get.snackbar('安装失败', '$e');
    } finally {
      isInstalling.value = false;
    }
  }

  /// 安装 CUDA 扩展编译所需的轻量工具链：
  ///   1. pip install ninja  （几 MB，构建系统）
  ///   2. winget 仅安装 MSVC C++ 编译器 + Windows SDK（~1.5 GB，无 IDE）
  Future<void> installBuildTools() async {
    if (isBuildToolsInstalling.value) return;
    isBuildToolsInstalling.value = true;
    buildToolsLog.value = '';

    try {
      // ── 1. ninja ─────────────────────────────────────────────────
      buildToolsLog.value += '▶ 安装 ninja 构建工具...\n';
      final ninjaResult = await Process.run(
        'pip',
        ['install', 'ninja', '--no-warn-script-location'],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final ninjaOut = (ninjaResult.stdout as String).trim();
      final ninjaErr = (ninjaResult.stderr as String).trim();
      if (ninjaOut.isNotEmpty) buildToolsLog.value += '$ninjaOut\n';
      if (ninjaErr.isNotEmpty) buildToolsLog.value += '$ninjaErr\n';
      buildToolsLog.value += ninjaResult.exitCode == 0
          ? '✓ ninja 安装成功\n\n'
          : '✗ ninja 安装失败\n\n';

      // ── 2. 检测是否已有 cl.exe ────────────────────────────────────
      final clCheck = await Process.run(
        'where',
        ['cl'],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (clCheck.exitCode == 0) {
        buildToolsLog.value +=
            '✓ 已检测到 MSVC cl.exe，无需重复安装\n'
            '  ${(clCheck.stdout as String).trim()}\n';
        Get.snackbar(
          '编译工具',
          '已检测到 MSVC，无需重复安装',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // ── 3. 用 winget 安装最小化 MSVC（仅编译器 + Windows SDK）────
      buildToolsLog.value +=
          '▶ 正在通过 winget 安装 MSVC C++ 编译器...\n'
          '  仅安装编译器组件，约 1.5 GB（无 IDE）\n'
          '  系统将弹出 UAC 权限提示，请点击「是」\n\n';

      final msvcResult = await Process.run(
        'winget',
        [
          'install',
          '--id',
          'Microsoft.VisualStudio.2022.BuildTools',
          '--override',
          '--passive --wait '
              '--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 '
              '--add Microsoft.VisualStudio.Component.Windows11SDK.22621',
        ],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final msvcOut = (msvcResult.stdout as String).trim();
      final msvcErr = (msvcResult.stderr as String).trim();
      if (msvcOut.isNotEmpty) buildToolsLog.value += '$msvcOut\n';
      if (msvcErr.isNotEmpty) buildToolsLog.value += '$msvcErr\n';

      if (msvcResult.exitCode == 0) {
        buildToolsLog.value +=
            '\n✓ MSVC 编译工具安装完成！\n'
            '  请重启应用后重新运行训练\n';
        Get.snackbar(
          '安装完成',
          'MSVC 已安装，请重启应用后再训练',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 6),
        );
      } else {
        buildToolsLog.value +=
            '\n✗ winget 安装失败 (exit: ${msvcResult.exitCode})\n'
            '  请手动下载 VS Build Tools（免费，仅选 C++ 编译器）：\n'
            '  https://aka.ms/vs/17/release/vs_buildtools.exe\n'
            '  安装时只勾选 "MSVC v143" 和 "Windows SDK" 两项即可\n';
        Get.snackbar(
          '安装失败',
          '请手动安装 VS Build Tools',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 8),
        );
      }
    } catch (e) {
      buildToolsLog.value += '异常: $e\n';
      Get.snackbar('安装失败', '$e');
    } finally {
      isBuildToolsInstalling.value = false;
    }
  }

  Future<void> checkEnvironment() async {
    if (isChecking.value) return;
    isChecking.value = true;
    checkLog.value = '正在检测环境...\n';
    envReady.value = false;
    try {
      final missing = <String>[];
      for (final pkg in _envCheckPackages) {
        final result = await Process.run(
          'pip',
          ['show', pkg],
          runInShell: true,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        if (result.exitCode == 0) {
          checkLog.value += '✓ $pkg 已安装\n';
        } else {
          checkLog.value += '✗ $pkg 未安装\n';
          missing.add(pkg);
        }
      }

      // 额外检测 torch 是否为 GPU (CUDA) 版本
      bool torchHasCuda = false;
      if (!missing.contains('torch')) {
        checkLog.value += '\n▶ 检测 torch CUDA 支持...\n';
        final cudaCheck = await Process.run(
          'python',
          [
            '-c',
            'import torch; '
                'avail = torch.cuda.is_available(); '
                'ver = torch.version.cuda or "N/A"; '
                'print(f"cuda_available={avail}  cuda_version={ver}"); '
                'exit(0 if avail else 1)',
          ],
          runInShell: true,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        final cudaOut = (cudaCheck.stdout as String).trim();
        if (cudaCheck.exitCode == 0) {
          torchHasCuda = true;
          checkLog.value += '✓ torch GPU (CUDA) 版本正常  [$cudaOut]\n';
        } else {
          checkLog.value +=
              '✗ torch 未检测到 CUDA GPU 支持（当前为 CPU 版本）\n'
              '  请点击「一键安装」重新安装 GPU 版本 torch\n';
          if (cudaOut.isNotEmpty) checkLog.value += '  详情: $cudaOut\n';
          missing.add('torch(CUDA)');
        }
      }

      if (missing.isEmpty) {
        envReady.value = true;
        checkLog.value += '\n所有环境已经准备好';
        Get.snackbar('环境检测', '所有环境已准备好', snackPosition: SnackPosition.TOP);
      } else {
        checkLog.value += '\n缺少或需重装: ${missing.join(", ")}';
        if (!torchHasCuda && missing.contains('torch(CUDA)')) {
          Get.snackbar(
            '环境检测',
            'torch 未启用 CUDA，请点击「一键安装」安装 GPU 版本',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      checkLog.value += '检测异常: $e';
    } finally {
      isChecking.value = false;
    }
  }
}
