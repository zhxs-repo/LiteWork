import 'package:flutter/foundation.dart';
import '../../domain/repositories/sync_repository.dart';

class SyncProvider extends ChangeNotifier {
  SyncStatus _status = SyncStatus.idle;
  bool _wifiOnly = false;

  SyncStatus get status => _status;
  bool get wifiOnly => _wifiOnly;

  Future<void> setWifiOnly(bool value) async {
    _wifiOnly = value;
    notifyListeners();
  }

  Future<void> triggerSync() async {
    _status = SyncStatus.syncing;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    
    _status = SyncStatus.synced;
    notifyListeners();

    Future.delayed(const Duration(seconds: 2), () {
      _status = SyncStatus.idle;
      notifyListeners();
    });
  }
}
