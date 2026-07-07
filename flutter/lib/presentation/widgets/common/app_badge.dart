import 'package:flutter/material.dart';
import '../../theme/app_design_tokens.dart';

/// 统一的徽章/标签组件
///
/// 用于显示快捷键、状态标签等小型信息标记
class AppBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;

  const AppBadge({
    super.key,
    required this.text,
    this.icon,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBg = backgroundColor ?? theme.colorScheme.primaryContainer;
    final effectiveBorder = borderColor ?? theme.colorScheme.primary.withValues(alpha: 0.2);
    final effectiveText = textColor ?? theme.colorScheme.onPrimaryContainer;
    final effectiveIcon = iconColor ?? theme.colorScheme.onSurfaceVariant;

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            fontFamily: 'monospace',
            color: effectiveText,
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: AppTokens.space4),
          Icon(icon, size: AppTokens.iconMd, color: effectiveIcon),
        ],
      ],
    );

    if (onTap != null) {
      child = GestureDetector(onTap: onTap, child: child);
    }

    return Container(
      padding: AppTokens.shortcutBadgePadding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: effectiveBorder),
      ),
      child: child,
    );
  }
}
