import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

/// 任务状态
enum DistillTaskStatus { pending, running, completed, failed, cancelled }

/// 语言比例 (zh/en/ja/ko/de/fr/es/ru 需总和 100)
class LanguageRatios {
  int zh;
  int en;
  int ja;
  int ko;
  int de;
  int fr;
  int es;
  int ru;

  LanguageRatios({
    this.zh = 70,
    this.en = 15,
    this.ja = 2,
    this.ko = 2,
    this.de = 3,
    this.fr = 3,
    this.es = 3,
    this.ru = 2,
  });

  int get sum => zh + en + ja + ko + de + fr + es + ru;
  Map<String, int> toMap() =>
      {'zh': zh, 'en': en, 'ja': ja, 'ko': ko, 'de': de, 'fr': fr, 'es': es, 'ru': ru};

  factory LanguageRatios.fromMap(Map<String, dynamic> m) => LanguageRatios(
        zh: (m['zh'] as num?)?.toInt() ?? 70,
        en: (m['en'] as num?)?.toInt() ?? 15,
        ja: (m['ja'] as num?)?.toInt() ?? 2,
        ko: (m['ko'] as num?)?.toInt() ?? 2,
        de: (m['de'] as num?)?.toInt() ?? 3,
        fr: (m['fr'] as num?)?.toInt() ?? 3,
        es: (m['es'] as num?)?.toInt() ?? 3,
        ru: (m['ru'] as num?)?.toInt() ?? 2,
      );

  Map<String, int> toJson() => toMap();
}

/// 工具级别比例 (L0-L4 需总和 100)
class LevelRatios {
  int l0;
  int l1;
  int l2;
  int l3;
  int l4;

  LevelRatios({
    this.l0 = 10,
    this.l1 = 15,
    this.l2 = 25,
    this.l3 = 25,
    this.l4 = 25,
  });

  int get sum => l0 + l1 + l2 + l3 + l4;
  Map<String, int> toMap() => {'l0': l0, 'l1': l1, 'l2': l2, 'l3': l3, 'l4': l4};

  factory LevelRatios.fromMap(Map<String, dynamic> m) => LevelRatios(
        l0: (m['l0'] as num?)?.toInt() ?? 10,
        l1: (m['l1'] as num?)?.toInt() ?? 15,
        l2: (m['l2'] as num?)?.toInt() ?? 25,
        l3: (m['l3'] as num?)?.toInt() ?? 25,
        l4: (m['l4'] as num?)?.toInt() ?? 25,
      );
}

/// 任务配置
class DistillTaskConfig {
  String generatorType;
  int count;
  double temperature;
  int concurrency;
  String? apiKey;
  String? providerId;
  LanguageRatios langRatios;
  LevelRatios levelRatios;
  List<String>? selectedTopics;

  DistillTaskConfig({
    this.generatorType = 'no_tool',
    this.count = 100,
    this.temperature = 0.7,
    this.concurrency = 4,
    this.apiKey,
    this.providerId,
    LanguageRatios? langRatios,
    LevelRatios? levelRatios,
    this.selectedTopics,
  })  : langRatios = langRatios ?? LanguageRatios(),
        levelRatios = levelRatios ?? LevelRatios();

  Map<String, dynamic> toJson() => {
        'generatorType': generatorType,
        'count': count,
        'temperature': temperature,
        'concurrency': concurrency,
        'apiKey': apiKey,
        'providerId': providerId,
        'langRatios': langRatios.toMap(),
        'levelRatios': levelRatios.toMap(),
        'selectedTopics': selectedTopics,
      };

  factory DistillTaskConfig.fromJson(Map<String, dynamic> j) => DistillTaskConfig(
        generatorType: j['generatorType'] as String? ?? 'no_tool',
        count: (j['count'] as num?)?.toInt() ?? 100,
        temperature: (j['temperature'] as num?)?.toDouble() ?? 0.7,
        concurrency: (j['concurrency'] as num?)?.toInt() ?? 4,
        apiKey: j['apiKey'] as String?,
        providerId: j['providerId'] as String?,
        langRatios: j['langRatios'] != null
            ? LanguageRatios.fromMap(Map<String, dynamic>.from(j['langRatios'] as Map))
            : null,
        levelRatios: j['levelRatios'] != null
            ? LevelRatios.fromMap(Map<String, dynamic>.from(j['levelRatios'] as Map))
            : null,
        selectedTopics: (j['selectedTopics'] as List?)?.cast<String>(),
      );
}

