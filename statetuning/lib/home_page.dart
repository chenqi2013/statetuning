import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'distillation_controller.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D21),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      _buildTabBar(),
                      Expanded(
                        child: Obx(() => _buildContent()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (controller.sidebarIndex.value == 1) {
      return _buildDistillationContent();
    }
    switch (controller.currentTabIndex.value) {
      case 1:
        return _buildDataTab();
      case 2:
        return _buildTrainTab();
      case 3:
        return _buildMonitorTab();
      case 4:
        return _buildExportTab();
      case 5:
        return _buildSettingsTab();
      default:
        return _buildModelTab();
    }
  }

  Widget _buildSidebar() {
    return Obx(() {
      final sel = controller.sidebarIndex.value;
      return Container(
        width: 72,
        color: const Color(0xFF1E2228),
        child: Column(
          children: [
            _sidebarItem(Icons.fitness_center, '训练', 0, sel),
            _sidebarItem(Icons.science, '蒸馏', 1, sel),
          ],
        ),
      );
    });
  }

  Widget _sidebarItem(IconData icon, String label, int index, int selected) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: () => controller.setSidebarIndex(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF252830) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF252830),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'State-Tuning Studio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Obx(() => _chip(Icons.memory, 'GPU: ${controller.gpuInfo.value}')),
              const SizedBox(width: 16),
              Obx(() => _chip(
                    controller.isTraining.value
                        ? Icons.play_arrow
                        : Icons.circle,
                    controller.status.value,
                    color: controller.isTraining.value
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFB0B5BC),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color color = const Color(0xFFB0B5BC)}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }

  // ─── Tab Bar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Obx(() {
      if (controller.sidebarIndex.value == 1) {
        return _buildDistillationTabBar();
      }
      return _buildTrainingTabBar();
    });
  }

  Widget _buildTrainingTabBar() {
    const tabs = ['模型', '数据', '训练', '监控', '导出', '设置'];
    return Container(
      color: const Color(0xFF1A1D21),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = controller.currentTabIndex.value == i;
          return GestureDetector(
            onTap: () => controller.setTabIndex(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF6B7280),
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDistillationTabBar() {
    const tabs = ['创建任务', '任务队列', '实时监控', '数据统计', '数据导出', '生成器管理', 'LLM服务商'];
    return Obx(
      () => Container(
        color: const Color(0xFF1A1D21),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final selected = controller.distillationTabIndex.value == i;
            return GestureDetector(
              onTap: () => controller.setDistillationTabIndex(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF6B7280),
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDistillationContent() {
    switch (controller.distillationTabIndex.value) {
      case 1:
        return _buildDistillationQueueTab();
      case 2:
        return _buildDistillationMonitorTab();
      case 3:
        return _buildDistillationStatsTab();
      case 4:
        return _buildDistillationExportTab();
      case 5:
        return _buildDistillationGeneratorTab();
      case 6:
        return _buildDistillationLLMTab();
      default:
        return _buildDistillationCreateTaskTab();
    }
  }

  // ─── Tab 0: 模型 ─────────────────────────────────────────────────────────────

  Widget _buildModelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            title: '模型规格预设',
            child: Obx(() => Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: HomeController.presets.map((p) {
                    final selected = controller.selectedPreset.value == p.label;
                    return GestureDetector(
                      onTap: () => controller.applyPreset(p.label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF1A1D21),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF3A3F47),
                          ),
                        ),
                        child: Text(
                          p.label,
                          style: TextStyle(
                            color: selected ? Colors.white : const Color(0xFFB0B5BC),
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: '模型文件路径',
            child: _labeledField(
              '预训练模型 (.pth)',
              controller.modelPathController,
              hint: '点击右侧按钮选择文件',
              onBrowse: controller.pickModelFile,
              browseIcon: Icons.file_open,
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: '训练精度',
            child: Obx(() => Row(
                  children: [
                    _precisionButton('BF16', TrainingPrecision.bf16),
                    const SizedBox(width: 12),
                    _precisionButton('FP16', TrainingPrecision.fp16),
                    const SizedBox(width: 12),
                    _precisionButton('FP32', TrainingPrecision.fp32),
                  ],
                )),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: 'ModelArgs（高级）',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _labeledField('词表大小 (vocab_size)',
                          controller.vocabSizeController,
                          hint: '65536', keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _labeledField('上下文长度 (ctx_len)',
                          controller.ctxLenController,
                          hint: '512', keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _labeledField('嵌入维度 (n_embd)',
                          controller.nEmbdController,
                          hint: '1024', keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _labeledField('层数 (n_layer)',
                          controller.nLayerController,
                          hint: '24', keyboardType: TextInputType.number),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.setTabIndex(1),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('下一步: 数据配置'),
              style: _btnStyle(const Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _precisionButton(String label, TrainingPrecision p) {
    final selected = controller.precision.value == p;
    return GestureDetector(
      onTap: () => controller.setPrecision(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B82F6) : const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : const Color(0xFF3A3F47),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFB0B5BC),
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ─── Tab 1: 数据 ─────────────────────────────────────────────────────────────

  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            title: '仓库来源 (github.com/Joluck/statetuning)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 路径输入 + 浏览已有文件夹
                _labeledField('本地仓库路径', controller.repoPathController,
                    hint: '选择或填写仓库所在文件夹',
                    onBrowse: controller.pickRepoDir),
                const SizedBox(height: 4),
                const Text(
                  '选择文件夹后自动检测；或使用下方按钮获取仓库',
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 12),
                ),
                const SizedBox(height: 14),
                // 操作按钮
                Obx(() {
                  final busy = controller.isCloningRepo.value;
                  return Row(
                    children: [
                      // 从 GitHub 克隆
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: busy ? null : controller.cloneRepo,
                          icon: busy
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.download, size: 18),
                          label: Text(
                              busy ? '克隆中...' : '从 GitHub 克隆',
                              style: const TextStyle(fontSize: 13)),
                          style: _btnStyle(const Color(0xFF6366F1)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 检查路径
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: busy ? null : controller.checkRepo,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('检查路径',
                              style: TextStyle(fontSize: 13)),
                          style: _btnStyle(const Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                Obx(() => _logBox(controller.repoLog.value,
                    minHeight: 60,
                    placeholder: '选择文件夹 / 解压 ZIP / 克隆仓库后状态显示在此')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: '训练数据',
            child: Column(
              children: [
                _labeledField('JSONL 数据文件路径', controller.dataPathController,
                    hint: '点击右侧按钮选择文件',
                    onBrowse: controller.pickDataFile,
                    browseIcon: Icons.file_open),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D21),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF3A3F47)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('数据格式示例 (每行一个 JSON):',
                          style: TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12)),
                      SizedBox(height: 6),
                      SelectableText(
                        '{"text": "User: 你好\\n\\nAssistant: 你好！有什么可以帮助你的吗？\\n\\n"}\n'
                        '{"text": "User: 讲个笑话\\n\\nAssistant: 好的...\\n\\n"}',
                        style: TextStyle(
                            color: Color(0xFF86EFAC),
                            fontSize: 12,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: '输出目录',
            child: _labeledField('输出目录', controller.outputDirController,
                hint: '点击右侧按钮选择文件夹',
                onBrowse: controller.pickOutputDir),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.setTabIndex(2),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('下一步: 训练参数'),
              style: _btnStyle(const Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: 训练 ─────────────────────────────────────────────────────────────

  Widget _buildTrainTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            title: '训练超参数',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _labeledField('Batch Size', controller.batchSizeController,
                          hint: '4', keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _labeledField('训练步数 (num_steps)',
                          controller.numStepsController,
                          hint: '1000', keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _labeledField('训练轮数 (num_epochs)',
                          controller.numEpochsController,
                          hint: '1', keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _labeledField('学习率', controller.learningRateController,
                          hint: '1e-5'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Obx(() => _sectionCard(
                title: '配置摘要',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryRow('仓库路径',
                        controller.repoPath.value.isEmpty ? '未设置' : controller.repoPath.value),
                    _summaryRow('模型文件',
                        controller.modelPath.value.isEmpty ? '未设置' : controller.modelPath.value),
                    _summaryRow('数据文件',
                        controller.dataPath.value.isEmpty ? '未设置' : controller.dataPath.value),
                    _summaryRow('输出目录', controller.outputDir.value),
                    _summaryRow('精度', controller.precisionString.toUpperCase()),
                    _summaryRow('模型规格', controller.selectedPreset.value),
                    _summaryRow('n_embd / n_layer',
                        '${controller.nEmbd.value} / ${controller.nLayer.value}'),
                    _summaryRow('ctx_len', '${controller.ctxLen.value}'),
                    _summaryRow('batch / steps / epochs',
                        '${controller.batchSize.value} / ${controller.numSteps.value} / ${controller.numEpochs.value}'),
                    _summaryRow('学习率', controller.learningRate.value),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          Obx(() => Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed:
                          controller.isTraining.value ? null : controller.startTraining,
                      icon: controller.isTraining.value
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.rocket_launch),
                      label: Text(
                          controller.isTraining.value ? '训练中...' : '开始训练'),
                      style: _btnStyle(const Color(0xFF22C55E)),
                    ),
                  ),
                  if (controller.isTraining.value) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.stopTraining,
                        icon: const Icon(Icons.stop),
                        label: const Text('停止训练'),
                        style: _btnStyle(const Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ],
              )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF252830),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3A3F47)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[300]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '点击「开始训练」将生成 _flutter_train.py 脚本并在仓库目录执行，训练日志实时显示在「监控」标签页。',
                    style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(key,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ─── Tab 3: 监控 ─────────────────────────────────────────────────────────────

  Widget _buildMonitorTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Obx(() => _statusBadge(controller.isTraining.value)),
              const Spacer(),
              Obx(() {
                if (!controller.isTraining.value) return const SizedBox.shrink();
                return ElevatedButton.icon(
                  onPressed: controller.stopTraining,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('停止训练'),
                  style: _btnStyle(const Color(0xFFEF4444), compact: true),
                );
              }),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => controller.trainingLog.value = '',
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('清空日志'),
                style: _btnStyle(const Color(0xFF3A3F47), compact: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final log = controller.trainingLog.value;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0F12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3A3F47)),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: SelectableText(
                    log.isEmpty ? '训练日志将在此实时显示...' : log,
                    style: TextStyle(
                      color: log.isEmpty
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFD1FAE5),
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.6,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isTraining) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isTraining
            ? const Color(0xFF22C55E).withValues(alpha: 0.15)
            : const Color(0xFF3A3F47),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTraining ? const Color(0xFF22C55E) : const Color(0xFF4B5563),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTraining)
            const SizedBox(
              width: 10, height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF22C55E)),
            )
          else
            const Icon(Icons.circle, size: 10, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(
            isTraining ? '训练进行中' : '待机',
            style: TextStyle(
              color: isTraining ? const Color(0xFF22C55E) : const Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 4: 导出 ─────────────────────────────────────────────────────────────

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            title: '输出文件',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      '输出目录: ${controller.outputDir.value}',
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 13),
                    )),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: controller.refreshOutputFiles,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('刷新文件列表'),
                  style: _btnStyle(const Color(0xFF3B82F6), compact: true),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final files = controller.outputFiles;
                  if (files.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D21),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF3A3F47)),
                      ),
                      child: const Center(
                        child: Text(
                          '暂无输出文件\n训练完成后，.state 权重文件将显示在这里',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF4B5563), fontSize: 14),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: files.map((path) => _fileItem(path)).toList(),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: '使用说明',
            child: const Text(
              '训练完成后，State 权重文件 (.state) 可加载到 RWKV 推理框架中。\n\n'
              '• 与原始 .pth 模型权重分开存储，体积极小\n'
              '• 只包含经过微调的 state 参数\n'
              '• 推理时合并使用: model.pth + xxx.state',
              style: TextStyle(
                color: Color(0xFFB0B5BC),
                fontSize: 13,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileItem(String path) {
    final fileName = path.split(RegExp(r'[/\\]')).last;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3F47)),
      ),
      child: Row(
        children: [
          const Icon(Icons.data_object, color: Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text(path,
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 蒸馏子页 ───────────────────────────────────────────────────────────────────

  /// 创建任务 - 基本配置 + 语言比例分配 + 话题范围配置
  Widget _buildDistillationCreateTaskTab() {
    final dc = Get.find<DistillationController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _distillCard(
              icon: Icons.settings,
              title: '基本配置',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: dc.taskNameController,
                    decoration: const InputDecoration(
                      labelText: '任务名称',
                      hintText: '输入任务名称',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Obx(() {
                    final gt = dc.taskGeneratorType.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: gt,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: const Color(0xFF252830),
                          style: const TextStyle(color: Colors.white),
                          items: dc.generators
                              .where((g) => g.enabled)
                              .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                              .toList(),
                          onChanged: (v) => v != null ? dc.setTaskGeneratorType(v) : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dc.generators.where((g) => g.id == gt).isEmpty ? '' : dc.generators.where((g) => g.id == gt).first.description,
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextField(
                      controller: dc.taskCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '生成数量',
                        hintText: '100',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Obx(() => Row(
                    children: [
                      Text('Temperature: ${dc.taskTemperature.value.toStringAsFixed(1)}',
                          style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: const Color(0xFF3B82F6),
                            inactiveTrackColor: const Color(0xFF3A3F47),
                            thumbColor: const Color(0xFF3B82F6),
                          ),
                          child: Slider(
                            value: dc.taskTemperature.value,
                            onChanged: (v) => dc.setTaskTemperature(v),
                          ),
                        ),
                      ),
                    ],
                  )),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextField(
                      controller: dc.taskConcurrencyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '并发数 (线程数)',
                        hintText: '4',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextField(
                    controller: dc.taskApiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key (可选)',
                      hintText: '默认使用 sk-test',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (dc.llmProviders.isNotEmpty)
                    Obx(() => DropdownButtonFormField<String>(
                          value: dc.taskProviderId.value.isEmpty ? null : dc.taskProviderId.value,
                          decoration: const InputDecoration(
                            labelText: 'LLM 服务商',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: const Color(0xFF252830),
                          style: const TextStyle(color: Colors.white),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('-- 使用 API Key 或默认 --')),
                            ...dc.llmProviders.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                          ],
                          onChanged: (v) => dc.setTaskProviderId(v ?? ''),
                        )),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => dc.createTask(),
                      icon: const Icon(Icons.add_circle, size: 18),
                      label: const Text('创建任务'),
                      style: _btnStyle(const Color(0xFF22C55E)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _distillCard(
                  icon: Icons.language,
                  title: '语言比例分配',
                  compact: true,
                  child: Obx(() {
                    final r = dc.taskLangRatios.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('各语言比例总和必须等于100%', style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            _langPercentItem(dc, 'zh', '中文 (ZH)', r.zh),
                            _langPercentItem(dc, 'en', '英文 (EN)', r.en),
                            _langPercentItem(dc, 'ja', '日文 (JA)', r.ja),
                            _langPercentItem(dc, 'ko', '韩文 (KO)', r.ko),
                            _langPercentItem(dc, 'de', '德文 (DE)', r.de),
                            _langPercentItem(dc, 'fr', '法文 (FR)', r.fr),
                            _langPercentItem(dc, 'es', '西班牙 (ES)', r.es),
                            _langPercentItem(dc, 'ru', '俄文 (RU)', r.ru),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '总计: ${r.sum}%',
                          style: TextStyle(
                            color: r.sum == 100 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Obx(() {
                  if (dc.taskGeneratorType.value == 'tool') {
                    return _distillCard(
                      icon: Icons.layers,
                      title: '级别比例 (L0-L4)',
                      compact: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('工具对话级别分配，总和必须为100%', style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              _langPercentItem(dc, 'l0', 'L0 无工具', dc.taskLevelRatios.value.l0, isLevel: true),
                              _langPercentItem(dc, 'l1', 'L1 单工具', dc.taskLevelRatios.value.l1, isLevel: true),
                              _langPercentItem(dc, 'l2', 'L2 双工具', dc.taskLevelRatios.value.l2, isLevel: true),
                              _langPercentItem(dc, 'l3', 'L3 三工具', dc.taskLevelRatios.value.l3, isLevel: true),
                              _langPercentItem(dc, 'l4', 'L4 四工具+', dc.taskLevelRatios.value.l4, isLevel: true),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '总计: ${dc.taskLevelRatios.value.sum}%',
                            style: TextStyle(
                              color: dc.taskLevelRatios.value.sum == 100 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 20),
                _distillCard(
                  icon: Icons.category,
                  title: '话题范围配置',
                  compact: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('选择要包含的话题分类，留空则使用全部', style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dc.availableTopics.map((topic) {
                          final sel = dc.taskSelectedTopics.contains(topic);
                          return FilterChip(
                            label: Text(topic),
                            selected: sel,
                            onSelected: (_) => dc.toggleTopic(topic),
                            backgroundColor: const Color(0xFF1A1D21),
                            selectedColor: const Color(0xFF3B82F6),
                            labelStyle: TextStyle(color: sel ? Colors.white : const Color(0xFFB0B5BC)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(onPressed: dc.selectAllTopics, child: const Text('全选')),
                          TextButton(onPressed: dc.clearTopics, child: const Text('全不选')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _langPercentItem(DistillationController dc, String key, String label, int value, {bool isLevel = false}) {
    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: value.toString())
              ..selection = TextSelection.collapsed(offset: value.toString().length),
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n >= 0 && n <= 100) {
                if (isLevel) dc.setLevelRatio(key, n);
                else dc.setLangRatio(key, n);
              }
            },
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF1A1D21),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistillationQueueTab() {
    final dc = Get.find<DistillationController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _distillCard(
        icon: Icons.playlist_play,
        title: '任务队列',
        compact: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '待执行和运行中的蒸馏任务',
              style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            Obx(() {
              final tasks = dc.distillTasks.where((t) =>
                  t.status == DistillTaskStatus.pending || t.status == DistillTaskStatus.running).toList();
              if (tasks.isEmpty) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D21),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF3A3F47)),
                      ),
                      child: Center(
                        child: Text(
                          dc.distillTasks.isEmpty ? '暂无任务\n请在「创建任务」中新建' : '暂无待执行/运行中的任务',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => controller.setDistillationTabIndex(0),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('去创建任务'),
                      style: _btnStyle(const Color(0xFF3B82F6)),
                    ),
                  ],
                );
              }
              return Column(
                children: tasks.map((t) => _distillQueueItem(dc, t)).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _distillLogCard(DistillationController dc) {
    return Obx(() => _distillCard(
      icon: Icons.description,
      title: '实时日志',
      compact: false,
      minHeight: 150,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: SelectableText(
          dc.distillLog.value.isEmpty ? '系统就绪, 等待任务...' : dc.distillLog.value,
          style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontFamily: 'monospace'),
        ),
      ),
    ));
  }

  Widget _distillQueueItem(DistillationController dc, DistillTask t) {
    final running = t.status == DistillTaskStatus.running;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3F47)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${t.config.generatorType} · ${t.config.count} 条',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
                if (running) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: t.config.count > 0 ? t.stats.recordsGenerated / t.config.count : 0,
                    backgroundColor: const Color(0xFF3A3F47),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${t.stats.recordsGenerated}/${t.config.count} · ${t.stats.currentSpeed.toStringAsFixed(1)} 条/分钟',
                    style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (t.status == DistillTaskStatus.pending)
            ElevatedButton.icon(
              onPressed: () => dc.runTask(t.id),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('运行'),
              style: _btnStyle(const Color(0xFF22C55E), compact: true),
            ),
          if (running) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => dc.cancelTask(t.id),
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('取消'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDistillationMonitorTab() {
    final dc = Get.find<DistillationController>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: _distillMonitorProgressRow(dc),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _distillLogCard(dc),
          ),
        ],
      ),
    );
  }

  Widget _distillMonitorProgressRow(DistillationController dc) {
    return Obx(() {
      final running = dc.distillTasks.where((t) => t.status == DistillTaskStatus.running).toList();
      final active = running.isNotEmpty ? running.first : null;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: _distillCard(
              icon: Icons.show_chart,
              title: '实时进度',
              compact: false,
              minHeight: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    active != null
                        ? '${active.stats.currentSpeed.toStringAsFixed(1)} 条/分钟'
                        : '0.0 条/分钟',
                    style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    active != null && active.stats.estimatedRemaining > 0
                        ? 'ETA: ${(active.stats.estimatedRemaining ~/ 60)}:${(active.stats.estimatedRemaining % 60).toString().padLeft(2, '0')}'
                        : 'ETA: --:--',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                  const Spacer(),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D21),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3A3F47)),
                    ),
                    child: const Center(
                      child: Text(
                        '图表区域',
                        style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: _distillCard(
              icon: Icons.people,
              title: '工作状态',
              compact: false,
              minHeight: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    active != null ? '运行中: ${active.name}' : '暂无运行中的任务',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                  if (active != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '并发: ${active.config.concurrency} 线程',
                      style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    '线程活跃度',
                    style: TextStyle(
                        color: Color(0xFFB0B5BC),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  /// 数据统计 - 系统概览
  Widget _buildDistillationStatsTab() {
    final dc = Get.find<DistillationController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _distillCard(
            icon: Icons.bar_chart,
            title: '系统概览',
            compact: true,
            child: Row(
              children: [
                _statCard('总任务数', dc.totalTasks),
                const SizedBox(width: 16),
                _statCard('总记录数', dc.totalRecords),
                const SizedBox(width: 16),
                _statCard('运行中', dc.runningCount),
                const SizedBox(width: 16),
                _statCard('已完成', dc.completedCount),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: const Color(0xFF252830),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3A3F47)),
            ),
            child: Center(
              child: Text(
                dc.distillTasks.isEmpty ? '暂无数据,请先完成一些生成任务' : '任务分布、话题分布等图表（需接入数据源）',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _statCard(String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3A3F47)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            const SizedBox(height: 8),
            Text('$value', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 24, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  /// 数据导出 - RWKV 导出 + 导出历史
  Widget _buildDistillationExportTab() {
    final dc = Get.find<DistillationController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _distillCard(
              icon: Icons.folder_open,
              title: 'RWKV 导出',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择已完成的任务进行导出 (使用生成器对应的 RWKV 模板)',
                    style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => Row(children: [
                    Checkbox(value: dc.exportShuffle.value, onChanged: (v) => dc.exportShuffle.value = v ?? true),
                    const Text('打乱顺序 (防止过拟合)', style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
                  ])),
                  const SizedBox(height: 4),
                  Obx(() => Row(children: [
                    Checkbox(value: dc.exportMergeByType.value, onChanged: (v) => dc.exportMergeByType.value = v ?? false),
                    const Text('按类型合并 (生成多个文件)', style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
                  ])),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: dc.exportFormat.value,
                    decoration: const InputDecoration(labelText: '导出格式', border: OutlineInputBorder()),
                    dropdownColor: const Color(0xFF252830),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'multi_turn', child: Text('multi_turn')),
                      DropdownMenuItem(value: 'single_turn', child: Text('single_turn')),
                      DropdownMenuItem(value: 'instruction', child: Text('instruction')),
                    ],
                    onChanged: (v) => v != null ? dc.exportFormat.value = v : null,
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    final completed = dc.completedTasks;
                    if (completed.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D21),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF3A3F47)),
                        ),
                        child: const Center(
                          child: Text('暂无已完成的任务', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                        ),
                      );
                    }
                    return Column(
                      children: completed.map((t) => CheckboxListTile(
                        value: dc.exportSelectedTaskIds.contains(t.id),
                        onChanged: (v) => dc.toggleExportTask(t.id),
                        title: Text(t.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        subtitle: Text('${t.stats.recordsGenerated} 条', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                      )).toList(),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => dc.exportRwkv(),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('导出 RWKV 格式'),
                        style: _btnStyle(const Color(0xFF3B82F6), compact: true),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.square, size: 18),
                        label: const Text('导出 BINIDX'),
                        style: _btnStyle(const Color(0xFF22C55E), compact: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: _distillCard(
              icon: Icons.description,
              title: '导出历史',
              compact: true,
              child: Obx(() {
                if (dc.exportHistory.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('暂无导出记录', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dc.exportHistory.take(10).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${e.exportedAt.split('T').first} · ${e.formatType} · ${e.recordsCount} 条',
                      style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 13),
                    ),
                  )).toList(),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 生成器管理 - 生成器列表 + 生成器配置
  Widget _buildDistillationGeneratorTab() {
    final dc = Get.find<DistillationController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _distillCard(
              icon: Icons.settings,
              title: '生成器列表',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('管理可用的数据生成器（参考 rwkv-fine-tuning-data-generator）', style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
                  const SizedBox(height: 20),
                  Obx(() => Column(
                    children: dc.generators.map((g) => ListTile(
                      dense: true,
                      title: Text(g.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(g.description, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                      trailing: Icon(g.enabled ? Icons.check_circle : Icons.cancel, color: g.enabled ? const Color(0xFF22C55E) : const Color(0xFF6B7280), size: 20),
                    )).toList(),
                  )),
                  const SizedBox(height: 16),
                  const Text(
                    '新建生成器需在本地配置 YAML，详见 GENERATORS.md',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: _distillCard(
              icon: Icons.edit,
              title: '生成器说明',
              compact: true,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '无工具对话: 生成纯对话数据，无需工具调用\n'
                    '工具调用: 生成需要工具调用的对话数据，支持 L0-L4 级别',
                    style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// LLM服务商 - 服务商列表 + 服务商配置
  Widget _buildDistillationLLMTab() {
    final dc = Get.find<DistillationController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _distillCard(
              icon: Icons.psychology,
              title: 'LLM 服务商列表',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('配置和管理 LLM 服务商', style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
                  const SizedBox(height: 16),
                  Obx(() => Column(
                    children: dc.llmProviders.map((p) => ListTile(
                      dense: true,
                      title: Text(p.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(p.model.isNotEmpty ? p.model : p.apiBaseUrl, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                        onPressed: () => dc.removeLLMProvider(p.id),
                      ),
                    )).toList(),
                  )),
                  if (dc.llmProviders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('暂无服务商，在右侧添加', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _buildLLMProviderForm(dc),
          ),
        ],
      ),
    );
  }

  Widget _buildLLMProviderForm(DistillationController dc) {
    return _distillCard(
      icon: Icons.edit,
      title: '新增服务商',
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: dc.llmNameController,
            decoration: const InputDecoration(labelText: '服务商名称', hintText: 'OpenRouter', border: OutlineInputBorder()),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dc.llmUrlController,
            decoration: const InputDecoration(labelText: 'API Base URL', hintText: 'https://api.openai.com/v1', border: OutlineInputBorder()),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dc.llmKeyController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder()),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dc.llmModelController,
            decoration: const InputDecoration(labelText: '模型', hintText: 'gpt-4', border: OutlineInputBorder()),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dc.llmModelsController,
            decoration: const InputDecoration(labelText: '可用模型(可选,逗号分隔)', border: OutlineInputBorder()),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dc.llmTokensController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '最大 Token 数', border: OutlineInputBorder()),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final name = dc.llmNameController.text.trim();
                if (name.isEmpty) {
                  Get.snackbar('提示', '请输入服务商名称');
                  return;
                }
                dc.addLLMProvider(LLMProvider(
                  id: 'llm_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  apiBaseUrl: dc.llmUrlController.text.trim(),
                  apiKey: dc.llmKeyController.text.trim(),
                  model: dc.llmModelController.text.trim(),
                  modelsList: dc.llmModelsController.text.trim().isEmpty ? null : dc.llmModelsController.text.trim(),
                  maxTokens: int.tryParse(dc.llmTokensController.text) ?? 4096,
                ));
                dc.llmNameController.clear();
                dc.llmUrlController.clear();
                dc.llmKeyController.clear();
                dc.llmModelController.clear();
                dc.llmModelsController.clear();
                Get.snackbar('已添加', '服务商 $name 已添加');
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加服务商'),
              style: _btnStyle(const Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _distillCard({
    required IconData icon,
    required String title,
    required Widget child,
    bool compact = false,
    double? minHeight,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: compact
          ? (minHeight != null ? BoxConstraints(minHeight: minHeight) : null)
          : BoxConstraints(minHeight: minHeight ?? 420),
      decoration: BoxDecoration(
        color: const Color(0xFF252830),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3F47)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF3B82F6), size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (compact) child else Expanded(child: child),
        ],
      ),
    );
  }

  // ─── Tab 5: 设置 ─────────────────────────────────────────────────────────────

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildCudaCard(),
          const SizedBox(height: 20),
          _buildEnvCard(),
        ],
      ),
    );
  }

  Widget _buildCudaCard() {
    return _sectionCard(
      title: 'CUDA 配置',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RWKV7 训练需要 CUDA_HOME 环境变量指向 CUDA 安装目录。\n'
            '启动时会自动检测，也可手动选择。',
            style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),
          _labeledField(
            'CUDA 安装目录',
            controller.cudaHomeController,
            hint: r'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.x',
            onBrowse: controller.pickCudaHomeDir,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: controller.detectCudaHome,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('自动检测'),
                style: _btnStyle(const Color(0xFF3B82F6), compact: true),
              ),
              const SizedBox(width: 12),
              // 检测结果状态指示
              Obx(() {
                final path = controller.cudaHome.value;
                if (path.isEmpty) {
                  return const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFBBF24), size: 18),
                      SizedBox(width: 6),
                      Text('未设置，训练时将尝试自动检测',
                          style: TextStyle(
                              color: Color(0xFFFBBF24), fontSize: 13)),
                    ],
                  );
                }
                return Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF22C55E), size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(path,
                          style: const TextStyle(
                              color: Color(0xFF22C55E), fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() => _logBox(controller.cudaDetectLog.value,
              minHeight: 50, placeholder: '点击「自动检测」检查 CUDA 安装')),
        ],
      ),
    );
  }

  Widget _buildEnvCard() {
    return _sectionCard(
        title: '环境配置',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '一键安装 RWKV State Tuning 所需依赖\n'
              '(来源: github.com/Joluck/statetuning)',
              style: TextStyle(
                  color: Color(0xFFB0B5BC), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D21),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3A3F47)),
              ),
              child: const SelectableText(
                'torch>=2.0.0\ntransformers>=4.30.0\ntqdm>=4.65.0\nhuggingface-hub',
                style: TextStyle(
                    color: Color(0xFF86EFAC),
                    fontSize: 12,
                    fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.isInstalling.value
                            ? null
                            : controller.installEnvironment,
                        icon: controller.isInstalling.value
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.install_desktop),
                        label: Text(controller.isInstalling.value
                            ? '安装中...'
                            : '一键安装'),
                        style: _btnStyle(const Color(0xFF3B82F6)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (controller.isInstalling.value ||
                                controller.isChecking.value)
                            ? null
                            : controller.checkEnvironment,
                        icon: controller.isChecking.value
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.verified_user),
                        label: Text(controller.isChecking.value
                            ? '检测中...'
                            : '检测环境'),
                        style: _btnStyle(controller.envReady.value
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                )),
            Obx(() => controller.envReady.value
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green[400], size: 20),
                        const SizedBox(width: 8),
                        Text('所有环境已经准备好',
                            style: TextStyle(
                                color: Colors.green[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 20),
            _logLabel('安装日志'),
            const SizedBox(height: 8),
            Obx(() => _logBox(controller.installLog.value,
                placeholder: '点击「一键安装」开始安装...')),
            const SizedBox(height: 16),
            _logLabel('检测结果'),
            const SizedBox(height: 8),
            Obx(() => _logBox(controller.checkLog.value,
                placeholder: '点击「检测环境」按钮检查依赖是否已安装')),
          ],
        ),
    );
  }

  // ─── Shared Helpers ──────────────────────────────────────────────────────────

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF252830),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3F47)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _labeledField(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onBrowse,
    IconData browseIcon = Icons.folder_open,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle:
                      const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF1A1D21),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF3A3F47)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF3A3F47)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                ),
              ),
            ),
            if (onBrowse != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: '浏览',
                child: Material(
                  color: const Color(0xFF3A3F47),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onBrowse,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(browseIcon,
                          color: const Color(0xFFB0B5BC), size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _logBox(String text,
      {double minHeight = 140, String placeholder = ''}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3F47)),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text.isEmpty ? placeholder : text,
          style: TextStyle(
            color: text.isEmpty
                ? const Color(0xFF4B5563)
                : const Color(0xFFB0B5BC),
            fontSize: 12,
            fontFamily: 'monospace',
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _logLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: Color(0xFFB0B5BC),
            fontSize: 13,
            fontWeight: FontWeight.w500));
  }

  ButtonStyle _btnStyle(Color color, {bool compact = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      disabledBackgroundColor: color.withValues(alpha: 0.4),
      disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
          : const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    );
  }
}
