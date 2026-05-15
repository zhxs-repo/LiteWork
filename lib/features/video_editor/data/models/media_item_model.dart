import 'package:hive/hive.dart';

part 'media_item_model.g.dart';

@HiveType(typeId: 20)
enum MediaType {
  @HiveField(0) video,
  @HiveField(1) image,
  @HiveField(2) audio,
}

@HiveType(typeId: 21)
class MediaItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String path;

  @HiveField(2)
  MediaType type;

  @HiveField(3)
  int durationMs; // 视频/音频时长，图片为0

  @HiveField(4)
  int sizeBytes;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String? thumbnailPath;

  @HiveField(7)
  int? width;

  @HiveField(8)
  int? height;

  MediaItem({
    required this.id,
    required this.path,
    required this.type,
    this.durationMs = 0,
    this.sizeBytes = 0,
    required this.createdAt,
    this.thumbnailPath,
    this.width,
    this.height,
  });

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as String,
      path: map['path'] as String,
      type: MediaType.values[map['type'] as int],
      durationMs: map['durationMs'] as int? ?? 0,
      sizeBytes: map['sizeBytes'] as int? ?? 0,
      createdAt: map['createdAt'] as DateTime,
      thumbnailPath: map['thumbnailPath'] as String?,
      width: map['width'] as int?,
      height: map['height'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'type': type.index,
      'durationMs': durationMs,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt,
      'thumbnailPath': thumbnailPath,
      'width': width,
      'height': height,
    };
  }
}
