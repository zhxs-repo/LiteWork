import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../domain/usecases/user_usecases.dart';

/// 用户状态枚举
enum UserStatus {
  unknown,      // 未知状态（初始化中）
  guest,        // 游客模式
  logged,       // 已登录
  unauthenticated, // 未认证
}

/// 用户 ViewModel (Provider)
class UserProvider extends ChangeNotifier {
  final GetOrCreateGuestUser _getOrCreateGuestUser;
  final GetCurrentUser _getCurrentUser;
  final LogoutUser _logoutUser;
  final CheckIsLoggedIn _checkIsLoggedIn;
  final CheckIsGuest _checkIsGuest;

  User? _currentUser;
  UserStatus _status = UserStatus.unknown;

  UserProvider({
    required GetOrCreateGuestUser getOrCreateGuestUser,
    required GetCurrentUser getCurrentUser,
    required LogoutUser logoutUser,
    required CheckIsLoggedIn checkIsLoggedIn,
    required CheckIsGuest checkIsGuest,
  })  : _getOrCreateGuestUser = getOrCreateGuestUser,
        _getCurrentUser = getCurrentUser,
        _logoutUser = logoutUser,
        _checkIsLoggedIn = checkIsLoggedIn,
        _checkIsGuest = checkIsGuest;

  /// 获取当前用户
  User? get currentUser => _currentUser;

  /// 获取用户状态
  UserStatus get status => _status;

  /// 是否为游客
  bool get isGuest => _currentUser?.isGuest ?? true;

  /// 是否已登录（包括游客）
  bool get isLoggedIn => _status == UserStatus.guest || _status == UserStatus.logged;

  /// 初始化用户状态
  Future<void> initialize() async {
    try {
      _status = UserStatus.unknown;
      notifyListeners();

      final user = await _getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _status = user.isGuest ? UserStatus.guest : UserStatus.logged;
      } else {
        // 如果没有用户，自动创建游客用户
        await createGuestUser();
        return;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('初始化用户失败：$e');
      _status = UserStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// 创建或获取游客用户
  Future<void> createGuestUser() async {
    try {
      _status = UserStatus.unknown;
      notifyListeners();

      final user = await _getOrCreateGuestUser();
      _currentUser = user;
      _status = UserStatus.guest;

      debugPrint('游客用户创建成功：${user.id}');
      notifyListeners();
    } catch (e) {
      debugPrint('创建游客用户失败：$e');
      _status = UserStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  /// 退出登录（清除用户数据，重新创建游客）
  Future<void> logout() async {
    try {
      await _logoutUser();
      _currentUser = null;
      _status = UserStatus.unauthenticated;
      notifyListeners();

      // 退出后自动创建新的游客用户
      await createGuestUser();
    } catch (e) {
      debugPrint('退出登录失败：$e');
      rethrow;
    }
  }

  /// 刷新用户信息
  Future<void> refreshUser() async {
    final user = await _getCurrentUser();
    if (user != null) {
      _currentUser = user;
      _status = user.isGuest ? UserStatus.guest : UserStatus.logged;
      notifyListeners();
    }
  }

  /// 检查登录状态
  Future<bool> checkLoginStatus() async {
    final isLoggedIn = await _checkIsLoggedIn();
    final isGuest = await _checkIsGuest();
    
    if (isLoggedIn) {
      _status = isGuest ? UserStatus.guest : UserStatus.logged;
    } else {
      _status = UserStatus.unauthenticated;
    }
    
    notifyListeners();
    return isLoggedIn;
  }
}
