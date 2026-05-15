/// 云同步抽象接口
abstract class ISyncDataSource {
  /// 上传数据到云端
  Future<bool> upload(String key, dynamic data);

  /// 从云端下载数据
  Future<dynamic> download(String key);

  /// 解决冲突策略
  Future<dynamic> resolveConflict(String key, dynamic localData, dynamic remoteData);

  /// 获取同步状态
  SyncStatus get status;
}

enum SyncStatus { idle, syncing, success, failed, offline }
