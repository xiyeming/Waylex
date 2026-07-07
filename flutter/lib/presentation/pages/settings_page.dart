import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/ffi_datasource.dart';
import '../../data/models/provider_config.dart';
import '../../data/models/shortcut_binding.dart';
import '../../presentation/services/hotkey_service.dart';
import '../../presentation/widgets/common/update_dialog.dart';
import '../../presentation/providers/theme_provider.dart';
import '../widgets/common/loading_indicator.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/foundation/app_card.dart';
import '../widgets/foundation/app_toggle.dart';
import '../widgets/common/app_divider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('设置'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.api, size: AppTokens.iconMd), text: '厂商'),
            Tab(icon: Icon(Icons.keyboard, size: AppTokens.iconMd), text: '快捷键'),
            Tab(icon: Icon(Icons.language, size: AppTokens.iconMd), text: '语言'),
            Tab(icon: Icon(Icons.palette, size: AppTokens.iconMd), text: '外观'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ProviderSettingsTab(),
          _ShortcutSettingsTab(),
          _LanguageSettingsTab(),
          _ThemeSettingsTab(),
        ],
      ),
    );
  }
}

class _ProviderSettingsTab extends ConsumerStatefulWidget {
  const _ProviderSettingsTab();

  @override
  ConsumerState<_ProviderSettingsTab> createState() => _ProviderSettingsTabState();
}

class _ProviderSettingsTabState extends ConsumerState<_ProviderSettingsTab> {
  List<ProviderConfig> _providers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      final ffi = FfiDatasource();
      final providers = await ffi.getProviders();
      if (mounted) setState(() { _providers = providers; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载厂商配置失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _toggleActive(ProviderConfig p) async {
    var saved = _providers.where((s) => s.id == p.id).firstOrNull;
    var hasKey = saved?.apiKey != null && saved!.apiKey!.isNotEmpty;

    // 缓存中没有 apiKey 时，从数据库刷新一次（编辑页返回后缓存可能过时）
    if (!hasKey) {
      final ffi = FfiDatasource();
      final fresh = await ffi.getProviders();
      saved = fresh.where((s) => s.id == p.id).firstOrNull;
      hasKey = saved?.apiKey != null && saved!.apiKey!.isNotEmpty;
      if (hasKey && mounted) {
        setState(() {
          _providers = fresh;
        });
      }
    }

    if (!(saved?.isActive ?? false) && !hasKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先配置 API Key 后再启用厂商'), duration: Duration(seconds: 2)),
        );
      }
      return;
    }
    final newActive = !(saved?.isActive ?? p.isActive);
    setState(() {
      final idx = _providers.indexWhere((x) => x.id == p.id);
      if (idx >= 0) _providers[idx] = (saved ?? p).copyWith(isActive: newActive);
      else {
        _providers.add(p.copyWith(isActive: newActive, createdAt: DateTime.now()));
      }
    });
    final ffi = FfiDatasource();
    await ffi.saveProvider((saved ?? p).copyWith(isActive: newActive));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppLoadingIndicator.scaffoldBody();
    }

    final defaultProviders = <String, ProviderConfig>{
      for (final p in [
        ProviderConfig(id: 'openai', name: 'OpenAI', model: 'gpt-4o-mini', authType: 'api_key', isActive: false, createdAt: DateTime.now()),
        ProviderConfig(id: 'deepl', name: 'DeepL', model: 'default', authType: 'api_key', isActive: false, createdAt: DateTime.now()),
        ProviderConfig(id: 'google', name: 'Google', model: 'nmt', authType: 'api_key', isActive: false, createdAt: DateTime.now()),
        ProviderConfig(id: 'qwen', name: 'Qwen (通义千问)', model: 'qwen-turbo', authType: 'api_key', isActive: false, createdAt: DateTime.now()),
        ProviderConfig(id: 'deepseek', name: 'DeepSeek', model: 'deepseek-chat', authType: 'api_key', isActive: false, createdAt: DateTime.now()),
        ProviderConfig(id: 'kimi', name: 'Kimi (月之暗面)', model: 'moonshot-v1-8k', authType: 'api_key', isActive: false, createdAt: DateTime.now()),
        ProviderConfig(id: 'glm', name: 'GLM (智谱)', model: 'glm-4-plus', authType: 'api_key', isActive: false, createdAt: DateTime.now()),
        ProviderConfig(id: 'anthropic', name: 'Anthropic', model: 'claude-3-haiku-20240307', authType: 'api_key', isActive: false, createdAt: DateTime.now()),
        ProviderConfig(id: 'azure', name: 'Azure OpenAI', model: 'gpt-4o-mini', authType: 'api_key', isActive: false, createdAt: DateTime.now()),
        ProviderConfig(id: 'custom', name: 'Custom (兼容 API)', model: '自定义', authType: 'api_key', isActive: false, createdAt: DateTime.now()),
      ]) p.id: p
    };

