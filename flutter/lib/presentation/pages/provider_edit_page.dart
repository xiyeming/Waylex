import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/provider_config.dart';
import '../../data/datasources/ffi_datasource.dart';
import '../widgets/common/loading_indicator.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/foundation/app_input.dart';
import '../widgets/foundation/app_toggle.dart';
import '../widgets/foundation/app_button.dart';
import '../widgets/foundation/app_card.dart';

class ProviderEditPage extends ConsumerStatefulWidget {
  final String? providerId;
  final String? defaultName;
  final String? defaultModel;

  const ProviderEditPage({
    super.key,
    this.providerId,
    this.defaultName,
    this.defaultModel,
  });

  @override
  ConsumerState<ProviderEditPage> createState() => _ProviderEditPageState();
}

class _ProviderEditPageState extends ConsumerState<ProviderEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  final _systemPromptController = TextEditingController();

  bool _isActive = true;
  bool _obscureApiKey = true;
  bool _isTesting = false;
  bool _isSaving = false;
  bool _isLoading = false;
  String? _testResult;
  bool _testSuccess = false;

  bool get _isNew => widget.providerId == null;

  static const _defaultBaseUrls = <String, String>{
    'openai': 'https://api.openai.com/v1',
    'deepl': 'https://api-free.deepl.com/v2',
    'google': 'https://translation.googleapis.com',
    'qwen': 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    'deepseek': 'https://api.deepseek.com/v1',
    'kimi': 'https://api.moonshot.cn/v1',
    'glm': 'https://open.bigmodel.cn/api/paas/v4',
    'anthropic': 'https://api.anthropic.com/v1',
    'azure': '',
    'custom': '',
  };

  @override
  void initState() {
    super.initState();
    if (!_isNew) {
      _nameController.text = widget.defaultName ?? '';
      _modelController.text = widget.defaultModel ?? '';
      final id = widget.providerId ?? '';
      _baseUrlController.text = _defaultBaseUrls[id] ?? '';
      _loadSavedConfig();
    }
  }

  Future<void> _loadSavedConfig() async {
    if (widget.providerId == null) return;
    setState(() => _isLoading = true);
    try {
      final ffi = FfiDatasource();
      final providers = await ffi.getProviders();
      final saved = providers.where((p) => p.id == widget.providerId).firstOrNull;
      if (saved != null && mounted) {
        setState(() {
          _nameController.text = saved.name;
          _modelController.text = saved.model;
          if (saved.apiUrl != null && saved.apiUrl!.isNotEmpty) {
            _baseUrlController.text = saved.apiUrl!;
          }
          if (saved.apiKey != null && saved.apiKey!.isNotEmpty) {
            _apiKeyController.text = saved.apiKey!;
          }
          if (saved.systemPrompt != null && saved.systemPrompt!.isNotEmpty) {
            _systemPromptController.text = saved.systemPrompt!;
          }
          _isActive = saved.isActive;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载配置失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_modelController.text.trim().isEmpty) {
      setState(() { _testResult = '请先填写模型名称'; _testSuccess = false; });
      return;
    }
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() { _testResult = '请先填写 API Key'; _testSuccess = false; });
      return;
    }

    setState(() { _isTesting = true; _testResult = null; });

try {
      await _saveSilently();
      final ffi = FfiDatasource();
      final id = widget.providerId ?? _nameController.text.trim().toLowerCase().replaceAll(' ', '_');
      final result = await ffi.testProvider(id);
      setState(() {
        _isTesting = false;
        _testSuccess = result.success;
        _testResult = result.message;
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = '测试异常: $e';
      });
    }
  }

  Future<void> _saveSilently() async {
    final ffi = FfiDatasource();
    final id = widget.providerId ?? _nameController.text.trim().toLowerCase().replaceAll(' ', '_');
    final config = ProviderConfig(
      id: id,
      name: _nameController.text.trim(),
      apiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
      apiUrl: _baseUrlController.text.trim().isEmpty ? null : _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      authType: 'api_key',
      isActive: _isActive,
      sortOrder: 0,
      systemPrompt: _systemPromptController.text.trim().isEmpty ? null : _systemPromptController.text.trim(),
      createdAt: DateTime.now(),
    );
    await ffi.saveProvider(config);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final ffi = FfiDatasource();
      final id = widget.providerId ?? _nameController.text.trim().toLowerCase().replaceAll(' ', '_');
      final config = ProviderConfig(
        id: id,
        name: _nameController.text.trim(),
        apiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
        apiUrl: _baseUrlController.text.trim().isEmpty ? null : _baseUrlController.text.trim(),
        model: _modelController.text.trim(),
        authType: 'api_key',
        isActive: _isActive,
        sortOrder: 0,
        systemPrompt: _systemPromptController.text.trim().isEmpty ? null : _systemPromptController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ffi.saveProvider(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        context.go('/settings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (_isNew) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${_nameController.text} 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('删除', style: TextStyle(color: AppTokens.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final ffi = FfiDatasource();
      await ffi.deleteProvider(widget.providerId!);
      if (mounted) context.go('/settings');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return AppLoadingIndicator.scaffoldBody();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        title: Text(_isNew ? '添加厂商' : '编辑厂商'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppTokens.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput.text(
                label: '名称',
                hintText: '例如: OpenAI, DeepL',
                value: _nameController.text,
                onChanged: (v) => _nameController.text = v,
                prefixIcon: Icons.label,
                onClear: () => _nameController.clear(),
              ),
              const SizedBox(height: AppTokens.space16),

              AppInput.text(
                label: 'API Key',
                hintText: '输入 API 密钥',
                value: _apiKeyController.text,
                onChanged: (v) => _apiKeyController.text = v,
                prefixIcon: Icons.key,
                obscureText: _obscureApiKey,
                suffixIcon: IconButton(
                  icon: Icon(_obscureApiKey ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                  tooltip: _obscureApiKey ? '显示' : '隐藏',
                ),
                onClear: () => _apiKeyController.clear(),
              ),
              const SizedBox(height: AppTokens.space16),

              AppInput.text(
                label: 'Base URL',
                hintText: _isNew
                    ? '例如: https://api.openai.com/v1'
                    : '留空使用默认地址',
                value: _baseUrlController.text,
                onChanged: (v) => _baseUrlController.text = v,
                prefixIcon: Icons.link,
                helperText: '仅填写 Base URL，接口路径会自动拼接',
              ),
              const SizedBox(height: AppTokens.space16),

              AppInput.text(
                label: '模型',
                hintText: '例如: gpt-4o-mini, deepseek-chat',
                value: _modelController.text,
                onChanged: (v) => _modelController.text = v,
                prefixIcon: Icons.smart_toy,
              ),
              const SizedBox(height: AppTokens.space16),

              AppInput.multiline(
                label: '系统提示词 (可选)',
                hintText: '留空使用默认: You are a translation engine...',
                value: _systemPromptController.text,
                onChanged: (v) => _systemPromptController.text = v,
                prefixIcon: Icons.chat,
                maxLines: 5,
                helperText: '默认会强制模型只输出翻译结果，不进行对话',
              ),
              const SizedBox(height: AppTokens.space16),

              AppToggle.switch_(
                label: '启用此厂商',
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: AppTokens.space24),

              AppButton.primary(
                label: _isSaving ? '保存中...' : '保存',
                icon: _isSaving
                    ? AppLoadingIndicator.inlineForFilledButton()
                    : const Icon(Icons.save),
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
                fullWidth: true,
              ),
              const SizedBox(height: AppTokens.space16),

              AppButton.secondary(
                label: _isTesting ? '测试中...' : '测试连接',
                icon: _isTesting
                    ? AppLoadingIndicator.inlineForOutlinedButton(context)
                    : const Icon(Icons.wifi_find),
                onPressed: _isTesting ? null : _testConnection,
                isLoading: _isTesting,
                fullWidth: true,
              ),
              if (_testResult != null) ...[
                const SizedBox(height: AppTokens.space8),
                AppCard.surface(
                  padding: AppTokens.cardPadding,
                  child: Row(
                    children: [
                      Icon(_testSuccess ? Icons.check_circle : Icons.error,
                          color: _testSuccess ? theme.colorScheme.primary : theme.colorScheme.error, size: AppTokens.iconXl),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            color: _testSuccess ? theme.colorScheme.primary : theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}