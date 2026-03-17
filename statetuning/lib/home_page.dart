import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左：基本配置
          Expanded(
            flex: 1,
            child: _distillCard(
              icon: Icons.settings,
              title: '基本配置',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _distillFormField('任务名称', '输入任务名称'),
                  const SizedBox(height: 14),
                  _distillFormField('生成器类型', '无工具对话'),
                  const Text(
                    '生成纯对话数据,无需工具调用',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  _distillFormField('生成数量', '100'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Temperature: 0.7',
                          style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: const Color(0xFF3B82F6),
                            inactiveTrackColor: const Color(0xFF3A3F47),
                            thumbColor: const Color(0xFF3B82F6),
                          ),
                          child: Slider(value: 0.7, onChanged: (_) {}),
                        ),
                      ),
                    ],
                  ),
                  _distillFormField('并发数 (线程数)', '4'),
                  _distillFormField('API Key (可选)', '默认使用 sk-test'),
                  _distillFormField('LLM 服务商(可选)', '-- 使用API Key 或默认--'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // 右：语言比例 + 话题范围
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _distillCard(
                  icon: Icons.language,
                  title: '语言比例分配',
                  compact: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '各语言比例总和必须等于100%',
                        style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _langPercentItem('中文 (ZH)', 70),
                          _langPercentItem('英文 (EN)', 15),
                          _langPercentItem('日文 (JA)', 2),
                          _langPercentItem('韩文 (KO)', 2),
                          _langPercentItem('德文 (DE)', 3),
                          _langPercentItem('法文 (FR)', 3),
                          _langPercentItem('西班牙 (ES)', 3),
                          _langPercentItem('俄文 (RU)', 2),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('总计: 100%',
                          style: TextStyle(color: Color(0xFF22C55E), fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _distillCard(
                  icon: Icons.category,
                  title: '话题范围配置',
                  compact: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '选择要包含的话题分类,留空则使用全部话题',
                        style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text('加载中...',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: _btnStyle(const Color(0xFF3B82F6), compact: true),
                            child: const Text('全选'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {},
                            style: _btnStyle(const Color(0xFF6B7280), compact: true),
                            child: const Text('全不选'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('新增话题'),
                            style: _btnStyle(const Color(0xFF22C55E), compact: true),
                          ),
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

  Widget _langPercentItem(String label, int value) {
    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D21),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF3A3F47)),
            ),
            child: Text('$value', style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildDistillationQueueTab() {
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
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D21),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3A3F47)),
              ),
              child: const Center(
                child: Text(
                  '暂无任务\n请在「配置」中创建蒸馏任务',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => controller.setDistillationTabIndex(0),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('去配置新建任务'),
              style: _btnStyle(const Color(0xFF3B82F6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistillationMonitorTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Row(
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
                            const Text(
                              '0.0 条/分钟',
                              style: TextStyle(color: Color(0xFFA78BFA), fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'ETA: --:--:--',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
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
                            const Text(
                              '暂无运行中的任务',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                            ),
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
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _distillCard(
                  icon: Icons.description,
                  title: '实时日志',
                  compact: false,
                  minHeight: 150,
                  child: LayoutBuilder(
                    builder: (_, c) => SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: const SelectableText(
                          '系统就绪, 等待任务...',
                          style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 数据统计 - 系统概览
  Widget _buildDistillationStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _distillCard(
            icon: Icons.bar_chart,
            title: '系统概览',
            compact: true,
            child: Row(
              children: [
                _statCard('总任务数', 0),
                const SizedBox(width: 16),
                _statCard('总记录数', 0),
                const SizedBox(width: 16),
                _statCard('运行中', 0),
                const SizedBox(width: 16),
                _statCard('已完成', 0),
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
            child: const Center(
              child: Text(
                '暂无数据,请先完成一些生成任务',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
              ),
            ),
          ),
        ],
      ),
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
                    '选择已完成的任务进行导出 (使用生成器对应的RWKV 模板)',
                    style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [_distillCheckbox('打乱顺序 (防止过拟合)', true)]),
                  const SizedBox(height: 8),
                  Row(children: [_distillCheckbox('按类型合并 (生成多个文件)', false)]),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D21),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3A3F47)),
                    ),
                    child: const Center(
                      child: Text('暂无已完成的任务', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('预览'),
                        style: _btnStyle(const Color(0xFF22C55E), compact: true),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {},
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D21),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3A3F47)),
                    ),
                    child: const Center(
                      child: Text('暂无导出记录', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 生成器管理 - 生成器列表 + 生成器配置
  Widget _buildDistillationGeneratorTab() {
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
                  const Text('管理可用的数据生成器', style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新建生成器'),
                    style: _btnStyle(const Color(0xFF3B82F6)),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D21),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3A3F47)),
                    ),
                    child: const Center(
                      child: Text('暂无生成器\n点击「新建生成器」添加', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14), textAlign: TextAlign.center),
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
              icon: Icons.edit,
              title: '生成器配置',
              compact: true,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Center(
                    child: Text('从左侧选择一个生成器进行编辑', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _distillCard(
              icon: Icons.psychology,
              title: 'LLM 服务商配置',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('配置和管理 LLM 服务商', style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新增服务商'),
                    style: _btnStyle(const Color(0xFF3B82F6)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _distillCard(
              icon: Icons.edit,
              title: '服务商配置',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _distillFormField('服务商名称', 'OpenRouter'),
                  _distillFormField('服务商类型', '自定义'),
                  _distillFormField('API Base URL', 'https://huoshan.com'),
                  _distillFormField('API Key', '............'),
                  _distillFormField('模型', 'huoshan'),
                  _distillFormField('可用模型列表(可选,逗号分隔)', 'doubaov2.3'),
                  _distillFormField('最大 Token 数', '4096'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('保存配置'),
                      style: _btnStyle(const Color(0xFF3B82F6)),
                    ),
                  ),
                ],
              ),
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

  Widget _distillFormField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D21),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A3F47)),
          ),
          child: Text(
            hint,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _distillCheckbox(String label, bool value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: value ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: value ? const Color(0xFF3B82F6) : const Color(0xFF6B7280)),
          ),
          child: value
              ? const Icon(Icons.check, color: Colors.black, size: 14)
              : null,
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 13)),
      ],
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
