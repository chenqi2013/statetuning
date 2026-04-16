import 'dart:io' show Platform;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D21),
      body: Stack(
        children: [
          Column(
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
                      return _buildMonitorTab(context);
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
          Obx(() {
            if (!controller.isCloningRepo.value) return const SizedBox.shrink();
            return Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '正在初始化仓库...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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
          Obx(() {
            if (!controller.envReady.value) return const SizedBox.shrink();
            return Row(
              children: [
                _chip(Icons.memory, 'GPU: ${controller.gpuInfo.value}'),
                const SizedBox(width: 16),
                _chip(
                  controller.isTraining.value
                      ? Icons.play_arrow
                      : Icons.circle,
                  controller.status.value,
                  color: controller.isTraining.value
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFB0B5BC),
                ),
              ],
            );
          }),
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

  /// 内容索引 -> 标签。0=模型 1=数据 2=训练 3=监控 4=导出 5=设置
  static const _tabLabels = ['模型', '数据', '训练', '监控', '导出', '设置'];

  /// 环境未就绪时设置放第一位，就绪后放最后
  List<int> _tabOrder() =>
      controller.envReady.value ? [0, 1, 2, 3, 4, 5] : [5, 0, 1, 2, 3, 4];

  Widget _buildTabBar() {
    return Obx(
      () {
        final order = _tabOrder();
        return Container(
          color: const Color(0xFF1A1D21),
          child: Row(
            children: order.map((contentIndex) {
              final selected = controller.currentTabIndex.value == contentIndex;
              return GestureDetector(
                onTap: () => controller.setTabIndex(contentIndex),
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
                    _tabLabels[contentIndex],
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF6B7280),
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labeledField(
                  '预训练模型 (.pth)',
                  controller.modelPathController,
                  hint: '选择或粘贴路径，自动读取模型尺寸',
                  onBrowse: controller.pickModelFile,
                  browseIcon: Icons.file_open,
                ),
                Obx(() {
                  if (!controller.isDetectingModel.value) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Row(children: [
                      SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('正在读取模型尺寸...',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                    ]),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: 'ModelArgs（高级）',
            child: Row(
              children: [
                Expanded(
                  child: _labeledField('词表大小 (vocab_size)',
                      controller.vocabSizeController,
                      hint: '65536', keyboardType: TextInputType.number, readOnly: true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _labeledField('嵌入维度 (n_embd)',
                      controller.nEmbdController,
                      hint: '1024', keyboardType: TextInputType.number, readOnly: true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _labeledField('层数 (n_layer)',
                      controller.nLayerController,
                      hint: '24', keyboardType: TextInputType.number, readOnly: true),
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
            title: '训练仓库',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '首次进入已自动解压内置仓库到 exe 同目录，可直接使用。',
                  style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                _labeledField('仓库路径', controller.repoPathController,
                    hint: '默认：exe 同目录 / statetuning_repo',
                    onBrowse: controller.pickRepoDir),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: controller.isCloningRepo.value ? null : controller.checkRepo,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('检查路径'),
                      style: _btnStyle(const Color(0xFF6B7280), compact: true),
                    ),
                    const SizedBox(width: 12),
                    Obx(() {
                      if (!controller.repoCloned.value &&
                          controller.repoPath.value.isNotEmpty) {
                        return TextButton.icon(
                          onPressed: controller.isCloningRepo.value
                              ? null
                              : controller.initRepoFromBundle,
                          icon: const Icon(Icons.folder_copy, size: 16),
                          label: const Text('解压到此处'),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() => _logBox(controller.repoLog.value,
                    minHeight: 50,
                    placeholder: '仓库状态显示在此')),
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
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D21),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3A3F47)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _labeledField('上下文长度 (ctx_len)',
                          controller.ctxLenController,
                          hint: '512', keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('训练精度',
                              style: TextStyle(
                                  color: Color(0xFF9CA3AF), fontSize: 13)),
                          const SizedBox(height: 8),
                          Obx(() => Row(
                                children: [
                                  _precisionButton('BF16', TrainingPrecision.bf16),
                                  const SizedBox(width: 10),
                                  _precisionButton('FP16', TrainingPrecision.fp16),
                                  const SizedBox(width: 10),
                                  _precisionButton('FP32', TrainingPrecision.fp32),
                                ],
                              )),
                        ],
                      ),
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
                    '点击「开始训练」会直接在仓库目录运行 train.py 并传入参数，训练日志实时显示在「监控」标签页。',
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

  Widget _buildMonitorTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Obx(() => _statusBadge(controller.isTraining.value)),
              const Spacer(),
              // 「查看Loss曲线」按钮：训练完成且有数据时显示
              Obx(() {
                if (controller.lossHistory.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    onPressed: controller.exportLossLog,
                    icon: const Icon(Icons.file_present, size: 18),
                    label: const Text('导出 train_loss.jsonl'),
                    style: _btnStyle(const Color(0xFF3B82F6), compact: true),
                  ),
                );
              }),
              Obx(() {
                if (controller.lossHistory.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => _showLossChart(context),
                    icon: const Icon(Icons.show_chart, size: 18),
                    label: const Text('查看Loss曲线'),
                    style: _btnStyle(const Color(0xFF7C3AED), compact: true),
                  ),
                );
              }),
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

  void _showLossChart(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1D21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 700,
          height: 460,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.show_chart, color: Color(0xFF7C3AED), size: 22),
                    const SizedBox(width: 10),
                    const Text('Training Loss 曲线',
                        style: TextStyle(color: Color(0xFFE2E8F0),
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Obx(() => Text(
                          '共 ${controller.lossHistory.length} 步',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 13),
                        )),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(child: Obx(() => _buildLossChart(controller.lossHistory))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLossChart(List<double> losses) {
    if (losses.isEmpty) {
      return const Center(
          child: Text('暂无 Loss 数据', style: TextStyle(color: Color(0xFF6B7280))));
    }

    // 每隔 N 点采样，避免数据量太大时渲染卡顿
    const maxPoints = 400;
    final step = losses.length > maxPoints ? (losses.length / maxPoints).ceil() : 1;
    final spots = <FlSpot>[];
    for (var i = 0; i < losses.length; i += step) {
      spots.add(FlSpot(i.toDouble(), losses[i]));
    }

    final minY = losses.reduce((a, b) => a < b ? a : b);
    final maxY = losses.reduce((a, b) => a > b ? a : b);
    final padY = (maxY - minY) * 0.1 + 0.05;

    return LineChart(
      LineChartData(
        minY: minY - padY,
        maxY: maxY + padY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF7C3AED),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFF2A2D35), strokeWidth: 1),
          getDrawingVerticalLine: (_) =>
              const FlLine(color: Color(0xFF2A2D35), strokeWidth: 1),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFF3A3F47)),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Loss',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, _) => Text(v.toStringAsFixed(2),
                  style: const TextStyle(
                      color: Color(0xFF6B7280), fontSize: 11)),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Step',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: const TextStyle(
                      color: Color(0xFF6B7280), fontSize: 11)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF252830),
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      'Step ${s.x.toInt()}\nLoss: ${s.y.toStringAsFixed(4)}',
                      const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                    ))
                .toList(),
          ),
        ),
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
                          '暂无输出文件\n训练完成后，.state.pth 权重文件将显示在这里',
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
              '训练完成后，State 权重文件 (.state.pth) 可加载到 RWKV 推理框架中。\n\n'
              '• 与原始 .pth 模型权重分开存储，体积极小\n'
              '• 只包含经过微调的 state 参数，pth 格式避免混淆\n'
              '• 推理时合并使用: model.pth + xxx.state.pth',
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
      child: Column(
        children: [
          _buildSystemBaseCard(),
          const SizedBox(height: 20),
          _buildCudaCard(),
          const SizedBox(height: 20),
          _buildEnvCard(),
        ],
      ),
    );
  }

  Widget _buildSystemBaseCard() {
    return _sectionCard(
      title: '系统基础（全新电脑必检）',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '以下为一键安装的先决条件，全新 Windows 请按顺序检查：',
            style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final winget = controller.wingetInstalled.value;
            return _buildStatusRow(
              'winget（应用安装程序）',
              winget,
              description: 'Git / Python / CUDA / MSVC 等一键安装均依赖 winget',
              onRetry: controller.detectWinget,
              whenMissing: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '全新系统可能未预装，请通过以下方式安装：',
                    style: TextStyle(color: Color(0xFFFBBF24), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => controller.openUrl('https://aka.ms/getwinget'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('打开 winget 安装页'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('或运行 PowerShell（以管理员身份）：',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                  const SizedBox(height: 4),
                  SelectableText(
                    'Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe',
                    style: const TextStyle(
                      color: Color(0xFF86EFAC),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            );
              }),
          const SizedBox(height: 16),
          Obx(() {
            final uv = controller.uvInstalled.value;
            return _buildStatusRow(
              'UV',
              uv,
              description: 'Python 虚拟环境工具，依赖安装到项目 python_venv 目录',
              onRetry: controller.detectUv,
              whenMissing: ElevatedButton.icon(
                onPressed: controller.isUvInstalling.value ? null : controller.installUv,
                icon: controller.isUvInstalling.value
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download, size: 18),
                label: Text(controller.isUvInstalling.value ? '安装中...' : '一键安装 UV'),
                style: _btnStyle(const Color(0xFF7C3AED), compact: true),
              ),
            );
          }),
          const SizedBox(height: 16),
          Obx(() {
            final nvidia = controller.nvidiaDriverInstalled.value;
            return _buildStatusRow(
              'NVIDIA 驱动',
              nvidia,
              description: 'GPU 训练需先装驱动，再装 CUDA Toolkit（无 NVIDIA 显卡可跳过）',
              onRetry: controller.detectNvidiaDriver,
              whenMissing: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => controller.openUrl('https://www.nvidia.com/Download/index.aspx'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('前往 NVIDIA 官网下载驱动'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    bool installed, {
    required String description,
    VoidCallback? onRetry,
    Widget? whenMissing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: installed ? const Color(0xFF22C55E) : const Color(0xFF3A3F47),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                installed ? Icons.check_circle : Icons.warning_amber_rounded,
                color: installed ? const Color(0xFF22C55E) : const Color(0xFFFBBF24),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: installed ? const Color(0xFF22C55E) : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onRetry != null) ...[
                const Spacer(),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('重新检测'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
          if (!installed && whenMissing != null) ...[
            const SizedBox(height: 12),
            whenMissing,
          ],
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
            'RWKV7 训练需要 CUDA Toolkit（CUDA_HOME 指向安装目录）。\n'
            '启动时自动检测，未检测到可点击「一键安装 CUDA」或手动选择。',
            style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),
          _labeledField(
            'CUDA 安装目录',
            controller.cudaHomeController,
            hint: r'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.x 或 v13.x',
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
              Obx(() {
                if (controller.cudaInstalled.value) {
                  return Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF22C55E), size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(controller.cudaHome.value,
                              style: const TextStyle(
                                  color: Color(0xFF22C55E), fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                }
                return Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.isCudaInstalling.value
                        ? null
                        : controller.installCuda,
                    icon: controller.isCudaInstalling.value
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: Text(controller.isCudaInstalling.value
                        ? '安装中...'
                        : '一键安装 CUDA'),
                    style: _btnStyle(const Color(0xFF7C3AED), compact: true),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() => _logBox(controller.cudaDetectLog.value,
              minHeight: 50, placeholder: '点击「自动检测」检查 CUDA 安装')),
          Obx(() {
            if (controller.cudaInstallLog.value.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _logLabel('CUDA 安装日志'),
                  const SizedBox(height: 8),
                  _logBox(controller.cudaInstallLog.value),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEnvCard() {
    return _sectionCard(
        title: '环境配置',
        child: Obx(() {
          final ready = controller.envReady.value;
          final checking = controller.isChecking.value;
          final installing = controller.isInstalling.value;
          return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 环境就绪状态栏 ──────────────────────────────────────
            if (checking)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('正在检测环境...', style: TextStyle(color: Color(0xFFB0B5BC))),
                ]),
              )
            else if (ready)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[400], size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('所有环境已就绪',
                          style: TextStyle(color: Colors.green[400],
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    TextButton.icon(
                      onPressed: controller.checkEnvironment,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('重新检测'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              )
            else ...[
              // ── 未安装 UV 时优先显示 ────────────────────────────────
              Obx(() {
                if (!controller.uvInstalled.value) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFFBBF24), size: 20),
                          SizedBox(width: 8),
                          Text('未检测到 UV，依赖将安装到项目目录',
                              style: TextStyle(color: Color(0xFFFBBF24),
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'UV 会创建 python_venv 虚拟环境，依赖装到项目目录，不占用 C 盘。',
                        style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.isUvInstalling.value
                              ? null
                              : controller.installUv,
                          icon: controller.isUvInstalling.value
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.download),
                          label: Text(controller.isUvInstalling.value
                              ? '安装中...'
                              : '一键安装 UV'),
                          style: _btnStyle(const Color(0xFF7C3AED)),
                        ),
                      ),
                      if (controller.uvInstallLog.value.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _logLabel('UV 安装日志'),
                        const SizedBox(height: 8),
                        Obx(() => _logBox(controller.uvInstallLog.value)),
                      ],
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFF3A3F47)),
                      const SizedBox(height: 12),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              const Text(
                '以下依赖将安装到项目 python_venv 目录（不占 C 盘），点击「一键安装」：\n'
                '(来源: github.com/Joluck/statetuning)',
                style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 14, height: 1.5),
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
                  'UV 创建 python_venv → 安装：\n'
                  'torch>=2.0.0  [GPU/CUDA，自动匹配 CUDA 版本]\n'
                  'transformers>=4.30.0\n'
                  'tqdm>=4.65.0\n'
                  'huggingface-hub\n'
                  'ninja          [CUDA 扩展构建]',
                  style: TextStyle(color: Color(0xFF86EFAC),
                      fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: installing ? null : controller.installEnvironment,
                      icon: installing
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.install_desktop),
                      label: Text(installing ? '安装中...' : '一键安装'),
                      style: _btnStyle(const Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (installing || checking)
                          ? null : controller.checkEnvironment,
                      icon: checking
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.verified_user),
                      label: Text(checking ? '检测中...' : '检测环境'),
                      style: _btnStyle(const Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ],
            // ── 检测结果日志（有问题时才显示）────────────────────────
            if (!ready) ...[
              const SizedBox(height: 16),
              _logLabel('检测结果'),
              const SizedBox(height: 8),
              _logBox(controller.checkLog.value,
                  placeholder: '正在检测环境...'),
            ],
            // ── 安装日志（有内容时才显示）────────────────────────────
            if (controller.installLog.value.isNotEmpty) ...[
              const SizedBox(height: 16),
              _logLabel('安装日志'),
              const SizedBox(height: 8),
              _logBox(controller.installLog.value,
                  placeholder: '点击「一键安装」开始安装...'),
            ],
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF3A3F47)),
            const SizedBox(height: 16),
            const Text(
              'CUDA 编译工具',
              style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              '训练时需要实时编译 CUDA 内核（rwkv7_state_clampw），'
              '必须安装 MSVC C++ 编译器。\n'
              '点击下方按钮自动安装轻量版编译工具（约 1.5 GB，无 IDE）：\n'
              '  • ninja  — 构建系统（pip 安装，几 MB）\n'
              '  • MSVC C++ 编译器 + Windows SDK（通过 winget 安装）',
              style: TextStyle(
                  color: Color(0xFFB0B5BC), fontSize: 13, height: 1.6),
            ),
            if (Platform.isWindows) ...[
              const SizedBox(height: 12),
              Obx(() => _buildStatusRow(
                    'ninja',
                    controller.ninjaOnPath.value,
                    description:
                        '系统 PATH 或仓库内 python_venv\\Scripts\\ninja.exe（pip 安装）',
                    onRetry: controller.detectBuildTools,
                  )),
              const SizedBox(height: 10),
              Obx(() => _buildStatusRow(
                    'MSVC C++（cl.exe）',
                    controller.msvcClOnPath.value,
                    description: 'Visual Studio Build Tools：C++ 编译器与 Windows SDK',
                    onRetry: controller.detectBuildTools,
                  )),
            ],
            const SizedBox(height: 12),
            Obx(() {
              final installing = controller.isBuildToolsInstalling.value;
              final ready = controller.buildToolsFullyReady.value;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (installing || ready)
                      ? null
                      : controller.installBuildTools,
                  icon: installing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          ready ? Icons.check_circle : Icons.build,
                          size: 20,
                        ),
                  label: Text(
                    installing
                        ? '安装中...'
                        : ready
                            ? '已安装（ninja + MSVC）'
                            : '安装编译工具（ninja + MSVC）',
                  ),
                  style: _btnStyle(
                    ready
                        ? const Color(0xFF166534)
                        : const Color(0xFF7C3AED),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            _logLabel('编译工具安装日志'),
            const SizedBox(height: 8),
            Obx(() => _logBox(controller.buildToolsLog.value,
                placeholder: '点击「安装编译工具」开始安装...')),
          ],
        );
        }), // end Obx
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
    bool readOnly = false,
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
                readOnly: readOnly,
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
