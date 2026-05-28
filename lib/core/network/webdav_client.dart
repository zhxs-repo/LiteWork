/// WebDAV 客户端服务
/// 
/// 提供与 WebDAV 服务器的完整交互功能，支持文件上传、下载、删除等操作
/// 遵循 RFC 4918 WebDAV 标准

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../error/exceptions.dart';
import 'webdav_config.dart';

/// WebDAV 客户端服务类
class WebDavClient {
  late final Dio _dio;
  late final FlutterSecureStorage _secureStorage;
  WebDavConfig? _config;
  
  /// 存储配置键名
  static const String _configKey = 'webdav_config';
  
  /// 获取当前配置
  WebDavConfig? get config => _config;
  
  /// 检查是否已配置
  bool get isConfigured => _config != null && _config!.isValid;
  
  /// 初始化 WebDAV 客户端
  Future<void> init() async {
    _secureStorage = const FlutterSecureStorage();
    await _loadConfig();
    _initDio();
  }
  
  /// 初始化 Dio 实例
  void _initDio() {
    if (_config == null) {
      _dio = Dio();
      return;
    }
    
    _dio = Dio(BaseOptions(
      baseUrl: _config!.baseUrl,
      connectTimeout: Duration(seconds: _config!.connectionTimeout),
      receiveTimeout: Duration(seconds: _config!.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // 添加认证拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = _buildAuthHeader();
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          throw const AuthException('WebDAV 认证失败，请检查用户名和密码');
        } else if (error.response?.statusCode == 403) {
          throw const AuthException('WebDAV 权限不足');
        } else if (error.response?.statusCode == 404) {
          throw NetworkException('资源不存在：${error.requestOptions.path}');
        } else if (error.type == DioExceptionType.connectionTimeout ||
                   error.type == DioExceptionType.receiveTimeout) {
          throw NetworkException('网络连接超时');
        }
        return handler.next(error);
      },
    ));
  }
  
  /// 构建 Basic Auth 头
  String _buildAuthHeader() {
    if (_config == null) return '';
    final credentials = '${_config!.username}:${_config!.password}';
    final base64Credentials = base64Encode(utf8.encode(credentials));
    return 'Basic $base64Credentials';
  }
  
  /// 加载保存的配置
  Future<void> _loadConfig() async {
    final configJson = await _secureStorage.read(key: _configKey);
    if (configJson != null) {
      try {
        final map = jsonDecode(configJson) as Map<String, dynamic>;
        _config = WebDavConfig.fromMap(map);
      } catch (e) {
        throw CacheException('WebDAV 配置加载失败：$e');
      }
    }
  }
  
  /// 保存配置到安全存储
  Future<void> _saveConfig() async {
    if (_config == null) return;
    try {
      final configJson = jsonEncode(_config!.toMap());
      await _secureStorage.write(key: _configKey, value: configJson);
    } catch (e) {
      throw CacheException('WebDAV 配置保存失败：$e');
    }
  }
  
  // ==================== 配置管理 ====================
  
  /// 配置 WebDAV 连接
  Future<void> configure(WebDavConfig config) async {
    if (!config.isValid) {
      throw const ValidationException('WebDAV 配置无效，请检查服务器地址、用户名和密码');
    }
    _config = config;
    await _saveConfig();
    _initDio();
  }
  
  /// 清除配置
  Future<void> clearConfig() async {
    _config = null;
    await _secureStorage.delete(key: _configKey);
    _dio = Dio();
  }
  
  /// 测试连接
  Future<bool> testConnection() async {
    if (!isConfigured) return false;
    try {
      final response = await _dio.head('/');
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (e) {
      return false;
    }
  }
  
  /// 使用指定配置测试连接（不保存配置）
  Future<bool> testConnectionWithConfig(WebDavConfig config) async {
    if (!config.isValid) return false;
    
    try {
      // 创建临时 Dio 实例进行测试
      final testDio = Dio(BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: Duration(seconds: config.connectionTimeout),
        receiveTimeout: Duration(seconds: config.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
        },
      ));
      
      // 添加 Basic Auth
      final credentials = '${config.username}:${config.password}';
      final base64Credentials = base64Encode(utf8.encode(credentials));
      testDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Basic $base64Credentials';
          return handler.next(options);
        },
      ));
      
      final response = await testDio.head('/');
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (e) {
      return false;
    }
  }
  
  // ==================== 文件操作 ====================
  
  /// 上传文件/数据
  /// 
  /// [remotePath] WebDAV 服务器上的路径 (例如：/litework/notes/note123.json)
  /// [data] 要上传的数据 (字符串或字节)
  /// [contentType] 内容类型 (默认 application/json)
  Future<void> upload({
    required String remotePath,
    required dynamic data,
    String contentType = 'application/json',
  }) async {
    if (!isConfigured) {
      throw const NetworkException('WebDAV 未配置，请先设置服务器信息');
    }
    
    try {
      // 确保路径以斜杠开头
      final path = remotePath.startsWith('/') ? remotePath : '/$remotePath';
      
      // 创建目录 (如果不存在)
      final dirPath = path.substring(0, path.lastIndexOf('/'));
      if (dirPath.isNotEmpty) {
        await _createDirectory(dirPath);
      }
      
      // 上传数据
      final bytes = data is String ? utf8.encode(data) : data as List<int>;
      
      await _dio.put(
        path,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length.toString(),
          },
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw const AuthException('WebDAV 认证失败或权限不足');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException('上传超时，请检查网络连接');
      }
      throw NetworkException('上传失败：${e.message}');
    } catch (e) {
      if (e is NetworkException || e is AuthException) rethrow;
      throw NetworkException('上传失败：$e');
    }
  }
  
  /// 下载文件
  /// 
  /// [remotePath] WebDAV 服务器上的路径
  /// 返回文件内容字符串
  Future<String> download({required String remotePath}) async {
    if (!isConfigured) {
      throw const NetworkException('WebDAV 未配置，请先设置服务器信息');
    }
    
    try {
      final path = remotePath.startsWith('/') ? remotePath : '/$remotePath';
      
      final response = await _dio.get<String>(path);
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw NetworkException('下载失败：HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NetworkException('远程文件不存在');
      } else if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw const AuthException('WebDAV 认证失败或权限不足');
      }
      throw NetworkException('下载失败：${e.message}');
    } catch (e) {
      if (e is NetworkException || e is AuthException) rethrow;
      throw NetworkException('下载失败：$e');
    }
  }
  
  /// 删除远程文件
  Future<void> delete({required String remotePath}) async {
    if (!isConfigured) {
      throw const NetworkException('WebDAV 未配置，请先设置服务器信息');
    }
    
    try {
      final path = remotePath.startsWith('/') ? remotePath : '/$remotePath';
      await _dio.delete(path);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // 文件不存在视为成功
        return;
      } else if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw const AuthException('WebDAV 认证失败或权限不足');
      }
      throw NetworkException('删除失败：${e.message}');
    } catch (e) {
      if (e is NetworkException || e is AuthException) rethrow;
      throw NetworkException('删除失败：$e');
    }
  }
  
  /// 检查远程文件是否存在
  Future<bool> exists(String remotePath) async {
    if (!isConfigured) return false;
    
    try {
      final path = remotePath.startsWith('/') ? remotePath : '/$remotePath';
      final response = await _dio.head(path);
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// 列出目录内容 (PROPFIND 方法)
  Future<List<String>> listDirectory(String remotePath) async {
    if (!isConfigured) {
      throw const NetworkException('WebDAV 未配置，请先设置服务器信息');
    }
    
    try {
      final path = remotePath.startsWith('/') ? remotePath : '/$remotePath';
      
      final response = await _dio.request(
        path,
        options: Options(
          method: 'PROPFIND',
          headers: {
            'Depth': '1',
            'Content-Type': 'application/xml',
          },
        ),
        data: '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:displayname/>
    <d:resourcetype/>
    <d:getcontentlength/>
    <d:getlastmodified/>
  </d:prop>
</d:propfind>''',
      );
      
      // 解析 XML 响应 (简化处理，实际项目可使用 xml 包)
      final items = <String>[];
      // TODO: 使用 xml 包解析 DAV 响应
      return items;
    } on DioException catch (e) {
      throw NetworkException('列出目录失败：${e.message}');
    } catch (e) {
      throw NetworkException('列出目录失败：$e');
    }
  }
  
  // ==================== 辅助方法 ====================
  
  /// 创建远程目录
  Future<void> _createDirectory(String dirPath) async {
    if (dirPath.isEmpty || dirPath == '/') return;
    
    // 逐级创建目录
    final segments = dirPath.split('/').where((s) => s.isNotEmpty).toList();
    var currentPath = '';
    
    for (final segment in segments) {
      currentPath = '$currentPath/$segment';
      try {
        await _dio.request(
          currentPath,
          options: Options(method: 'MKCOL'),
        );
      } on DioException catch (e) {
        // 目录已存在 (409) 或其他错误忽略
        if (e.response?.statusCode != 409) {
          // 继续尝试，因为父目录可能已存在
        }
      }
    }
  }
  
  /// 获取同步状态文件路径
  String getSyncStatusPath() => '/litework/.sync_status.json';
  
  /// 获取笔记存储目录
  String getNotesDir() => '/litework/notes';
  
  /// 获取特定笔记的远程路径
  String getNotePath(String noteId) => '/litework/notes/$noteId.json';
  
  /// 获取文件夹存储目录
  String getFoldersDir() => '/litework/folders';
  
  /// 获取特定文件夹的远程路径
  String getFolderPath(String folderId) => '/litework/folders/$folderId.json';
}
