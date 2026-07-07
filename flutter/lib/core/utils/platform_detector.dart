import 'dart:io';

/// 平台检测工具（仅限 Linux 平台使用）
class PlatformDetector {
  static bool get isLinux => Platform.isLinux;

  static String? _env(String key) {
    try {
      return Platform.environment[key];
    } on UnsupportedError {
      return null;
    }
  }

  static bool get isWayland => _env('WAYLAND_DISPLAY') != null;

  static String? get currentDesktop {
    return _env('XDG_CURRENT_DESKTOP');
  }

  static bool get isKde => currentDesktop?.toLowerCase().contains('kde') ?? false;
  static bool get isHyprland => currentDesktop?.toLowerCase().contains('hyprland') ?? false;
  static bool get isGnome => currentDesktop?.toLowerCase().contains('gnome') ?? false;
}