/// 任务统计
class DistillTaskStats {
  int recordsGenerated;
  int recordsFailed;
  double currentSpeed;
  int estimatedRemaining;
  String? startTime;
  String? endTime;

  DistillTaskStats({
    this.recordsGenerated = 0,
    this.recordsFailed = 0,
    this.currentSpeed = 0,
    this.estimatedRemaining = 0,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() => {
        'recordsGenerated': recordsGenerated,
        'recordsFailed': recordsFailed,
        'currentSpeed': currentSpeed,
        'estimatedRemaining': estimatedRemaining,
        'startTime': startTime,
        'endTime': endTime,
      };

  factory DistillTaskStats.fromJson(Map<String, dynamic> j) => DistillTaskStats(
        recordsGenerated: (j['recordsGenerated'] as num?)?.toInt() ?? 0,
        recordsFailed: (j['recordsFailed'] as num?)?.toInt() ?? 0,
        currentSpeed: (j['currentSpeed'] as num?)?.toDouble() ?? 0,
        estimatedRemaining: (j['estimatedRemaining'] as num?)?.toInt() ?? 0,
        startTime: j['startTime'] as String?,
        endTime: j['endTime'] as String?,
      );
}

/// 蒸馏任务
class DistillTask {
  String id;
  String name;
  DistillTaskStatus status;
  DistillTaskConfig config;
  DistillTaskStats stats;
  String createdAt;
  String updatedAt;
  String dataFile;
  String exportStatus;
  String? errorMessage;

  DistillTask({
    required this.id,
    required this.name,
    required this.status,
    required this.config,
    required this.stats,
    required this.createdAt,
    required this.updatedAt,
    required this.dataFile,
    this.exportStatus = 'not_exported',
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.name,
        'config': config.toJson(),
        'stats': stats.toJson(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'dataFile': dataFile,
        'exportStatus': exportStatus,
        'errorMessage': errorMessage,
      };

  factory DistillTask.fromJson(Map<String, dynamic> j) => DistillTask(
        id: j['id'] as String,
        name: j['name'] as String,
        status: DistillTaskStatus.values.byName((j['status'] as String?) ?? 'pending'),
        config: DistillTaskConfig.fromJson(Map<String, dynamic>.from((j['config'] ?? {}) as Map)),
        stats: DistillTaskStats.fromJson(Map<String, dynamic>.from((j['stats'] ?? {}) as Map)),
        createdAt: j['createdAt'] as String? ?? '',
        updatedAt: j['updatedAt'] as String? ?? '',
        dataFile: j['dataFile'] as String? ?? '',
        exportStatus: j['exportStatus'] as String? ?? 'not_exported',
        errorMessage: j['errorMessage'] as String?,
      );
}

/// LLM 服务商
class LLMProvider {
  String id;
  String name;
  String type;
  String apiBaseUrl;
  String apiKey;
  String model;
  String? modelsList;
  int maxTokens;

  LLMProvider({
    required this.id,
    required this.name,
    this.type = 'custom',
    this.apiBaseUrl = '',
    this.apiKey = '',
    this.model = '',
    this.modelsList,
    this.maxTokens = 4096,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'apiBaseUrl': apiBaseUrl,
        'apiKey': apiKey,
        'model': model,
        'modelsList': modelsList,
        'maxTokens': maxTokens,
      };

  factory LLMProvider.fromJson(Map<String, dynamic> j) => LLMProvider(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        type: j['type'] as String? ?? 'custom',
        apiBaseUrl: j['apiBaseUrl'] as String? ?? '',
        apiKey: j['apiKey'] as String? ?? '',
        model: j['model'] as String? ?? '',
        modelsList: j['modelsList'] as String?,
        maxTokens: (j['maxTokens'] as num?)?.toInt() ?? 4096,
      );
}

/// 生成器
class DistillGenerator {
  String id;
  String name;
  String description;
  bool enabled;

  DistillGenerator({
    required this.id,
    required this.name,
    this.description = '',
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'enabled': enabled};

  factory DistillGenerator.fromJson(Map<String, dynamic> j) => DistillGenerator(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        enabled: j['enabled'] as bool? ?? true,
      );
}

/// 导出记录
class ExportRecord {
  String id;
  String exportedAt;
  List<String> taskIds;
  String formatType;
  String outputFile;
  int recordsCount;

  ExportRecord({
    required this.id,
    required this.exportedAt,
    required this.taskIds,
    required this.formatType,
    required this.outputFile,
    required this.recordsCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'exportedAt': exportedAt,
        'taskIds': taskIds,
        'formatType': formatType,
        'outputFile': outputFile,
        'recordsCount': recordsCount,
      };

  factory ExportRecord.fromJson(Map<String, dynamic> j) => ExportRecord(
        id: j['id'] as String? ?? '',
        exportedAt: j['exportedAt'] as String? ?? '',
        taskIds: ((j['taskIds'] as List?) ?? []).map((e) => e.toString()).toList(),
        formatType: j['formatType'] as String? ?? 'multi_turn',
        outputFile: j['outputFile'] as String? ?? '',
        recordsCount: (j['recordsCount'] as num?)?.toInt() ?? 0,
      );
}

class DistillationController extends GetxController {
  // --- 任务 ---
  final distillTasks = <DistillTask>[].obs;
  final distillLog = ''.obs;
  String? _runningTaskId;
  bool _cancelRequested = false;
  final Random _random = Random();

  // --- 创建任务表单 ---
  late final TextEditingController taskNameController;
  late final TextEditingController taskCountController;
  late final TextEditingController taskConcurrencyController;
  late final TextEditingController taskApiKeyController;
  final llmNameController = TextEditingController();
  final llmUrlController = TextEditingController();
  final llmKeyController = TextEditingController();
  final llmModelController = TextEditingController();
  final llmModelsController = TextEditingController();
  final llmTokensController = TextEditingController(text: '4096');
  final taskGeneratorType = 'no_tool'.obs;
  final taskCount = 100.obs;
  final taskTemperature = 0.7.obs;
  final taskConcurrency = 4.obs;
  final taskApiKey = ''.obs;
  final taskProviderId = ''.obs;
  final taskLangRatios = LanguageRatios().obs;
  final taskLevelRatios = LevelRatios().obs;
  final taskSelectedTopics = <String>[].obs;

  // --- 生成器 ---
  final generators = <DistillGenerator>[
    DistillGenerator(id: 'no_tool', name: '无工具对话', description: '生成纯对话数据，无需工具调用'),
    DistillGenerator(id: 'tool', name: '工具调用', description: '生成需要工具调用的对话数据，支持 L0-L4'),
  ].obs;

  // --- LLM 服务商 ---
  final llmProviders = <LLMProvider>[].obs;

  // --- 导出 ---
  final exportSelectedTaskIds = <String>[].obs;
  final exportFormat = 'multi_turn'.obs;
  final exportShuffle = true.obs;
  final exportMergeByType = false.obs;
  final exportHistory = <ExportRecord>[].obs;

  // --- 话题 (默认列表，可从 chat_topics 加载) ---
  final availableTopics = <String>[
    '日常生活', '科技互联网', '娱乐休闲', '学习教育', '健康养生',
    '金融理财', '旅游出行', '美食烹饪', '体育运动', '文化艺术',
  ].obs;

  static String _taskId() =>
      'task_${DateTime.now().toIso8601String().replaceAll(':', '').split('.').first}_${DateTime.now().microsecondsSinceEpoch.remainder(1000000)}';

  String? _dataDir;

  Future<String> _getDataDir() async {
    if (_dataDir != null) return _dataDir!;
    final dir = await getApplicationSupportDirectory();
    _dataDir = '${dir.path}${Platform.pathSeparator}statetuning_distill';
    await Directory(_dataDir!).create(recursive: true);
    return _dataDir!;
  }

  Future<File> _tasksFile() async {
    final d = await _getDataDir();
    return File('$d${Platform.pathSeparator}tasks.json');
  }

  Future<File> _providersFile() async {
    final d = await _getDataDir();
    return File('$d${Platform.pathSeparator}llm_providers.json');
  }

  Future<File> _exportHistoryFile() async {
    final d = await _getDataDir();
    return File('$d${Platform.pathSeparator}export_history.json');
  }

  @override
  void onInit() {
    super.onInit();
    taskNameController = TextEditingController();
    taskCountController = TextEditingController(text: '100');
    taskConcurrencyController = TextEditingController(text: '4');
    taskApiKeyController = TextEditingController();
    _loadTasks();
    _loadProviders();
    _loadExportHistory();
  }

  @override
  void onClose() {
    taskNameController.dispose();
    taskCountController.dispose();
    taskConcurrencyController.dispose();
    taskApiKeyController.dispose();
    llmNameController.dispose();
    llmUrlController.dispose();
    llmKeyController.dispose();
    llmModelController.dispose();
    llmModelsController.dispose();
    llmTokensController.dispose();
    super.onClose();
  }

  Future<void> _loadTasks() async {
    try {
      final f = await _tasksFile();
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        distillTasks.value = list.map((e) => DistillTask.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveTasks() async {
    try {
      final f = await _tasksFile();
      await f.writeAsString(jsonEncode(distillTasks.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _loadProviders() async {
    try {
      final f = await _providersFile();
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        llmProviders.value = list.map((e) => LLMProvider.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveProviders() async {
    try {
      final f = await _providersFile();
      await f.writeAsString(jsonEncode(llmProviders.map((p) => p.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _loadExportHistory() async {
    try {
      final f = await _exportHistoryFile();
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        exportHistory.value =
            list.map((e) => ExportRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveExportHistory() async {
    try {
      final f = await _exportHistoryFile();
      await f.writeAsString(jsonEncode(exportHistory.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  void _appendLog(String message) {
    final next = '${distillLog.value}[${DateTime.now().toIso8601String()}] $message\n';
    final lines = const LineSplitter().convert(next);
    distillLog.value = lines.length > 400
        ? '${lines.sublist(lines.length - 400).join('\n')}\n'
        : next;
  }

  LLMProvider? _resolveProvider(DistillTaskConfig config) {
    if (config.providerId == null || config.providerId!.isEmpty) {
      return null;
    }
    for (final provider in llmProviders) {
      if (provider.id == config.providerId) {
        return provider;
      }
    }
    return null;
  }

  String _weightedPick(Map<String, int> weights) {
    final total = weights.values.fold<int>(0, (sum, value) => sum + value);
    if (total <= 0) return weights.keys.first;
    var point = _random.nextInt(total);
    for (final entry in weights.entries) {
      point -= entry.value;
      if (point < 0) return entry.key;
    }
    return weights.keys.first;
  }

  String _pickLanguage(LanguageRatios ratios) {
    return _weightedPick(ratios.toMap());
  }

  String _pickTopic(DistillTask task) {
    final topics = (task.config.selectedTopics != null && task.config.selectedTopics!.isNotEmpty)
        ? task.config.selectedTopics!
        : availableTopics;
    return topics[_random.nextInt(topics.length)];
  }

  String _languageName(String code) {
    const names = {
      'zh': '中文',
      'en': 'English',
      'ja': '日本語',
      'ko': '한국어',
      'de': 'Deutsch',
      'fr': 'Français',
      'es': 'Español',
      'ru': 'Русский',
    };
    return names[code] ?? code;
  }

  List<Map<String, String>> _buildLocalTurns({
    required String language,
    required String topic,
    required bool toolMode,
    required int index,
  }) {
    final langName = _languageName(language);
    final user = '$langName 用户请你聊聊「$topic」这个话题，并给出一个实用建议。';
    final assistant = toolMode
        ? '当然可以。关于 $topic，我会先整理需求，再给出一个可执行的方案，并说明如果要调用工具通常会检查哪些信息。'
        : '当然可以。关于 $topic，这里有一个简洁、自然、适合训练用的回答示例，并附带一个可执行的小建议。';
    final extraUser = '如果我是初学者，应该先从哪一步开始？';
    final extraAssistant = '建议先从最基础的一步开始，设定一个很小但能坚持的目标，然后逐步扩展。';

    if (!toolMode) {
      return [
        {'role': 'user', 'say': user},
        {'role': 'assistant', 'respond': '$assistant (样本 ${index + 1})'},
      ];
    }

    return [
      {'role': 'user', 'say': user},
      {'role': 'assistant', 'respond': assistant},
      {'role': 'user', 'say': extraUser},
      {'role': 'assistant', 'respond': '$extraAssistant (样本 ${index + 1})'},
    ];
  }

  Future<Map<String, dynamic>> _generateProviderRecord(
    DistillTask task,
    int index,
    String language,
    String topic,
  ) async {
    final provider = _resolveProvider(task.config);
    final apiKey = provider?.apiKey ?? task.config.apiKey;
    final baseUrl = provider?.apiBaseUrl ?? '';
    final model = provider?.model ?? '';

    if (apiKey == null || apiKey.isEmpty || baseUrl.isEmpty || model.isEmpty) {
      throw StateError('未配置可用的 LLM 服务商');
    }

    final toolMode = task.config.generatorType == 'tool';
    final uri = Uri.parse(baseUrl.endsWith('/chat/completions')
        ? baseUrl
        : '${baseUrl.replaceAll(RegExp(r'/$'), '')}/chat/completions');

    final prompt = toolMode
        ? '请生成一段适合 RWKV 微调用的多轮对话数据，语言为 ${_languageName(language)}，主题为 $topic。'
            '返回严格 JSON：{"turns":[{"role":"user","say":"..."},{"role":"assistant","respond":"..."},'
            '{"role":"user","say":"..."},{"role":"assistant","respond":"..."}]}。'
        : '请生成一段适合 RWKV 微调用的单轮问答数据，语言为 ${_languageName(language)}，主题为 $topic。'
            '返回严格 JSON：{"turns":[{"role":"user","say":"..."},{"role":"assistant","respond":"..."}]}。';

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      request.write(jsonEncode({
        'model': model,
        'temperature': task.config.temperature,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content': '你是训练数据生成器。只输出合法 JSON，不要输出解释文字。',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
      }));

      final response = await request.close().timeout(const Duration(seconds: 90));
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}: $responseBody');
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = (json['choices'] as List?) ?? const [];
      if (choices.isEmpty) {
        throw const FormatException('LLM 返回为空');
      }

      final message = Map<String, dynamic>.from((choices.first as Map)['message'] as Map);
      final content = (message['content'] ?? '').toString().trim();
      final parsed = _tryParseEmbeddedJson(content);
      final turnsRaw = parsed['turns'];
      if (turnsRaw is! List) {
        throw const FormatException('返回 JSON 不包含 turns');
      }

      final turns = turnsRaw
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map((item) {
            final role = (item['role'] ?? '').toString();
            if (role == 'assistant') {
              return {
                'role': 'assistant',
                'respond': (item['respond'] ?? item['content'] ?? '').toString(),
              };
            }
            return {
              'role': 'user',
              'say': (item['say'] ?? item['content'] ?? '').toString(),
            };
          })
          .toList();

      return {
        'id': '${task.id}_$index',
        'generator_type': task.config.generatorType,
        'language': language,
        'topic': topic,
        'turns': turns,
      };
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic> _tryParseEmbeddedJson(String content) {
    try {
      return Map<String, dynamic>.from(jsonDecode(content) as Map);
    } catch (_) {
      final start = content.indexOf('{');
      final end = content.lastIndexOf('}');
      if (start >= 0 && end > start) {
        return Map<String, dynamic>.from(
          jsonDecode(content.substring(start, end + 1)) as Map,
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _generateTaskRecord(DistillTask task, int index) async {
    final language = _pickLanguage(task.config.langRatios);
    final topic = _pickTopic(task);
    try {
      final provider = _resolveProvider(task.config);
      if (provider != null || (task.config.apiKey?.isNotEmpty ?? false)) {
        return await _generateProviderRecord(task, index, language, topic);
      }
    } catch (e) {
      _appendLog('LLM 生成失败，回退到本地样例: $e');
    }

    return {
      'id': '${task.id}_$index',
      'generator_type': task.config.generatorType,
      'language': language,
      'topic': topic,
      'turns': _buildLocalTurns(
        language: language,
        topic: topic,
        toolMode: task.config.generatorType == 'tool',
        index: index,
      ),
    };
  }

  Future<void> _appendTaskRecord(DistillTask task, Map<String, dynamic> record) async {
    final file = File(task.dataFile);
    await file.parent.create(recursive: true);
    final sink = file.openWrite(mode: FileMode.append);
    sink.writeln(jsonEncode(record));
    await sink.flush();
    await sink.close();
  }

  String _extractAssistantText(Map<String, dynamic> turn) {
    return (turn['respond'] ?? turn['say'] ?? turn['content'] ?? '').toString().trim();
  }

  String _extractUserText(Map<String, dynamic> turn) {
    return (turn['say'] ?? turn['content'] ?? turn['respond'] ?? '').toString().trim();
  }

  String _fixRwkvText(String text) {
    final trimmed = text.trimRight();
    if (trimmed.endsWith('\n\n# User')) return '$trimmed\n\n';
    if (trimmed.endsWith('\n\n# User\n\n')) return trimmed;
    return '$trimmed\n\n# User\n\n';
  }

  Map<String, String>? _convertRecordToRwkv(
    Map<String, dynamic> record,
    String formatType,
  ) {
    final turnsRaw = record['turns'];
    final turns = turnsRaw is List
        ? turnsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    if (turns.isEmpty) return null;

    if (formatType == 'single_turn') {
      final user = turns.firstWhere(
        (t) => (t['role'] ?? '').toString() == 'user',
        orElse: () => const {},
      );
      final assistant = turns.firstWhere(
        (t) => (t['role'] ?? '').toString() == 'assistant',
        orElse: () => const {},
      );
      if (user.isEmpty || assistant.isEmpty) return null;
      return {
        'text': _fixRwkvText(
          'User: ${_extractUserText(user)}\n\nAssistant: ${_extractAssistantText(assistant)}',
        ),
      };
    }

    if (formatType == 'instruction') {
      final user = turns.firstWhere(
        (t) => (t['role'] ?? '').toString() == 'user',
        orElse: () => const {},
      );
      final assistant = turns.firstWhere(
        (t) => (t['role'] ?? '').toString() == 'assistant',
        orElse: () => const {},
      );
      if (user.isEmpty || assistant.isEmpty) return null;
      return {
        'text': _fixRwkvText(
          'Instruction: 请根据输入生成回答\n\n'
          'Input: ${_extractUserText(user)}\n\n'
          'Response: ${_extractAssistantText(assistant)}',
        ),
      };
    }

    final parts = <String>[];
    for (final turn in turns) {
      final role = (turn['role'] ?? '').toString();
      if (role == 'assistant') {
        final text = _extractAssistantText(turn);
        if (text.isNotEmpty) parts.add('Assistant: $text');
      } else {
        final text = _extractUserText(turn);
        if (text.isNotEmpty) parts.add('User: $text');
      }
    }
    if (parts.isEmpty) return null;
    return {'text': _fixRwkvText(parts.join('\n\n'))};
  }

  Future<List<Map<String, dynamic>>> _readTaskRecords(List<String> taskIds) async {
    final records = <Map<String, dynamic>>[];
    for (final taskId in taskIds) {
      final task = distillTasks.firstWhereOrNull((t) => t.id == taskId);
      if (task == null) continue;
      final file = File(task.dataFile);
      if (!await file.exists()) continue;
      final lines = await file.readAsLines();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        try {
          records.add(Map<String, dynamic>.from(jsonDecode(trimmed) as Map));
        } catch (_) {}
      }
    }
    return records;
  }

  String? validateCreateTask() {
    final name = taskNameController.text.trim();
    if (name.isEmpty) return '请输入任务名称';
    if (distillTasks.any((t) => t.name == name)) return '任务名称已存在';
    if (taskLangRatios.value.sum != 100) return '语言比例总和必须为 100% (当前 ${taskLangRatios.value.sum}%)';
    if (taskGeneratorType.value == 'tool' && taskLevelRatios.value.sum != 100) {
      return '级别比例总和必须为 100% (当前 ${taskLevelRatios.value.sum}%)';
    }
    if (taskCount.value < 1) return '生成数量至少为 1';
    return null;
  }

  Future<void> createTask() async {
    final err = validateCreateTask();
    if (err != null) {
      Get.snackbar('校验失败', err);
      return;
    }
    final dir = await _getDataDir();
    final id = _taskId();
    final dataFile = '$dir${Platform.pathSeparator}tasks${Platform.pathSeparator}$id.jsonl';
    await Directory(File(dataFile).parent.path).create(recursive: true);

    final now = DateTime.now().toIso8601String();
    final task = DistillTask(
      id: id,
      name: taskNameController.text.trim(),
      status: DistillTaskStatus.pending,
      config: DistillTaskConfig(
        generatorType: taskGeneratorType.value,
        count: int.tryParse(taskCountController.text) ?? 100,
        temperature: taskTemperature.value,
        concurrency: int.tryParse(taskConcurrencyController.text) ?? 4,
        apiKey: taskApiKeyController.text.isEmpty ? null : taskApiKeyController.text,
        providerId: taskProviderId.value.isEmpty ? null : taskProviderId.value,
        langRatios: taskLangRatios.value,
        levelRatios: taskLevelRatios.value,
        selectedTopics: taskSelectedTopics.isEmpty ? null : List.from(taskSelectedTopics),
      ),
      stats: DistillTaskStats(),
      createdAt: now,
      updatedAt: now,
      dataFile: dataFile,
    );
    distillTasks.insert(0, task);
    await _saveTasks();
    Get.snackbar('成功', '任务「${task.name}」已创建');
  }

  Future<void> runTask(String taskId) async {
    final list = distillTasks.where((x) => x.id == taskId).toList();
    if (list.isEmpty) return;
    final t = list.first;
    if (t.status != DistillTaskStatus.pending) return;
    if (_runningTaskId != null) {
      Get.snackbar('提示', '当前已有任务运行中，请先等待完成或取消');
      return;
    }

    t.status = DistillTaskStatus.running;
    t.stats.startTime = DateTime.now().toIso8601String();
    t.stats.endTime = null;
    _runningTaskId = taskId;
    _cancelRequested = false;
    _appendLog('开始任务: ${t.name}');
    await _saveTasks();
    unawaited(_processTask(taskId));
  }

  Future<void> _processTask(String taskId) async {
    final task = distillTasks.firstWhereOrNull((x) => x.id == taskId);
    if (task == null) return;
    final startedAt = DateTime.now();

    try {
      while (!_cancelRequested && task.stats.recordsGenerated < task.config.count) {
        final record = await _generateTaskRecord(task, task.stats.recordsGenerated);
        await _appendTaskRecord(task, record);
        task.stats.recordsGenerated += 1;
        final elapsedSeconds = max(1, DateTime.now().difference(startedAt).inSeconds);
        task.stats.currentSpeed = task.stats.recordsGenerated / elapsedSeconds * 60;
        final remaining = max(0, task.config.count - task.stats.recordsGenerated);
        task.stats.estimatedRemaining = task.stats.currentSpeed > 0
            ? (remaining / task.stats.currentSpeed * 60).round()
            : 0;
        task.updatedAt = DateTime.now().toIso8601String();

        if (task.stats.recordsGenerated % 10 == 0 ||
            task.stats.recordsGenerated == task.config.count) {
          _appendLog(
            '任务 ${task.name}: ${task.stats.recordsGenerated}/${task.config.count} '
            '(${task.stats.currentSpeed.toStringAsFixed(1)} 条/分钟)',
          );
        }
        await _saveTasks();
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }

      if (_cancelRequested) {
        task.status = DistillTaskStatus.cancelled;
        _appendLog('任务已取消: ${task.name}');
      } else {
        task.status = DistillTaskStatus.completed;
        task.stats.endTime = DateTime.now().toIso8601String();
        _appendLog('任务完成: ${task.name}');
      }
      task.updatedAt = DateTime.now().toIso8601String();
      await _saveTasks();
    } catch (e) {
      task.status = DistillTaskStatus.failed;
      task.errorMessage = e.toString();
      task.updatedAt = DateTime.now().toIso8601String();
      _appendLog('任务失败: ${task.name} - $e');
      await _saveTasks();
      Get.snackbar('任务失败', e.toString());
    } finally {
      _cancelRequested = false;
      _runningTaskId = null;
    }
  }

  Future<void> cancelTask(String taskId) async {
    final list = distillTasks.where((x) => x.id == taskId).toList();
    if (list.isEmpty) return;
    final t = list.first;
    if (t.status == DistillTaskStatus.running) {
      _cancelRequested = true;
      Get.snackbar('已取消', '任务 ${t.name} 正在停止');
      return;
    }
    t.status = DistillTaskStatus.cancelled;
    t.updatedAt = DateTime.now().toIso8601String();
    _appendLog('任务已取消: ${t.name}');
    await _saveTasks();
    Get.snackbar('已取消', '任务 ${t.name} 已取消');
  }

  Future<void> deleteTask(String taskId) async {
    final list = distillTasks.where((x) => x.id == taskId).toList();
    if (list.isEmpty) return;
    final t = list.first;
    if (t.status == DistillTaskStatus.running) {
      Get.snackbar('提示', '请先取消运行中的任务');
      return;
    }
    distillTasks.removeWhere((x) => x.id == taskId);
    try {
      if (await File(t.dataFile).exists()) await File(t.dataFile).delete();
    } catch (_) {}
    await _saveTasks();
    Get.snackbar('已删除', '任务已删除');
  }

  List<DistillTask> get completedTasks => distillTasks.where((t) => t.status == DistillTaskStatus.completed).toList();

  void setTaskGeneratorType(String v) => taskGeneratorType.value = v;

  void setTaskTemperature(double v) => taskTemperature.value = v;

  void setTaskProviderId(String v) => taskProviderId.value = v;

  void setLangRatio(String key, int value) {
    final r = taskLangRatios.value;
    switch (key) {
      case 'zh':
        r.zh = value;
        break;
      case 'en':
        r.en = value;
        break;
      case 'ja':
        r.ja = value;
        break;
      case 'ko':
        r.ko = value;
        break;
      case 'de':
        r.de = value;
        break;
      case 'fr':
        r.fr = value;
        break;
      case 'es':
        r.es = value;
        break;
      case 'ru':
        r.ru = value;
        break;
    }
    taskLangRatios.refresh();
  }

  void setLevelRatio(String key, int value) {
    final r = taskLevelRatios.value;
    switch (key) {
      case 'l0':
        r.l0 = value;
        break;
      case 'l1':
        r.l1 = value;
        break;
      case 'l2':
        r.l2 = value;
        break;
      case 'l3':
        r.l3 = value;
        break;
      case 'l4':
        r.l4 = value;
        break;
    }
    taskLevelRatios.refresh();
  }

  void toggleTopic(String topic) {
    if (taskSelectedTopics.contains(topic)) {
      taskSelectedTopics.remove(topic);
    } else {
      taskSelectedTopics.add(topic);
    }
  }

  void selectAllTopics() => taskSelectedTopics.assignAll(availableTopics);

  void clearTopics() => taskSelectedTopics.clear();

  // --- 统计 ---
  int get totalTasks => distillTasks.length;

  int get totalRecords => distillTasks.fold(0, (s, t) => s + t.stats.recordsGenerated);

  int get runningCount => distillTasks.where((t) => t.status == DistillTaskStatus.running).length;

  int get completedCount => distillTasks.where((t) => t.status == DistillTaskStatus.completed).length;

  // --- 导出 ---
  void toggleExportTask(String id) {
    if (exportSelectedTaskIds.contains(id)) {
      exportSelectedTaskIds.remove(id);
    } else {
      exportSelectedTaskIds.add(id);
    }
  }

  Future<void> exportRwkv() async {
    if (exportSelectedTaskIds.isEmpty) {
      Get.snackbar('提示', '请至少选择一个任务');
      return;
    }
    final dir = await _getDataDir();
    final outDir = '$dir${Platform.pathSeparator}export';
    await Directory(outDir).create(recursive: true);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final sourceRecords = await _readTaskRecords(exportSelectedTaskIds);
    if (sourceRecords.isEmpty) {
      Get.snackbar('提示', '选中的任务没有可导出的数据');
      return;
    }

    final converted = <Map<String, String>>[];
    final seenTexts = <String>{};
    for (final record in sourceRecords) {
      final rwkv = _convertRecordToRwkv(record, exportFormat.value);
      if (rwkv == null) continue;
      final text = rwkv['text'] ?? '';
      if (text.isEmpty || !seenTexts.add(text)) continue;
      converted.add(rwkv);
    }

    if (converted.isEmpty) {
      Get.snackbar('提示', '没有可转换的 RWKV 记录');
      return;
    }

    if (exportShuffle.value) {
      converted.shuffle(_random);
    }

    final outFile = '$outDir${Platform.pathSeparator}export_$ts.jsonl';
    final sink = File(outFile).openWrite();
    for (final item in converted) {
      sink.writeln(jsonEncode(item));
    }
    await sink.flush();
    await sink.close();

    final record = ExportRecord(
      id: 'exp_$ts',
      exportedAt: DateTime.now().toIso8601String(),
      taskIds: List.from(exportSelectedTaskIds),
      formatType: exportFormat.value,
      outputFile: outFile,
      recordsCount: converted.length,
    );
    exportHistory.insert(0, record);
    for (final tid in exportSelectedTaskIds) {
      final t = distillTasks.firstWhereOrNull((x) => x.id == tid);
      if (t != null) t.exportStatus = 'exported';
    }
    exportSelectedTaskIds.clear();
    await _saveTasks();
    await _saveExportHistory();
    _appendLog('RWKV 导出完成: $outFile (${converted.length} 条)');
    Get.snackbar('导出完成', '已导出 ${converted.length} 条到 $outFile');
  }

  Future<void> exportBinidx() async {
    Get.snackbar('暂未实现', 'BINIDX 需要接入 json2binidx 工具，当前已实现 RWKV JSONL 导出');
  }

  // --- LLM 服务商 ---
  void addLLMProvider(LLMProvider p) {
    llmProviders.removeWhere((item) => item.id == p.id || item.name == p.name);
    llmProviders.add(p);
    _saveProviders();
  }

  void updateLLMProvider(int idx, LLMProvider p) {
    if (idx >= 0 && idx < llmProviders.length) {
      llmProviders[idx] = p;
      _saveProviders();
    }
  }

  void removeLLMProvider(String id) {
    llmProviders.removeWhere((p) => p.id == id);
    _saveProviders();
  }
}
