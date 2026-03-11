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
          _buildTabBar(),
          Expanded(
            child: Obx(() {
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
            }),
          ),
        ],
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
    const tabs = ['模型', '数据', '训练', '监控', '导出', '设置'];
    return Obx(
      () => Container(
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
      ),
    );
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
            title: '仓库路径 (github.com/Joluck/statetuning)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labeledField('本地路径', controller.repoPathController,
                    hint: '点击右侧按钮选择文件夹',
                    onBrowse: controller.pickRepoDir),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Obx(() => Expanded(
                          child: ElevatedButton.icon(
                            onPressed: controller.isCloningRepo.value
                                ? null
                                : controller.cloneRepo,
                            icon: controller.isCloningRepo.value
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.download),
                            label: Text(controller.isCloningRepo.value
                                ? '克隆中...'
                                : '克隆仓库'),
                            style: _btnStyle(const Color(0xFF6366F1)),
                          ),
                        )),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.checkRepo,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('检查路径'),
                        style: _btnStyle(const Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() => _logBox(controller.repoLog.value,
                    minHeight: 60, placeholder: '点击「检查路径」或「克隆仓库」')),
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

  // ─── Tab 5: 设置 ─────────────────────────────────────────────────────────────

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _sectionCard(
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
