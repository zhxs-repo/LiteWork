/// 检查 WebDAV 是否已配置 UseCase
/// 
/// 用于检查用户是否已经配置了 WebDAV 服务器

class CheckWebDavConfiguredUseCase {
  final bool Function() _checkFunc;

  CheckWebDavConfiguredUseCase(this._checkFunc);

  bool call() {
    return _checkFunc();
  }
}
