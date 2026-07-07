import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../presentation/theme/app_design_tokens.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, AccentColor>((ref) {
  return AccentColorNotifier();
});

class AccentColorNotifier extends StateNotifier<AccentColor> {
  AccentColorNotifier() : super(AppTokens.defaultAccent);

  void setAccent(AccentColor accent) {
    state = accent;
  }
}
