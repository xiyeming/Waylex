#!/usr/bin/env python3
"""Migrate floating_page.dart to use AppDropdown and AppChip."""

file_path = '/home/xiyeming/Projects/RustProjects/Waylex/flutter/lib/presentation/pages/floating_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports for AppDropdown and AppChip
old_imports = """import '../widgets/common/app_divider.dart';"""

new_imports = """import '../widgets/common/app_divider.dart';
import '../widgets/common/app_dropdown.dart';
import '../widgets/common/app_chip.dart';"""

content = content.replace(old_imports, new_imports)

# 2. Replace _buildCompactDropdown method with AppDropdown usage
# First, replace the _buildLanguageBar to use AppDropdown
old_language_bar = '''  Widget _buildLanguageBar(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactDropdown<String>(
            label: '源语言',
            value: _sourceLang,
            icon: Icon(
              Icons.language,
              size: AppTokens.iconSm,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            items: _languages.entries
                .where((e) => e.key != _targetLang)
                .map(
                  (e) => PopupMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: AppTokens.fontMd)),
                  ),
                )
                .toList(),
            onSelected: (v) {
              if (v != null) setState(() => _sourceLang = v);
            },
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
          child: _buildCompactDropdown<String>(
            label: '目标语言',
            value: _targetLang,
            icon: Icon(
              Icons.translate,
              size: AppTokens.iconSm,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            items: _languages.entries
                .where((e) => e.key != 'auto' && e.key != _sourceLang)
                .map(
                  (e) => PopupMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: AppTokens.fontMd)),
                  ),
                )
                .toList(),
            onSelected: (v) {
              if (v != null) setState(() => _targetLang = v);
            },
          ),
        ),
      ],
    );
  }'''

new_language_bar = '''  Widget _buildLanguageBar(ThemeData theme) {
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
  }'''

content = content.replace(old_language_bar, new_language_bar)

# 3. Replace _buildPromptSelector's Container with AppDropdown
# The _buildPromptSelector has a complex structure with inner PopupMenuButton
# We need to replace the outer Container with AppDropdown
# First, let's find the prompt selector method and replace it

old_prompt_selector = '''  Widget _buildPromptSelector(ThemeData theme) {
    final hasActive =
        _activePromptId != null && _activePromptId != '__default__';
    final selectedName = hasActive
        ? _promptTemplates
              .where((t) => t.id == _activePromptId)
              .firstOrNull
              ?.name
        : null;
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
    return Container(
      height: AppTokens.dropdownHeight,
      decoration: BoxDecoration(
        border: Border.all(
          color: hasActive
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
            child: Icon(
              Icons.auto_awesome,
              size: AppTokens.iconSm,
              color: hasActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: PopupMenuButton<String>(
              offset: const Offset(0, AppTokens.dropdownHeight),
              position: PopupMenuPosition.under,
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
              itemBuilder: (_) => items,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  selectedName ?? '使用厂商默认提示词',
                  style: TextStyle(
                    fontSize: AppTokens.fontMd,
                    color: selectedName != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: AppTokens.iconLg),
            tooltip: '管理',
            visualDensity: VisualDensity.compact,
            onPressed: () => _showPromptManager(),
          ),
        ],
      ),
    );
  }'''

new_prompt_selector = '''  Widget _buildPromptSelector(ThemeData theme) {
    final hasActive =
        _activePromptId != null && _activePromptId != '__default__';
    final selectedName = hasActive
        ? _promptTemplates
              .where((t) => t.id == _activePromptId)
              .firstOrNull
              ?.name
        : null;
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
      suffixIcon: Icons.add_circle_outline,
    );
  }'''

content = content.replace(old_prompt_selector, new_prompt_selector)

# 4. Replace _buildProviderChips to use AppChip
old_provider_chips = '''  Widget _buildProviderChips(ThemeData theme) {
    return Wrap(
      spacing: AppTokens.space6,
      runSpacing: AppTokens.space4,
      children: [
        ..._selectedProviders.map(
          (id) => Chip(
            label: Text(
              _providers[id] ?? id,
              style: theme.textTheme.labelSmall,
            ),
            deleteIcon: const Icon(Icons.close, size: AppTokens.iconSm),
            onDeleted: _selectedProviders.length > 1
                ? () => setState(() {
                    _selectedProviders.remove(id);
                    _results.remove(id);
                  })
                : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        ActionChip(
          avatar: Icon(
            _providerPanelOpen ? Icons.expand_less : Icons.expand_more,
            size: AppTokens.iconMd,
          ),
          label: Text(
            _providerPanelOpen ? '收起' : '选择厂商',
            style: theme.textTheme.labelSmall,
          ),
          onPressed: () =>
              setState(() => _providerPanelOpen = !_providerPanelOpen),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }'''

new_provider_chips = '''  Widget _buildProviderChips(ThemeData theme) {
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
  }'''

content = content.replace(old_provider_chips, new_provider_chips)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("floating_page.dart migration complete!")
