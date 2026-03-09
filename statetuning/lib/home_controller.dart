import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ModelPrecision { fp16, int8, q4 }

enum TrainingMode { inference, supervised }

class ModelInfo {
  final String name;
  final String parameters;
  final String context;
  final int vramRequired;

  const ModelInfo({
    required this.name,
    required this.parameters,
    required this.context,
    required this.vramRequired,
  });
}

class HomeController extends GetxController {
  // Tab index
  final currentTabIndex = 0.obs;

  // Teacher model
  final teacherModel = 'DeepSeek V3'.obs;
  final teacherModels = ['DeepSeek V3', 'Qwen2.5 72B', 'Llama 3.1 70B'];

  // Student model
  final studentModel = 'Qwen2.5 7B'.obs;
  final studentModels = ['Qwen2.5 7B', 'Qwen2.5 3B', 'Llama 3.2 3B'];

  // Model precision
  final modelPrecision = ModelPrecision.q4.obs;

  // Max context length
  final maxContextLength = 4096.obs;

  // Training mode
  final trainingMode = TrainingMode.supervised.obs;

  // GPU info
  final gpuInfo = 'RTX 4090 24GB'.obs;
  final status = '空闲'.obs;

  // Environment install (参考 RWKV-PEFT: https://github.com/Joluck/RWKV-PEFT)
  // deepspeed、triton 不支持 Windows 已排除
  static const _envPackages = [
    'bitsandbytes',
    'einops',
    'peft',
    'rwkv-fla',
    'rwkv',
    'transformers',
    'lightning>=2.0.0',
    'datasets',
    'jsonlines',
    'wandb',
  ];
  final isInstalling = false.obs;
  final installLog = ''.obs;

  // Computed model info
  ModelInfo get teacherModelInfo {
    switch (teacherModel.value) {
      case 'DeepSeek V3':
        return const ModelInfo(
          name: 'DeepSeek V3',
          parameters: '72B',
          context: '128K',
          vramRequired: 48,
        );
      case 'Qwen2.5 72B':
        return const ModelInfo(
          name: 'Qwen2.5 72B',
          parameters: '72B',
          context: '128K',
          vramRequired: 48,
        );
      case 'Llama 3.1 70B':
        return const ModelInfo(
          name: 'Llama 3.1 70B',
          parameters: '70B',
          context: '128K',
          vramRequired: 48,
        );
      default:
        return const ModelInfo(
          name: 'DeepSeek V3',
          parameters: '72B',
          context: '128K',
          vramRequired: 48,
        );
    }
  }

  ModelInfo get studentModelInfo {
    switch (studentModel.value) {
      case 'Qwen2.5 7B':
        return const ModelInfo(
          name: 'Qwen2.5 7B',
          parameters: '7B',
          context: '32K',
          vramRequired: 14,
        );
      case 'Qwen2.5 3B':
        return const ModelInfo(
          name: 'Qwen2.5 3B',
          parameters: '3B',
          context: '32K',
          vramRequired: 6,
        );
      case 'Llama 3.2 3B':
        return const ModelInfo(
          name: 'Llama 3.2 3B',
          parameters: '3B',
          context: '128K',
          vramRequired: 6,
        );
      default:
        return const ModelInfo(
          name: 'Qwen2.5 7B',
          parameters: '7B',
          context: '32K',
          vramRequired: 14,
        );
    }
  }

  // VRAM estimation (based on quantization)
  int get teacherVramUsage {
    final base = teacherModelInfo.vramRequired;
    switch (modelPrecision.value) {
      case ModelPrecision.fp16:
        return base;
      case ModelPrecision.int8:
        return (base * 0.5).round();
      case ModelPrecision.q4:
        return (base * 0.25).round();
    }
  }

  int get studentVramUsage {
    final base = studentModelInfo.vramRequired;
    switch (modelPrecision.value) {
      case ModelPrecision.fp16:
        return base;
      case ModelPrecision.int8:
        return (base * 0.5).round();
      case ModelPrecision.q4:
        return (base * 0.25).round();
    }
  }

  int get totalVramUsage => teacherVramUsage + studentVramUsage;
  int get availableVram => 24; // RTX 4090 24GB
  bool get isVramInsufficient => totalVramUsage > availableVram;

  void setTabIndex(int index) => currentTabIndex.value = index;

  void setTeacherModel(String model) => teacherModel.value = model;

  void setStudentModel(String model) => studentModel.value = model;

  void setModelPrecision(ModelPrecision precision) =>
      modelPrecision.value = precision;

  void setMaxContextLength(int value) => maxContextLength.value = value;

  void setTrainingMode(TrainingMode mode) => trainingMode.value = mode;

  final maxContextLengthController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    maxContextLengthController.text = maxContextLength.value.toString();
    maxContextLengthController.addListener(_onContextLengthChanged);
  }

  void _onContextLengthChanged() {
    final parsed = int.tryParse(maxContextLengthController.text);
    if (parsed != null && parsed > 0) {
      maxContextLength.value = parsed;
    }
  }

  @override
  void onClose() {
    maxContextLengthController.removeListener(_onContextLengthChanged);
    maxContextLengthController.dispose();
    super.onClose();
  }

  void goToDataPreparation() {
    // TODO: Navigate to data preparation
    Get.snackbar('提示', '下一步: 数据准备');
  }

  Future<void> installEnvironment() async {
    if (isInstalling.value) return;
    isInstalling.value = true;
    installLog.value = '正在检测 Python 环境...\n';

    try {
      // 检测 pip 是否可用
      final pipCheck = await Process.run('pip', ['--version'],
          runInShell: true, stdoutEncoding: null);
      if (pipCheck.exitCode != 0) {
        installLog.value += '错误: 未找到 pip，请先安装 Python 并确保已添加到 PATH\n';
        Get.snackbar('安装失败', '未找到 pip，请先安装 Python');
        return;
      }
      installLog.value += 'pip 已就绪\n\n';

      final packages = _envPackages.join(' ');
      installLog.value += '正在安装: $packages\n\n';

      final result = await Process.run(
        'pip',
        ['install', ..._envPackages],
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      final output = '${result.stdout}\n${result.stderr}';
      installLog.value += output;

      if (result.exitCode == 0) {
        installLog.value += '\n✓ 环境安装完成';
        Get.snackbar('安装成功', '依赖包已安装完成');
      } else {
        installLog.value += '\n✗ 安装过程中出现错误 (exit: ${result.exitCode})';
        Get.snackbar('安装异常', '请查看日志，部分包可能安装失败');
      }
    } catch (e, st) {
      installLog.value += '异常: $e\n$st';
      Get.snackbar('安装失败', '执行出错: $e');
    } finally {
      isInstalling.value = false;
    }
  }
}
