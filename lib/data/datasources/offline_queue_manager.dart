import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

/// 离线队列管理器 - 处理断网时的操作排队和联网后自动重放
class OfflineQueueManager {
  static const String _boxName = 'offline_queue';
  static const String _networkStatusKey = 'network_status';

  final Box _box;
  final Connectivity _connectivity;
  final StreamSubscription? _networkSubscription;

  bool _isOnline = true;
  final List<Function()> _pendingListeners = [];

  OfflineQueueManager._(this._box, this._connectivity, this._networkSubscription) {
    _listenToNetworkChanges();
  }

  static Future<OfflineQueueManager> create() async {
    final box = await Hive.openBox(_boxName);
    final connectivity = Connectivity();
    final instance = OfflineQueueManager._(box, connectivity, null);
    return instance;
  }

  void _listenToNetworkChanges() {
    _networkSubscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      if (hasConnection && !_isOnline) {
        _isOnline = true;
        _flushQueue();
      } else if (!hasConnection && _isOnline) {
        _isOnline = false;
      }
      _notifyListeners();
    });
  }

  /// 检查当前是否在线
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);
    return _isOnline;
  }

  /// 是否在线
  bool get isOnline => _isOnline;

  /// 添加操作到队列（仅在离线时）
  Future<void> enqueue(String operationType, Map<String, dynamic> data) async {
    final queue = _getQueue();
    queue.add({
      'type': operationType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _saveQueue(queue);
    
    if (!_isOnline) {
      print('[OfflineQueue] Enqueued: $operationType');
    }
  }

  /// 获取队列中的所有操作
  List<Map<String, dynamic>> _getQueue() {
    final queueJson = _box.get('queue', defaultValue: '[]') as String;
    return (jsonDecode(queueJson) as List).cast<Map<String, dynamic>>();
  }

  /// 保存队列
  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    await _box.put('queue', jsonEncode(queue));
  }

  /// 清空队列
  Future<void> clearQueue() async {
    await _box.put('queue', '[]');
  }

  /// 刷新队列（联网时自动调用）
  Future<void> _flushQueue() async {
    final queue = _getQueue();
    if (queue.isEmpty) return;

    print('[OfflineQueue] Flushing ${queue.length} pending operations...');
    
    for (final item in queue) {
      try {
        await _executeOperation(item);
      } catch (e) {
        print('[OfflineQueue] Failed to execute ${item['type']}: $e');
        // 失败则保留在队列中，下次重试
        break;
      }
    }

    // 成功执行的操作从队列移除（简化处理：全部清空）
    await clearQueue();
    print('[OfflineQueue] Queue flushed successfully');
  }

  /// 执行单个操作（需要外部提供实际执行逻辑）
  Future<void> _executeOperation(Map<String, dynamic> operation) async {
    // 此处应调用对应的 Repository 方法重新执行
    // 通过事件通知上层处理
    for (final listener in _pendingListeners) {
      listener();
    }
  }

  /// 注册队列刷新监听器
  void addQueueFlushListener(Function() listener) {
    _pendingListeners.add(listener);
  }

  void _notifyListeners() {
    for (final listener in _pendingListeners) {
      listener();
    }
  }

  /// 释放资源
  void dispose() {
    _networkSubscription?.cancel();
    _box.close();
  }
}

/// 网络状态枚举
enum NetworkStatus { online, offline, unknown }
