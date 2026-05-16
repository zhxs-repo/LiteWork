import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// 认证服务 - 处理用户登录、注册和 Token 管理
class AuthService {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  // API Base URL - 替换为真实后端地址
  static const String baseUrl = 'https://api.litework.example.com';

  AuthService({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _secureStorage = storage ?? const FlutterSecureStorage();

  /// 用户登录
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = AuthResult.fromJson(data);
        await _saveTokens(result);
        return result;
      } else if (response.statusCode == 401) {
        throw AuthException('邮箱或密码错误');
      } else {
        throw AuthException('登录失败：${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('网络连接失败，请检查网络设置');
    }
  }

  /// 用户注册
  Future<AuthResult> register(String email, String password, String username) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final result = AuthResult.fromJson(data);
        await _saveTokens(result);
        return result;
      } else if (response.statusCode == 409) {
        throw AuthException('该邮箱已被注册');
      } else {
        throw AuthException('注册失败：${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('网络连接失败，请检查网络设置');
    }
  }

  /// 刷新 Token
  Future<AuthResult> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        throw AuthException('未找到刷新令牌，请重新登录');
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = AuthResult.fromJson(data);
        await _saveTokens(result);
        return result;
      } else {
        await logout();
        throw AuthException('会话已过期，请重新登录');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('刷新令牌失败');
    }
  }

  /// 获取当前 Token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// 获取当前用户 ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  /// 登出
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _client.post(
          Uri.parse('$baseUrl/api/v1/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      // 忽略登出 API 调用失败，继续清理本地数据
    } finally {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userIdKey);
    }
  }

  Future<void> _saveTokens(AuthResult result) async {
    await _secureStorage.write(key: _tokenKey, value: result.accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: result.refreshToken);
    if (result.userId != null) {
      await _secureStorage.write(key: _userIdKey, value: result.userId);
    }
  }
}

/// 认证结果模型
class AuthResult {
  final String accessToken;
  final String refreshToken;
  final String? userId;
  final UserInfo? user;

  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    this.userId,
    this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token'] ?? json['accessToken'] ?? '',
      refreshToken: json['refresh_token'] ?? json['refreshToken'] ?? '',
      userId: json['user_id'] ?? json['userId'],
      user: json['user'] != null ? UserInfo.fromJson(json['user']) : null,
    );
  }
}

/// 用户信息模型
class UserInfo {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;

  UserInfo({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// 认证异常
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
