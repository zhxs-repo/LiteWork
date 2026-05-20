/// 同步状态枚举
enum SyncStatus { idle, syncing, synced, error }

/// 同步仓库接口
abstract class ISyncRepository {
  Future<bool> syncData(String key, dynamic data);
  SyncStatus get status;
}

/// 数据同步接口（Domain 层抽象，不应直接引用 Data 层实现）
abstract class ISyncDataSource {
  Future<bool> upload(String key, dynamic data);
  Future<dynamic> download(String key);
}
