import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/translation_result.dart';
import '../../data/datasources/ffi_datasource.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/result_card.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/foundation/app_input.dart';
import '../widgets/foundation/app_button.dart';
import '../widgets/foundation/app_card.dart';

class ComparePage extends ConsumerStatefulWidget {
  const ComparePage({super.key});

  @override
  ConsumerState<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends ConsumerState<ComparePage> {
  final _textController = TextEditingController();
  final _compareResults = <String, TranslationResult>{};
  final _selectedProviders = <String>{'openai', 'deepl'};
  bool _isComparing = false;

  final _allProviders = <String, String>{
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

  final _ffi = FfiDatasource();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startCompare() async {
    if (_textController.text.trim().isEmpty || _selectedProviders.isEmpty) return;

    setState(() => _isComparing = true);

    try {
      final results = await _ffi.translateCompare(
        text: _textController.text.trim(),
        sourceLang: 'auto',
        targetLang: 'zh',
        providerIds: _selectedProviders.toList(),
      );
      setState(() {
        _compareResults.clear();
        for (final r in results) {
          _compareResults[r.providerId] = r;
        }
        _isComparing = false;
      });
    } catch (e) {
      setState(() {
        for (final id in _selectedProviders) {
          _compareResults[id] = TranslationResult(
            providerId: id,
            providerName: _allProviders[id] ?? id,
            sourceText: _textController.text.trim(),
            translatedText: '翻译失败: $e',
            responseTimeMs: 0,
            isSuccess: false,
            errorMessage: e.toString(),
          );
        }
        _isComparing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('多厂商对比'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (id) {
              setState(() {
                if (_selectedProviders.contains(id)) {
                  if (_selectedProviders.length > 1) {
                    _selectedProviders.remove(id);
                    _compareResults.remove(id);
                  }
                } else {
                  _selectedProviders.add(id);
                }
              });
            },
            itemBuilder: (context) {
              return _allProviders.entries.map((e) {
                return PopupMenuItem<String>(
                  value: e.key,
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selectedProviders.contains(e.key),
                        onChanged: null,
                      ),
                      Text(e.value),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Padding(
        padding: AppTokens.pagePadding,
        child: Column(
          children: [
            AppInput.multiline(
              hintText: '输入对比翻译文本...',
              value: _textController.text,
              onChanged: (v) => _textController.text = v,
              maxLines: 3,
            ),
            const SizedBox(height: AppTokens.space12),

            Wrap(
              spacing: AppTokens.space8,
              children: _selectedProviders.map((id) {
                return Chip(
                  avatar: Icon(Icons.api, size: AppTokens.iconMd, color: theme.colorScheme.primary),
                  label: Text(_allProviders[id] ?? id),
                  deleteIcon: const Icon(Icons.close, size: AppTokens.iconMd),
                  onDeleted: _selectedProviders.length > 1
                      ? () {
                          setState(() {
                            _selectedProviders.remove(id);
                            _compareResults.remove(id);
                          });
                        }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: AppTokens.space12),

            AppButton.primary(
              label: _isComparing
                  ? '对比中...'
                  : '开始对比 (${_selectedProviders.length}个厂商)',
              icon: _isComparing
                  ? AppLoadingIndicator.inline(color: theme.colorScheme.onPrimary)
                  : const Icon(Icons.compare),
              onPressed: _isComparing || _selectedProviders.isEmpty ? null : _startCompare,
              isLoading: _isComparing,
              fullWidth: true,
            ),
            const SizedBox(height: AppTokens.space16),

            if (_compareResults.isNotEmpty)
              Expanded(
                child: ListView(
                  children: _selectedProviders.map((id) {
                    final result = _compareResults[id];
                    if (result == null) {
                      if (_isComparing) {
                        return AppCard.surface(
                          margin: const EdgeInsets.only(bottom: AppTokens.space12),
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
                                Text(
                                  '${_allProviders[id] ?? id} 翻译中...',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                      }
                      return const SizedBox.shrink();
                    }
                    return _buildResultCard(theme, id, result);
                  }).toList(),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, String providerId, TranslationResult result) {
    return AppResultCard(
      providerName: _allProviders[providerId] ?? providerId,
      text: result.translatedText,
      isError: !result.isSuccess,
      responseTimeMs: result.responseTimeMs,
      totalTokens: result.totalTokens,
      onCopy: () => _ffi.setClipboardText(result.translatedText),
    );
  }

}