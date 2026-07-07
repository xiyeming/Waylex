import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import '../../data/models/translation_result.dart';
import '../../data/models/prompt_template.dart';
import '../../data/models/provider_config.dart';
import '../../data/datasources/ffi_datasource.dart';
import '../services/hotkey_service.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/result_card.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/foundation/app_card.dart';
import '../widgets/foundation/app_toggle.dart';
import '../widgets/foundation/app_input.dart';
import '../widgets/foundation/app_button.dart';
import '../widgets/common/app_divider.dart';
import '../widgets/common/app_dropdown.dart';
import '../widgets/common/app_chip.dart';

class FloatingPage extends ConsumerStatefulWidget {
  const FloatingPage({super.key});

  @override
  ConsumerState<FloatingPage> createState() => _FloatingPageState();
}

class _FloatingPageState extends ConsumerState<FloatingPage> {
  static const _defaultProviders = <String, String>{
    'openai': 'OpenAI',
    'deepl': 'DeepL',
    'google': 'Google',
    'qwen': 'Qwen',
    'deepseek': 'DeepSeek',
    'kimi': 'Kimi',
    'glm': 'GLM',
    'anthropic': 'Anthropic',
    'azure': 'Azure',
    'custom': 'Custom',
  };

  final _textController = TextEditingController();
  String _sourceLang = 'auto';
  String _targetLang = 'zh';
  final _results = <String, TranslationResult>{};
  bool _isTranslating = false;
  bool _providerPanelOpen = false;
  String? _activePromptId;
  String? _activePromptContent;

  static const _languages = <String, String>{
    'auto': '自动检测',
    'zh': '中文',
    'en': '英语',
    'ja': '日语',
    'ko': '韩语',
    'fr': '法语',
    'de': '德语',
    'es': '西班牙语',
    'ru': '俄语',
    'pt': '葡萄牙语',
  };

  Map<String, String> _providers = Map.of(_defaultProviders);
  final _selectedProviders = <String>{};
  List<ProviderConfig> _savedProviders = [];
  List<PromptTemplate> _promptTemplates = [];
  bool _isLoading = true;
  bool _isOcrProcessing = false;
  final _lastHotkeyTime = <String, DateTime>{};
  StreamSubscription<String>? _hotkeySubscription;

  final _ffi = FfiDatasource();

  @override
  void initState() {
    super.initState();
    _loadAll();
    _listenHotkeys();
  }

  void _listenHotkeys() {
    _hotkeySubscription?.cancel();
    _hotkeySubscription = HotkeyService().hotkeyStream.listen((action) async {
      if (!mounted) {
        debugPrint('[hotkey][page] event SKIP (not mounted): $action');
        return;
      }
      final now = DateTime.now();
      final last = _lastHotkeyTime[action];
      if (last != null && now.difference(last).inMilliseconds < 500) {
        debugPrint('[hotkey][page] event DROP (rate limit 500ms): $action');
        return;
      }
      _lastHotkeyTime[action] = now;
      debugPrint('[hotkey][page] event ACCEPT: $action');

      if (action == 'translate_selected') {
        debugPrint('[hotkey][page] -> translate_selected');
        await _handleTranslateSelected();
      } else if (action == 'toggle_window') {
        debugPrint('[hotkey][page] -> toggle_window');
        final visible = await windowManager.isVisible();
        if (visible) {
          debugPrint('[hotkey][page] -> toggle_window: hiding');
          await windowManager.hide();
        } else {
          debugPrint('[hotkey][page] -> toggle_window: showing');
          await windowManager.show();
          await windowManager.focus();
        }
      } else if (action == 'ocr_screenshot') {
        debugPrint('[hotkey][page] -> ocr_screenshot');
        await _handleOcrScreenshot();
      } else {
        debugPrint('[hotkey][page] -> UNKNOWN action: $action');
      }
    });
  }

