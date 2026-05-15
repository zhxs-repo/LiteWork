/// 视频本地数据源 (桩代码)
class VideoLocalDataSource {
  // TODO: 实现 Hive 存储逻辑
  // - 打开 video_projects box
  // - CRUD 操作
  // - 媒体文件路径管理
  
  Future<void> init() async {
    // 初始化占位
  }

  Future<List<Map<String, dynamic>>> getAllProjects() async {
    return [];
  }

  Future<void> saveProject(Map<String, dynamic> project) async {
    // TODO: 保存到 Hive
  }

  Future<void> deleteProject(String id) async {
    // TODO: 从 Hive 删除
  }
}
