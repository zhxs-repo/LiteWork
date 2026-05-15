import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储管理器 - SharedPreferences 封装
class StorageManager {
  static final StorageManager _instance = StorageManager._internal();
  
  factory StorageManager() {
    return _instance;
  }
  
  StorageManager._internal();
  
  SharedPreferences? _prefs;
  
  /// 初始化存储
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// 保存字符串
  Future<bool> setString(String key, String value) async {
    await _ensureInit();
    return await _prefs!.setString(key, value);
  }
  
  /// 获取字符串
  String? getString(String key, {String? defaultValue}) {
    return _prefs?.getString(key) ?? defaultValue;
  }
  
  /// 保存整数
  Future<bool> setInt(String key, int value) async {
    await _ensureInit();
    return await _prefs!.setInt(key, value);
  }
  
  /// 获取整数
  int? getInt(String key, {int? defaultValue}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }
  
  /// 保存布尔值
  Future<bool> setBool(String key, bool value) async {
    await _ensureInit();
    return await _prefs!.setBool(key, value);
  }
  
  /// 获取布尔值
  bool? getBool(String key, {bool? defaultValue}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }
  
  /// 保存字符串列表
  Future<bool> setStringList(String key, List<String> value) async {
    await _ensureInit();
    return await _prefs!.setStringList(key, value);
  }
  
  /// 获取字符串列表
  List<String>? getStringList(String key, {List<String>? defaultValue}) {
    return _prefs?.getStringList(key) ?? defaultValue;
  }
  
  /// 删除键
  Future<bool> remove(String key) async {
    await _ensureInit();
    return await _prefs!.remove(key);
  }
  
  /// 清空所有数据
  Future<bool> clear() async {
    await _ensureInit();
    return await _prefs!.clear();
  }
  
  /// 检查是否包含某个键
  bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }
  
  /// 获取所有键
  Set<String> getKeys() {
    return _prefs?.getKeys() ?? {};
  }
  
  /// 确保已初始化
  Future<void> _ensureInit() async {
    if (_prefs == null) {
      await init();
    }
  }
}

/// 存储键常量
class StorageKeys {
  // 主题相关
  static const String isDarkMode = 'is_dark_mode';
  
  // 用户相关
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userToken = 'user_token';
  
  // 设置相关
  static const String autoSaveEnabled = 'auto_save_enabled';
  static const String syncEnabled = 'sync_enabled';
  
  // 最近使用
  static const String recentProjects = 'recent_projects';
  static const String recentNotes = 'recent_notes';
}
