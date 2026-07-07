#!/usr/bin/env python3
"""Migrate remaining sections of floating_page.dart to use unified components."""

file_path = '/home/xiyeming/Projects/RustProjects/Waylex/flutter/lib/presentation/pages/floating_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add import for app_input.dart and app_button.dart
old_imports = """import '../widgets/foundation/app_card.dart';
import '../widgets/foundation/app_toggle.dart';"""

new_imports = """import '../widgets/foundation/app_card.dart';
import '../widgets/foundation/app_toggle.dart';
import '../widgets/foundation/app_input.dart';
import '../widgets/foundation/app_button.dart';"""

content = content.replace(old_imports, new_imports)

# 2. Replace TextField in _buildInputArea with AppInput.multiline
old_input_area = """  Widget _buildInputArea(ThemeData theme) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            !HardwareKeyboard.instance.isShiftPressed &&
            !HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isAltPressed) {
          _translate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _textController,
        maxLines: 4,
        minLines: 2,
        decoration: InputDecoration(
          hintText: '输入要翻译的文本... (Shift+Enter 换行)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusXl)),
          contentPadding: AppTokens.inputContentPadding,
          suffixIcon: _textController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: AppTokens.iconLg),
                  onPressed: () {
                    _textController.clear();
                    setState(() => _results.clear());
                  },
                )
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }"""

new_input_area = """  Widget _buildInputArea(ThemeData theme) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            !HardwareKeyboard.instance.isShiftPressed &&
            !HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isAltPressed) {
          _translate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AppInput.multiline(
        hintText: '输入要翻译的文本... (Shift+Enter 换行)',
        value: _textController.text,
        onChanged: (_) => setState(() {}),
        maxLines: 4,
        onClear: () {
          _textController.clear();
          setState(() => _results.clear());
        },
      ),
    );
  }"""

content = content.replace(old_input_area, new_input_area)

# 3. Replace FilledButton.icon in _buildTranslateButton with AppButton.primary
old_translate_btn = """  Widget _buildTranslateButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: _isTranslating || _selectedProviders.isEmpty
          ? null
          : _translate,
      icon: _isTranslating
          ? AppLoadingIndicator.inline(color: theme.colorScheme.onPrimary)
          : const Icon(Icons.translate, size: AppTokens.iconLg),
      label: Text(
        _isTranslating
            ? '翻译中...'
            : _selectedProviders.length == 1
            ? '翻译'
            : '翻译 (${_selectedProviders.length}个厂商)',
      ),
    );
  }"""

new_translate_btn = """  Widget _buildTranslateButton(ThemeData theme) {
    return AppButton.primary(
      label: _isTranslating
          ? '翻译中...'
          : _selectedProviders.length == 1
          ? '翻译'
          : '翻译 (${_selectedProviders.length}个厂商)',
      icon: _isTranslating
          ? AppLoadingIndicator.inline(color: theme.colorScheme.onPrimary)
          : const Icon(Icons.translate, size: AppTokens.iconLg),
      onPressed: _isTranslating || _selectedProviders.isEmpty ? null : _translate,
      isLoading: _isTranslating,
      fullWidth: true,
    );
  }"""

content = content.replace(old_translate_btn, new_translate_btn)

# 4. Replace loading state Container+Card with AppCard.surface
old_loading_card = """    if (result == null) {
      if (_isTranslating) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppTokens.space12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(AppTokens.radius2Xl),
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius2Xl)),
            child: Padding(
              padding: AppTokens.cardPadding,
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
            ),
          ),
        );
      }"""

new_loading_card = """    if (result == null) {
      if (_isTranslating) {
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
              Text('$providerName 翻译中...', style: theme.textTheme.bodySmall),
            ],
          ),
        );
      }"""

content = content.replace(old_loading_card, new_loading_card)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Migration complete!")
