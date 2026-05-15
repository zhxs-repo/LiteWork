import 'package:flutter/foundation.dart';

/// 视频模块状态管理 (桩代码)
class VideoProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get projects => _projects;
  bool get isLoading => _isLoading;

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    // TODO: 从数据源加载
    await Future.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createProject(String title) async {
    // TODO: 创建新项目
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    // TODO: 删除项目
    notifyListeners();
  }
}
