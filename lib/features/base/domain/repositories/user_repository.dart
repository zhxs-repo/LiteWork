import '../../data/models/user_model.dart';

/// 用户仓库接口
abstract class UserRepository {
  /// 获取当前用户
  Future<User?> getCurrentUser();

  /// 创建或获取游客用户
  Future<User> getOrCreateGuestUser();

  /// 保存用户
  Future<void> saveUser(User user);

  /// 检查是否已登录
  Future<bool> isLoggedIn();

  /// 清除用户数据
  Future<void> clearUser();

  /// 判断是否为游客
  Future<bool> isGuest();
}
