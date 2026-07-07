import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../theme/app_design_tokens.dart';

/// Wayland 可拖动浮动窗口组件
///
/// 提供无边框窗口的拖动功能，通过 window_manager 与系统窗口管理器通信。
/// 在 Wayland 下使用 xdg-shell 协议进行窗口定位。
class FloatingWindow extends StatefulWidget {
  /// 窗口内容
  final Widget child;

  /// 拖动区域高度（默认 32px）
  final double dragHeight;

  /// 窗口最小宽度
  final double minWidth;

  /// 窗口最小高度
  final double minHeight;

  const FloatingWindow({
    super.key,
    required this.child,
    this.dragHeight = 32,
    this.minWidth = 300,
    this.minHeight = 200,
  });

  @override
  State<FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<FloatingWindow> {
  bool _isDragging = false;
  Offset? _dragStartPosition;
  Offset? _windowStartPosition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(
        onPanStart: (details) {
          _isDragging = true;
          _dragStartPosition = details.globalPosition;
          _startWindowPositionCapture();
        },
        onPanUpdate: (details) {
          if (!_isDragging || _dragStartPosition == null) return;
          final delta = details.globalPosition - _dragStartPosition!;
          _moveWindow(delta);
        },
        onPanEnd: (_) {
          _isDragging = false;
          _dragStartPosition = null;
          _windowStartPosition = null;
        },
        child: Column(
          children: [
            // 拖动区域
            _DragHandle(
              height: widget.dragHeight,
              onDoubleTap: () => windowManager.minimize(),
              child: Row(
                children: [
                  // 窗口控制按钮
                  _WindowButton(
                    icon: Icons.remove,
                    color: theme.colorScheme.onSurfaceVariant,
                    onTap: () => windowManager.minimize(),
                  ),
                  _WindowButton(
                    icon: Icons.close,
                    color: theme.colorScheme.error,
                    onTap: () => windowManager.close(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // 内容区域
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }

  Future<void> _startWindowPositionCapture() async {
    try {
      _windowStartPosition = await windowManager.getPosition();
    } catch (e) {
      debugPrint('[floating_window] getPosition failed: $e');
      _windowStartPosition = Offset.zero;
    }
  }

  Future<void> _moveWindow(Offset delta) async {
    if (_windowStartPosition == null) return;
    final newPosition = _windowStartPosition! + delta;
    try {
      await windowManager.setPosition(newPosition);
    } catch (e) {
      debugPrint('[floating_window] setPosition failed: $e');
    }
  }
}

/// 拖动把手组件
class _DragHandle extends StatelessWidget {
  final double height;
  final VoidCallback? onDoubleTap;
  final Widget child;

  const _DragHandle({
    required this.height,
    this.onDoubleTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
          child: child,
        ),
      ),
    );
  }
}

/// 窗口控制按钮
class _WindowButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WindowButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Icon(icon, size: AppTokens.iconXs, color: color),
      ),
    );
  }
}
