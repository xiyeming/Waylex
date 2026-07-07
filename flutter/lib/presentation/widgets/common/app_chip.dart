import 'package:flutter/material.dart';
import '../../theme/app_design_tokens.dart';

/// 统一的芯片/标签组件
class AppChip extends StatelessWidget {
  final String label;
  final Widget? avatar;
  final Widget? deleteIcon;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final bool selected;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? deleteColor;

  const AppChip({
    super.key,
    required this.label,
    this.avatar,
    this.deleteIcon,
    this.onDeleted,
    this.onTap,
    this.selected = false,
    this.backgroundColor,
    this.foregroundColor,
    this.deleteColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveBg = backgroundColor != null
        ? (selected ? theme.colorScheme.primary.withValues(alpha: 0.15) : backgroundColor)
        : (selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest);

    final effectiveFg = foregroundColor != null
        ? foregroundColor!
        : (selected ? theme.colorScheme.primary : theme.colorScheme.onSurface);

    final borderColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.3)
        : theme.colorScheme.outline.withValues(alpha: 0.5);

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (avatar != null) ...[
          avatar!,
          const SizedBox(width: AppTokens.space4),
        ],
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: effectiveFg),
        ),
        if (onDeleted != null) ...[
          const SizedBox(width: AppTokens.space4),
          InkWell(
            onTap: onDeleted,
            child: deleteIcon ??
                Icon(
                  Icons.close,
                  size: AppTokens.iconSm,
                  color: deleteColor ?? effectiveFg.withValues(alpha: 0.7),
                ),
          ),
        ],
      ],
    );

    if (onTap != null) {
      child = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          child: child,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space10, vertical: AppTokens.space6),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }
}
