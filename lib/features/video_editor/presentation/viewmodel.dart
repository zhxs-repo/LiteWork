/// 短视频剪辑模块 - ViewModel (MVVM)

import 'package:flutter/foundation.dart';
import '../domain/models.dart';

/// 视频编辑 ViewModel
class VideoEditorViewModel extends ChangeNotifier {
  final List<VideoProject> _projects = [];
  VideoProject? _currentProject;
  bool _isLoading = false;
  String? _error;
  double _renderProgress = 0.0;
  
  List<VideoProject> get projects => _projects;
  VideoProject? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get renderProgress => _renderProgress;
  
  /// 加载项目列表
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: 从数据层加载数据
      await Future.delayed(const Duration(milliseconds: 500));
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
      final project = VideoProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        template: template,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // TODO: 保存到数据层
      _projects.insert(0, project);
      _currentProject = project;
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
      // TODO: 实现渲染逻辑
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        _renderProgress = i / 100;
        notifyListeners();
      }
      
      _currentProject = _currentProject!.copyWith(
        status: ProjectStatus.completed,
      );
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
      // TODO: 从数据层删除
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
