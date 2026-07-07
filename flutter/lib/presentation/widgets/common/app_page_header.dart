import 'package:flutter/material.dart';
import '../../theme/app_design_tokens.dart';

/// 统一的页面标题栏
///
/// 用于浮动窗口、对比页等，确保一致的标题视觉表现。
class AppPageHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  const AppPageHeader({
    super.key,
    required this.title,
    this.icon,
    this.actions,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12, vertical: AppTokens.space6),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: AppTokens.iconLg),
              tooltip: '返回',
              onPressed: onBack,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          if (icon != null) ...[
            Icon(icon, size: AppTokens.iconXl, color: theme.colorScheme.primary),
            const SizedBox(width: AppTokens.space8),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
