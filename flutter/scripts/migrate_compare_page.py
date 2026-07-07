#!/usr/bin/env python3
"""Migrate compare_page.dart to use unified components."""

file_path = '/home/xiyeming/Projects/RustProjects/Waylex/flutter/lib/presentation/pages/compare_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add import for app_input.dart and app_button.dart
old_imports = """import '../widgets/common/loading_indicator.dart';
import '../widgets/common/result_card.dart';
import '../theme/app_design_tokens.dart';"""

new_imports = """import '../widgets/common/loading_indicator.dart';
import '../widgets/common/result_card.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/foundation/app_input.dart';
import '../widgets/foundation/app_button.dart';"""

content = content.replace(old_imports, new_imports)

# 2. Replace TextField with AppInput.multiline
old_text_field = """            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '输入对比翻译文本...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radius2Xl),
                ),
              ),
            ),"""

new_text_field = """            AppInput.multiline(
              hintText: '输入对比翻译文本...',
              value: _textController.text,
              onChanged: (v) => _textController.text = v,
              maxLines: 3,
            ),"""

content = content.replace(old_text_field, new_text_field)

# 3. Replace FilledButton.icon with AppButton.primary
old_button = """            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isComparing || _selectedProviders.isEmpty
                    ? null
                    : _startCompare,
                icon: _isComparing
                    ? AppLoadingIndicator.inline(color: theme.colorScheme.onPrimary)
                    : const Icon(Icons.compare),
                label: Text(_isComparing
                    ? '对比中...'
                    : '开始对比 (${_selectedProviders.length}个厂商)'),
              ),
            ),"""

new_button = """            AppButton.primary(
              label: _isComparing
                  ? '对比中...'
                  : '开始对比 (${_selectedProviders.length}个厂商)',
              icon: _isComparing
                  ? AppLoadingIndicator.inline(color: theme.colorScheme.onPrimary)
                  : const Icon(Icons.compare),
              onPressed: _isComparing || _selectedProviders.isEmpty ? null : _startCompare,
              isLoading: _isComparing,
              fullWidth: true,
            ),"""

content = content.replace(old_button, new_button)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Migration complete!")
