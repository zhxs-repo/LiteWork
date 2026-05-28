/// 同步状态 Provider
/// 
/// 管理 WebDAV 同步配置状态和同步操作

import 'package:flutter/foundation.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/webdav_client.dart';

/// 同步状态 Provider
class SyncProvider extends ChangeNotifier {
  final WebDavClient _webDavClient = di.sl<WebDavClient>();
  
  bool _isConfigured = false;
  bool _isSyncing = false;
  String? _lastSyncTime;
  String? _error;
  int _syncProgress = 0;
  String _syncStatus = 'idle'; // idle, syncing, success, error
  
  bool get isConfigured => _isConfigured;
  bool get isSyncing => _isSyncing;
  String? get lastSyncTime => _lastSyncTime;
  String? get error => _error;
  int get syncProgress => _syncProgress;
  String get syncStatus => _syncStatus;
  
  /// 初始化并检查同步状态
  Future<void> init() async {
    await checkSyncStatus();
  }
  
  /// 检查 WebDAV 配置状态
  Future<void> checkSyncStatus() async {
    try {
      _isConfigured = _webDavClient.isConfigured;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = '检查同步状态失败：${e.toString()}';
      notifyListeners();
    }
  }
  
  /// 测试当前连接
  Future<bool> testConnection() async {
    if (!_isConfigured) {
      _error = 'WebDAV 未配置';
      notifyListeners();
      return false;
    }
    
    try {
      _isSyncing = true;
      _syncStatus = 'syncing';
      notifyListeners();
      
      final success = await _webDavClient.testConnection();
      
      _isSyncing = false;
      _syncStatus = success ? 'success' : 'error';
      if (!success) {
        _error = '连接测试失败';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _isSyncing = false;
      _syncStatus = 'error';
      _error = '连接测试错误：${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// 更新最后同步时间
  void updateLastSyncTime() {
    _lastSyncTime = DateTime.now().toString().substring(0, 16).replaceAll('T', ' ');
    notifyListeners();
  }
  
  /// 更新同步进度
  void updateProgress(int progress, String status) {
    _syncProgress = progress;
    _syncStatus = status;
    notifyListeners();
  }
  
  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// 重置状态
  void reset() {
    _isSyncing = false;
    _syncProgress = 0;
    _syncStatus = 'idle';
    _error = null;
    notifyListeners();
  }
}
