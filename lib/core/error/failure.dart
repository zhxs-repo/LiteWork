/// 基础失败类 - 用于函数式错误处理
/// 
/// 在 Clean Architecture 中，Failure 用于表示业务逻辑层的错误
/// 使用 Either<Failure, T> 模式进行错误传播

import 'package:equatable/equatable.dart';

/// 基础 Failure 抽象类
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object?> get props => [message];
}

/// 缓存失败 - Hive/本地存储相关错误
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// 网络失败 - HTTP/API 调用相关错误
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// 验证失败 - 用户输入验证错误
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// 认证失败 - 登录/权限相关错误
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// 同步失败 - 云同步相关错误
class SyncFailure extends Failure {
  const SyncFailure(super.message);
}

/// 视频处理失败 - FFmpeg/视频编辑相关错误
class VideoExportFailure extends Failure {
  const VideoExportFailure(super.message);
}

/// 未知失败 - 未分类的错误
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
