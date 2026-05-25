/// 基础异常类 - 用于 Data 层异常抛出
/// 
/// 这些异常会在 Repository 层被捕获并转换为 Failure

/// 缓存异常 - Hive/本地存储相关
class CacheException implements Exception {
  final String message;
  
  const CacheException(this.message);
  
  @override
  String toString() => 'CacheException: $message';
}

/// 网络异常 - HTTP/API 调用相关
class NetworkException implements Exception {
  final String message;
  
  const NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// 服务器异常 - 服务端返回错误
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  const ServerException(this.message, {this.statusCode});
  
  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// 认证异常 - 登录/权限相关
class AuthException implements Exception {
  final String message;
  
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}

/// 验证异常 - 用户输入验证错误
class ValidationException implements Exception {
  final String message;
  
  const ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
}

/// 同步异常 - 云同步相关
class SyncException implements Exception {
  final String message;
  
  const SyncException(this.message);
  
  @override
  String toString() => 'SyncException: $message';
}

/// 视频处理异常 - FFmpeg/视频编辑相关
class VideoExportException implements Exception {
  final String message;
  
  const VideoExportException(this.message);
  
  @override
  String toString() => 'VideoExportException: $message';
}
