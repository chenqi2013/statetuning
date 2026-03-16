import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final cudaInstalled = false.obs;
  final isCudaInstalling = false.obs;
  final cudaInstallLog = ''.obs;

  // --- Training State ---
  final isTraining = false.obs;
  final trainingLog = ''.obs;
  // step → loss，用于去重（每步 tqdm 会打两次）
  final _lossMap = <int, double>{};
  final lossHistory = <double>[].obs;
  Process? _trainingProcess;
  // 日志缓冲区 + 定时刷新，避免高频 stdout 触发过多 UI 重建
  // _logLines: 已完成的行列表；_logCurrentLine: 当前未换行的内容
  // 通过正确处理 \r（tqdm 覆写进度条），避免日志无限膨胀
  final _logLines = <String>[];
  String _logCurrentLine = '';
  Timer? _logFlushTimer;

  // --- Repo State ---
  final isCloningRepo = false.obs;
  final repoLog = ''.obs;
  final repoCloned = false.obs;

  // --- 系统基础（全新电脑首要依赖）---
  final wingetInstalled = false.obs;
  final nvidiaDriverInstalled = false.obs;

  // --- Git (克隆仓库依赖) ---
  final gitInstalled = false.obs;
  final isGitInstalling = false.obs;
  final gitInstallLog = ''.obs;

  // --- Output Files ---
  final outputFiles = <String>[].obs;

  // --- Environment (statetuning deps) ---
  static const _envPackages = [
    'torch>=2.0.0',
    'transformers>=4.30.0',
    'tqdm>=4.65.0',
    'huggingface-hub',
    'ninja',
    'einops',
  ];
  static const _envCheckPackages = [
    'torch',
    'transformers',
    'tqdm',

    'huggingface_hub',
    'ninja',
    'einops',
  ];
  final isInstalling = false.obs;
  final isDetectingModel = false.obs;
  Timer? _modelDetectTimer;
  final installLog = ''.obs;
  final isChecking = false.obs;
  final envReady = false.obs;
  final checkLog = ''.obs;
  bool _hasGuidedToSettings = false;

  // --- UV + 项目内虚拟环境 (替代系统 Python/pip，依赖装项目目录) ---
  final uvInstalled = false.obs;
  final isUvInstalling = false.obs;
  final uvInstallLog = ''.obs;
  // 兼容旧逻辑，pythonInstalled 表示「有可用 Python」（UV venv 或回退系统）
  final pythonInstalled = false.obs;
  final isPythonInstalling = false.obs;
  final pythonInstallLog = ''.obs;

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
    modelPathController.addListener(() {
      final path = modelPathController.text;
      modelPath.value = path;
      // 防抖：输入停止 800ms 后若路径是 .pth 文件则自动检测
      _modelDetectTimer?.cancel();
      if (path.toLowerCase().endsWith('.pth')) {
        _modelDetectTimer = Timer(const Duration(milliseconds: 800), () {
          _autoDetectModelShape(path);
        });
      }
    });
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

    detectWinget();
    detectNvidiaDriver();
    detectUv();
    detectCudaHome();
    detectPython();
    // 启动时静默检测一次环境
    checkEnvironment();
    // 首次进入自动解压内置仓库到 exe 同目录
    Future.microtask(_ensureRepoExtracted);
    ever(currentTabIndex, (idx) {
      if (idx == 4) {
        detectWinget();
        detectNvidiaDriver();
        detectUv();
        detectPython();
        if (!isChecking.value) checkEnvironment();
        detectCudaHome();
      }
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
    _logFlushTimer?.cancel();
    _modelDetectTimer?.cancel();
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

  /// 在浏览器中打开链接（仅 Windows）
  Future<void> openUrl(String url) async {
    if (Platform.operatingSystem == 'windows') {
      try {
        await Process.run('cmd', ['/c', 'start', '', url], runInShell: true);
      } catch (_) {}
    }
  }

  /// 检测 winget 是否可用（一键安装 Git/Python/CUDA/MSVC 的先决条件）
  Future<void> detectWinget() async {
    if (Platform.operatingSystem != 'windows') {
      wingetInstalled.value = false;
      return;
    }
    try {
      final r = await Process.run(
        'winget',
        ['--version'],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      wingetInstalled.value = r.exitCode == 0;
    } catch (_) {
      wingetInstalled.value = false;
    }
  }

  /// 检测 NVIDIA 驱动是否已安装（GPU 训练需先装驱动，再装 CUDA Toolkit）
  Future<void> detectNvidiaDriver() async {
    try {
      final r = await Process.run(
        'nvidia-smi',
        [],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      nvidiaDriverInstalled.value = r.exitCode == 0;
    } catch (_) {
      nvidiaDriverInstalled.value = false;
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
        // 按版本号排序（如 v12.8 < v13.2），取最大
        versions.sort((a, b) {
          final va = _parseCudaVersionFromPath(a);
          final vb = _parseCudaVersionFromPath(b);
          if (va == null) return 1;
          if (vb == null) return -1;
          if (va.$1 != vb.$1) return va.$1.compareTo(vb.$1);
          return va.$2.compareTo(vb.$2);
        });
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
        '✗ 未自动检测到 CUDA，请手动选择安装目录或点击「一键安装 CUDA」\n'
        '  常见路径: C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\v12.x 或 v13.x\n';
    cudaInstalled.value = false;
  }

  void _setCudaHome(String path) {
    cudaHome.value = path;
    cudaHomeController.text = path;
    cudaInstalled.value = true;
  }

  /// 从路径中解析 CUDA 版本，如 .../v12.8/... 或 .../CUDA/v13.2/... 返回 (12,8) 或 (13,2)
  (int, int)? _parseCudaVersionFromPath(String path) {
    final segments = path.replaceAll('\\', '/').split('/');
    for (final seg in segments.reversed) {
      final m = RegExp(r'^[vV]?(\d+)\.(\d+)').firstMatch(seg);
      if (m != null) {
        final major = int.tryParse(m.group(1)!);
        final minor = int.tryParse(m.group(2)!);
        if (major != null && minor != null) return (major, minor);
      }
    }
    return null;
  }

  /// 从 cudaHome 路径提取 CUDA 版本，映射到 PyTorch 支持的 wheel tag。
  /// PyTorch 支持: cu118, cu121, cu124, cu126, cu128, cu130 等。
  /// 若无法解析或版本较新则返回兼容的最近 tag。
  String _getCudaWheelTag() {
    final home = cudaHome.value;
    if (home.isNotEmpty) {
      final segments = home.replaceAll('\\', '/').split('/');
      for (final seg in segments.reversed) {
        final m = RegExp(r'^[vV]?(\d+)\.(\d+)').firstMatch(seg);
        if (m != null) {
          final major = int.tryParse(m.group(1)!) ?? 0;
          final minor = int.tryParse(m.group(2)!) ?? 0;
          // 映射到 PyTorch 实际支持的 tag
          if (major == 11) return minor <= 8 ? 'cu118' : 'cu118';
          if (major == 12) {
            if (minor <= 1) return 'cu121';
            if (minor <= 4) return 'cu124';
            if (minor <= 6) return 'cu126';
            if (minor <= 8) return 'cu128';
            return 'cu128'; // 12.9+ 用 cu128
          }
          if (major >= 13) return 'cu130'; // 13.0, 13.2 等用 cu130
        }
      }
    }
    return 'cu128'; // 未检测到时用较新版本
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

  /// 通过 winget 一键安装 CUDA 最新版（需管理员权限）
  Future<void> installCuda() async {
    if (isCudaInstalling.value) return;
    if (Platform.operatingSystem != 'windows') {
      Get.snackbar('提示', '一键安装 CUDA 仅支持 Windows');
      return;
    }
    if (!wingetInstalled.value) {
      Get.snackbar(
        '需先安装 winget',
        '请先安装「应用安装程序」以使用一键安装，详见设置页顶部',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
      return;
    }
    isCudaInstalling.value = true;
    cudaInstallLog.value = '';
    try {
      cudaInstallLog.value =
          '▶ 正在通过 winget 安装 CUDA 最新版...\n'
          '  包: Nvidia.CUDA（自动选择最新版本）\n'
          '  系统会弹出 UAC 权限提示，请点击「是」\n'
          '  安装过程可能需 5–15 分钟，请耐心等待\n\n';
      final result = await Process.run(
        'winget',
        [
          'install',
          '-e',
          '--id',
          'Nvidia.CUDA',
          '--accept-package-agreements',
          '--accept-source-agreements',
        ],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final out = (result.stdout as String).trim();
      final err = (result.stderr as String).trim();
      if (out.isNotEmpty) cudaInstallLog.value += '$out\n';
      if (err.isNotEmpty) cudaInstallLog.value += '$err\n';
      cudaInstallLog.value += result.exitCode == 0
          ? '\n✓ CUDA 安装完成！请点击「自动检测」刷新路径，或重启应用。'
          : '\n✗ 安装失败 (exit: ${result.exitCode})，可尝试从 NVIDIA 官网手动下载安装。';
      if (result.exitCode == 0) {
        await detectCudaHome();
        Get.snackbar(
          '安装完成',
          'CUDA 已安装，请重启应用后开始训练',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      cudaInstallLog.value += '\n✗ 执行出错: $e';
      Get.snackbar('安装失败', '$e');
    } finally {
      isCudaInstalling.value = false;
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
      _modelDetectTimer?.cancel(); // 取消防抖，避免与下方直接调用重复
      modelPathController.text = path;
      _modelDetectTimer?.cancel(); // 设置 text 会再次触发 listener，再取消一次
      await _autoDetectModelShape(path);
    }
  }

  /// 读取 .pth checkpoint，自动检测并更新模型尺寸参数。
  Future<void> _autoDetectModelShape(String pthPath) async {
    if (isDetectingModel.value) return;
    if (!await File(pthPath).exists()) return;
    isDetectingModel.value = true;
    // 写入临时 Python 脚本文件，避免 Windows shell 对 -c 多行代码的破坏
    final tmpScript = File(
      '${Directory.systemTemp.path}\\rwkv_detect_shape.py',
    );
    await tmpScript.writeAsString(
      'import torch, re, sys\n'
      'path = sys.argv[1]\n'
      'try:\n'
      '    ckpt = torch.load(path, map_location="cpu", weights_only=True)\n'
      'except Exception:\n'
      '    ckpt = torch.load(path, map_location="cpu", weights_only=False)\n'
      'n_embd = ckpt["head.weight"].shape[1] if "head.weight" in ckpt else -1\n'
      'vocab  = ckpt["head.weight"].shape[0] if "head.weight" in ckpt else -1\n'
      'layers = max(\n'
      '    (int(re.match(r"blocks\\.(\\d+)\\.", k).group(1)) for k in ckpt if re.match(r"blocks\\.(\\d+)\\.", k)),\n'
      '    default=-1\n'
      ') + 1\n'
      'print(f"{n_embd},{vocab},{layers}")\n',
      encoding: utf8,
    );
    try {
      final py = _venvPythonPath ?? 'python';
      final result = await Process.run(
        py,
        ['-X', 'utf8', tmpScript.path, pthPath],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (result.exitCode != 0) {
        Get.snackbar(
          '模型尺寸检测失败',
          (result.stderr as String).trim().isNotEmpty
              ? (result.stderr as String).trim()
              : '无法读取模型文件',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
        return;
      }
      final parts = (result.stdout as String).trim().split(',');
      if (parts.length < 3) return;
      final detectedEmbd = int.tryParse(parts[0]) ?? -1;
      final detectedVocab = int.tryParse(parts[1]) ?? -1;
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
      if (detectedEmbd > 0 || detectedVocab > 0 || detectedLayers > 0) {
        selectedPreset.value = '自定义';
        Get.snackbar(
          '模型尺寸已自动检测',
          'n_embd=$detectedEmbd  n_layer=$detectedLayers  vocab=$detectedVocab',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        '模型尺寸检测出错',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
    } finally {
      isDetectingModel.value = false;
    }
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

  /// 检测 Git 是否已安装（克隆仓库依赖）
  Future<void> detectGit() async {
    try {
      final r = await Process.run(
        'git',
        ['--version'],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      gitInstalled.value = r.exitCode == 0;
    } catch (_) {
      gitInstalled.value = false;
    }
  }

  /// 通过 winget 一键安装 Git
  Future<void> installGit() async {
    if (isGitInstalling.value) return;
    if (Platform.operatingSystem != 'windows') {
      Get.snackbar('提示', '一键安装 Git 仅支持 Windows');
      return;
    }
    if (!wingetInstalled.value) {
      Get.snackbar(
        '需先安装 winget',
        '请先安装「应用安装程序」以使用一键安装，详见设置页顶部',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
      return;
    }
    isGitInstalling.value = true;
    gitInstallLog.value = '';
    try {
      gitInstallLog.value =
          '▶ 正在通过 winget 安装 Git...\n'
          '  系统会弹出 UAC 权限提示，请点击「是」\n\n';
      final result = await Process.run(
        'winget',
        [
          'install',
          '-e',
          '--id',
          'Git.Git',
          '--accept-package-agreements',
          '--accept-source-agreements',
        ],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final out = (result.stdout as String).trim();
      final err = (result.stderr as String).trim();
      if (out.isNotEmpty) gitInstallLog.value += '$out\n';
      if (err.isNotEmpty) gitInstallLog.value += '$err\n';
      gitInstallLog.value += result.exitCode == 0
          ? '\n✓ Git 安装完成！请点击「检测 Git」或重启应用。'
          : '\n✗ 安装失败 (exit: ${result.exitCode})，可从 https://git-scm.com 手动下载安装。';
      if (result.exitCode == 0) {
        await detectGit();
        Get.snackbar(
          '安装完成',
          'Git 已安装，可以进行克隆操作',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      gitInstallLog.value += '\n✗ 执行出错: $e';
      Get.snackbar('安装失败', '$e');
    } finally {
      isGitInstalling.value = false;
    }
  }

  /// 默认仓库路径：exe 所在目录下的 statetuning_repo
  String _getDefaultRepoPath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return '$exeDir${Platform.pathSeparator}statetuning_repo';
  }

  /// 首次进入时自动解压内置仓库到默认路径，无需用户操作
  Future<void> _ensureRepoExtracted() async {
    isCloningRepo.value = true;
    try {
      final defaultPath = _getDefaultRepoPath();
      final trainFile = File('$defaultPath${Platform.pathSeparator}train.py');
      if (await trainFile.exists()) {
        repoPath.value = defaultPath;
        repoPathController.text = defaultPath;
        repoCloned.value = true;
        repoLog.value = '✓ 仓库已就绪: $defaultPath';
        return;
      }
      repoPath.value = defaultPath;
      repoPathController.text = defaultPath;
      await _extractZipToPath(defaultPath, managedByCaller: true);
    } finally {
      isCloningRepo.value = false;
    }
  }

  /// 将内置 zip 解压到指定路径（供 _ensureRepoExtracted 和 initRepoFromBundle 复用）
  /// [managedByCaller] 为 true 时由调用方管理 isCloningRepo，内部不再设置
  Future<void> _extractZipToPath(
    String targetPath, {
    bool managedByCaller = false,
  }) async {
    if (!managedByCaller && isCloningRepo.value) return;
    if (!managedByCaller) isCloningRepo.value = true;
    repoCloned.value = false;
    repoLog.value = '正在解压内置仓库到 $targetPath ...\n';
    try {
      final dir = Directory(targetPath);
      if (!await dir.exists()) await dir.create(recursive: true);
      final data = await rootBundle.load('assets/statetuning_repo.zip');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final archive = ZipDecoder().decodeBytes(bytes);
      final sep = Platform.pathSeparator;
      final base = targetPath.endsWith(sep) ? targetPath : '$targetPath$sep';
      for (final file in archive) {
        final name = file.name.replaceAll('\\', '/');
        if (file.isFile) {
          final relPath = name.replaceAll('/', sep);
          final outFile = File('$base$relPath');
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
          repoLog.value += '  ✓ $name\n';
        } else {
          final relPath = name
              .replaceAll('/', sep)
              .replaceAll(RegExp(r'/$'), '');
          if (relPath.isEmpty) continue;
          final outDir = Directory('$base$relPath');
          await outDir.create(recursive: true);
        }
      }
      repoCloned.value = true;
      repoLog.value += '\n✓ 仓库就绪！';
      await checkRepo();
    } catch (e) {
      repoLog.value += '异常: $e';
    } finally {
      if (!managedByCaller) isCloningRepo.value = false;
    }
  }

  /// 手动解压到当前选择的路径（数据 tab 可选）
  Future<void> initRepoFromBundle() async {
    if (repoPath.value.isEmpty) {
      Get.snackbar('提示', '请先选择或输入目标路径');
      return;
    }
    await _extractZipToPath(repoPath.value);
    if (repoCloned.value) {
      Get.snackbar('初始化成功', '仓库已解压到 ${repoPath.value}');
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

# ── Windows: 将 torch/lib 和 CUDA/bin 加入 DLL 搜索路径 ──────────────────
# JIT 编译的 .pyd 加载时需能找到 torch_cuda.dll、cudart64_*.dll 等
if os.name == "nt":
    _repo = r"${repoPath.value}"
    _torch_lib = os.path.join(_repo, "python_venv", "Lib", "site-packages", "torch", "lib")
    if os.path.isdir(_torch_lib):
        os.add_dll_directory(_torch_lib)
        print(f"[BUILD] add_dll_directory: {_torch_lib}")
    if _cuda_home:
        _cuda_bin = os.path.join(_cuda_home, "bin")
        if os.path.isdir(_cuda_bin):
            os.add_dll_directory(_cuda_bin)
            print(f"[BUILD] add_dll_directory: {_cuda_bin}")

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
    # 使用 cp936 解码，避免中文 Windows 下 set 输出导致 UnicodeDecodeError
    print(f"[BUILD] 初始化 MSVC 环境: {vcvars}")
    try:
        _enc = "cp936" if os.name == "nt" else "utf-8"
        result = _sp2.run(
            f'"{vcvars}" x64 > nul 2>&1 && set',
            capture_output=True, text=True, encoding=_enc, shell=True, timeout=60,
        )
        applied = 0
        for line in (result.stdout or "").splitlines():
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
    _logLines.clear();
    _logCurrentLine = '';
    _lossMap.clear();
    lossHistory.value = [];
    currentTabIndex.value = 3;

    try {
      final scriptPath =
          '${repoPath.value}${Platform.pathSeparator}_flutter_train.py';
      await File(scriptPath).writeAsString(_buildTrainingScript());
      _appendLogData('✓ 训练脚本已生成: $scriptPath\n${'=' * 50}\n\n');
      trainingLog.value = _buildLogDisplay();

      final py = _venvPythonPath ?? 'python';
      // 启动训练时注入 PATH：torch/lib 含 CUDA 等 DLL，JIT 编译的 .pyd 加载时需要
      final env = Map<String, String>.from(Platform.environment);
      if (_venvPythonPath != null && repoPath.value.isNotEmpty) {
        final torchLib =
            '${repoPath.value}${Platform.pathSeparator}python_venv'
            '${Platform.pathSeparator}Lib${Platform.pathSeparator}site-packages'
            '${Platform.pathSeparator}torch${Platform.pathSeparator}lib';
        final sep = Platform.pathSeparator;
        env['PATH'] = '$torchLib$sep${env['PATH'] ?? ''}';
        if (cudaHome.value.isNotEmpty) {
          final cudaBin = '${cudaHome.value}${Platform.pathSeparator}bin';
          env['PATH'] = '$cudaBin$sep${env['PATH']}';
        }
      }
      _trainingProcess = await Process.start(
        py,
        ['-u', '-X', 'utf8', '_flutter_train.py'],
        workingDirectory: repoPath.value,
        environment: env,
        runInShell: true,
      );

      // 定时器每 1000ms 刷新一次日志显示，大幅降低 UI 重建频率
      _logFlushTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
        final s = _buildLogDisplay();
        if (s != trainingLog.value) trainingLog.value = s;
      });

      // allowMalformed:true 防止 tqdm 特殊字节导致 stream 中断
      const dec = Utf8Codec(allowMalformed: true);
      void onData(String data) {
        _appendLogData(data);
        _parseLoss(data);
      }

      _trainingProcess!.stdout.transform(dec.decoder).listen(onData);
      _trainingProcess!.stderr.transform(dec.decoder).listen(onData);

      _trainingProcess!.exitCode.then((code) {
        _logFlushTimer?.cancel();
        _logFlushTimer = null;
        // 最终刷新一次，确保末尾日志完整显示
        final suffix = code == 0
            ? '\n${'=' * 50}\n✓ 训练成功完成！\n'
            : '\n✗ 训练异常退出 (exit: $code)\n';
        _appendLogData(suffix);
        trainingLog.value = _buildLogDisplay();

        isTraining.value = false;
        status.value = code == 0 ? '训练完成' : '训练异常';
        if (code == 0) {
          Get.snackbar('训练完成', '模型已保存到 ${outputDir.value}');
          refreshOutputFiles();
        } else {
          Get.snackbar('训练失败', '请查看监控日志');
        }
      });
    } catch (e) {
      _logFlushTimer?.cancel();
      _logFlushTimer = null;
      _appendLogData('启动失败: $e\n');
      trainingLog.value = _buildLogDisplay();
      isTraining.value = false;
      status.value = '空闲';
      Get.snackbar('启动失败', '$e');
    }
  }

  /// 处理一段原始输出，正确模拟终端的 \r / \n / \r\n 行为。
  /// tqdm 用 \r 覆写当前行，不处理则每帧都追加新行导致日志爆炸。
  void _appendLogData(String data) {
    for (int i = 0; i < data.length; i++) {
      final ch = data[i];
      if (ch == '\r') {
        if (i + 1 < data.length && data[i + 1] == '\n') {
          // \r\n → 正常换行
          _logLines.add(_logCurrentLine);
          _logCurrentLine = '';
          i++;
        } else {
          // 单独 \r → 回到行首（tqdm 覆写进度条）
          _logCurrentLine = '';
        }
      } else if (ch == '\n') {
        _logLines.add(_logCurrentLine);
        _logCurrentLine = '';
      } else {
        _logCurrentLine += ch;
      }
    }
  }

  /// 从当前行缓冲区拼出用于显示的字符串，最多保留最后 300 行。
  String _buildLogDisplay({String extra = ''}) {
    const maxLines = 300;
    final lines = _logLines.length > maxLines
        ? _logLines.sublist(_logLines.length - maxLines)
        : _logLines;
    final sb = StringBuffer();
    for (final l in lines) {
      sb.writeln(l);
    }
    if (_logCurrentLine.isNotEmpty) sb.write(_logCurrentLine);
    if (extra.isNotEmpty) sb.write(extra);
    return sb.toString();
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
    _logFlushTimer?.cancel();
    _logFlushTimer = null;
    if (_trainingProcess != null) {
      final pid = _trainingProcess!.pid;
      await Process.run('taskkill', [
        '/F',
        '/T',
        '/PID',
        '$pid',
      ], runInShell: true);
      _trainingProcess = null;
    }
    _appendLogData('\n⏹ 训练已手动停止\n');
    trainingLog.value = _buildLogDisplay();
    isTraining.value = false;
    status.value = '已停止';
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

  /// 项目内 venv 的 Python 路径（repoPath/python_venv/Scripts/python.exe）
  String? get _venvPythonPath {
    if (repoPath.value.isEmpty) return null;
    final p =
        '${repoPath.value}${Platform.pathSeparator}python_venv'
        '${Platform.pathSeparator}Scripts${Platform.pathSeparator}python.exe';
    return p;
  }

  /// 检测 UV 是否已安装
  Future<void> detectUv() async {
    try {
      final r = await Process.run(
        'uv',
        ['--version'],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      uvInstalled.value = r.exitCode == 0;
    } catch (_) {
      uvInstalled.value = false;
    }
  }

  /// 通过 winget 一键安装 UV
  Future<bool> installUv() async {
    if (isUvInstalling.value) return false;
    if (Platform.operatingSystem != 'windows') {
      Get.snackbar('提示', '一键安装 UV 仅支持 Windows');
      return false;
    }
    if (!wingetInstalled.value) {
      Get.snackbar('需先安装 winget', '详见设置页顶部');
      return false;
    }
    isUvInstalling.value = true;
    uvInstallLog.value = '';
    try {
      uvInstallLog.value =
          '▶ 正在通过 winget 安装 UV...\n'
          '  包: astral-sh.uv\n'
          '  系统会弹出 UAC 权限提示，请点击「是」\n\n';
      final result = await Process.run(
        'winget',
        [
          'install',
          '--id',
          'astral-sh.uv',
          '-e',
          '--accept-package-agreements',
          '--accept-source-agreements',
        ],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final out = (result.stdout as String).trim();
      final err = (result.stderr as String).trim();
      if (out.isNotEmpty) uvInstallLog.value += '$out\n';
      if (err.isNotEmpty) uvInstallLog.value += '$err\n';
      uvInstallLog.value += result.exitCode == 0
          ? '\n✓ UV 安装完成！请重启应用。'
          : '\n✗ 安装失败 (exit: ${result.exitCode})';
      if (result.exitCode == 0) {
        await detectUv();
        Get.snackbar(
          '安装完成',
          'UV 已安装，请重启应用',
          duration: const Duration(seconds: 5),
        );
        return true;
      }
      return false;
    } catch (e) {
      uvInstallLog.value += '\n✗ 执行出错: $e';
      Get.snackbar('安装失败', '$e');
      return false;
    } finally {
      isUvInstalling.value = false;
    }
  }

  /// 检测 Python / pip 是否已安装（优先检测项目 venv，其次系统 pip）
  Future<void> detectPython() async {
    final venv = _venvPythonPath;
    if (venv != null) {
      try {
        final r = await Process.run(
          venv,
          ['--version'],
          runInShell: true,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        pythonInstalled.value = r.exitCode == 0;
        return;
      } catch (_) {}
    }
    try {
      final r = await Process.run(
        'pip',
        ['--version'],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      pythonInstalled.value = r.exitCode == 0;
    } catch (_) {
      pythonInstalled.value = false;
    }
  }

  /// 通过 winget 一键安装 Python 3.12
  Future<bool> installPython() async {
    if (isPythonInstalling.value) return false;
    if (Platform.operatingSystem != 'windows') {
      Get.snackbar('提示', '一键安装 Python 仅支持 Windows');
      return false;
    }
    if (!wingetInstalled.value) {
      Get.snackbar(
        '需先安装 winget',
        '请先安装「应用安装程序」以使用一键安装，详见设置页顶部',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
      return false;
    }
    isPythonInstalling.value = true;
    pythonInstallLog.value = '';
    try {
      pythonInstallLog.value =
          '▶ 正在通过 winget 安装 Python 3.12...\n'
          '  系统会弹出 UAC 权限提示，请点击「是」\n'
          '  安装完成后请重启本应用，以便识别新安装的 Python\n\n';
      final result = await Process.run(
        'winget',
        [
          'install',
          '-e',
          '--id',
          'Python.Python.3.12',
          '--accept-package-agreements',
          '--accept-source-agreements',
        ],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final out = (result.stdout as String).trim();
      final err = (result.stderr as String).trim();
      if (out.isNotEmpty) pythonInstallLog.value += '$out\n';
      if (err.isNotEmpty) pythonInstallLog.value += '$err\n';
      pythonInstallLog.value += result.exitCode == 0
          ? '\n✓ Python 3.12 安装完成！\n  请关闭并重新打开本应用，然后点击「一键安装」安装依赖包。'
          : '\n✗ 安装失败 (exit: ${result.exitCode})，可从 https://www.python.org 手动下载安装。';
      if (result.exitCode == 0) {
        await detectPython();
        Get.snackbar(
          '安装完成',
          'Python 已安装，请重启应用后点击「一键安装」继续',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 6),
        );
        return true;
      }
      return false;
    } catch (e) {
      pythonInstallLog.value += '\n✗ 执行出错: $e';
      Get.snackbar('安装失败', '$e');
      return false;
    } finally {
      isPythonInstalling.value = false;
    }
  }

  Future<void> installEnvironment() async {
    if (isInstalling.value) return;
    if (repoPath.value.isEmpty) {
      Get.snackbar('提示', '请等待仓库初始化完成，或先在数据页选择仓库路径');
      return;
    }
    isInstalling.value = true;
    installLog.value = '';

    try {
      // ── 1. 检测 UV ───────────────────────────────────────────────
      installLog.value += '▶ 检测 UV（虚拟环境工具）...\n';
      await detectUv();
      if (!uvInstalled.value) {
        installLog.value += '✗ 未找到 UV，正在自动安装...\n\n';
        final ok = await installUv();
        if (ok) installLog.value += '\n→ 请重启应用后再次点击「一键安装」。\n';
        return;
      }
      installLog.value += '✓ UV 已安装\n';
      installLog.value += '  依赖将安装到项目目录: ${repoPath.value}/python_venv\n\n';

      // ── 2. 创建/确认 venv ───────────────────────────────────────
      final venvDir = '${repoPath.value}${Platform.pathSeparator}python_venv';
      final venvPy =
          '$venvDir${Platform.pathSeparator}Scripts${Platform.pathSeparator}python.exe';
      if (!await File(venvPy).exists()) {
        installLog.value += '▶ 创建虚拟环境 python_venv（Python 3.12）...\n';
        final venvResult = await Process.run(
          'uv',
          ['venv', './python_venv', '--python', '3.12'],
          workingDirectory: repoPath.value,
          runInShell: true,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        if (venvResult.exitCode != 0) {
          installLog.value += '✗ 创建 venv 失败\n';
          installLog.value += '${venvResult.stderr}\n';
          return;
        }
        installLog.value += '✓ 虚拟环境已创建\n\n';
      } else {
        installLog.value += '✓ 虚拟环境已存在: python_venv\n\n';
      }

      // ── 3. 安装依赖包（使用 uv pip，目标 venv）──────────────────
      await detectCudaHome();
      final torchWheelTag = _getCudaWheelTag();
      final torchIndexUrl = 'https://download.pytorch.org/whl/$torchWheelTag';
      installLog.value += '▶ 将安装 GPU (CUDA) torch，根据当前 CUDA 配置: $torchWheelTag\n\n';

      final venvPython = './python_venv/Scripts/python.exe';
      final failed = <String>[];

      for (final pkg in _envPackages) {
        installLog.value += '─' * 50 + '\n';
        installLog.value += '▶ 安装 $pkg ...\n';

        if (pkg.startsWith('torch')) {
          installLog.value += '  从 PyTorch GPU 源下载（约 1–2 GB）...\n';
          // 优先用 UV --torch-backend（UV 0.5.3+），可正确解析依赖；若失败则回退到 venv 的 pip
          var result = await Process.run(
            'uv',
            [
              'pip',
              'install',
              '--python',
              venvPython,
              pkg,
              '--torch-backend',
              torchWheelTag,
            ],
            workingDirectory: repoPath.value,
            runInShell: true,
            stdoutEncoding: utf8,
            stderrEncoding: utf8,
          );
          if (result.stdout.toString().isNotEmpty)
            installLog.value += '${result.stdout}';
          if (result.stderr.toString().isNotEmpty)
            installLog.value += '${result.stderr}';

          if (result.exitCode != 0) {
            installLog.value += '\n  UV 安装 torch 失败，尝试使用 pip 回退...\n';
            // pip + --index-url：必须用 PyTorch GPU 索引才能装到 CUDA 版，否则会从 PyPI 装到 CPU 版
            result = await Process.run(
              venvPython,
              ['-m', 'pip', 'install', pkg, '--index-url', torchIndexUrl],
              workingDirectory: repoPath.value,
              runInShell: true,
              stdoutEncoding: utf8,
              stderrEncoding: utf8,
            );
            if (result.stdout.toString().isNotEmpty)
              installLog.value += '${result.stdout}';
            if (result.stderr.toString().isNotEmpty)
              installLog.value += '${result.stderr}';
          }

          if (result.exitCode == 0) {
            installLog.value += '✓ $pkg 安装成功\n\n';
          } else {
            failed.add(pkg);
            installLog.value += '\n✗ $pkg 安装失败 (exit: ${result.exitCode})\n\n';
          }
        } else {
          final result = await Process.run(
            'uv',
            ['pip', 'install', '--python', venvPython, pkg],
            workingDirectory: repoPath.value,
            runInShell: true,
            stdoutEncoding: utf8,
            stderrEncoding: utf8,
          );
          if (result.stdout.toString().isNotEmpty)
            installLog.value += '${result.stdout}';
          if (result.stderr.toString().isNotEmpty)
            installLog.value += '${result.stderr}';

          if (result.exitCode == 0) {
            installLog.value += '✓ $pkg 安装成功\n\n';
          } else {
            failed.add(pkg);
            installLog.value += '\n✗ $pkg 安装失败 (exit: ${result.exitCode})\n\n';
          }
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
    if (!wingetInstalled.value && Platform.operatingSystem == 'windows') {
      Get.snackbar(
        '需先安装 winget',
        '请先安装「应用安装程序」以使用一键安装，详见设置页顶部',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
      return;
    }
    isBuildToolsInstalling.value = true;
    buildToolsLog.value = '';

    try {
      // ── 1. ninja ─────────────────────────────────────────────────
      buildToolsLog.value += '▶ 安装 ninja 构建工具...\n';
      final useUv = repoPath.value.isNotEmpty && uvInstalled.value;
      final ninjaResult = await Process.run(
        useUv ? 'uv' : 'pip',
        useUv
            ? [
                'pip',
                'install',
                '--python',
                './python_venv/Scripts/python.exe',
                'ninja',
              ]
            : ['install', 'ninja', '--no-warn-script-location'],
        workingDirectory: useUv ? repoPath.value : null,
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
      // 先检测 UV 和 Python（项目 venv 或系统）
      await detectUv();
      await detectPython();
      final py = _venvPythonPath ?? 'python';
      if (!pythonInstalled.value) {
        checkLog.value +=
            '✗ 未找到可用 Python\n'
            '  请点击「一键安装」安装 UV 并创建项目虚拟环境\n\n';
      } else {
        checkLog.value +=
            '✓ 使用: ${_venvPythonPath != null ? "项目 venv (python_venv)" : "系统 Python"}\n';
      }
      final missing = <String>[];
      bool torchHasCuda = false;
      if (!pythonInstalled.value) {
        for (final pkg in _envCheckPackages) {
          missing.add(pkg);
        }
        checkLog.value += '\n缺少: ${missing.join(", ")}';
        Get.snackbar(
          '环境检测',
          '请点击「一键安装」安装 UV 和依赖',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
        );
        if (!_hasGuidedToSettings) {
          _hasGuidedToSettings = true;
          currentTabIndex.value = 5;
        }
      } else {
        // UV venv 默认无 pip，用 uv pip show 检测；系统 Python 用 python -m pip show
        final useUvCheck = _venvPythonPath != null && uvInstalled.value;
        for (final pkg in _envCheckPackages) {
          final pkgName = pkg.replaceAll(
            '_',
            '-',
          ); // huggingface_hub -> huggingface-hub
          final ProcessResult result;
          if (useUvCheck) {
            result = await Process.run(
              'uv',
              ['pip', 'show', '--python', _venvPythonPath!, pkgName],
              runInShell: true,
              stdoutEncoding: utf8,
              stderrEncoding: utf8,
            );
          } else {
            result = await Process.run(
              py,
              ['-m', 'pip', 'show', pkg],
              runInShell: true,
              stdoutEncoding: utf8,
              stderrEncoding: utf8,
            );
          }
          if (result.exitCode == 0) {
            checkLog.value += '✓ $pkg 已安装\n';
          } else {
            checkLog.value += '✗ $pkg 未安装\n';
            missing.add(pkg);
          }
        }

        // 额外检测 torch 是否为 GPU (CUDA) 版本
        if (!missing.contains('torch')) {
          checkLog.value += '\n▶ 检测 torch CUDA 支持...\n';
          final cudaCheck = await Process.run(
            py,
            [
              '-c',
              'import torch; '
                  'avail = torch.cuda.is_available(); '
                  'ver = torch.version.cuda or "N/A"; '
                  'print(f"cuda_available={avail}  cuda_version={ver}"); '
                  'exit(0 if avail else 1)',
            ],
            workingDirectory: repoPath.value.isNotEmpty ? repoPath.value : null,
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
                '✗ torch 未检测到 CUDA GPU 支持\n'
                '  请更新 NVIDIA 显卡驱动至最新版本，或使用支持 CUDA 13.0 的驱动\n';
            if (cudaOut.isNotEmpty) checkLog.value += '  详情: $cudaOut\n';
            missing.add('torch(CUDA)');
          }
        }

        if (missing.isEmpty) {
          envReady.value = true;
          _detectGpu();
          checkLog.value += '\n所有环境已经准备好';
          Get.snackbar('环境检测', '所有环境已准备好', snackPosition: SnackPosition.TOP);
        } else {
          checkLog.value += '\n缺少或需重装: ${missing.join(", ")}';
          if (!_hasGuidedToSettings) {
            _hasGuidedToSettings = true;
            currentTabIndex.value = 5;
          }
          if (!torchHasCuda && missing.contains('torch(CUDA)')) {
            Get.snackbar(
              '环境检测',
              'torch 未启用 CUDA，请更新 NVIDIA 显卡驱动至最新版本',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 5),
            );
          }
        }
      }
    } catch (e) {
      checkLog.value += '检测异常: $e';
    } finally {
      isChecking.value = false;
    }
  }
}
