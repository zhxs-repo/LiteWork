import 'package:hive_flutter/hive_flutter.dart';
import '../models/video_project_model.dart';
import '../models/media_item_model.dart';
import '../models/timeline_clip_model.dart';

/// 视频本地数据源 - 使用 Map 存储以避免 Hive 类型注册问题
class VideoLocalDataSource {
  static const String projectBoxName = 'video_projects';
  static const String mediaBoxName = 'media_items';
  static const String clipsBoxName = 'timeline_clips';
  
  late Box<Map> _projectBox;
  late Box<Map> _mediaBox;
  late Box<Map> _clipsBox;

  /// 初始化数据源
  Future<void> init() async {
    // 确保 Hive 已初始化
    if (!Hive.isBoxOpen(projectBoxName)) {
      _projectBox = await Hive.openBox<Map>(projectBoxName);
    } else {
      _projectBox = Hive.box<Map>(projectBoxName);
    }
    
    if (!Hive.isBoxOpen(mediaBoxName)) {
      _mediaBox = await Hive.openBox<Map>(mediaBoxName);
    } else {
      _mediaBox = Hive.box<Map>(mediaBoxName);
    }
    
    if (!Hive.isBoxOpen(clipsBoxName)) {
      _clipsBox = await Hive.openBox<Map>(clipsBoxName);
    } else {
      _clipsBox = Hive.box<Map>(clipsBoxName);
    }
  }

  // ==================== Project CRUD ====================
  
  Future<List<VideoProject>> getAllProjects() async {
    return _projectBox.values.map((data) => _mapToProject(data)).toList();
  }

  Future<VideoProject?> getProjectById(String id) async {
    final data = _projectBox.get(id);
    if (data == null) return null;
    return _mapToProject(data);
  }

  Future<void> saveProject(VideoProject project) async {
    await _projectBox.put(project.id, _projectToMap(project));
  }

  Future<void> deleteProject(String id) async {
    await _projectBox.delete(id);
  }

  // ==================== Media CRUD ====================
  
  Future<List<MediaItem>> getAllMedia() async {
    return _mediaBox.values.map((data) => _mapToMedia(data)).toList();
  }

  Future<MediaItem?> getMediaById(String id) async {
    final data = _mediaBox.get(id);
    if (data == null) return null;
    return _mapToMedia(data);
  }

  /// 按 id 集合批量读取素材（项目加载时只取自己用到的素材）
  Future<List<MediaItem>> getMediaByIds(Iterable<String> ids) async {
    final result = <MediaItem>[];
    for (final id in ids.toSet()) {
      final data = _mediaBox.get(id);
      if (data != null) result.add(_mapToMedia(data));
    }
    return result;
  }

  Future<void> saveMedia(MediaItem media) async {
    await _mediaBox.put(media.id, _mediaToMap(media));
  }

  Future<void> saveMediaBatch(List<MediaItem> mediaList) async {
    final batch = <String, Map<String, dynamic>>{};
    for (final media in mediaList) {
      batch[media.id] = _mediaToMap(media);
    }
    await _mediaBox.putAll(batch);
  }

  Future<void> deleteMedia(String id) async {
    await _mediaBox.delete(id);
  }

  // ==================== Clips CRUD ====================
  
  Future<List<TimelineClip>> getClipsForProject(String projectId) async {
    return _clipsBox.values
        .where((data) => _mapToClip(data).projectId == projectId)
        .map((data) => _mapToClip(data))
        .toList();
  }

  /// 跨项目的所有片段，用于判断素材是否仍被引用
  Future<List<TimelineClip>> getAllClips() async {
    return _clipsBox.values.map(_mapToClip).toList();
  }

  Future<void> deleteClipsForProject(String projectId) async {
    final keys = _clipsBox.keys
        .where((key) => (_clipsBox.get(key)?['projectId'] as String?) == projectId)
        .toList();
    await _clipsBox.deleteAll(keys);
  }

  Future<void> saveClip(TimelineClip clip) async {
    await _clipsBox.put(clip.id, _clipToMap(clip));
  }

  Future<void> deleteClip(String clipId) async {
    await _clipsBox.delete(clipId);
  }

  Future<void> clearAll() async {
    await _projectBox.clear();
    await _mediaBox.clear();
    await _clipsBox.clear();
  }

  // ==================== Data Conversion ====================
  
  Map<String, dynamic> _projectToMap(VideoProject project) {
    return {
      'id': project.id,
      'title': project.title,
      'mediaPaths': project.mediaPaths,
      'duration': project.duration?.inSeconds,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
      'thumbnailPath': project.thumbnailPath,
    };
  }

  VideoProject _mapToProject(Map data) {
    return VideoProject(
      id: data['id'] as String,
      title: data['title'] as String,
      mediaPaths: List<String>.from(data['mediaPaths'] ?? []),
      duration: data['duration'] != null
          ? Duration(seconds: data['duration'] as int)
          : null,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      thumbnailPath: data['thumbnailPath'] as String?,
    );
  }

  Map<String, dynamic> _mediaToMap(MediaItem media) {
    return {
      'id': media.id,
      'path': media.path,
      'type': media.type.index,
      'durationMs': media.durationMs,
      'sizeBytes': media.sizeBytes,
      'thumbnailPath': media.thumbnailPath,
      'width': media.width,
      'height': media.height,
      'createdAt': media.createdAt.toIso8601String(),
      'name': media.name,
      'modifiedMs': media.modifiedMs,
    };
  }

  MediaItem _mapToMedia(Map data) {
    return MediaItem(
      id: data['id'] as String,
      path: data['path'] as String,
      type: MediaType.values[data['type'] as int],
      durationMs: (data['durationMs'] as int?) ?? 0,
      sizeBytes: (data['sizeBytes'] as int?) ?? 0,
      thumbnailPath: data['thumbnailPath'] as String?,
      width: data['width'] as int?,
      height: data['height'] as int?,
      name: data['name'] as String?,
      modifiedMs: (data['modifiedMs'] as int?) ??
          (data['createdAt'] != null
              ? DateTime.parse(data['createdAt'] as String)
                  .millisecondsSinceEpoch
              : null),
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  Map<String, dynamic> _clipToMap(TimelineClip clip) {
    return {
      'id': clip.id,
      'projectId': clip.projectId,
      'mediaId': clip.mediaId,
      'trackIndex': clip.trackIndex,
      'startTimeMs': clip.startTimeMs,
      'endTimeMs': clip.endTimeMs,
      'durationMs': clip.durationMs,
      'positionMs': clip.positionMs,
      'trimStartMs': clip.trimStartMs,
      'trimEndMs': clip.trimEndMs,
      'speed': clip.speed,
      'isReversed': clip.isReversed,
      'effects': clip.effects,
    };
  }

  TimelineClip _mapToClip(Map data) {
    return TimelineClip(
      id: data['id'] as String,
      projectId: data['projectId'] as String,
      mediaId: data['mediaId'] as String,
      trackIndex: data['trackIndex'] as int,
      startTimeMs: data['startTimeMs'] as int,
      endTimeMs: data['endTimeMs'] as int,
      durationMs: data['durationMs'] as int,
      positionMs: data['positionMs'] as int,
      trimStartMs: (data['trimStartMs'] as int?) ?? 0,
      trimEndMs: (data['trimEndMs'] as int?) ?? 0,
      speed: (data['speed'] as num?)?.toDouble() ?? 1.0,
      isReversed: (data['isReversed'] as bool?) ?? false,
      effects: data['effects'] as Map<String, dynamic>?,
    );
  }
}
