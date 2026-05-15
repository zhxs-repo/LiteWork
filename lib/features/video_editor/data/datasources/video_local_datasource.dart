import 'package:hive/hive.dart';
import '../models/video_project_model.dart';
import '../models/media_item_model.dart';
import '../models/timeline_clip_model.dart';

class VideoLocalDataSource {
  static const String _projectBoxName = 'video_projects';
  static const String _mediaBoxName = 'media_items';
  static const String _clipsBoxName = 'timeline_clips';

  late Box<VideoProject> _projectBox;
  late Box<MediaItem> _mediaBox;
  late Box<TimelineClip> _clipsBox;

  Future<void> init() async {
    _projectBox = await Hive.openBox<VideoProject>(_projectBoxName);
    _mediaBox = await Hive.openBox<MediaItem>(_mediaBoxName);
    _clipsBox = await Hive.openBox<TimelineClip>(_clipsBoxName);
  }

  // Project CRUD
  Future<List<VideoProject>> getAllProjects() async {
    return _projectBox.values.toList();
  }

  Future<VideoProject?> getProjectById(String id) async {
    return _projectBox.get(id);
  }

  Future<void> saveProject(VideoProject project) async {
    await _projectBox.put(project.id, project);
  }

  Future<void> deleteProject(String id) async {
    await _projectBox.delete(id);
  }

  // Media CRUD
  Future<List<MediaItem>> getAllMedia() async {
    return _mediaBox.values.toList();
  }

  Future<void> saveMedia(MediaItem media) async {
    await _mediaBox.put(media.id, media);
  }

  Future<void> saveMediaBatch(List<MediaItem> mediaList) async {
    for (var media in mediaList) {
      await _mediaBox.put(media.id, media);
    }
  }

  // Clips CRUD
  Future<List<TimelineClip>> getClipsForProject(String projectId) async {
    return _clipsBox.values.where((clip) => clip.id.startsWith(projectId)).toList();
  }

  Future<void> saveClip(TimelineClip clip) async {
    await _clipsBox.put(clip.id, clip);
  }

  Future<void> deleteClip(String clipId) async {
    await _clipsBox.delete(clipId);
  }

  Future<void> clearAll() async {
    await _projectBox.clear();
    await _mediaBox.clear();
    await _clipsBox.clear();
  }
}
