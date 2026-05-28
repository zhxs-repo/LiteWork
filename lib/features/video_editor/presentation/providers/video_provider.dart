import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../data/datasources/video_local_datasource.dart';
import '../../data/models/video_project_model.dart' as data;
import '../../data/models/media_item_model.dart';
import '../../data/models/timeline_clip_model.dart';
import '../../data/models/timeline_data_model.dart';
import '../../domain/models.dart' as domain;
import '../../services/ffmpeg_render_service.dart';

/// 统一视频 Provider - 合并项目列表 CRUD、编辑器详情、导出配置
class VideoProvider extends ChangeNotifier {
  final VideoLocalDataSource _dataSource = VideoLocalDataSource();

  // 项目列表状态
  List<domain.VideoProject> _projects = [];
  bool _isLoading = false;
  String? _error;

  // 当前编辑的项目
  domain.VideoProject? _currentProject;
  List<MediaItem> _availableMedia = [];
  List<TimelineClip> _clips = [];

  // 导出配置
  bool _isExporting = false;
  int _exportProgress = 0;
  double _renderProgress = 0.0;
  String _resolution = '1080p';
  String _frameRate = '30';
  String _aspectRatio = '9:16';
  String? _lastExportPath;
  
  final FFmpegRenderService _ffmpegService = FFmpegRenderService();

  // Getters - 项目列表
  List<domain.VideoProject> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters - 当前项目
  domain.VideoProject? get currentProject => _currentProject;
  List<MediaItem> get availableMedia => _availableMedia;
  List<TimelineClip> get clips => _clips;

  // Getters - 导出
  bool get isExporting => _isExporting;
  int get exportProgress => _exportProgress;
  double get renderProgress => _renderProgress;
  String get resolution => _resolution;
  String get frameRate => _frameRate;
  String get aspectRatio => _aspectRatio;
  String? get lastExportPath => _lastExportPath;
  String get estimatedSize => '~${(_resolution == '1080p' ? 150 : 80)}MB';
  String get estimatedTime => '~2分钟';

  Future<void> init() async {
    await _dataSource.init();
  }

  // ==================== 项目列表 CRUD ====================

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
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

  Future<void> createProject(String title, {domain.VideoTemplate? template}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final dataProject = data.VideoProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        mediaPaths: [],
        duration: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        thumbnailPath: null,
      );

      await _dataSource.saveProject(dataProject);

      final domainProject = domain.VideoProject(
        id: dataProject.id,
        title: dataProject.title,
        clips: [],
        status: domain.ProjectStatus.draft,
        createdAt: dataProject.createdAt,
        updatedAt: dataProject.updatedAt,
        thumbnailPath: dataProject.thumbnailPath,
      );

