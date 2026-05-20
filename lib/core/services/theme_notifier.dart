import 'package:flutter/material.dart';
import '../storage/storage_manager.dart';

/// 主题模式通知器
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final storageManager = StorageManager();
    final isDarkMode = storageManager.getBool(StorageKeys.isDarkMode);
    _themeMode = isDarkMode == null
        ? ThemeMode.system
        : (isDarkMode ? ThemeMode.dark : ThemeMode.light);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final storageManager = StorageManager();

    switch (mode) {
      case ThemeMode.light:
        await storageManager.setBool(StorageKeys.isDarkMode, false);
        break;
      case ThemeMode.dark:
        await storageManager.setBool(StorageKeys.isDarkMode, true);
        break;
      case ThemeMode.system:
        await storageManager.remove(StorageKeys.isDarkMode);
        break;
    }

    notifyListeners();
  }
}
