import 'package:flutter/material.dart';

/// Waylex Design System
///
/// 7-layer surface hierarchy, accent system, semantic colors.
/// Target: Modern AI Desktop (Cursor / Raycast / Cherry Studio)
class AppTokens {
  AppTokens._();

  // ========== 间距（8dp Grid） ==========
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // ========== 字体 ==========
  static const double fontXs = 10;
  static const double fontSm = 12;
  static const double fontMd = 13;
  static const double fontBase = 14;
  static const double fontLg = 16;
  static const double fontXl = 20;

  // 兼容旧命名
  static const double fontCaption = 13;
  static const double fontBody = 14;
  static const double fontTitleSm = 16;
  static const double fontTitleMd = 18;
  static const double fontTitleLg = 22;

  // ========== 图标 ==========
  static const double iconXs = 10;
  static const double iconSm = 14;
  static const double iconMd = 18;
  static const double iconLg = 20;
  static const double iconXl = 22;

  // 兼容旧命名
  static const double iconDisplay = 48;

  // ========== 圆角（仅三档） ==========
  static const double radiusXs = 2;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;

  // 兼容旧命名
  static const double radiusXl = 12;
  static const double radius2Xl = 16;

  // ========== 组件尺寸 ==========
  static const double inputHeight = 48;
  static const double buttonHeight = 46;
  static const double menuItemHeight = 42;
  static const double listItemHeight = 52;
  static const double switchTrackHeight = 28;
  static const double switchTrackWidth = 48;
  static const double switchThumbSize = 22;

  // ========== 暗色主题色板（单一数据源） ==========
  static const Color background = Color(0xFF18181F);

  static const Color surface = Color(0xFF22232B);

  static const Color surfaceVariant = Color(0xFF292A33);

  static const Color surfaceHover = Color(0xFF30313B);

  static const Color surfacePressed = Color(0xFF383944);

  static const Color surfaceSelected = Color(0x1A9F9BFF);

  static const Color inputFocused = Color(0xFF292B37);

  static const Color primary = Color(0xFF9F9BFF);

  static const Color primaryHover = Color(0xFFB8B3FF);

  static const Color primaryPressed = Color(0xFF8D86F8);

  static const Color success = Color(0xFF48D597);

  static const Color warning = Color(0xFFF7B955);

  static const Color error = Color(0xFFFF6A6A);

  static const Color info = Color(0xFF54A8FF);

  static const Color ai = Color(0xFFB48CFF);

  static const Color border = Color(0xFF31323C);

  static const Color divider = Color(0x0DFFFFFF);

  static const Color textPrimary = Color(0xFFF7F8FA);

  static const Color textSecondary = Color(0xFFA6A8B8);

  static const Color textHint = Color(0xFF7A7D8A);

  static const Color textDisabled = Color(0xFF646675);

  static const Color switchOffThumb = Color(0xFF9A9AAA);

  static const Color switchOffThumbLight = Color(0xFF9E9E9E);

  static const Color switchOffTrack = Color(0xFF3A3B45);

  static const Color switchOffTrackLight = Color(0xFFE0E0E5);

  static const Color switchOffHover = Color(0xFF3E3F4A);

  static const Color switchOffHoverLight = Color(0xFFEAEAEF);

  // ========== Provider 品牌色 ==========
  static const Color providerOpenai = Color(0xFF10A37F);

  static const Color providerClaude = Color(0xFFD97757);

  static const Color providerGemini = Color(0xFF4F8EF7);

  static const Color providerQwen = Color(0xFF8B7DFF);

  static const Color providerDeepl = Color(0xFF0F6FFF);

  static const Color providerGoogle = Color(0xFF4285F4);

  static const Color providerOllama = Color(0xFF7C8CFF);

  static const Color providerLmstudio = Color(0xFFA97BFF);

  // ========== 效果 ==========
  static const Color focusRing = Color(0x1A9F9BFF);

  static const Color cardShadow = Color(0x33000000);

  static const Color menuShadow = Color(0x59000000);

  static const Color overlayWeak = Color(0x33000000);

  static const Color overlayMedium = Color(0x66000000);

  static const Color overlayStrong = Color(0x99000000);

  // ========== Accent 主题 ==========
  static const AccentColor defaultAccent = AccentColor.violet;

  // ========== 便捷 EdgeInsets ==========
  static const EdgeInsets pagePadding = EdgeInsets.all(space16);

  static const EdgeInsets cardPadding = EdgeInsets.all(space16);

  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(space12);

  static const EdgeInsets inputContentPadding = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space12,
  );

  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: space8,
    vertical: space4,
  );

  static const EdgeInsets shortcutBadgePadding = EdgeInsets.symmetric(
    horizontal: space12,
    vertical: space6,
  );

  static const EdgeInsets sheetHandlePadding = EdgeInsets.symmetric(
    horizontal: space8,
  );
}

/// Accent color presets for theme switching.
class AccentColor {
  final String name;
  final Color value;
  final Color hover;
  final Color pressed;
  final Color container;

  const AccentColor({
    required this.name,
    required this.value,
    required this.hover,
    required this.pressed,
    required this.container,
  });

  static const violet = AccentColor(
    name: '紫罗兰',
    value: Color(0xFF9F9BFF),
    hover: Color(0xFFB8B3FF),
    pressed: Color(0xFF8D86F8),
    container: Color(0x1A9F9BFF),
  );

  static const blue = AccentColor(
    name: '天空蓝',
    value: Color(0xFF66A3FF),
    hover: Color(0xFF7DB3FF),
    pressed: Color(0xFF5A94F5),
    container: Color(0x1A66A3FF),
  );

  static const cyan = AccentColor(
    name: '青蓝',
    value: Color(0xFF47C5FF),
    hover: Color(0xFF65D0FF),
    pressed: Color(0xFF3DB8F5),
    container: Color(0x1A47C5FF),
  );

  static const emerald = AccentColor(
    name: '翡翠',
    value: Color(0xFF41D39E),
    hover: Color(0xFF5DE0B0),
    pressed: Color(0xFF35BF8F),
    container: Color(0x1A41D39E),
  );

  static const orange = AccentColor(
    name: '橙',
    value: Color(0xFFFFAF52),
    hover: Color(0xFFFFBF70),
    pressed: Color(0xFFF5A040),
    container: Color(0x1AFFAF52),
  );

  static const rose = AccentColor(
    name: '玫瑰',
    value: Color(0xFFFF7FAF),
    hover: Color(0xFFFF90C0),
    pressed: Color(0xFFF5709A),
    container: Color(0x1AFF7FAF),
  );

  static const all = <AccentColor>[
    violet,
    blue,
    cyan,
    emerald,
    orange,
    rose,
  ];
}
