import 'package:flutter/material.dart';
import '../../theme/app_design_tokens.dart';

/// 统一的输入框组件
///
/// Label 固定在输入框外部，更加桌面化。
/// 提供三种变体：
/// - [AppInput.text] - 单行文本输入
/// - [AppInput.multiline] - 多行文本输入
/// - [AppInput.dropdown] - 下拉选择
class AppInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? value;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? helperText;
  final bool obscureText;
  final bool readOnly;
  final int? maxLines;
  final InputVariant variant;
  final List<PopupMenuEntry<String>>? dropdownItems;
  final ValueChanged<String>? onDropdownSelected;

  const AppInput.text({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.value,
    this.onChanged,
    this.onClear,
    this.prefixIcon,
    this.suffixIcon,
    this.helperText,
    this.obscureText = false,
    this.readOnly = false,
  })  : variant = InputVariant.text,
        maxLines = 1,
        dropdownItems = null,
        onDropdownSelected = null;

  const AppInput.multiline({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.value,
    this.onChanged,
    this.onClear,
    this.prefixIcon,
    this.suffixIcon,
    this.helperText,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 4,
  })  : variant = InputVariant.multiline,
        dropdownItems = null,
        onDropdownSelected = null;

  const AppInput.dropdown({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.value,
    this.onDropdownSelected,
    this.prefixIcon,
    this.dropdownItems,
  })  : variant = InputVariant.dropdown,
        onChanged = null,
        onClear = null,
        obscureText = false,
        readOnly = true,
        maxLines = 1,
        suffixIcon = null,
        helperText = null;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _hovered = false;
  bool _focused = false;
  late final TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null &&
        widget.value != null &&
        widget.value != _internalController.text) {
      _internalController.text = widget.value!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  TextEditingController get _controller => widget.controller ?? _internalController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color _fillColor() {
      if (widget.variant == InputVariant.dropdown) {
        return theme.colorScheme.surfaceContainerHighest;
      }
      if (_focused) return isDark ? AppTokens.inputFocused : theme.colorScheme.surfaceContainerHighest;
      if (_hovered) return isDark ? AppTokens.surfaceHover : theme.colorScheme.surfaceContainerHighest;
      return isDark ? AppTokens.surfaceVariant : theme.colorScheme.surfaceContainerHighest;
    }

    Widget input;
    final borderRadius = BorderRadius.circular(AppTokens.radiusSm);

    final border = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
    );

    switch (widget.variant) {
      case InputVariant.text:
      case InputVariant.multiline:
        input = MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Focus(
            onFocusChange: (f) => setState(() => _focused = f),
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              obscureText: widget.obscureText,
              readOnly: widget.readOnly,
              maxLines: widget.maxLines,
              minLines: widget.maxLines != 1 ? widget.maxLines! ~/ 2 : null,
              decoration: InputDecoration(
                hintText: widget.hintText,
                helperText: widget.helperText,
                border: border,
                focusedBorder: focusedBorder,
                enabledBorder: border,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, size: AppTokens.iconMd, color: theme.colorScheme.onSurfaceVariant)
                    : null,
                suffixIcon: widget.suffixIcon != null
                    ? Padding(padding: const EdgeInsets.all(AppTokens.space8), child: widget.suffixIcon!)
                    : (widget.onClear != null && _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: AppTokens.iconLg),
                            onPressed: widget.onClear,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          )
                        : null),
                contentPadding: AppTokens.inputContentPadding,
                fillColor: _fillColor(),
              ),
            ),
          ),
        );
        break;
      case InputVariant.dropdown:
        final displayValue = widget.hintText ?? (widget.value ?? '请选择');
        input = Container(
          padding: AppTokens.inputContentPadding,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            border: Border.all(color: theme.colorScheme.outline, width: 1),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(widget.prefixIcon, size: AppTokens.iconMd, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppTokens.space8),
              ],
              Expanded(
                child: Text(
                  displayValue,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.value == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: AppTokens.iconLg,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        );
        break;
    }

    if (widget.label != null && widget.variant != InputVariant.dropdown) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space8),
            child: Text(
              widget.label!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          input,
        ],
      );
    }

    return input;
  }
}

enum InputVariant { text, multiline, dropdown }
