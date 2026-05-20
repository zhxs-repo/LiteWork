import 'package:flutter/foundation.dart';
import '../../data/models/video_project_model.dart' as data;
import '../../data/models/media_item_model.dart';
import '../../data/models/timeline_clip_model.dart';
import '../../data/datasources/video_local_datasource.dart';
import '../../domain/models.dart' as domain;

class VideoEditorProvider extends ChangeNotifier {
  final VideoLocalDataSource _dataSource = VideoLocalDataSource();
  
  domain.VideoProject? _currentProject;
  List<MediaItem> _availableMedia = [];
  List<TimelineClip> _clips = [];
  bool _isLoading = false;
  String? _error;

  domain.VideoProject? get currentProject => _currentProject;
  List<MediaItem> get availableMedia => _availableMedia;
  List<TimelineClip> get clips => _clips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await _dataSource.init();
  }

  Future<void> createProject(String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      final dataProject = data.VideoProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dataSource.saveProject(dataProject);
      
      // 转换为 domain 模型
      _currentProject = domain.VideoProject(
        id: dataProject.id,
        title: dataProject.title,
        clips: [],
        status: domain.ProjectStatus.draft,
        createdAt: dataProject.createdAt,
        updatedAt: dataProject.updatedAt,
      );
      _clips = [];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProject(String projectId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final dataProject = await _dataSource.getProjectById(projectId);
      if (dataProject != null) {
        // 转换为 domain 模型
        _currentProject = domain.VideoProject(
          id: dataProject.id,
          title: dataProject.title,
          clips: [],
          status: domain.ProjectStatus.draft,
          createdAt: dataProject.createdAt,
          updatedAt: dataProject.updatedAt,
        );
        
        // 加载对应的 clips
        final clipsData = await _dataSource.getClipsForProject(projectId);
        _clips = clipsData;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importMedia(List<MediaItem> mediaList) async {
    try {
      await _dataSource.saveMediaBatch(mediaList);
      _availableMedia.addAll(mediaList);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addClipToTimeline(TimelineClip clip) async {
    try {
      await _dataSource.saveClip(clip);
      _clips.add(clip);
      
      // 更新项目时长
      if (_currentProject != null) {
        final maxEnd = _clips.fold<int>(
          0,
          (max, clip) => clip.startTimeMs + clip.durationMs > max ? clip.startTimeMs + clip.durationMs : max,
        );
        _currentProject = _currentProject!.copyWith(
          totalDuration: Duration(milliseconds: maxEnd),
          updatedAt: DateTime.now(),
        );
        final dataProject = data.VideoProject(
          id: _currentProject!.id,
          title: _currentProject!.title,
          mediaPaths: _clips.map((c) => c.mediaId).toList(),
          duration: Duration(milliseconds: maxEnd),
          createdAt: _currentProject!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _dataSource.saveProject(dataProject);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateClip(TimelineClip clip) async {
    try {
      await _dataSource.saveClip(clip);
      final index = _clips.indexWhere((c) => c.id == clip.id);
      if (index != -1) {
        _clips[index] = clip;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteClip(String clipId) async {
    try {
      await _dataSource.deleteClip(clipId);
      _clips.removeWhere((c) => c.id == clipId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> saveProject() async {
    if (_currentProject == null) return;
    try {
      final dataProject = data.VideoProject(
        id: _currentProject!.id,
        title: _currentProject!.title,
        mediaPaths: _clips.map((c) => c.mediaId).toList(),
        duration: _currentProject!.totalDuration,
        createdAt: _currentProject!.createdAt,
        updatedAt: DateTime.now(),
      );
      await _dataSource.saveProject(dataProject);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> exportVideo() async {
    if (_currentProject == null) return;
    try {
      _isLoading = true;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 2));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
