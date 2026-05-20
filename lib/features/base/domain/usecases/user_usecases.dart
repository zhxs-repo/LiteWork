import '../repositories/user_repository.dart';
import '../../data/models/user_model.dart';

/// 获取或创建游客用户用例
class GetOrCreateGuestUser {
  final UserRepository _repository;

  GetOrCreateGuestUser(this._repository);

  Future<User> call() async {
    return await _repository.getOrCreateGuestUser();
  }
}

/// 获取当前用户用例
class GetCurrentUser {
  final UserRepository _repository;

  GetCurrentUser(this._repository);

  Future<User?> call() async {
    return await _repository.getCurrentUser();
  }
}

/// 退出登录用例
class LogoutUser {
  final UserRepository _repository;

  LogoutUser(this._repository);

  Future<void> call() async {
    await _repository.clearUser();
  }
}

/// 检查是否已登录用例
class CheckIsLoggedIn {
  final UserRepository _repository;

  CheckIsLoggedIn(this._repository);

  Future<bool> call() async {
    return await _repository.isLoggedIn();
  }
}

/// 检查是否为游客用例
class CheckIsGuest {
  final UserRepository _repository;

  CheckIsGuest(this._repository);

  Future<bool> call() async {
    return await _repository.isGuest();
  }
}
