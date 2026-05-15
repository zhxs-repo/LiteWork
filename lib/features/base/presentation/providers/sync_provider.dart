import 'package:flutter/foundation.dart';
import '../data/repositories/sync_repository_impl.dart';
import '../data/datasources/sync_datasource.dart';

class SyncProvider extends ChangeNotifier {
  final SyncRepositoryImpl _repository;
  SyncStatus _status = SyncStatus.idle;
  bool _wifiOnly = false;

  SyncProvider(this._repository) {
    _status = _repository.status;
  }

  SyncStatus get status => _status;
  bool get wifiOnly => _wifiOnly;

  Future<void> setWifiOnly(bool value) async {
    _wifiOnly = value;
    notifyListeners();
  }

  Future<void> triggerSync(String key, dynamic data) async {
    _status = SyncStatus.syncing;
    notifyListeners();

    final success = await _repository.syncData(key, data);
    
    _status = success ? SyncStatus.success : SyncStatus.failed;
    notifyListeners();

    // 重置状态
    Future.delayed(const Duration(seconds: 2), () {
      _status = SyncStatus.idle;
      notifyListeners();
    });
  }
}
