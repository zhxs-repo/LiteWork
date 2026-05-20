import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/theme_notifier.dart';

/// 主题设置页面 - 支持亮色/暗色/跟随系统切换
class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final theme = Theme.of(context);

    final String selectedMode;
    switch (themeNotifier.themeMode) {
      case ThemeMode.light:
        selectedMode = 'light';
        break;
      case ThemeMode.dark:
        selectedMode = 'dark';
        break;
      case ThemeMode.system:
        selectedMode = 'system';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // 说明卡片
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.palette,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '选择您喜欢的主题模式',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 亮色模式：清爽明亮，适合白天使用\n'
                      '• 暗色模式：护眼舒适，适合夜间使用\n'
                      '• 跟随系统：自动匹配系统主题',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 主题选项列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '主题模式',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _buildThemeOption(
                        icon: Icons.light_mode,
                        title: '亮色模式',
                        subtitle: '清爽明亮的界面',
                        value: 'light',
                        groupValue: selectedMode,
                        onChanged: (mode) => _changeTheme(context, mode),
                        theme: theme,
                      ),
                      Divider(
                        height: 1,
                        indent: 72,
                        color: theme.dividerColor.withOpacity(0.5),
                      ),
                      _buildThemeOption(
                        icon: Icons.dark_mode,
                        title: '暗色模式',
                        subtitle: '护眼舒适的深色界面',
                        value: 'dark',
                        groupValue: selectedMode,
                        onChanged: (mode) => _changeTheme(context, mode),
                        theme: theme,
                      ),
                      Divider(
                        height: 1,
                        indent: 72,
                        color: theme.dividerColor.withOpacity(0.5),
                      ),
                      _buildThemeOption(
                        icon: Icons.brightness_auto,
                        title: '跟随系统',
                        subtitle: '自动匹配系统主题设置',
                        value: 'system',
                        groupValue: selectedMode,
                        onChanged: (mode) => _changeTheme(context, mode),
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 预览区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '效果预览',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // 模拟应用栏
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.menu,
                                  color: theme.colorScheme.onPrimaryContainer),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'LiteWork',
                                  style: TextStyle(
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(Icons.search,
                                  color: theme.colorScheme.onPrimaryContainer),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 模拟内容卡片
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 12,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 8,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _changeTheme(BuildContext context, String mode) async {
    final themeNotifier = context.read<ThemeNotifier>();
    final ThemeMode newMode;
    switch (mode) {
      case 'light':
        newMode = ThemeMode.light;
        break;
      case 'dark':
        newMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        newMode = ThemeMode.system;
        break;
    }

    await themeNotifier.setThemeMode(newMode);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getThemeModeText(mode)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  String _getThemeModeText(String mode) {
    switch (mode) {
      case 'light':
        return '已切换到亮色模式';
      case 'dark':
        return '已切换到暗色模式';
      case 'system':
        return '已设置为跟随系统';
      default:
        return '';
    }
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String> onChanged,
    required ThemeData theme,
  }) {
    final isSelected = value == groupValue;

    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: (v) => onChanged(v!),
      secondary: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      activeColor: theme.colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
