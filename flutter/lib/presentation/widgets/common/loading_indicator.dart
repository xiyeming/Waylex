import 'package:flutter/material.dart';
import '../../theme/app_design_tokens.dart';

/// 统一的加载指示器组件
///
/// 提供全屏和行内两种模式，保持全应用一致的视觉风格。
class AppLoadingIndicator {
  AppLoadingIndicator._();

  /// 全屏加载遮罩（带可选提示文字）
  static Widget fullScreen({
    String? message,
    Color? backgroundColor,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppTokens.space16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: AppTokens.fontBase,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 全屏加载 Scaffold body
  static Widget scaffoldBody({String? message}) {
    return Scaffold(
      body: Center(
        child: fullScreen(message: message),
      ),
    );
  }

  /// 行内按钮加载（小尺寸，适配 FilledButton / OutlinedButton）
  static Widget inline({Color? color, double strokeWidth = 2}) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color,
      ),
    );
  }

  /// 行内按钮加载（白色，用于 FilledButton）
  static Widget inlineForFilledButton() {
    return inline(color: Colors.white, strokeWidth: 2);
  }

  /// 行内按钮加载（主题色，用于 OutlinedButton）
  static Widget inlineForOutlinedButton(BuildContext context) {
    final theme = Theme.of(context);
    return inline(color: theme.colorScheme.primary, strokeWidth: 2);
  }
}
