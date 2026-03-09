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
          _buildTopBar(controller),
          _buildTabBar(controller),
          Expanded(
            child: Obx(() {
              if (controller.currentTabIndex.value == 5) {
                return _buildSettingsContent(controller);
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildModelConfig(controller)),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildRightPanel(controller)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildNextButton(controller),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(HomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF252830),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'State-Tuning Studio 一体训练工具',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Obx(
                () => Text(
                  'GPU: ${controller.gpuInfo.value}',
                  style: const TextStyle(
                    color: Color(0xFFB0B5BC),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Obx(
                () => Text(
                  '状态: ${controller.status.value}',
                  style: const TextStyle(
                    color: Color(0xFFB0B5BC),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFFB0B5BC)),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF3B82F6),
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(HomeController controller) {
    final tabs = ['模型', '数据', '训练', '监控', '导出', '设置'];
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        color: const Color(0xFF1A1D21),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = controller.currentTabIndex.value == index;
            return GestureDetector(
              onTap: () => controller.setTabIndex(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(HomeController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF252830),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3F47)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '环境配置',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '一键安装 RWKV-PEFT 训练所需依赖（参考 github.com/Joluck/RWKV-PEFT）\n'
              '包含: bitsandbytes, einops, peft, rwkv-fla, rwkv, transformers, lightning, datasets, jsonlines, wandb\n'
              '注: deepspeed、triton 不支持 Windows 已排除',
              style: TextStyle(
                color: Color(0xFFB0B5BC),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.isInstalling.value
                      ? null
                      : controller.installEnvironment,
                  icon: controller.isInstalling.value
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
                    controller.isInstalling.value ? '安装中...' : '一键安装配置环境',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '安装日志',
              style: TextStyle(
                color: Color(0xFFB0B5BC),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D21),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3A3F47)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SelectableText(
                    controller.installLog.value.isEmpty
                        ? '点击上方按钮开始安装...'
                        : controller.installLog.value,
                    style: const TextStyle(
                      color: Color(0xFFB0B5BC),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelConfig(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF252830),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3F47)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '模型配置',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => _buildModelDropdown(
              title: 'Teacher 模型 (未训练)',
              value: controller.teacherModel.value,
              items: controller.teacherModels,
              onChanged: controller.setTeacherModel,
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => _buildModelDropdown(
              title: 'Student 模型 (训练中)',
              value: controller.studentModel.value,
              items: controller.studentModels,
              onChanged: controller.setStudentModel,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '模型精度',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Row(
              children: [
                _buildRadioOption(controller, 'FP16', ModelPrecision.fp16),
                const SizedBox(width: 24),
                _buildRadioOption(controller, 'INT8', ModelPrecision.int8),
                const SizedBox(width: 24),
                _buildRadioOption(controller, 'Q4', ModelPrecision.q4),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                '最大上下文长度:',
                style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 14),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: controller.maxContextLengthController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1A1D21),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelDropdown({
    required String title,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D21),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A3F47)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF252830),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFFB0B5BC),
              ),
              items: items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (v) => v != null ? onChanged(v) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(
    HomeController controller,
    String label,
    ModelPrecision precision,
  ) {
    final isSelected = controller.modelPrecision.value == precision;
    return GestureDetector(
      onTap: () => controller.setModelPrecision(precision),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF6B7280),
                width: 2,
              ),
              color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFB0B5BC),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(HomeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '模式:',
              style: TextStyle(color: Color(0xFFB0B5BC), fontSize: 14),
            ),
            const SizedBox(width: 12),
            Obx(
              () => Row(
                children: [
                  _buildModeButton(controller, '推理模式', TrainingMode.inference),
                  const SizedBox(width: 8),
                  _buildModeButton(controller, '监督模式', TrainingMode.supervised),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.help_outline, size: 18, color: Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 20),
        Obx(
          () => _buildInfoCard('Teacher 模型信息', [
            '参数量: ${controller.teacherModelInfo.parameters}',
            '上下文: ${controller.teacherModelInfo.context}',
            '显存需求: ${controller.teacherModelInfo.vramRequired}GB',
          ]),
        ),
        const SizedBox(height: 16),
        Obx(
          () => _buildInfoCard('Student 模型信息', [
            '参数量: ${controller.studentModelInfo.parameters}',
            '显存需求: ${controller.studentModelInfo.vramRequired}GB',
            '量化缩减',
          ]),
        ),
        const SizedBox(height: 16),
        Obx(() => _buildVramCard(controller)),
      ],
    );
  }

  Widget _buildModeButton(
    HomeController controller,
    String label,
    TrainingMode mode,
  ) {
    final isSelected = controller.trainingMode.value == mode;
    return GestureDetector(
      onTap: () => controller.setTrainingMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A3F47) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : const Color(0xFF3A3F47),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFB0B5BC),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                item,
                style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVramCard(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252830),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3F47)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '显存占用估计',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Teacher: ${controller.teacherVramUsage} GB',
            style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Student: ${controller.studentVramUsage} GB',
            style: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 14),
          ),
          if (controller.isVramInsufficient) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '显存不足 建议用Q4量化',
                    style: TextStyle(color: Colors.amber, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextButton(HomeController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.goToDataPreparation,
        icon: const Icon(Icons.rocket_launch),
        label: const Text('下一步: 数据准备'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
