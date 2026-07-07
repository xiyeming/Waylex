import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/foundation/app_button.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waylex'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: '多厂商对比',
            onPressed: () {
              // TODO: 导航到对比页面
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              // TODO: 导航到设置页面
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.translate,
                size: AppTokens.iconDisplay,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppTokens.space16),
              Text(
                'AI 翻译工具',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTokens.space8),
              Text(
                '支持 OpenAI / DeepL / Google 多厂商翻译',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTokens.space32),
              AppButton.primary(
                label: '打开浮动窗口',
                icon: const Icon(Icons.open_in_new),
                onPressed: () {
                  // TODO: 打开浮动翻译窗口
                },
                fullWidth: true,
              ),
              const SizedBox(height: AppTokens.space12),
              AppButton.secondary(
                label: '截图翻译',
                icon: const Icon(Icons.screenshot),
                onPressed: () {
                  // TODO: 截图OCR翻译
                },
                fullWidth: true,
              ),
              const SizedBox(height: AppTokens.space24),
              Text(
                '快捷键: Super+Alt+F 翻译 | Ctrl+Shift+S 截图翻译',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
