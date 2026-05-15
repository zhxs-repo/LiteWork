/// 云同步数据源基类
/// 定义统一的同步协议，所有模块的同步实现都需继承此类
abstract class BaseSyncDataSource {
  /// 上传数据
  Future<bool> upload(String key, dynamic data);

  /// 下载数据
  Future<dynamic> download(String key);

  /// 检查冲突
  Future<SyncConflictType> checkConflict(String key, dynamic localData, dynamic remoteData);

  /// 解决冲突
  Future<dynamic> resolveConflict(
    String key, 
    dynamic localData, 
    dynamic remoteData, 
    ConflictResolutionStrategy strategy
  );
}

/// 冲突类型
enum SyncConflictType {
  none, // 无冲突
  modifiedBoth, // 两端都修改
  deletedRemote, // 远程已删除
  deletedLocal, // 本地已删除
}

/// 冲突解决策略
enum ConflictResolutionStrategy {
  useLocal, // 使用本地
  useRemote, // 使用远程
  merge, // 尝试合并
  keepBoth, // 保留两份
}
