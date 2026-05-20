/// 同步状态枚举
enum SyncStatus { idle, syncing, synced, error }

/// 同步仓库接口
abstract class ISyncRepository {
  Future<bool> syncData(String key, dynamic data);
  SyncStatus get status;
}