    final merged = <String, ProviderConfig>{};
    for (final p in _providers) { merged[p.id] = p; }
    for (final e in defaultProviders.entries) {
      merged.putIfAbsent(e.key, () => e.value);
    }

    final sorted = merged.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      padding: AppTokens.pagePadding,
      children: [
        ...sorted.map((p) => _buildProviderCard(context, p)),
        const SizedBox(height: AppTokens.space24),
        OutlinedButton.icon(
          onPressed: () => context.go('/settings/provider'),
          icon: const Icon(Icons.add),
          label: const Text('添加厂商'),
        ),
      ],
    );
  }

  Widget _buildProviderCard(BuildContext context, ProviderConfig p) {
    final isConfigured = _providers.any((s) => s.id == p.id && s.apiKey != null && s.apiKey!.isNotEmpty);
    final saved = _providers.where((s) => s.id == p.id).firstOrNull;
    final isActive = saved?.isActive ?? p.isActive;
    const icons = <String, IconData>{
      'openai': Icons.auto_awesome, 'deepl': Icons.translate, 'google': Icons.cloud,
      'qwen': Icons.auto_awesome, 'deepseek': Icons.auto_awesome, 'kimi': Icons.auto_awesome,
      'glm': Icons.auto_awesome, 'anthropic': Icons.auto_awesome, 'azure': Icons.cloud, 'custom': Icons.tune,
    };
    final theme = Theme.of(context);
    return AppCard.interactive(
      onTap: () => context.go('/settings/provider?id=${p.id}&name=${Uri.encodeComponent(p.name)}&model=${Uri.encodeComponent(p.model)}'),
      child: Row(
        children: [
          Icon(icons[p.id] ?? Icons.api, size: AppTokens.iconLg, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    ),
                    Icon(Icons.circle, size: AppTokens.iconXs, color: isConfigured ? theme.colorScheme.primary : theme.colorScheme.outline),
                    const SizedBox(width: AppTokens.space12),
                    AppToggle.switch_(value: isActive, onChanged: (_) => _toggleActive(p)),
                    const SizedBox(width: AppTokens.space4),
                    Icon(Icons.chevron_right, size: AppTokens.iconSm, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: AppTokens.space2),
                Text(
                  '模型: ${p.model}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutSettingsTab extends ConsumerStatefulWidget {
  const _ShortcutSettingsTab();

  @override
  ConsumerState<_ShortcutSettingsTab> createState() => _ShortcutSettingsTabState();
}

class _ShortcutSettingsTabState extends ConsumerState<_ShortcutSettingsTab> {
  List<ShortcutBinding> _bindings = [];
  bool _isLoading = true;

  static const _actions = {
    'translate_selected': '翻译选中文本',
    'ocr_screenshot': '截图翻译',
    'toggle_window': '显示/隐藏窗口',
  };

  @override
  void initState() {
    super.initState();
    _loadBindings();
  }

  Future<void> _loadBindings() async {
    try {
      final ffi = FfiDatasource();
      var bindings = await ffi.getShortcuts();
      if (bindings.isEmpty) {
        final defaults = [
          ShortcutBinding(id: 'translate_selected', action: 'translate_selected', keyCombination: 'Super+Alt+F', enabled: true),
          ShortcutBinding(id: 'ocr_screenshot', action: 'ocr_screenshot', keyCombination: 'Ctrl+Shift+S', enabled: true),
          ShortcutBinding(id: 'toggle_window', action: 'toggle_window', keyCombination: 'Ctrl+Shift+F', enabled: true),
        ];
        for (final b in defaults) { await ffi.updateShortcut(b); }
        bindings = defaults;
      }
      if (mounted) setState(() { _bindings = bindings; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载快捷键失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _updateAndApply() async {
    try {
      final service = HotkeyService();
      await service.updateAndReregister(_bindings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('快捷键已更新'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新快捷键失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _recordShortcut(ShortcutBinding binding) async {
    final keys = await showDialog<String>(
      context: context,
      builder: (ctx) => _RecordShortcutDialog(currentKeys: binding.keyCombination),
    );
    if (keys != null && mounted) {
      setState(() {
        final idx = _bindings.indexWhere((b) => b.id == binding.id);
        _bindings[idx] = binding.copyWith(keyCombination: keys);
      });
      final ffi = FfiDatasource();
      final b = _bindings.firstWhere((b) => b.id == binding.id);
      await ffi.updateShortcut(b);
      await _updateAndApply();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) return AppLoadingIndicator.fullScreen();

    return ListView(
      padding: AppTokens.pagePadding,
      children: [
        Text('修改后即时生效，点击快捷键组合开始录制', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppTokens.space12),
        ..._bindings.map((b) => AppCard.surface(
          padding: AppTokens.cardPaddingCompact,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_actions[b.id] ?? b.action, style: theme.textTheme.bodyMedium),
                  ),
                  AppToggle.switch_(value: b.enabled, onChanged: (v) {
                    setState(() {
                      final idx = _bindings.indexWhere((b2) => b2.id == b.id);
                      _bindings[idx] = b.copyWith(enabled: v);
                    });
                    final ffi = FfiDatasource();
                    ffi.updateShortcut(b.copyWith(enabled: v));
                    _updateAndApply();
                  }),
                ],
              ),
              AppDivider.subtle(),
              Row(
                children: [
                  Text('快捷键', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _recordShortcut(b),
                    child: Container(
                      padding: AppTokens.shortcutBadgePadding,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(b.keyCombination, style: theme.textTheme.labelMedium?.copyWith(fontFamily: 'monospace', color: theme.colorScheme.onSurface)),
                          const SizedBox(width: AppTokens.space4),
                          Icon(Icons.edit, size: AppTokens.iconMd, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _RecordShortcutDialog extends StatefulWidget {
  final String currentKeys;
  const _RecordShortcutDialog({required this.currentKeys});

  @override
  State<_RecordShortcutDialog> createState() => _RecordShortcutDialogState();
}

class _RecordShortcutDialogState extends State<_RecordShortcutDialog> {
  final _modifiers = <String>[];
  String _key = '';
  bool _recording = false;
  bool _done = false;

  String get _display {
    final parts = [..._modifiers.toSet()];
    if (_key.isNotEmpty) parts.add(_key);
    return parts.join(' + ');
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (_done) return false;
    if (event is! KeyDownEvent) return false;

    final label = event.logicalKey.keyLabel;

    final isMod = event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight ||
        event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight ||
        event.logicalKey == LogicalKeyboardKey.metaLeft;

    if (isMod) {
      setState(() {
        if (event.logicalKey == LogicalKeyboardKey.controlLeft || event.logicalKey == LogicalKeyboardKey.controlRight) _modifiers.add('Ctrl');
        else if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) _modifiers.add('Shift');
        else if (event.logicalKey == LogicalKeyboardKey.altLeft || event.logicalKey == LogicalKeyboardKey.altRight) _modifiers.add('Alt');
        else if (event.logicalKey == LogicalKeyboardKey.metaLeft) _modifiers.add('Super');
        _recording = true;
      });
      return true;
    }

    if (label.isNotEmpty && label.length <= 4 && _recording) {
      final hw = HardwareKeyboard.instance;
      if (hw.isControlPressed) _modifiers.add('Ctrl');
      if (hw.isShiftPressed) _modifiers.add('Shift');
      if (hw.isAltPressed) _modifiers.add('Alt');
      if (hw.isMetaPressed) _modifiers.add('Super');
      _key = label.length == 1 ? label.toUpperCase() : label;
      _done = true;
      Future.delayed(Duration.zero, () => Navigator.pop(context, _display));
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('录制快捷键'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('同时按下组合键 (Ctrl/Shift/Alt/Super + 字母)', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppTokens.space16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppTokens.space20),
            decoration: BoxDecoration(
              border: Border.all(color: _recording ? theme.colorScheme.primary : theme.colorScheme.outline, width: 2),
              borderRadius: BorderRadius.circular(AppTokens.radius2Xl),
              color: _recording ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.colorScheme.surfaceContainerHighest,
            ),
            alignment: Alignment.center,
            child: Text(
              _recording ? _display : (widget.currentKeys.isNotEmpty ? widget.currentKeys : '按下组合键...'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: _recording ? 'monospace' : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () { _done = true; Navigator.pop(context, null); }, child: const Text('取消')),
        TextButton(onPressed: () { _done = true; Navigator.pop(context, widget.currentKeys); }, child: const Text('保持当前')),
      ],
    );
  }
}

class _LanguageSettingsTab extends ConsumerWidget {
  const _LanguageSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView(
      padding: AppTokens.pagePadding,
      children: [
        AppCard.surface(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('自动检测语言', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppTokens.space2),
                    Text('翻译时自动识别源语言', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              AppToggle.switch_(value: true, onChanged: (_) {}),
            ],
          ),
        ),
        AppDivider.bold(height: AppTokens.space24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space8),
          child: Text(
            '常用语言',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...['中文', '英语', '日语', '韩语', '法语'].map((lang) {
          return AppCard.surface(
            margin: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space4),
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space12),
            child: Row(
              children: [
                Expanded(
                  child: Text(lang, style: Theme.of(context).textTheme.bodyMedium),
                ),
                AppToggle.checkbox(value: true, onChanged: (_) {}),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ThemeSettingsTab extends ConsumerStatefulWidget {
  const _ThemeSettingsTab();

  @override
  ConsumerState<_ThemeSettingsTab> createState() => _ThemeSettingsTabState();
}

class _ThemeSettingsTabState extends ConsumerState<_ThemeSettingsTab> {
  String _version = '';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await FfiDatasource().getAppVersion();
    if (mounted) setState(() => _version = v);
  }

  Future<void> _checkUpdate() async {
    setState(() => _checking = true);
    try {
      final ffi = FfiDatasource();
      final currentVersion = await ffi.getAppVersion();
      final updateInfo = await ffi.checkUpdate(currentVersion);
      if (!mounted) return;
      if (updateInfo != null) {
        UpdateDialog.show(context, updateInfo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('当前已是最新版本')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检查更新失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentAccent = ref.watch(accentColorProvider);
    final themeModeValue = currentThemeMode == ThemeMode.light
        ? 'light'
        : currentThemeMode == ThemeMode.dark
            ? 'dark'
            : 'system';

    return ListView(
      padding: AppTokens.pagePadding,
      children: [
        AppCard.surface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ThemeOption(
                label: '跟随系统',
                selected: themeModeValue == 'system',
                onTap: () {
                  final mode = ThemeMode.system;
                  ref.read(themeModeProvider.notifier).setTheme(mode);
                },
              ),
              AppDivider.subtle(),
              _ThemeOption(
                label: '浅色模式',
                selected: themeModeValue == 'light',
                onTap: () {
                  final mode = ThemeMode.light;
                  ref.read(themeModeProvider.notifier).setTheme(mode);
                },
              ),
              AppDivider.subtle(),
              _ThemeOption(
                label: '深色模式',
                selected: themeModeValue == 'dark',
                onTap: () {
                  final mode = ThemeMode.dark;
                  ref.read(themeModeProvider.notifier).setTheme(mode);
                },
              ),
            ],
          ),
        ),
        AppDivider.bold(height: AppTokens.space32),
        AppCard.surface(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.space16, AppTokens.space16, AppTokens.space16, AppTokens.space8),
                child: Text(
                  '主题色',
                  style: TextStyle(
                    fontSize: AppTokens.fontCaption,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space16, vertical: AppTokens.space4),
                child: Wrap(
                  spacing: AppTokens.space12,
                  runSpacing: AppTokens.space12,
                  children: AccentColor.all.map((accent) {
                    final isSelected = currentAccent == accent;
                    return GestureDetector(
                      onTap: () =>
                          ref.read(accentColorProvider.notifier).setAccent(accent),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.value,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: accent.value.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(Icons.check,
                                size: AppTokens.iconMd,
                                color: Theme.of(context).colorScheme.onPrimary)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppTokens.space8),
            ],
          ),
        ),
        AppDivider.bold(height: AppTokens.space32),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('当前版本'),
          subtitle: Text(_version.isEmpty ? '加载中...' : _version),
        ),
        ListTile(
          leading: _checking
              ? AppLoadingIndicator.inline(strokeWidth: 2)
              : const Icon(Icons.system_update),
          title: const Text('检查更新'),
          onTap: _checking ? null : _checkUpdate,
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12, vertical: AppTokens.space8),
        child: Row(
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            AppToggle.radio(value: selected, onChanged: (_) => onTap()),
          ],
        ),
      ),
    );
  }
}
