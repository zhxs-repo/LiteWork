import 'package:flutter/foundation.dart';
import '../data/models/video_project_model.dart';
import '../data/models/media_item_model.dart';
import '../data/models/timeline_clip_model.dart';
import '../data/datasources/video_local_datasource.dart';

class VideoEditorProvider extends ChangeNotifier {
  final VideoLocalDataSource _dataSource = VideoLocalDataSource();
  
  VideoProject? _currentProject;
  List<MediaItem> _availableMedia = [];
  List<TimelineClip> _clips = [];
  bool _isLoading = false;
  String? _error;

  VideoProject? get currentProject => _currentProject;
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

      final project = VideoProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        aspectRatio: '9:16',
        durationMs: 0,
      );

      await _dataSource.saveProject(project);
      _currentProject = project;
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

      final project = await _dataSource.getProjectById(projectId);
      if (project != null) {
        _currentProject = project;
        // TODO: 加载对应的 clips
        _clips = [];
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
          durationMs: maxEnd,
          updatedAt: DateTime.now(),
        );
        await _dataSource.saveProject(_currentProject!);
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
}
