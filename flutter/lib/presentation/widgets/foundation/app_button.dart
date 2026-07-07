import 'package:flutter/material.dart';
import '../../theme/app_design_tokens.dart';

/// 统一的按钮组件系统
///
/// 三种变体：
/// - [AppButton.primary] - 主要操作按钮
/// - [AppButton.secondary] - 次要操作按钮
/// - [AppButton.tertiary] - 三级操作按钮
class AppButton extends StatelessWidget {
  final String? label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final bool fullWidth;

  const AppButton.primary({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = ButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = ButtonVariant.secondary;

  const AppButton.tertiary({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = ButtonVariant.tertiary;

  const AppButton.danger({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = ButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color? border;
    Color fg;
    Color hoverBg;

    switch (variant) {
      case ButtonVariant.primary:
        bg = theme.colorScheme.primary;
        fg = theme.colorScheme.onPrimary;
        hoverBg = theme.colorScheme.primary.withValues(alpha: 0.85);
        break;
      case ButtonVariant.secondary:
        bg = theme.colorScheme.surfaceContainerHighest;
        border = theme.colorScheme.outline;
        fg = theme.colorScheme.onSurface;
        hoverBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);
        break;
      case ButtonVariant.tertiary:
        bg = Colors.transparent;
        fg = theme.colorScheme.onSurfaceVariant;
        hoverBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
        break;
      case ButtonVariant.danger:
        bg = AppTokens.error;
        fg = Colors.white;
        hoverBg = AppTokens.error.withValues(alpha: 0.85);
        break;
    }

    final disabledBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final disabledFg = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: AppTokens.iconMd,
        height: AppTokens.iconMd,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: variant == ButtonVariant.primary ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: AppTokens.space8)],
          if (label != null)
            Text(
              label!,
              style: TextStyle(fontSize: AppTokens.fontBody, fontWeight: FontWeight.w500),
            ),
        ],
      );
    }

    final button = _ButtonInteractable(
      onPressed: isEnabled ? onPressed : null,
      backgroundColor: isEnabled ? bg : disabledBg,
      hoverBackgroundColor: hoverBg,
      foregroundColor: isEnabled ? fg : disabledFg,
      border: border,
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
        child: SizedBox(
          height: AppTokens.buttonHeight,
          child: Center(child: content),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

class _ButtonInteractable extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color? hoverBackgroundColor;
  final Color foregroundColor;
  final Color? border;
  final BorderRadius borderRadius;
  final Widget child;

  const _ButtonInteractable({
    this.onPressed,
    required this.backgroundColor,
    this.hoverBackgroundColor,
    required this.foregroundColor,
    this.border,
    required this.borderRadius,
    required this.child,
  });

  @override
  State<_ButtonInteractable> createState() => _ButtonInteractableState();
}

class _ButtonInteractableState extends State<_ButtonInteractable> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = _pressed
        ? (widget.hoverBackgroundColor ?? widget.backgroundColor)
        : (_hovered ? (widget.hoverBackgroundColor ?? widget.backgroundColor) : widget.backgroundColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: widget.borderRadius,
            border: widget.border != null ? Border.all(color: widget.border!, width: 1) : null,
          ),
          child: DefaultTextStyle(
            style: TextStyle(color: widget.foregroundColor),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

enum ButtonVariant { primary, secondary, tertiary, danger }
