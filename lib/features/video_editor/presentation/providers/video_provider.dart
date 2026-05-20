import 'package:flutter/foundation.dart';
import '../../data/datasources/video_local_datasource.dart';
import '../../data/models/video_project_model.dart' as data;
import '../../domain/models.dart' as domain;

/// 视频项目列表 Provider - 已实现真实数据源
class VideoProvider extends ChangeNotifier {
  final VideoLocalDataSource _dataSource = VideoLocalDataSource();
  
  List<domain.VideoProject> _projects = [];
  bool _isLoading = false;
  bool _isExporting = false;
  int _exportProgress = 0;
  String? _error;
  String _resolution = '1080p';
  String _frameRate = '30';
  String _aspectRatio = '9:16';

  List<domain.VideoProject> get projects => _projects;
  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  int get exportProgress => _exportProgress;
  String? get error => _error;
  String get resolution => _resolution;
  String get frameRate => _frameRate;
  String get aspectRatio => _aspectRatio;
  String get estimatedSize => '~${(_resolution == '1080p' ? 150 : 80)}MB';
  String get estimatedTime => '~2分钟';

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

      await _dataSource.deleteProject(id);
      await loadProjects();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startExport() async {
    _isExporting = true;
    _exportProgress = 0;
    notifyListeners();
    
    try {
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 300));
        _exportProgress = i;
        notifyListeners();
      }
      _isExporting = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isExporting = false;
      notifyListeners();
    }
  }

  void setResolution(String value) {
    _resolution = value;
    notifyListeners();
  }

  void setFrameRate(String value) {
    _frameRate = value;
    notifyListeners();
  }

  void setAspectRatio(String value) {
    _aspectRatio = value;
    notifyListeners();
  }

  void applyTemplate(String templateName) {
    notifyListeners();
  }
}
