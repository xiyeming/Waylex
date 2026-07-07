import 'package:flutter/material.dart';
import '../../theme/app_design_tokens.dart';

/// 统一的下拉选择组件
///
/// 桌面风格菜单，自定义 Popup 外观。
class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T?> onSelected;
  final Widget? icon;
  final Widget? suffixIcon;
  final Widget? suffixAction;
  final bool isActive;
  final Color? activeBorderColor;

  const AppDropdown({
    super.key,
    this.label,
    this.value,
    required this.items,
    required this.onSelected,
    this.icon,
    this.suffixIcon,
    this.suffixAction,
    this.isActive = false,
    this.activeBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = label ?? (value?.toString() ?? '请选择');

    final borderColor = isActive
        ? (activeBorderColor ?? theme.colorScheme.primary)
        : theme.colorScheme.outline;

    return PopupMenuButton<T>(
      offset: const Offset(0, AppTokens.space4),
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: Container(
        height: AppTokens.inputHeight,
        padding: AppTokens.inputContentPadding,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: AppTokens.space8),
            ],
            Expanded(
              child: Text(
                displayValue,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: value == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (suffixAction != null)
              suffixAction!
            else if (suffixIcon != null)
              suffixIcon!
            else
              Icon(
                Icons.arrow_drop_down,
                size: AppTokens.iconLg,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
