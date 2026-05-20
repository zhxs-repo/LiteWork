import 'dart:convert';
import '../../../../core/storage/storage_manager.dart';
import '../models/user_model.dart';

/// 用户本地数据源
class UserLocalDataSource {
  final StorageManager _storageManager;

  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  UserLocalDataSource({required StorageManager storageManager})
      : _storageManager = storageManager;

  /// 获取当前用户
  Future<User?> getCurrentUser() async {
    final userJson = await _storageManager.getString(_userKey);
    if (userJson == null) return null;
    
    try {
      final Map<String, dynamic> jsonMap = json.decode(userJson);
      return User.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// 保存用户
  Future<void> saveUser(User user) async {
    await _storageManager.setString(_userKey, json.encode(user.toJson()));
    await _storageManager.setBool(_isLoggedInKey, true);
  }

  /// 创建或获取游客用户
  Future<User> getOrCreateGuestUser() async {
    final existingUser = await getCurrentUser();
    if (existingUser != null && existingUser.isGuest) {
      return existingUser;
    }
    
    final guestUser = User.guest();
    await saveUser(guestUser);
    return guestUser;
  }

  /// 检查是否已登录（包括游客）
  Future<bool> isLoggedIn() async {
    return await _storageManager.getBool(_isLoggedInKey) ?? false;
  }

  /// 清除用户数据（退出登录）
  Future<void> clearUser() async {
    await _storageManager.remove(_userKey);
    await _storageManager.setBool(_isLoggedInKey, false);
  }

  /// 判断是否为游客
  Future<bool> isGuest() async {
    final user = await getCurrentUser();
    return user?.isGuest ?? true;
  }
}
