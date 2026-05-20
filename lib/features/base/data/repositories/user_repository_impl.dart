import '../models/user_model.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';

/// 用户仓库实现
class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _localDataSource;

  UserRepositoryImpl(this._localDataSource);

  @override
  Future<User?> getCurrentUser() {
    return _localDataSource.getCurrentUser();
  }

  @override
  Future<User> getOrCreateGuestUser() {
    return _localDataSource.getOrCreateGuestUser();
  }

  @override
  Future<void> saveUser(User user) {
    return _localDataSource.saveUser(user);
  }

  @override
  Future<bool> isLoggedIn() {
    return _localDataSource.isLoggedIn();
  }

  @override
  Future<void> clearUser() {
    return _localDataSource.clearUser();
  }

  @override
  Future<bool> isGuest() {
    return _localDataSource.isGuest();
  }
}
