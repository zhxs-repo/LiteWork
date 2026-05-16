import '../../data/datasources/sync_datasource.dart';

/// 同步仓库接口
abstract class ISyncRepository {
  Future<bool> syncData(String key, dynamic data);
  SyncStatus get status;
}
