import 'package:flutter/material.dart';
import '../../theme/app_design_tokens.dart';

/// 统一的开关/复选框/单选组件
///
/// 三种变体：
/// - [AppToggle.switch_] - 开关，用于启用/禁用
/// - [AppToggle.checkbox] - 复选框，用于多选
/// - [AppToggle.radio] - 单选框，用于单选
class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final ToggleVariant variant;
  final String? label;
  final String? description;

  const AppToggle.switch_({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
  }) : variant = ToggleVariant.switch_;

  const AppToggle.checkbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
  }) : variant = ToggleVariant.checkbox;

  const AppToggle.radio({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
  }) : variant = ToggleVariant.radio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (variant) {
      case ToggleVariant.switch_:
        return _buildSwitch(theme);
      case ToggleVariant.checkbox:
        return _buildCheckbox(theme);
      case ToggleVariant.radio:
        return _buildRadio(theme);
    }
  }

  Widget _buildCompactSwitch(ThemeData theme) {
    final trackWidth = AppTokens.switchTrackWidth;
    final trackHeight = AppTokens.switchTrackHeight;
    final thumbSize = AppTokens.switchThumbSize;
    final padding = (trackHeight - thumbSize) / 2;

    final isInteractive = onChanged != null;

    Color offTrack(Brightness b) =>
        b == Brightness.dark ? AppTokens.switchOffTrack : AppTokens.switchOffTrackLight;
    Color offHover(Brightness b) =>
        b == Brightness.dark ? AppTokens.switchOffHover : AppTokens.switchOffHoverLight;
    Color offThumb(Brightness b) =>
        b == Brightness.dark ? AppTokens.switchOffThumb : AppTokens.switchOffThumbLight;

    return _SwitchInteractable(
      enabled: isInteractive,
      builder: (hovered) {
        final trackColor = value
            ? (hovered
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : theme.colorScheme.primary.withValues(alpha: 0.3))
            : (hovered ? offHover(theme.brightness) : offTrack(theme.brightness));

        final thumbColor = value ? Colors.white : offThumb(theme.brightness);

        return GestureDetector(
          onTap: isInteractive ? () => onChanged!(!value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: trackWidth,
            height: trackHeight,
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(trackHeight),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.all(padding),
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: thumbColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitch(ThemeData theme) {
    if (label == null && description == null) {
      return _buildCompactSwitch(theme);
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: theme.textTheme.bodyMedium,
                ),
              if (description != null) ...[
                const SizedBox(height: AppTokens.space2),
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppTokens.space12),
        _buildCompactSwitch(theme),
      ],
    );
  }

  Widget _buildCheckbox(ThemeData theme) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: AppTokens.iconMd,
        height: AppTokens.iconMd,
        decoration: BoxDecoration(
          color: value ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusXs),
          border: Border.all(
            color: value ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          opacity: value ? 1.0 : 0.0,
          child: Icon(
            Icons.check,
            size: AppTokens.iconXs,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(ThemeData theme) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: AppTokens.iconMd,
        height: AppTokens.iconMd,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: value ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          scale: value ? 1.0 : 0.0,
          child: Container(
            margin: const EdgeInsets.all(AppTokens.space4),
            width: AppTokens.iconXs,
            height: AppTokens.iconXs,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchInteractable extends StatefulWidget {
  final bool enabled;
  final Widget Function(bool hovered) builder;

  const _SwitchInteractable({
    required this.enabled,
    required this.builder,
  });

  @override
  State<_SwitchInteractable> createState() => _SwitchInteractableState();
}

class _SwitchInteractableState extends State<_SwitchInteractable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.builder(false);
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(_hovered),
    );
  }
}

enum ToggleVariant { switch_, checkbox, radio }
