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
  ];
  static const _envCheckPackages = [
    'torch',
    'transformers',
    'tqdm',
    'huggingface_hub',
  ];
  final isInstalling = false.obs;
  final installLog = ''.obs;
  final isChecking = false.obs;
  final envReady = false.obs;
  final checkLog = ''.obs;

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
    vocabSizeController = TextEditingController(text: vocabSize.value.toString());
    nEmbdController = TextEditingController(text: nEmbd.value.toString());
    nLayerController = TextEditingController(text: nLayer.value.toString());
    ctxLenController = TextEditingController(text: ctxLen.value.toString());
    modelPathController = TextEditingController(text: modelPath.value);
    dataPathController = TextEditingController(text: dataPath.value);
    outputDirController = TextEditingController(text: outputDir.value);
    repoPathController = TextEditingController(text: repoPath.value);
    batchSizeController = TextEditingController(text: batchSize.value.toString());
    numStepsController = TextEditingController(text: numSteps.value.toString());
    numEpochsController = TextEditingController(text: numEpochs.value.toString());
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
    modelPathController.addListener(() => modelPath.value = modelPathController.text);
    dataPathController.addListener(() => dataPath.value = dataPathController.text);
    outputDirController.addListener(() => outputDir.value = outputDirController.text);
    repoPathController.addListener(() => repoPath.value = repoPathController.text);
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
    learningRateController.addListener(() => learningRate.value = learningRateController.text);
    cudaHomeController.addListener(() => cudaHome.value = cudaHomeController.text);

    _detectGpu();
    detectCudaHome();
  }

  @override
  void onClose() {
    for (final c in [
      vocabSizeController, nEmbdController, nLayerController, ctxLenController,
      modelPathController, dataPathController, outputDirController, repoPathController,
      batchSizeController, numStepsController, numEpochsController, learningRateController,
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
        ['-c', 'import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else "No CUDA GPU")'],
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
    final envCuda = Platform.environment['CUDA_HOME'] ??
        Platform.environment['CUDA_PATH'];
    if (envCuda != null && envCuda.isNotEmpty) {
      final nvcc = File('$envCuda${Platform.pathSeparator}bin${Platform.pathSeparator}nvcc.exe');
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
        final nvcc = File('$latest${Platform.pathSeparator}bin${Platform.pathSeparator}nvcc.exe');
        if (await nvcc.exists()) {
          _setCudaHome(latest);
          cudaDetectLog.value += '✓ 自动检测到: $latest\n';
          return;
        }
      }
    }

    // 3. 尝试从 nvcc 命令反推路径
    try {
      final r = await Process.run('where', ['nvcc'], runInShell: true,
          stdoutEncoding: utf8, stderrEncoding: utf8);
      if (r.exitCode == 0) {
        final nvccPath = (r.stdout as String).trim().split('\n').first.trim();
        // nvccPath = C:\...\CUDA\v12.x\bin\nvcc.exe  → 取上两级
        final home = File(nvccPath).parent.parent.path;
        _setCudaHome(home);
        cudaDetectLog.value += '✓ 从 nvcc 命令检测到: $home\n';
        return;
      }
    } catch (_) {}

    cudaDetectLog.value += '✗ 未自动检测到 CUDA，请手动选择安装目录\n'
        '  常见路径: C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\v12.x\n';
  }

  void _setCudaHome(String path) {
    cudaHome.value = path;
    cudaHomeController.text = path;
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
    final trainFile = File('${repoPath.value}${Platform.pathSeparator}train.py');
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
    return '''import os, sys, glob
sys.path.insert(0, r"${repoPath.value}")
os.chdir(r"${repoPath.value}")

# ── CUDA_HOME 设置（由 Flutter 注入或自动检测）──────────────────────
_cuda_home = r"$cudaHomeStr"
if not _cuda_home:
    # 未手动指定时自动扫描 Windows 默认安装路径
    for _root in [
        r"C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA",
        r"C:\\CUDA",
    ]:
        _candidates = sorted(glob.glob(f"{_root}\\\\v*"), reverse=True)
        if _candidates:
            _cuda_home = _candidates[0]
            break
if _cuda_home:
    os.environ.setdefault("CUDA_HOME", _cuda_home)
    os.environ.setdefault("CUDA_PATH", _cuda_home)
    print(f"CUDA_HOME = {_cuda_home}")
else:
    print("WARNING: CUDA_HOME not found, CUDA kernel compilation may fail")

os.environ["WKV"] = "CUDA"
os.environ["FUSED_KERNEL"] = "0"
os.environ["RWKV_TRAIN_TYPE"] = "none"
os.environ["RWKV_HEAD_SIZE_A"] = "64"
os.environ["RWKV_MY_TESTING"] = "x070"
os.environ["RWKV_TRAIN_TYPE"] = "state"
os.environ["RWKV_FLOAT_MODE"] = "$p"

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
model_args.dim_att = model_args.n_embd
model_args.dim_ffn = model_args.n_embd * 4
train_args = TrainArgs()

print("Loading model from:", train_args.load_model)
model = RWKV7(model_args)
device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Device: {device}")
model = model.to(device)

state_dict = torch.load(train_args.load_model, map_location="cpu", weights_only=True)
model.load_state_dict(state_dict, strict=False)

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


model.train()
pbar = tqdm(range(train_args.num_steps), desc="Training", ncols=100)
for step in pbar:
    input_ids, labels = get_batch()
    logits = model(input_ids)
    loss = nn.functional.cross_entropy(
        logits.view(-1, logits.size(-1)), labels.view(-1)
    )
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
    currentTabIndex.value = 3;

    try {
      final scriptPath = '${repoPath.value}${Platform.pathSeparator}_flutter_train.py';
      await File(scriptPath).writeAsString(_buildTrainingScript());
      trainingLog.value += '✓ 训练脚本已生成: $scriptPath\n';
      trainingLog.value += '${'=' * 50}\n\n';

      _trainingProcess = await Process.start(
        'python',
        ['-u', '_flutter_train.py'],
        workingDirectory: repoPath.value,
        runInShell: true,
      );

      _trainingProcess!.stdout
          .transform(utf8.decoder)
          .listen((data) => trainingLog.value += data);
      _trainingProcess!.stderr
          .transform(utf8.decoder)
          .listen((data) => trainingLog.value += data);

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

  Future<void> stopTraining() async {
    _trainingProcess?.kill();
    isTraining.value = false;
    status.value = '已停止';
    trainingLog.value += '\n⏹ 训练已手动停止\n';
  }

  Future<void> refreshOutputFiles() async {
    final resolvedPath = outputDir.value.startsWith('./') || outputDir.value == '.'
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
        'pip', ['--version'],
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
        'pip', ['config', 'get', 'global.index-url'],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final indexUrl = (indexResult.stdout as String).trim();
      installLog.value +=
          '  pip 源: ${indexUrl.isNotEmpty ? indexUrl : "(默认 PyPI)"}\n\n';

      // ── 3. 逐包安装 ───────────────────────────────────────────────
      final failed = <String>[];
      for (final pkg in _envPackages) {
        installLog.value += '─' * 50 + '\n';
        installLog.value += '▶ 安装 $pkg ...\n';

        final process = await Process.start(
          'pip',
          ['install', pkg, '--no-warn-script-location'],
          runInShell: true,
        );

        // 收集全部输出
        final stdoutBuf = StringBuffer();
        final stderrBuf = StringBuffer();
        process.stdout
            .transform(utf8.decoder)
            .listen((d) {
          stdoutBuf.write(d);
          installLog.value += d;
        });
        process.stderr
            .transform(utf8.decoder)
            .listen((d) {
          stderrBuf.write(d);
          installLog.value += d;
        });

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

  Future<void> checkEnvironment() async {
    if (isChecking.value) return;
    isChecking.value = true;
    checkLog.value = '正在检测环境...\n';
    envReady.value = false;
    try {
      final missing = <String>[];
      for (final pkg in _envCheckPackages) {
        final result = await Process.run(
          'pip', ['show', pkg],
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
      if (missing.isEmpty) {
        envReady.value = true;
        checkLog.value += '\n所有环境已经准备好';
        Get.snackbar('环境检测', '所有环境已准备好', snackPosition: SnackPosition.TOP);
      } else {
        checkLog.value += '\n缺少: ${missing.join(", ")}';
      }
    } catch (e) {
      checkLog.value += '检测异常: $e';
    } finally {
      isChecking.value = false;
    }
  }
}
