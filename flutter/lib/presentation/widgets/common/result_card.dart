import 'package:flutter/material.dart';
import 'package:flutter_translate/presentation/theme/app_design_tokens.dart';

/// 统一的翻译结果卡片
///
/// 用于 compare_page 和 floating_page，确保一致的视觉表现。
class AppResultCard extends StatelessWidget {
  final String providerName;
  final String text;
  final bool isError;
  final int? responseTimeMs;
  final int? totalTokens;
  final VoidCallback? onCopy;

  const AppResultCard({
    super.key,
    required this.providerName,
    required this.text,
    required this.isError,
    this.responseTimeMs,
    this.totalTokens,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isError
        ? theme.colorScheme.error.withValues(alpha: 0.3)
        : theme.colorScheme.primary.withValues(alpha: 0.2);

    return Container(
      margin: EdgeInsets.only(bottom: AppTokens.space12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppTokens.radius2Xl),
      ),
      padding: AppTokens.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle,
                size: AppTokens.iconSm,
                color: isError
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              SizedBox(width: AppTokens.space6),
              Text(
                providerName,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isError
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (responseTimeMs != null && responseTimeMs! > 0)
                _buildTimeBadge(theme, responseTimeMs!),
              if (totalTokens != null && totalTokens! > 0) ...[
                SizedBox(width: AppTokens.space4),
                Text(
                  '$totalTokens t',
                  style: TextStyle(
                    fontSize: AppTokens.fontXs,
                    color: AppTokens.textHint,
                  ),
                ),
              ],
              SizedBox(width: AppTokens.space2),
              if (onCopy != null)
                IconButton(
                  icon: Icon(Icons.copy, size: AppTokens.iconSm),
                  tooltip: '复制',
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                  onPressed: onCopy,
                ),
            ],
          ),
          SizedBox(height: AppTokens.space4),
          SelectableText(
            text,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBadge(ThemeData theme, int ms) {
    final color = ms < 500
        ? theme.colorScheme.primary
        : ms < 1000
            ? theme.colorScheme.tertiary
            : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Text(
        '${ms}ms',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
