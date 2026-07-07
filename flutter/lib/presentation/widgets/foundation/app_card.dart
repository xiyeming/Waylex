import 'package:flutter/material.dart';
import '../../theme/app_design_tokens.dart';

/// 统一的卡片组件系统
///
/// 三种变体：
/// - [AppCard.primary] - 主要卡片，带边框
/// - [AppCard.surface] - 表面卡片，使用 surface 背景
/// - [AppCard.interactive] - 可交互卡片，支持 hover/press 反馈
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool interactive;
  final Color? borderColor;
  final Color? backgroundColor;

  const AppCard.primary({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
  }) : interactive = false;

  const AppCard.surface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
  }) : interactive = false;

  const AppCard.interactive({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
  }) : interactive = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding = padding ?? AppTokens.cardPadding;
    final effectiveMargin = margin ?? const EdgeInsets.only(bottom: AppTokens.space12);

    final effectiveBg = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final effectiveBorder = borderColor ?? theme.colorScheme.outline;
    final borderRadius = BorderRadius.circular(AppTokens.radiusMd);

    final card = Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: borderRadius,
        border: Border.all(color: effectiveBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: effectivePadding, child: child),
        ),
      ),
    );

    if (onTap != null || interactive) {
      return _InteractiveCardWrapper(child: card);
    }

    return card;
  }
}

class _InteractiveCardWrapperState extends _InteractiveCardWrapperStateBase {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppTokens.cardShadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _InteractiveCardWrapper extends StatefulWidget {
  final Widget child;

  const _InteractiveCardWrapper({required this.child});

  @override
  State<_InteractiveCardWrapper> createState() => _InteractiveCardWrapperState();
}

abstract class _InteractiveCardWrapperStateBase extends State<_InteractiveCardWrapper> {
  bool _hovered = false;
  bool _pressed = false;
}
