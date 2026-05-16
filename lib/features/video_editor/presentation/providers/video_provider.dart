import 'package:flutter/foundation.dart';
import '../../data/datasources/video_local_datasource.dart';
import '../../data/models/video_project_model.dart' as data;
import '../../domain/models.dart' as domain;

/// 视频项目列表 Provider - 已实现真实数据源
class VideoProvider extends ChangeNotifier {
  final VideoLocalDataSource _dataSource = VideoLocalDataSource();
  
  List<domain.VideoProject> _projects = [];
  bool _isLoading = false;
  String? _error;

  List<domain.VideoProject> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await _dataSource.init();
  }

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 从数据源加载项目列表
      final dataProjects = await _dataSource.getAllProjects();
      _projects = dataProjects.map((dp) => domain.VideoProject(
        id: dp.id,
        title: dp.title,
        clips: [],
        status: domain.ProjectStatus.draft,
        createdAt: dp.createdAt,
        updatedAt: dp.updatedAt,
      )).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProject(String title) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 创建新项目
      final dataProject = data.VideoProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dataSource.saveProject(dataProject);
      
      // 刷新列表
      await loadProjects();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 删除项目
      await _dataSource.deleteProject(id);
      
      // 刷新列表
      await loadProjects();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
