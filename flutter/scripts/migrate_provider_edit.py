#!/usr/bin/env python3
"""Migrate provider_edit_page.dart to use unified components."""

import re

file_path = '/home/xiyeming/Projects/RustProjects/Waylex/flutter/lib/presentation/pages/provider_edit_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports for new components
old_imports = """import '../../data/models/provider_config.dart';
import '../../data/datasources/ffi_datasource.dart';
import '../widgets/common/loading_indicator.dart';
import '../theme/app_design_tokens.dart';"""

new_imports = """import '../../data/models/provider_config.dart';
import '../../data/datasources/ffi_datasource.dart';
import '../widgets/common/loading_indicator.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/foundation/app_input.dart';
import '../widgets/foundation/app_toggle.dart';
import '../widgets/foundation/app_button.dart';
import '../widgets/common/app_card.dart';"""

content = content.replace(old_imports, new_imports)

# 2. Replace Name field
old_name = """              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '例如: OpenAI, DeepL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? '请输入名称' : null,
              ),
              const SizedBox(height: AppTokens.space16),"""

new_name = """              AppInput.text(
                label: '名称',
                hintText: '例如: OpenAI, DeepL',
                value: _nameController.text,
                onChanged: (v) => _nameController.text = v,
                prefixIcon: Icons.label,
                onClear: () => _nameController.clear(),
              ),
              const SizedBox(height: AppTokens.space16),"""

content = content.replace(old_name, new_name)

# 3. Replace API Key field (with obscure text toggle)
old_api_key = """              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: '输入 API 密钥',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_obscureApiKey ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                        tooltip: _obscureApiKey ? '显示' : '隐藏',
                      ),
                    ],
                  ),
                ),
                obscureText: _obscureApiKey,
              ),
              const SizedBox(height: AppTokens.space16),"""

new_api_key = """              AppInput.text(
                label: 'API Key',
                hintText: '输入 API 密钥',
                value: _apiKeyController.text,
                onChanged: (v) => _apiKeyController.text = v,
                prefixIcon: Icons.key,
                obscureText: _obscureApiKey,
                suffixIcon: _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                onClear: () => _apiKeyController.clear(),
              ),
              const SizedBox(height: AppTokens.space16),"""

content = content.replace(old_api_key, new_api_key)

# 4. Replace Base URL field
old_base_url = """              TextFormField(
                controller: _baseUrlController,
                decoration: InputDecoration(
                  labelText: 'Base URL',
                  hintText: _isNew
                      ? '例如: https://api.openai.com/v1'
                      : '留空使用默认地址',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                  helperText: '仅填写 Base URL，接口路径会自动拼接',
                ),
              ),
              const SizedBox(height: AppTokens.space16),"""

new_base_url = """              AppInput.text(
                label: 'Base URL',
                hintText: _isNew
                    ? '例如: https://api.openai.com/v1'
                    : '留空使用默认地址',
                value: _baseUrlController.text,
                onChanged: (v) => _baseUrlController.text = v,
                prefixIcon: Icons.link,
                helperText: '仅填写 Base URL，接口路径会自动拼接',
              ),
              const SizedBox(height: AppTokens.space16),"""

content = content.replace(old_base_url, new_base_url)

# 5. Replace Model field
old_model = """              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: '模型',
                  hintText: '例如: gpt-4o-mini, deepseek-chat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.smart_toy),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? '请输入模型名称' : null,
              ),
              const SizedBox(height: AppTokens.space16),"""

new_model = """              AppInput.text(
                label: '模型',
                hintText: '例如: gpt-4o-mini, deepseek-chat',
                value: _modelController.text,
                onChanged: (v) => _modelController.text = v,
                prefixIcon: Icons.smart_toy,
              ),
              const SizedBox(height: AppTokens.space16),"""

content = content.replace(old_model, new_model)

# 6. Replace System Prompt field (multiline)
old_system_prompt = """              TextFormField(
                controller: _systemPromptController,
                decoration: const InputDecoration(
                  labelText: '系统提示词 (可选)',
                  hintText: '留空使用默认: You are a translation engine...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.chat),
                  alignLabelWithHint: true,
                  helperText: '默认会强制模型只输出翻译结果，不进行对话',
                ),
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: AppTokens.space16),"""

new_system_prompt = """              AppInput.multiline(
                label: '系统提示词 (可选)',
                hintText: '留空使用默认: You are a translation engine...',
                value: _systemPromptController.text,
                onChanged: (v) => _systemPromptController.text = v,
                prefixIcon: Icons.chat,
                maxLines: 5,
                helperText: '默认会强制模型只输出翻译结果，不进行对话',
              ),
              const SizedBox(height: AppTokens.space16),"""

content = content.replace(old_system_prompt, new_system_prompt)

# 7. Replace SwitchListTile with AppToggle.switch_
old_switch = """              SwitchListTile(
                title: const Text('启用此厂商'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: AppTokens.space24),"""

new_switch = """              AppToggle.switch_(
                label: '启用此厂商',
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: AppTokens.space24),"""

content = content.replace(old_switch, new_switch)

# 8. Replace FilledButton.icon with AppButton.primary
old_save_btn = """              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? AppLoadingIndicator.inlineForFilledButton()
                    : const Icon(Icons.save),
                label: Text(_isSaving ? '保存中...' : '保存'),
              ),
              const SizedBox(height: AppTokens.space16),"""

new_save_btn = """              AppButton.primary(
                label: _isSaving ? '保存中...' : '保存',
                icon: _isSaving
                    ? AppLoadingIndicator.inlineForFilledButton()
                    : const Icon(Icons.save),
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
                fullWidth: true,
              ),
              const SizedBox(height: AppTokens.space16),"""

content = content.replace(old_save_btn, new_save_btn)

# 9. Replace OutlinedButton.icon with AppButton.secondary
old_test_btn = """              OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? AppLoadingIndicator.inlineForOutlinedButton(context)
                    : const Icon(Icons.wifi_find),
                label: Text(_isTesting ? '测试中...' : '测试连接'),
              ),"""

new_test_btn = """              AppButton.secondary(
                label: _isTesting ? '测试中...' : '测试连接',
                icon: _isTesting
                    ? AppLoadingIndicator.inlineForOutlinedButton(context)
                    : const Icon(Icons.wifi_find),
                onPressed: _isTesting ? null : _testConnection,
                isLoading: _isTesting,
                fullWidth: true,
              ),"""

content = content.replace(old_test_btn, new_test_btn)

# 10. Replace test result Container with AppCard.surface
old_test_result = """              if (_testResult != null) ...[
                const SizedBox(height: AppTokens.space8),
                Container(
                  padding: AppTokens.cardPadding,
                  decoration: BoxDecoration(
                    color: _testSuccess
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    border: Border.all(
                      color: _testSuccess ? theme.colorScheme.primary : theme.colorScheme.error,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_testSuccess ? Icons.check_circle : Icons.error,
                          color: _testSuccess ? theme.colorScheme.primary : theme.colorScheme.error, size: AppTokens.iconXl),
                      const SizedBox(width: 8),
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
              ],"""

new_test_result = """              if (_testResult != null) ...[
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
              ],"""

content = content.replace(old_test_result, new_test_result)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Migration complete!")
