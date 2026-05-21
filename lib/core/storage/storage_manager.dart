import 'dart:convert';
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
  
  /// 泛型保存方法 - 支持任意可 JSON 序列化的对象
  Future<bool> save<T>(String key, T value) async {
    await _ensureInit();
    if (value is String) {
      return await _prefs!.setString(key, value);
    } else if (value is int) {
      return await _prefs!.setInt(key, value);
    } else if (value is bool) {
      return await _prefs!.setBool(key, value);
    } else if (value is List<String>) {
      return await _prefs!.setStringList(key, value);
    } else if (value is double) {
      return await _prefs!.setDouble(key, value);
    } else {
      // 其他类型尝试 JSON 序列化后存储
      final jsonStr = jsonEncode(value);
      return await _prefs!.setString(key, jsonStr);
    }
  }
  
  /// 泛型获取方法 - 支持任意可 JSON 反序列化的对象
  T? get<T>(String key, {T? defaultValue}) {
    if (_prefs == null) return defaultValue;
    
    dynamic result;
    if (T == String) {
      result = _prefs!.getString(key);
    } else if (T == int) {
      result = _prefs!.getInt(key);
    } else if (T == bool) {
      result = _prefs!.getBool(key);
    } else if (T == List<String>) {
      result = _prefs!.getStringList(key);
    } else if (T == double) {
      result = _prefs!.getDouble(key);
    } else {
      // 其他类型尝试从 JSON 反序列化
      final jsonStr = _prefs!.getString(key);
      if (jsonStr != null) {
        result = jsonDecode(jsonStr) as T;
      }
    }
    
    return result ?? defaultValue;
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
  
  /// 清空本应用的所有数据（不影响第三方插件数据）
  Future<bool> clear() async {
    await _ensureInit();
    final appKeys = _prefs!.getKeys().where(
      (key) => StorageKeys.allKeys.contains(key),
    );
    for (final key in appKeys) {
      await _prefs!.remove(key);
    }
    return true;
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
  
  /// 保存数据（任意类型）- 兼容旧代码调用
  Future<bool> saveData<T>(String key, T value) async {
    return await save(key, value);
  }

  /// 获取数据（任意类型）- 兼容旧代码调用
  T? getData<T>(String key, {T? defaultValue}) {
    return get<T>(key, defaultValue: defaultValue);
  }

  /// 删除数据 - 兼容旧代码调用
  Future<bool> deleteData(String key) async {
    return await remove(key);
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

  // 数据列表
  static const String postsList = 'posts_list';
  static const String notesList = 'notes_list';
  static const String videoProjectsList = 'video_projects_list';
  static const String foldersList = 'folders_list';

  // Hive Box 名称
  static const String postsBox = 'posts_box';
  static const String notesBox = 'notes_box';
  static const String videoProjectsBox = 'video_projects_box';
  static const String trashBox = 'trash_box';
  static const String foldersBox = 'folders_box';

  /// 所有应用级 key（用于安全清除）
  static const Set<String> allKeys = {
    isDarkMode,
    userId,
    userName,
    userToken,
    autoSaveEnabled,
    syncEnabled,
    recentProjects,
    recentNotes,
    postsList,
    notesList,
    videoProjectsList,
    foldersList,
  };
}
