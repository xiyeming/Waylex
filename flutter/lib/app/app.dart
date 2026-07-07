import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_translate/main.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../presentation/providers/theme_provider.dart';
import '../data/datasources/ffi_datasource.dart';

class FlutterTranslateApp extends ConsumerStatefulWidget {
  const FlutterTranslateApp({super.key});

  @override
  ConsumerState<FlutterTranslateApp> createState() => _FlutterTranslateAppState();
}

class _FlutterTranslateAppState extends ConsumerState<FlutterTranslateApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void onWindowResize() async {
    try {
      final size = await windowManager.getSize();
      final ffi = FfiDatasource();
      await ffi.saveWindowSize(size.width.toInt(), size.height.toInt());
    } catch (e) {
      debugPrint('保存窗口尺寸失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);
    return TrayApp(
      child: MaterialApp.router(
        title: 'Waylex',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(accent),
        darkTheme: AppTheme.dark(accent),
        themeMode: themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}
