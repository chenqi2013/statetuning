import 'dart:io' show Platform;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home_controller.dart';
import 'l10n/app_locale.dart';

String _presetDisplayLabel(String label) =>
    label == '自定义' ? 'preset_custom'.tr : label;

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
                    case 6:
                      return _buildTestTab();
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
                      'clone_repo_initializing'.tr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
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
        children: [
          Text(
            'app_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _buildLanguageMenu(),
          Obx(() {
            if (!controller.envReady.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  _chip(
                    Icons.memory,
                    'gpu_chip'.trParams({'v': controller.gpuInfo.value}),
                  ),
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
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _sameLocale(Locale? a, Locale b) {
    if (a == null) return false;
    return a.languageCode == b.languageCode &&
        (a.countryCode ?? '') == (b.countryCode ?? '');
  }

  Widget _buildLanguageMenu() {
    final current = Get.locale ?? Get.fallbackLocale;
    return PopupMenuButton<Locale>(
      tooltip: 'tooltip_language'.tr,
      position: PopupMenuPosition.under,
      color: const Color(0xFF2A2F38),
      icon: const Icon(
        Icons.language_outlined,
        color: Color(0xFFB0B5BC),
        size: 22,
      ),
      onSelected: Get.updateLocale,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: kAppSupportedLocales[0],
          child: Row(
            children: [
              if (_sameLocale(current, kAppSupportedLocales[0]))
                const Icon(Icons.check, size: 18, color: Color(0xFF3B82F6))
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              const Text('English', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: kAppSupportedLocales[1],
          child: Row(
            children: [
              if (_sameLocale(current, kAppSupportedLocales[1]))
                const Icon(Icons.check, size: 18, color: Color(0xFF3B82F6))
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              const Text('简体中文', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: kAppSupportedLocales[2],
          child: Row(
            children: [
              if (_sameLocale(current, kAppSupportedLocales[2]))
                const Icon(Icons.check, size: 18, color: Color(0xFF3B82F6))
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              const Text('繁體中文', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(
    IconData icon,
    String label, {
    Color color = const Color(0xFFB0B5BC),
  }) {
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

  /// Content index -> label. 0=model … 6=test
  List<String> _tabLabels() => [
    'tab_model'.tr,
    'tab_data'.tr,
    'tab_train'.tr,
    'tab_monitor'.tr,
    'tab_export'.tr,
    'tab_settings'.tr,
    'tab_test'.tr,
  ];

  /// 环境未就绪时设置放第一位，就绪后放最后
  List<int> _tabOrder() =>
      controller.envReady.value ? [0, 1, 2, 3, 4, 5, 6] : [5, 0, 1, 2, 3, 4, 6];

  Widget _buildTabBar() {
    return Obx(() {
      final order = _tabOrder();
      return Container(
        color: const Color(0xFF1A1D21),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: order.map((contentIndex) {
            final selected = controller.currentTabIndex.value == contentIndex;
            return GestureDetector(
              onTap: () => controller.setTabIndex(contentIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? const Color(0xFF3B82F6)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _tabLabels()[contentIndex],
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
        ),
      );
    });
  }

  // ─── Tab 0: 模型 ─────────────────────────────────────────────────────────────

  Widget _buildModelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            title: 'model_specs_preset'.tr,
            child: Obx(
              () => Wrap(
                spacing: 12,
                runSpacing: 8,
                children: HomeController.presets.map((p) {
                  final selected = controller.selectedPreset.value == p.label;
                  return GestureDetector(
                    onTap: () => controller.applyPreset(p.label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
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
                        _presetDisplayLabel(p.label),
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFFB0B5BC),
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: 'model_file_path'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labeledField(
                  'label_pretrained_pth'.tr,
                  controller.modelPathController,
                  hint: 'hint_model_path'.tr,
                  onBrowse: controller.pickModelFile,
                  browseIcon: Icons.file_open,
                ),
                Obx(() {
                  if (!controller.isDetectingModel.value)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'reading_model_dims'.tr,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: 'modelargs_advanced'.tr,
            child: Row(
              children: [
                Expanded(
                  child: _labeledField(
                    'label_vocab_size'.tr,
                    controller.vocabSizeController,
                    hint: '65536',
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _labeledField(
                    'label_n_embd'.tr,
                    controller.nEmbdController,
                    hint: '1024',
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _labeledField(
                    'label_n_layer'.tr,
                    controller.nLayerController,
                    hint: '24',
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
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
              label: Text('next_data_config'.tr),
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
            title: 'train_repo'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'train_repo_desc'.tr,
                  style: const TextStyle(
                    color: Color(0xFFB0B5BC),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledField(
                  'label_repo_path'.tr,
                  controller.repoPathController,
                  hint: 'hint_repo_path_default'.tr,
                  onBrowse: controller.pickRepoDir,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: controller.isCloningRepo.value
                          ? null
                          : controller.checkRepo,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text('btn_check_path'.tr),
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
                          label: Text('btn_extract_here'.tr),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(
                  () => _logBox(
                    controller.repoLog.value,
                    minHeight: 50,
                    placeholder: 'repo_log_placeholder'.tr,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: 'train_data'.tr,
            child: Column(
              children: [
                _labeledField(
                  'label_jsonl_path'.tr,
                  controller.dataPathController,
                  hint: 'hint_jsonl_pick'.tr,
                  onBrowse: controller.pickDataFile,
                  browseIcon: Icons.file_open,
                ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'data_format_title'.tr,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          'data_format_example_line'.tr,
                          style: const TextStyle(
                            color: Color(0xFF86EFAC),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
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
            title: 'output_dir_section'.tr,
            child: _labeledField(
              'label_output_dir'.tr,
              controller.outputDirController,
              hint: 'hint_output_dir'.tr,
              onBrowse: controller.pickOutputDir,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.setTabIndex(2),
              icon: const Icon(Icons.arrow_forward),
              label: Text('next_train_params'.tr),
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
            title: 'train_hyperparams'.tr,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _labeledField(
                        'label_batch_size'.tr,
                        controller.batchSizeController,
                        hint: '4',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _labeledField(
                        'label_num_steps'.tr,
                        controller.numStepsController,
                        hint: '1000',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _labeledField(
                        'label_num_epochs'.tr,
                        controller.numEpochsController,
                        hint: '1',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _labeledField(
                        'label_lr'.tr,
                        controller.learningRateController,
                        hint: '1e-5',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _labeledField(
                        'label_ctx_len'.tr,
                        controller.ctxLenController,
                        hint: '512',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'label_train_precision'.tr,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Obx(
                            () => Row(
                              children: [
                                _precisionButton(
                                  'BF16',
                                  TrainingPrecision.bf16,
                                ),
                                const SizedBox(width: 10),
                                _precisionButton(
                                  'FP16',
                                  TrainingPrecision.fp16,
                                ),
                                const SizedBox(width: 10),
                                _precisionButton(
                                  'FP32',
                                  TrainingPrecision.fp32,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => _sectionCard(
              title: 'config_summary'.tr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow(
                    'summary_repo'.tr,
                    controller.repoPath.value.isEmpty
                        ? 'value_not_set'.tr
                        : controller.repoPath.value,
                  ),
                  _summaryRow(
                    'summary_model_file'.tr,
                    controller.modelPath.value.isEmpty
                        ? 'value_not_set'.tr
                        : controller.modelPath.value,
                  ),
                  _summaryRow(
                    'summary_data_file'.tr,
                    controller.dataPath.value.isEmpty
                        ? 'value_not_set'.tr
                        : controller.dataPath.value,
                  ),
                  _summaryRow('summary_output_dir'.tr, controller.outputDir.value),
                  _summaryRow(
                    'summary_precision'.tr,
                    controller.precisionString.toUpperCase(),
                  ),
                  _summaryRow(
                    'summary_model_spec'.tr,
                    _presetDisplayLabel(controller.selectedPreset.value),
                  ),
                  _summaryRow(
                    'summary_embd_layer'.tr,
                    '${controller.nEmbd.value} / ${controller.nLayer.value}',
                  ),
                  _summaryRow(
                    'summary_ctx_len'.tr,
                    '${controller.ctxLen.value}',
                  ),
                  _summaryRow(
                    'summary_batch_steps_epochs'.tr,
                    '${controller.batchSize.value} / ${controller.numSteps.value} / ${controller.numEpochs.value}',
                  ),
                  _summaryRow('summary_lr'.tr, controller.learningRate.value),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: controller.isTraining.value
                        ? null
                        : controller.startTraining,
                    icon: controller.isTraining.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.rocket_launch),
                    label: Text(
                      controller.isTraining.value
                          ? 'train_in_progress'.tr
                          : 'train_start'.tr,
                    ),
                    style: _btnStyle(const Color(0xFF22C55E)),
                  ),
                ),
                if (controller.isTraining.value) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.stopTraining,
                      icon: const Icon(Icons.stop),
                      label: Text('train_btn_stop'.tr),
                      style: _btnStyle(const Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
                Expanded(
                  child: Text(
                    'train_hint_footer'.tr,
                    style: const TextStyle(
                      color: Color(0xFFB0B5BC),
                      fontSize: 12,
                    ),
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
            child: Text(
              key,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
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
                if (controller.lossHistory.isEmpty)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    onPressed: controller.exportLossLog,
                    icon: const Icon(Icons.file_present, size: 18),
                    label: Text('monitor_export_loss_jsonl'.tr),
                    style: _btnStyle(const Color(0xFF3B82F6), compact: true),
                  ),
                );
              }),
              Obx(() {
                if (controller.lossHistory.isEmpty)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => _showLossChart(context),
                    icon: const Icon(Icons.show_chart, size: 18),
                    label: Text('monitor_view_loss_chart'.tr),
                    style: _btnStyle(const Color(0xFF7C3AED), compact: true),
                  ),
                );
              }),
              Obx(() {
                if (!controller.isTraining.value)
                  return const SizedBox.shrink();
                return ElevatedButton.icon(
                  onPressed: controller.stopTraining,
                  icon: const Icon(Icons.stop, size: 18),
                  label: Text('train_btn_stop'.tr),
                  style: _btnStyle(const Color(0xFFEF4444), compact: true),
                );
              }),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => controller.trainingLog.value = '',
                icon: const Icon(Icons.clear, size: 18),
                label: Text('monitor_clear_log'.tr),
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
                    log.isEmpty ? 'monitor_log_placeholder'.tr : log,
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
                    const Icon(
                      Icons.show_chart,
                      color: Color(0xFF7C3AED),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'monitor_loss_curve_title'.tr,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => Text(
                        'loss_steps_total'.trParams({
                          'n': '${controller.lossHistory.length}',
                        }),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Obx(() => _buildLossChart(controller.lossHistory)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLossChart(List<double> losses) {
    if (losses.isEmpty) {
      return Center(
        child: Text(
          'monitor_no_loss_data'.tr,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    // 每隔 N 点采样，避免数据量太大时渲染卡顿
    const maxPoints = 400;
    final step = losses.length > maxPoints
        ? (losses.length / maxPoints).ceil()
        : 1;
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
            axisNameWidget: Text(
              'monitor_axis_loss'.tr,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(2),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text(
              'monitor_axis_step'.tr,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF252830),
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    'monitor_tooltip_loss'.trParams({
                      'x': '${s.x.toInt()}',
                      'y': s.y.toStringAsFixed(4),
                    }),
                    const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                  ),
                )
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
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF22C55E),
              ),
            )
          else
            const Icon(Icons.circle, size: 10, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(
            isTraining ? 'monitor_badge_training'.tr : 'monitor_badge_idle'.tr,
            style: TextStyle(
              color: isTraining
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF6B7280),
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
            title: 'export_output_files'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    'export_output_dir_label'.trParams({
                      'path': controller.outputDir.value,
                    }),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: controller.refreshOutputFiles,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text('export_refresh_list'.tr),
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
                      child: Center(
                        child: Text(
                          'export_no_files'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 14,
                          ),
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
            title: 'export_usage_title'.tr,
            child: Text(
              'export_usage_body'.tr,
              style: const TextStyle(
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
                Text(
                  fileName,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  path,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 6: 测试 ─────────────────────────────────────────────────────────────

  Widget _buildTestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            title: 'test_model_load_title'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labeledField(
                  'label_test_pth'.tr,
                  controller.testModelPathController,
                  hint: 'hint_test_pth'.tr,
                  onBrowse: controller.pickTestModelFile,
                  browseIcon: Icons.file_open,
                ),
                const SizedBox(height: 12),
                _labeledField(
                  'label_tokenizer'.tr,
                  controller.testTokenizerPathController,
                  hint: 'hint_tokenizer'.tr,
                  onBrowse: controller.pickTestTokenizerFile,
                  browseIcon: Icons.file_open,
                ),
                const SizedBox(height: 12),
                _labeledField(
                  'label_state_file'.tr,
                  controller.testStatePathController,
                  hint: 'hint_state_file'.tr,
                  onBrowse: controller.pickTestStateFile,
                  browseIcon: Icons.file_open,
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: controller.isRwkvLoading.value
                              ? null
                              : controller.loadRwkvTestModel,
                          icon: controller.isRwkvLoading.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.play_circle_outline),
                          label: Text(
                            controller.isRwkvLoading.value
                                ? 'btn_load_model_loading'.tr
                                : 'btn_load_model'.tr,
                          ),
                          style: _btnStyle(const Color(0xFF3B82F6)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: controller.clearRwkvChat,
                          icon: const Icon(Icons.clear_all),
                          label: Text('btn_clear_chat'.tr),
                          style: _btnStyle(const Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Text(
                    '${'test_status_prefix'.tr}${controller.rwkvStatus.value}',
                    style: const TextStyle(
                      color: Color(0xFFB0B5BC),
                      fontSize: 13,
                    ),
                  ),
                ),
                Obx(
                  () => controller.isRwkvLoading.value
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(
                            value: controller.rwkvLoadProgress.value > 0
                                ? controller.rwkvLoadProgress.value
                                : null,
                            backgroundColor: const Color(0xFF3A3F47),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF3B82F6),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: 'test_chat_title'.tr,
            child: Column(
              children: [
                Obx(
                  () => Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 260,
                      maxHeight: 420,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D21),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3A3F47)),
                    ),
                    child: controller.rwkvMessages.isEmpty
                        ? Center(
                            child: Text(
                              'test_chat_empty'.tr,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: controller.rwkvMessages.length,
                            itemBuilder: (context, index) {
                              final m = controller.rwkvMessages[index];
                              final isUser = m['role'] == 'user';
                              return Align(
                                alignment: isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  constraints: const BoxConstraints(
                                    maxWidth: 680,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? const Color(
                                            0xFF3B82F6,
                                          ).withValues(alpha: 0.2)
                                        : const Color(0xFF252830),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF3A3F47),
                                    ),
                                  ),
                                  child: Text(
                                    m['text'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.testPromptController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'test_prompt_hint'.tr,
                          hintStyle: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1A1D21),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF3A3F47),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                        onSubmitted: (_) => controller.sendRwkvPrompt(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Obx(
                      () => ElevatedButton.icon(
                        onPressed: controller.isRwkvGenerating.value
                            ? null
                            : controller.sendRwkvPrompt,
                        icon: controller.isRwkvGenerating.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          controller.isRwkvGenerating.value
                              ? 'test_generating'.tr
                              : 'test_send'.tr,
                        ),
                        style: _btnStyle(
                          const Color(0xFF22C55E),
                          compact: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(
                  () => _logBox(
                    controller.rwkvTestLog.value,
                    minHeight: 80,
                    placeholder: 'test_log_placeholder'.tr,
                  ),
                ),
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
      title: 'settings_system_base'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'settings_system_intro'.tr,
            style: const TextStyle(
              color: Color(0xFFB0B5BC),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final winget = controller.wingetInstalled.value;
            return _buildStatusRow(
              'winget_row_title'.tr,
              winget,
              description: 'winget_row_desc'.tr,
              onRetry: controller.detectWinget,
              whenMissing: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'winget_missing_intro'.tr,
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        controller.openUrl('https://aka.ms/getwinget'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text('winget_btn_install_page'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'winget_ps_hint'.tr,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
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
              'uv_row_title'.tr,
              uv,
              description: 'uv_row_desc'.tr,
              onRetry: controller.detectUv,
              whenMissing: ElevatedButton.icon(
                onPressed: controller.isUvInstalling.value
                    ? null
                    : controller.installUv,
                icon: controller.isUvInstalling.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(
                  controller.isUvInstalling.value
                      ? 'uv_installing'.tr
                      : 'uv_install_btn'.tr,
                ),
                style: _btnStyle(const Color(0xFF7C3AED), compact: true),
              ),
            );
          }),
          const SizedBox(height: 16),
          Obx(() {
            final nvidia = controller.nvidiaDriverInstalled.value;
            return _buildStatusRow(
              'nvidia_row_title'.tr,
              nvidia,
              description: 'nvidia_row_desc'.tr,
              onRetry: controller.detectNvidiaDriver,
              whenMissing: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => controller.openUrl(
                      'https://www.nvidia.com/Download/index.aspx',
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text('nvidia_btn_download'.tr),
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
                color: installed
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFFBBF24),
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
                  label: Text('btn_retry_detect'.tr),
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
      title: 'cuda_section_title'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cuda_section_desc'.tr,
            style: const TextStyle(
              color: Color(0xFFB0B5BC),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _labeledField(
            'cuda_dir_label'.tr,
            controller.cudaHomeController,
            hint: 'cuda_hint_dir'.tr,
            onBrowse: controller.pickCudaHomeDir,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: controller.detectCudaHome,
                icon: const Icon(Icons.search, size: 18),
                label: Text('btn_auto_detect'.tr),
                style: _btnStyle(const Color(0xFF3B82F6), compact: true),
              ),
              const SizedBox(width: 12),
              Obx(() {
                if (controller.cudaInstalled.value) {
                  return Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF22C55E),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            controller.cudaHome.value,
                            style: const TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: Text(
                      controller.isCudaInstalling.value
                          ? 'cuda_installing'.tr
                          : 'cuda_install_btn'.tr,
                    ),
                    style: _btnStyle(const Color(0xFF7C3AED), compact: true),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          Obx(
            () => _logBox(
              controller.cudaDetectLog.value,
              minHeight: 50,
              placeholder: 'cuda_log_placeholder'.tr,
            ),
          ),
          Obx(() {
            if (controller.cudaInstallLog.value.isEmpty)
              return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _logLabel('cuda_install_log_label'.tr),
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
      title: 'env_section_title'.tr,
      child: Obx(() {
        final ready = controller.envReady.value;
        final checking = controller.isChecking.value;
        final installing = controller.isInstalling.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 环境就绪状态栏 ──────────────────────────────────────
            if (checking)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'env_checking'.tr,
                      style: const TextStyle(color: Color(0xFFB0B5BC)),
                    ),
                  ],
                ),
              )
            else if (ready)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[400],
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'env_all_ready'.tr,
                        style: TextStyle(
                          color: Colors.green[400],
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: controller.checkEnvironment,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text('btn_retry_detect'.tr),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                      ),
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
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFBBF24),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'env_uv_missing_title'.tr,
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'env_uv_missing_desc'.tr,
                        style: const TextStyle(
                          color: Color(0xFFB0B5BC),
                          fontSize: 12,
                        ),
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
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: Text(
                            controller.isUvInstalling.value
                                ? 'uv_installing'.tr
                                : 'env_one_click_uv'.tr,
                          ),
                          style: _btnStyle(const Color(0xFF7C3AED)),
                        ),
                      ),
                      if (controller.uvInstallLog.value.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _logLabel('uv_install_log_title'.tr),
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
              Text(
                'env_deps_intro'.tr,
                style: const TextStyle(
                  color: Color(0xFFB0B5BC),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D21),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3A3F47)),
                ),
                child: SelectableText(
                  'env_deps_list'.tr,
                  style: const TextStyle(
                    color: Color(0xFF86EFAC),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: installing
                          ? null
                          : controller.installEnvironment,
                      icon: installing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.install_desktop),
                      label: Text(
                        installing
                            ? 'env_build_installing'.tr
                            : 'env_one_click_install'.tr,
                      ),
                      style: _btnStyle(const Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (installing || checking)
                          ? null
                          : controller.checkEnvironment,
                      icon: checking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_user),
                      label: Text(
                        checking
                            ? 'env_checking_btn'.tr
                            : 'env_check_env'.tr,
                      ),
                      style: _btnStyle(const Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ],
            // ── 检测结果日志（有问题时才显示）────────────────────────
            if (!ready) ...[
              const SizedBox(height: 16),
              _logLabel('env_detect_result'.tr),
              const SizedBox(height: 8),
              _logBox(
                controller.checkLog.value,
                placeholder: 'env_placeholder_checking'.tr,
              ),
            ],
            // ── 安装日志（有内容时才显示）────────────────────────────
            if (controller.installLog.value.isNotEmpty) ...[
              const SizedBox(height: 16),
              _logLabel('env_install_log'.tr),
              const SizedBox(height: 8),
              _logBox(
                controller.installLog.value,
                placeholder: 'env_placeholder_install'.tr,
              ),
            ],
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF3A3F47)),
            const SizedBox(height: 16),
            Text(
              'env_cuda_tools_title'.tr,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'env_cuda_tools_desc'.tr,
              style: const TextStyle(
                color: Color(0xFFB0B5BC),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            if (Platform.isWindows) ...[
              const SizedBox(height: 12),
              Obx(
                () => _buildStatusRow(
                  'env_ninja_title'.tr,
                  controller.ninjaOnPath.value,
                  description: 'env_ninja_desc'.tr,
                  onRetry: controller.detectBuildTools,
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => _buildStatusRow(
                  'env_msvc_title'.tr,
                  controller.msvcClOnPath.value,
                  description: 'env_msvc_desc'.tr,
                  onRetry: controller.detectBuildTools,
                ),
              ),
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
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          ready ? Icons.check_circle : Icons.build,
                          size: 20,
                        ),
                  label: Text(
                    installing
                        ? 'env_build_installing'.tr
                        : ready
                        ? 'env_build_installed'.tr
                        : 'env_build_install_btn'.tr,
                  ),
                  style: _btnStyle(
                    ready ? const Color(0xFF166534) : const Color(0xFF7C3AED),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            _logLabel('env_build_log_label'.tr),
            const SizedBox(height: 8),
            Obx(
              () => _logBox(
                controller.buildToolsLog.value,
                placeholder: 'env_build_log_placeholder'.tr,
              ),
            ),
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 13),
        ),
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
                  hintStyle: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1D21),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
                message: 'tooltip_browse'.tr,
                child: Material(
                  color: const Color(0xFF3A3F47),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onBrowse,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        browseIcon,
                        color: const Color(0xFFB0B5BC),
                        size: 20,
                      ),
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

  Widget _logBox(
    String text, {
    double minHeight = 140,
    String placeholder = '',
  }) {
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
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFB0B5BC),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
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
