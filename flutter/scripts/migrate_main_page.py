#!/usr/bin/env python3
"""Migrate main_page.dart to use unified components."""

file_path = '/home/xiyeming/Projects/RustProjects/Waylex/flutter/lib/presentation/pages/main_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add import for app_button.dart
old_imports = """import '../theme/app_design_tokens.dart';"""

new_imports = """import '../theme/app_design_tokens.dart';
import '../widgets/foundation/app_button.dart';"""

content = content.replace(old_imports, new_imports)

# 2. Replace FilledButton.icon with AppButton.primary
old_primary_btn = """              FilledButton.icon(
                onPressed: () {
                  // TODO: 打开浮动翻译窗口
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('打开浮动窗口'),
              ),"""

new_primary_btn = """              AppButton.primary(
                label: '打开浮动窗口',
                icon: const Icon(Icons.open_in_new),
                onPressed: () {
                  // TODO: 打开浮动翻译窗口
                },
                fullWidth: true,
              ),"""

content = content.replace(old_primary_btn, new_primary_btn)

# 3. Replace OutlinedButton.icon with AppButton.secondary
old_secondary_btn = """              OutlinedButton.icon(
                onPressed: () {
                  // TODO: 截图OCR翻译
                },
                icon: const Icon(Icons.screenshot),
                label: const Text('截图翻译'),
              ),"""

new_secondary_btn = """              AppButton.secondary(
                label: '截图翻译',
                icon: const Icon(Icons.screenshot),
                onPressed: () {
                  // TODO: 截图OCR翻译
                },
                fullWidth: true,
              ),"""

content = content.replace(old_secondary_btn, new_secondary_btn)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Migration complete!")
