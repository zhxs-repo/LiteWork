/// 短视频剪辑模块 - ViewModel (MVVM)

import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../../data/datasources/video_local_datasource.dart';
import '../../data/models/video_project_model.dart' as data_models;

/// 视频编辑 ViewModel
class VideoEditorViewModel extends ChangeNotifier {
  final VideoLocalDataSource _dataSource = VideoLocalDataSource();
  final List<VideoProject> _projects = [];
  VideoProject? _currentProject;
  bool _isLoading = false;
  String? _error;
  double _renderProgress = 0.0;
  bool _isInitialized = false;
  
  List<VideoProject> get projects => _projects;
  VideoProject? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get renderProgress => _renderProgress;
  bool get isInitialized => _isInitialized;
  
  /// 初始化数据源并加载数据
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dataSource.init();
      await loadProjects();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '初始化失败：${e.toString()}';
      notifyListeners();
    }
  }
  
  /// 加载项目列表
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final loadedProjects = await _dataSource.getAllProjects();
      _projects.clear();
      _projects.addAll(loadedProjects.map((p) => _mapToDomainProject(p)));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 创建新项目
  Future<void> createProject(String title, {VideoTemplate? template}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final projectData = data_models.VideoProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        mediaPaths: [],
        duration: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        thumbnailPath: null,
      );
      
      await _dataSource.saveProject(projectData);
      final domainProject = _mapToDomainProject(projectData);
      _projects.insert(0, domainProject);
      _currentProject = domainProject;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 打开项目
  void openProject(String projectId) {
    _currentProject = _projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => throw Exception('Project not found'),
    );
    notifyListeners();
  }
  
  /// 保存当前项目
  Future<void> saveCurrentProject() async {
    if (_currentProject == null) return;
    
    try {
      final projectData = _mapToDataProject(_currentProject!);
      await _dataSource.saveProject(projectData);
    } catch (e) {
      _error = '保存失败：${e.toString()}';
      notifyListeners();
    }
  }
  
  /// 添加视频片段
  void addClip(VideoClip clip) {
    if (_currentProject != null) {
      final updatedClips = List<VideoClip>.from(_currentProject!.clips)..add(clip);
      _currentProject = _currentProject!.copyWith(clips: updatedClips);
      notifyListeners();
    }
  }
  
  /// 删除视频片段
  void removeClip(String clipId) {
    if (_currentProject != null) {
      final updatedClips = _currentProject!.clips.where((c) => c.id != clipId).toList();
      _currentProject = _currentProject!.copyWith(clips: updatedClips);
      notifyListeners();
    }
  }
  
  /// 应用效果
  void applyEffect(String clipId, VideoEffect effect) {
    if (_currentProject != null) {
      final clipIndex = _currentProject!.clips.indexWhere((c) => c.id == clipId);
      if (clipIndex != -1) {
        final clip = _currentProject!.clips[clipIndex];
        final updatedEffects = List<VideoEffect>.from(clip.effects)..add(effect);
        final updatedClip = clip.copyWith(effects: updatedEffects);
        final updatedClips = List<VideoClip>.from(_currentProject!.clips);
        updatedClips[clipIndex] = updatedClip;
        _currentProject = _currentProject!.copyWith(clips: updatedClips);
        notifyListeners();
      }
    }
  }
  
  /// 开始渲染
  Future<void> startRendering() async {
    if (_currentProject == null) return;
    
    _isLoading = true;
    _renderProgress = 0.0;
    notifyListeners();
    
    try {
      // 实现渲染逻辑：模拟视频渲染过程
      // 实际项目中需要调用 FFmpeg 或平台原生渲染 API
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        _renderProgress = i / 100;
        notifyListeners();
      }
      
      // 渲染完成，更新项目状态
      _currentProject = _currentProject!.copyWith(
        status: ProjectStatus.completed,
        lastRenderedAt: DateTime.now(),
      );
      
      // 保存渲染后的项目状态到数据源
      await _saveCurrentProject();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      _currentProject = _currentProject!.copyWith(
        status: ProjectStatus.failed,
      );
      notifyListeners();
    }
  }
  
  /// 删除项目
  Future<void> deleteProject(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dataSource.deleteProject(id);
      _projects.removeWhere((p) => p.id == id);
      if (_currentProject?.id == id) {
        _currentProject = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 清空错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // ==================== 数据转换 ====================
  
  VideoProject _mapToDomainProject(data_models.VideoProject data) {
    return VideoProject(
      id: data.id,
      title: data.title,
      clips: [], // 简化处理，实际需要从 clipsBox 加载
      status: ProjectStatus.draft,
      resolution: '1080p',
      fps: 30,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      thumbnailPath: data.thumbnailPath,
    );
  }
  
  data_models.VideoProject _mapToDataProject(VideoProject domain) {
    return data_models.VideoProject(
      id: domain.id,
      title: domain.title,
      mediaPaths: domain.clips.map((c) => c.sourcePath).toList(),
      duration: domain.clips.fold<Duration>(
        Duration.zero,
        (total, clip) => total + clip.duration,
      ),
      createdAt: domain.createdAt,
      updatedAt: DateTime.now(),
      thumbnailPath: domain.thumbnailPath,
    );
  }
}

/// VideoClip 扩展用于 copyWith
extension VideoClipExtension on VideoClip {
  VideoClip copyWith({
    String? id,
    String? sourcePath,
    Duration? startTime,
    Duration? endTime,
    Duration? duration,
    double? volume,
    List<VideoEffect>? effects,
    String? transition,
  }) {
    return VideoClip(
      id: id ?? this.id,
      sourcePath: sourcePath ?? this.sourcePath,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      effects: effects ?? this.effects,
      transition: transition ?? this.transition,
    );
  }
}
