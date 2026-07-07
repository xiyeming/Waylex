import 'package:flutter/material.dart';
import '../../theme/app_design_tokens.dart';

/// 统一的分隔线组件
///
/// 提供两种变体：
/// - [AppDivider.subtle] - 细微分隔线，用于卡片内部、列表项之间
/// - [AppDivider.bold] - 粗分隔线，用于 major section 之间
class AppDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final EdgeInsetsGeometry? margin;
  final double? indent;
  final double? endIndent;

  const AppDivider.subtle({
    super.key,
    this.height,
    this.thickness,
    this.margin,
    this.indent,
    this.endIndent,
  }) : super();

  const AppDivider.bold({
    super.key,
    this.height,
    this.thickness,
    this.margin,
    this.indent,
    this.endIndent,
  }) : super();

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? (thickness == null ? AppTokens.space8 : null);
    final effectiveThickness = thickness ?? (height == null ? 1 : null);

    return Divider(
      height: effectiveHeight,
      thickness: effectiveThickness,
      indent: indent,
      endIndent: endIndent,
      color: AppTokens.divider,
    );
  }
}