      _projects.insert(0, domainProject);
      _currentProject = domainProject;

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
      _projects.removeWhere((p) => p.id == id);
      if (_currentProject?.id == id) {
        _currentProject = null;
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

  Future<void> duplicateProject(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final original = _projects.firstWhere((p) => p.id == id);
      final newId = DateTime.now().millisecondsSinceEpoch.toString();

      // 从数据库加载原始项目的 clips
      final originalClips = await _dataSource.getClipsForProject(id);
      for (final clip in originalClips) {
        final newClip = TimelineClip(
          id: '${newId}_${clip.id}',
          projectId: newId,
          mediaId: clip.mediaId,
          trackIndex: clip.trackIndex,
          startTimeMs: clip.startTimeMs,
          endTimeMs: clip.endTimeMs,
          durationMs: clip.durationMs,
          positionMs: clip.positionMs,
          trimStartMs: clip.trimStartMs,
          trimEndMs: clip.trimEndMs,
          speed: clip.speed,
          isReversed: clip.isReversed,
          effects: clip.effects,
        );
        await _dataSource.saveClip(newClip);
      }

      final domainClips = originalClips.map((c) => domain.VideoClip(
        id: '${newId}_${c.id}',
        sourcePath: '',
        startTime: Duration(milliseconds: c.startTimeMs),
        endTime: Duration(milliseconds: c.endTimeMs),
        duration: Duration(milliseconds: c.durationMs),
      )).toList();

      final newProject = domain.VideoProject(
        id: newId,
        title: '${original.title} (副本)',
        clips: domainClips,
        status: domain.ProjectStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        thumbnailPath: original.thumbnailPath,
      );

      final dataProject = data.VideoProject(
        id: newId,
        title: newProject.title,
        mediaPaths: domainClips.map((c) => c.sourcePath).toList(),
        duration: domainClips.fold<Duration>(
          Duration.zero,
          (total, clip) => total + clip.duration,
        ),
        createdAt: newProject.createdAt,
        updatedAt: newProject.updatedAt,
        thumbnailPath: newProject.thumbnailPath,
      );

      await _dataSource.saveProject(dataProject);
      _projects.insert(0, newProject);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 当前项目管理 ====================

  void openProject(String projectId) {
    _currentProject = _projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => throw Exception('Project not found'),
    );
    notifyListeners();
  }

  Future<void> loadProject(String projectId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final dataProject = await _dataSource.getProjectById(projectId);
      if (dataProject != null) {
        final clipsData = await _dataSource.getClipsForProject(projectId);
        _clips = clipsData;

        final domainClips = _clips.map((tc) {
          final media = _availableMedia.firstWhere(
            (m) => m.id == tc.mediaId,
            orElse: () => MediaItem(id: '', path: '', type: MediaType.image, durationMs: 0, createdAt: DateTime.now()),
          );
          return domain.VideoClip(
            id: tc.id,
            sourcePath: media.path,
            startTime: Duration(milliseconds: tc.startTimeMs),
            endTime: Duration(milliseconds: tc.endTimeMs),
            duration: Duration(milliseconds: tc.durationMs),
          );
        }).toList();

        final maxDuration = _clips.fold<int>(
          0, (max, c) => (c.positionMs + c.durationMs) > max ? (c.positionMs + c.durationMs) : max);

        _currentProject = domain.VideoProject(
          id: dataProject.id,
          title: dataProject.title,
          clips: domainClips,
          status: domain.ProjectStatus.editing,
          totalDuration: Duration(milliseconds: maxDuration),
          createdAt: dataProject.createdAt,
          updatedAt: dataProject.updatedAt,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveCurrentProject() async {
    if (_currentProject == null) return;
    try {
      final dataProject = data.VideoProject(
        id: _currentProject!.id,
        title: _currentProject!.title,
        mediaPaths: _clips.map((c) => c.mediaId).toList(),
        duration: _currentProject!.totalDuration,
        createdAt: _currentProject!.createdAt,
        updatedAt: DateTime.now(),
        thumbnailPath: _currentProject!.thumbnailPath,
      );
      await _dataSource.saveProject(dataProject);
    } catch (e) {
      _error = '保存失败：${e.toString()}';
      notifyListeners();
    }
  }

  // ==================== 素材管理 ====================

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

  // ==================== 时间线片段管理 ====================

  Future<void> addClipToTimeline(TimelineClip clip) async {
    try {
      await _dataSource.saveClip(clip);
      _clips.add(clip);

      if (_currentProject != null) {
        final maxEnd = _clips.fold<int>(
          0,
          (max, clip) => clip.startTimeMs + clip.durationMs > max ? clip.startTimeMs + clip.durationMs : max,
        );
        _currentProject = _currentProject!.copyWith(
          totalDuration: Duration(milliseconds: maxEnd),
          updatedAt: DateTime.now(),
        );
        await saveCurrentProject();
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

  /// 批量更新时间线片段列表（用于分割等操作）
  void updateTimelineClips(List<TimelineClip> newClips) {
    _clips
      ..clear()
      ..addAll(newClips);
    notifyListeners();
  }

  // ==================== 时间线数据转换 ====================

  String? get firstClipPath {
    if (_clips.isEmpty) return null;
    final clip = _clips.first;
    final media = _availableMedia.firstWhere(
      (m) => m.id == clip.mediaId,
      orElse: () => MediaItem(id: '', path: '', type: MediaType.image, durationMs: 0, createdAt: DateTime.now()),
    );
    return media.path.isNotEmpty ? media.path : null;
  }

  TimelineData buildTimelineData() {
    final trackMap = <int, List<TimelineClip>>{};
    for (final clip in _clips) {
      trackMap.putIfAbsent(clip.trackIndex, () => []).add(clip);
    }

    final tracks = <Track>[];
    for (final entry in trackMap.entries) {
      final trackType = switch (entry.key) {
        0 || 1 => TrackType.video,
        2     => TrackType.audio,
        3     => TrackType.text,
        _     => TrackType.video,
      };

      final sortedClips = List<TimelineClip>.from(entry.value)
        ..sort((a, b) => a.positionMs.compareTo(b.positionMs));
      final segments = sortedClips.map((clip) {
        final clipIndex = _clips.indexOf(clip);
        final media = _availableMedia.firstWhere(
          (m) => m.id == clip.mediaId,
          orElse: () => MediaItem(id: '', path: '', type: MediaType.image, durationMs: 0, createdAt: DateTime.now()),
        );
        return TimelineSegment(
          id: clipIndex,
          name: media.path.split('/').last,
          startTime: clip.positionMs / 1000.0,
          duration: clip.durationMs / 1000.0,
          type: trackType,
        );
      }).toList();

      tracks.add(Track(
        id: 'track_${entry.key}',
        type: trackType,
        segments: segments,
      ));
    }

    final maxDuration = _clips.fold<double>(
      0, (max, clip) => math.max(max, (clip.positionMs + clip.durationMs) / 1000.0));

    return TimelineData(tracks: tracks, totalDuration: maxDuration);
  }

  // ==================== 渲染与导出 ====================

  /// 使用 FFmpeg 进行真实视频渲染
  Future<void> startRendering() async {
    if (_currentProject == null || _clips.isEmpty) return;

    _isLoading = true;
    _renderProgress = 0.0;
    notifyListeners();

    try {
      // 收集所有片段信息（包含修剪参数和图片标记）
      final clipsData = <Map<String, dynamic>>[];
      for (final clip in _clips) {
        final media = _availableMedia.firstWhere(
          (m) => m.id == clip.mediaId,
          orElse: () => MediaItem(id: '', path: '', type: MediaType.image, durationMs: 0, createdAt: DateTime.now()),
        );
        
        if (media.path.isEmpty) continue;

        // 计算修剪后的实际时长
        final trimStartMs = clip.trimStartMs ?? 0;
        final trimEndMs = clip.trimEndMs ?? media.durationMs;
        final actualDurationMs = (trimEndMs - trimStartMs).clamp(0, media.durationMs);

        clipsData.add({
          'path': media.path,
          'startTimeMs': trimStartMs,
          'durationMs': actualDurationMs,
          'isImage': media.type == MediaType.image,
        });
      }

      if (clipsData.isEmpty) {
        throw Exception('没有可用的素材');
      }

      // 生成输出文件路径
      final outputPath = await _ffmpegService.getOutputFilePath(
        projectName: _currentProject!.title,
      );

      // 执行 FFmpeg 渲染
      final resultPath = await _ffmpegService.renderVideo(
        clips: clipsData,
        outputPath: outputPath,
        resolution: _resolution,
        frameRate: _frameRate,
        aspectRatio: _aspectRatio,
        onProgress: (progress) {
          _renderProgress = progress;
          notifyListeners();
        },
      );

      if (resultPath != null) {
        _lastExportPath = resultPath;
        _currentProject = _currentProject!.copyWith(
          status: domain.ProjectStatus.completed,
        );
        await saveCurrentProject();
        
        // 将导出的视频添加到素材库
        final exportedMedia = MediaItem(
          id: 'exported_${DateTime.now().millisecondsSinceEpoch}',
          path: resultPath,
          type: MediaType.video,
          durationMs: clipsData.fold<int>(0, (sum, c) => sum + (c['durationMs'] as int)),
          createdAt: DateTime.now(),
        );
        await _dataSource.saveMedia(exportedMedia);
        _availableMedia.add(exportedMedia);
        
        print('视频导出成功：$resultPath');
      } else {
        throw Exception('FFmpeg 渲染失败');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '渲染失败：${e.toString()}';
      _currentProject = _currentProject!.copyWith(
        status: domain.ProjectStatus.failed,
      );
      notifyListeners();
    }
  }

  /// 导出视频（兼容旧接口）
  Future<String?> exportVideo() async {
    if (_currentProject == null) return null;
    try {
      _isLoading = true;
      notifyListeners();
      
      // 调用真实渲染
      await startRendering();
      
      _isLoading = false;
      notifyListeners();
      return _lastExportPath;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // 已废弃：使用 startRendering() 替代进行真实渲染
  @Deprecated('Use startRendering() instead for real FFmpeg rendering')
  Future<void> startExport() async {
    _isExporting = true;
    _exportProgress = 0;
    notifyListeners();

    try {
      // 模拟进度仅用于测试 UI，实际应调用 startRendering()
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

  // ==================== 导出配置 ====================

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
    // TODO: 实现模板应用逻辑
    notifyListeners();
  }

  // ==================== 错误处理 ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