  Future<void> _handleTranslateSelected() async {
    try {
      final clip = await _ffi.getClipboardText();
      if (!mounted || clip.isEmpty) return;
      await windowManager.show();
      await windowManager.focus();
      _textController.text = clip;
      setState(() {
        _results.clear();
      });
      await _translate();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取剪贴板内容失败: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _handleOcrScreenshot() async {
    if (_isOcrProcessing) return;
    setState(() => _isOcrProcessing = true);
    try {
      await windowManager.show();
      await windowManager.focus();
      final text = await _ffi.ocrScreenshot();
      if (!mounted) return;
      if (text.isNotEmpty) {
        _textController.text = text;
        setState(() {
          _results.clear();
          _isOcrProcessing = false;
        });
        await _translate();
      } else {
        setState(() => _isOcrProcessing = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOcrProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('截图识别失败: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await _reloadProviders();
    await _reloadSession();
    await _reloadPrompts();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _reloadProviders() async {
    try {
      final providers = await _ffi.getProviders();
      final providerMap = Map.of(_defaultProviders);
      for (final provider in providers) {
        providerMap[provider.id] = provider.name;
      }
      if (!mounted) return;
      setState(() {
        _savedProviders = providers;
        _providers = providerMap;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载厂商列表失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _reloadSession() async {
    try {
      final session = await _ffi.getActiveSession();
      final activeIds = _savedProviders.isEmpty
          ? _providers.keys.toSet()
          : _savedProviders.where((p) => p.isActive).map((p) => p.id).toSet();
      final nextSelection = <String>{};
      nextSelection.addAll(
        session.lastCompareProviders.where((id) => activeIds.contains(id)),
      );
      if (nextSelection.isEmpty &&
          session.lastProviderId.isNotEmpty &&
          activeIds.contains(session.lastProviderId)) {
        nextSelection.add(session.lastProviderId);
      }
      if (nextSelection.isEmpty && activeIds.isNotEmpty) {
        nextSelection.add(activeIds.first);
      }
      if (!mounted) return;
      setState(() {
        _selectedProviders
          ..clear()
          ..addAll(nextSelection);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复上次会话失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _reloadPrompts() async {
    try {
      final templates = await _ffi.getPromptTemplates();
      if (mounted) {
        setState(() {
          _promptTemplates = templates;
          final active = templates.where((t) => t.isActive).firstOrNull;
          if (active != null) {
            _activePromptId = active.id;
            _activePromptContent = active.content;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载提示词模板失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  void dispose() {
    _hotkeySubscription?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveSession() async {
    if (_selectedProviders.isEmpty) return;
    try {
      await _ffi.updateSession(
        providerId: _selectedProviders.first,
        compareProviders: _selectedProviders.toList(),
      );
    } catch (_) {}
  }

  Future<void> _translate() async {
    final text = _textController.text.trim();
    final selectedProviders = _selectedProviders.toList(growable: false);
    if (text.isEmpty || selectedProviders.isEmpty) return;
    setState(() => _isTranslating = true);
    try {
      if (selectedProviders.length == 1) {
        final pid = selectedProviders.first;
        final r = await _ffi.translate(
          text: text,
          sourceLang: _sourceLang,
          targetLang: _targetLang,
          providerId: pid,
          systemPromptOverride: _activePromptContent,
        );
        if (!mounted) return;
        setState(() {
          _results[pid] = r;
          _isTranslating = false;
        });
      } else {
        final results = await _ffi.translateCompare(
          text: text,
          sourceLang: _sourceLang,
          targetLang: _targetLang,
          providerIds: selectedProviders,
          systemPromptOverride: _activePromptContent,
        );
        if (!mounted) return;
        setState(() {
          for (final r in results) {
            _results[r.providerId] = r;
          }
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        for (final id in selectedProviders) {
          _results[id] = TranslationResult(
            providerId: id,
            providerName: _providers[id] ?? id,
            sourceText: text,
            translatedText: '翻译失败: $e',
            responseTimeMs: 0,
            isSuccess: false,
            errorMessage: e.toString(),
          );
        }
        _isTranslating = false;
      });
    }
  }

  void _swapLanguages() {
    if (_sourceLang == 'auto') return;
    setState(() {
      final t = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = t;
    });
  }

  Future<void> _toggleProvider(String id) async {
    setState(() {
      if (_selectedProviders.contains(id)) {
        if (_selectedProviders.length > 1) {
          _selectedProviders.remove(id);
          _results.remove(id);
        }
      } else {
        _selectedProviders.add(id);
      }
    });
    await _saveSession();
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading)
      return Scaffold(body: AppLoadingIndicator.scaffoldBody());

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(theme),
            AppDivider.subtle(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppTokens.space12, AppTokens.space8, AppTokens.space12, AppTokens.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLanguageBar(theme),
                    const SizedBox(height: AppTokens.space8),
                    _buildPromptSelector(theme),
                    if (_isOcrProcessing) _buildOcrStatus(theme),
                    const SizedBox(height: AppTokens.space8),
                    _buildProviderChips(theme),
                    if (_providerPanelOpen) _buildProviderPanel(theme),
                    const SizedBox(height: AppTokens.space8),
                    _buildInputArea(theme),
                    const SizedBox(height: AppTokens.space8),
                    _buildTranslateButton(theme),
                    if (_results.isNotEmpty) ...[
                      const SizedBox(height: AppTokens.space8),
                      ..._selectedProviders.map(
                        (id) => _buildResultCard(theme, id),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12, vertical: AppTokens.space6),
      child: Row(
        children: [
          Icon(Icons.translate, size: AppTokens.iconXl, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.space8),
          Text(
            'AI 翻译',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings, size: AppTokens.iconLg),
            tooltip: '设置',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageBar(ThemeData theme) {
    final sourceItems = _languages.entries
        .where((e) => e.key != _targetLang)
        .map(
          (e) => PopupMenuItem(
            value: e.key,
            child: Text(e.value, style: const TextStyle(fontSize: AppTokens.fontMd)),
          ),
        )
        .toList();
    final targetItems = _languages.entries
        .where((e) => e.key != 'auto' && e.key != _sourceLang)
        .map(
          (e) => PopupMenuItem(
            value: e.key,
            child: Text(e.value, style: const TextStyle(fontSize: AppTokens.fontMd)),
          ),
        )
        .toList();
    return Row(
      children: [
        Expanded(
          child: AppDropdown<String>(
            value: _sourceLang,
            items: sourceItems,
            onSelected: (v) {
              if (v != null) setState(() => _sourceLang = v);
            },
            icon: Icon(
              Icons.language,
              size: AppTokens.iconSm,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.space12),
        IconButton(
          icon: const Icon(Icons.swap_horiz, size: AppTokens.iconLg),
          tooltip: '切换',
          visualDensity: VisualDensity.compact,
          onPressed: _swapLanguages,
        ),
        const SizedBox(width: AppTokens.space12),
        Expanded(
          child: AppDropdown<String>(
            value: _targetLang,
            items: targetItems,
            onSelected: (v) {
              if (v != null) setState(() => _targetLang = v);
            },
            icon: Icon(
              Icons.translate,
              size: AppTokens.iconSm,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptSelector(ThemeData theme) {
    final hasActive =
        _activePromptId != null && _activePromptId != '__default__';
    final defaultValue = '__default__';
    final displayValue =
        _activePromptId == null || _activePromptId == defaultValue
        ? null
        : _activePromptId;
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: defaultValue,
        child: Row(
          children: [
            SizedBox(
              width: AppTokens.iconMd,
              child: !hasActive
                  ? Icon(
                      Icons.check,
                      size: AppTokens.iconMd,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
            const SizedBox(width: AppTokens.space4),
            const Text('使用厂商默认提示词', style: TextStyle(fontSize: AppTokens.fontMd)),
          ],
        ),
      ),
      ..._promptTemplates.map(
        (t) => PopupMenuItem<String>(
          value: t.id,
          child: Row(
            children: [
              SizedBox(
                width: AppTokens.iconMd,
                child: displayValue == t.id
                    ? Icon(
                        Icons.check,
                        size: AppTokens.iconMd,
                        color: theme.colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: AppTokens.space4),
              Text(t.name, style: const TextStyle(fontSize: AppTokens.fontMd)),
            ],
          ),
        ),
      ),
    ];
    return AppDropdown<String>(
      value: displayValue,
      items: items,
      onSelected: (v) {
        setState(() {
          if (v == defaultValue) {
            _activePromptId = v;
            _activePromptContent = null;
          } else {
            _activePromptId = v;
            _activePromptContent = _promptTemplates
                .where((t) => t.id == v)
                .firstOrNull
                ?.content;
          }
        });
      },
      icon: Icon(
        Icons.auto_awesome,
        size: AppTokens.iconSm,
        color: hasActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      isActive: hasActive,
      suffixAction: IconButton(
        icon: const Icon(Icons.add_circle_outline, size: AppTokens.iconLg),
        tooltip: '管理',
        visualDensity: VisualDensity.compact,
        onPressed: () => _showPromptManager(),
      ),
    );
  }

  Widget _buildProviderChips(ThemeData theme) {
    return Wrap(
      spacing: AppTokens.space6,
      runSpacing: AppTokens.space4,
      children: [
        ..._selectedProviders.map(
          (id) => AppChip(
            label: _providers[id] ?? id,
            avatar: Icon(Icons.api, size: AppTokens.iconSm, color: theme.colorScheme.primary),
            deleteIcon: const Icon(Icons.close, size: AppTokens.iconSm),
            onDeleted: _selectedProviders.length > 1
                ? () => setState(() {
                    _selectedProviders.remove(id);
                    _results.remove(id);
                  })
                : null,
          ),
        ),
        AppChip(
          avatar: Icon(
            _providerPanelOpen ? Icons.expand_less : Icons.expand_more,
            size: AppTokens.iconMd,
            color: theme.colorScheme.primary,
          ),
          label: _providerPanelOpen ? '收起' : '选择厂商',
          onTap: () => setState(() => _providerPanelOpen = !_providerPanelOpen),
        ),
      ],
    );
  }

  Widget _buildOcrStatus(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space4),
      child: Row(
        children: [
          AppLoadingIndicator.inline(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppTokens.space8),
          Text(
            '截图识别中...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderPanel(ThemeData theme) {
    final activeIds = _savedProviders.isEmpty
        ? _providers.keys
              .toSet() // 未保存时所有厂商默认可用
        : _savedProviders.where((p) => p.isActive).map((p) => p.id).toSet();
    final activeEntries = _providers.entries
        .where((e) => activeIds.contains(e.key))
        .toList();
    if (activeEntries.isEmpty) {
      return AppCard.surface(
        margin: const EdgeInsets.only(top: AppTokens.space4),
        padding: AppTokens.cardPadding,
        child: Text(
          '暂无启用的厂商，请在设置中启用',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return AppCard.surface(
      margin: const EdgeInsets.only(top: AppTokens.space4),
      child: Column(
        children: activeEntries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.space10, vertical: AppTokens.space4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.value, style: theme.textTheme.bodyMedium),
                    ),
                    AppToggle.checkbox(
                      value: _selectedProviders.contains(e.key),
                      onChanged: (_) => _toggleProvider(e.key),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const _TranslateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _TranslateIntent: CallbackAction<_TranslateIntent>(
            onInvoke: (intent) {
              _translate();
              return null;
            },
          ),
        },
        child: AppInput.multiline(
          controller: _textController,
          hintText: '输入要翻译的文本... (Shift+Enter 换行)',
          onChanged: (_) => setState(() {}),
          maxLines: 4,
          onClear: () {
            _textController.clear();
            setState(() => _results.clear());
          },
        ),
      ),
    );
  }

  Widget _buildTranslateButton(ThemeData theme) {
    return AppButton.primary(
      label: _isTranslating
          ? '翻译中...'
          : _selectedProviders.length == 1
          ? '翻译'
          : '翻译 (${_selectedProviders.length}个厂商)',
      icon: _isTranslating
          ? AppLoadingIndicator.inline(color: theme.colorScheme.onPrimary)
          : Icon(Icons.translate, size: AppTokens.iconLg, color: theme.colorScheme.onPrimary),
      onPressed: _isTranslating || _selectedProviders.isEmpty ? null : _translate,
      isLoading: _isTranslating,
      fullWidth: true,
    );
  }

  Widget _buildResultCard(ThemeData theme, String providerId) {
    final result = _results[providerId];
    final providerName = _providers[providerId] ?? providerId;
    if (result == null) {
      if (_isTranslating) {
        return AppCard.surface(
          margin: const EdgeInsets.only(bottom: AppTokens.space10),
          child: Row(
            children: [
              SizedBox(
                width: AppTokens.iconMd,
                height: AppTokens.iconMd,
                child: AppLoadingIndicator.inline(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTokens.space8),
              Text('$providerName 翻译中...', style: theme.textTheme.bodySmall),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return AppResultCard(
      providerName: providerName,
      text: result.translatedText,
      isError: !result.isSuccess,
      responseTimeMs: result.responseTimeMs,
      totalTokens: result.totalTokens,
      onCopy: () => _ffi.setClipboardText(result.translatedText),
    );
  }

  // ========== 提示词模板管理 ==========

  Future<void> _showPromptManager() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PromptManagerSheet(
        templates: _promptTemplates,
        onSave: (tpl) => _savePrompt(tpl),
        onDelete: (id) => _deletePrompt(id),
        onActivate: (id) => _activatePrompt(id),
      ),
    );
    if (result == true) await _loadPrompts();
  }

  Future<void> _savePrompt(PromptTemplate tpl) async {
    await _ffi.savePromptTemplate(tpl);
  }

  Future<void> _deletePrompt(String id) async {
    await _ffi.deletePromptTemplate(id);
  }

  Future<void> _activatePrompt(String id) async {
    final tpl = _promptTemplates.firstWhere((t) => t.id == id);
    await _ffi.savePromptTemplate(tpl.copyWith(isActive: true));
  }

  Future<void> _loadPrompts() async {
    try {
      final templates = await _ffi.getPromptTemplates();
      if (mounted)
        setState(() {
          _promptTemplates = templates;
          final a = templates.where((t) => t.isActive).firstOrNull;
          _activePromptId = a?.id;
          _activePromptContent = a?.content;
        });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刷新提示词失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }
}

class _TranslateIntent extends Intent {
  const _TranslateIntent();
}

// ========== 提示词模板管理 BottomSheet ==========

class _PromptManagerSheet extends StatefulWidget {
  final List<PromptTemplate> templates;
  final Future<void> Function(PromptTemplate) onSave;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(String) onActivate;

  _PromptManagerSheet({
    required this.templates,
    required this.onSave,
    required this.onDelete,
    required this.onActivate,
  });

  @override
  State<_PromptManagerSheet> createState() => _PromptManagerSheetState();
}

class _PromptManagerSheetState extends State<_PromptManagerSheet> {
  Future<void> _addOrEdit({PromptTemplate? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? '编辑提示词' : '新增提示词'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '例如: 翻译助手',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 6,
                minLines: 3,
                decoration: const InputDecoration(
                  labelText: '提示词内容',
                  hintText: '输入系统提示词...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == true &&
        nameCtrl.text.trim().isNotEmpty &&
        contentCtrl.text.trim().isNotEmpty) {
      await widget.onSave(
        PromptTemplate(
          id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameCtrl.text.trim(),
          content: contentCtrl.text.trim(),
          isActive: existing?.isActive ?? false,
          createdAt: existing?.createdAt ?? DateTime.now(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: AppTokens.pagePadding,
        child: Column(
          children: [
            Center(
              child: Container(
                width: 32,
                height: AppTokens.space4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(AppTokens.radiusXs),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            Row(
              children: [
                Text('提示词模板管理', style: theme.textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: AppTokens.iconXl),
                  tooltip: '新增',
                  onPressed: () => _addOrEdit(),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space8),
            if (widget.templates.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    '暂无提示词模板，点击 + 新增',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: widget.templates.length,
                  itemBuilder: (_, i) {
                    final t = widget.templates[i];
                    return AppCard.surface(
                      child: ListTile(
                        leading: t.isActive
                            ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: AppTokens.iconXl,
                              )
                            : const Icon(Icons.circle_outlined, size: AppTokens.iconXl),
                        title: Text(t.name, style: theme.textTheme.bodyMedium),
                        subtitle: Text(
                          t.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!t.isActive)
                              InkWell(
                                onTap: () async {
                                  await widget.onActivate(t.id);
                                  if (mounted) Navigator.pop(context, true);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(AppTokens.space4),
                                  child: Icon(
                                    Icons.check_circle_outline,
                                    size: AppTokens.iconXl,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            InkWell(
                              onTap: () => _addOrEdit(existing: t),
                              child: const Padding(
                                padding: EdgeInsets.all(AppTokens.space4),
                                child: Icon(Icons.edit, size: AppTokens.iconXl),
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('确认删除'),
                                    content: Text('删除 "${t.name}"？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('取消'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('删除'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await widget.onDelete(t.id);
                                  if (mounted) Navigator.pop(context, true);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(AppTokens.space4),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: AppTokens.iconXl,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
