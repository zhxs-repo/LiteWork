/// WebDAV 客户端配置模型
/// 
/// 用于存储和管理 WebDAV 服务器连接信息

import 'package:equatable/equatable.dart';

/// WebDAV 配置数据模型
class WebDavConfig extends Equatable {
  /// 服务器 URL (例如：https://dav.example.com)
  final String serverUrl;
  
  /// 用户名
  final String username;
  
  /// 密码或应用专用密码
  final String password;
  
  /// 是否启用 HTTPS 证书验证 (生产环境建议 true)
  final bool verifyCertificates;
  
  /// 连接超时时间 (秒)
  final int connectionTimeout;
  
  /// 接收超时时间 (秒)
  final int receiveTimeout;
  
  const WebDavConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.verifyCertificates = true,
    this.connectionTimeout = 30,
    this.receiveTimeout = 60,
  });
  
  /// 获取基础 URL (去除末尾斜杠)
  String get baseUrl => serverUrl.replaceAll(RegExp(r'/$'), '');
  
  /// 验证配置是否有效
  bool get isValid {
    if (serverUrl.isEmpty || !serverUrl.startsWith('http')) return false;
    if (username.isEmpty) return false;
    if (password.isEmpty) return false;
    return true;
  }
  
  @override
  List<Object?> get props => [
    serverUrl,
    username,
    password,
    verifyCertificates,
    connectionTimeout,
    receiveTimeout,
  ];
  
  /// 复制并修改配置
  WebDavConfig copyWith({
    String? serverUrl,
    String? username,
    String? password,
    bool? verifyCertificates,
    int? connectionTimeout,
    int? receiveTimeout,
  }) {
    return WebDavConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      verifyCertificates: verifyCertificates ?? this.verifyCertificates,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
    );
  }
  
  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'verifyCertificates': verifyCertificates,
      'connectionTimeout': connectionTimeout,
      'receiveTimeout': receiveTimeout,
    };
  }
  
  /// 从 Map 创建实例
  factory WebDavConfig.fromMap(Map<String, dynamic> map) {
    return WebDavConfig(
      serverUrl: map['serverUrl'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      verifyCertificates: map['verifyCertificates'] as bool? ?? true,
      connectionTimeout: map['connectionTimeout'] as int? ?? 30,
      receiveTimeout: map['receiveTimeout'] as int? ?? 60,
    );
  }
}
