import 'package:hive/hive.dart';

part 'timeline_clip_model.g.dart';

@HiveType(typeId: 22)
class TimelineClip extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId; // 所属项目 ID

  @HiveField(2)
  String mediaId; // 关联的 MediaItem ID

  @HiveField(3)
  int trackIndex; // 轨道索引 (0=主视频，1=画中画，2=音频，3=字幕)

  @HiveField(4)
  int startTimeMs; // 在时间线上的开始位置 (毫秒)

  @HiveField(5)
  int endTimeMs; // 在时间线上的结束位置 (毫秒)

  @HiveField(6)
  int durationMs; // 剪辑片段时长 (毫秒)

  @HiveField(7)
  int positionMs; // 在轨道上的位置 (毫秒)

  @HiveField(8)
  int trimStartMs; // 原始素材裁剪起始点

  @HiveField(9)
  int trimEndMs; // 原始素材裁剪结束点

  @HiveField(10)
  double speed; // 播放速度 (0.5x - 2.0x)

  @HiveField(11)
  bool isReversed; // 是否倒放

  @HiveField(12)
  Map<String, dynamic>? effects; // 滤镜、转场等配置

  TimelineClip({
    required this.id,
    required this.projectId,
    required this.mediaId,
    required this.trackIndex,
    required this.startTimeMs,
    required this.endTimeMs,
    required this.durationMs,
    required this.positionMs,
    this.trimStartMs = 0,
    this.trimEndMs = 0,
    this.speed = 1.0,
    this.isReversed = false,
    this.effects,
  });

  factory TimelineClip.fromMap(Map<String, dynamic> map) {
    return TimelineClip(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      mediaId: map['mediaId'] as String,
      trackIndex: map['trackIndex'] as int,
      startTimeMs: map['startTimeMs'] as int,
      endTimeMs: map['endTimeMs'] as int,
      durationMs: map['durationMs'] as int,
      positionMs: map['positionMs'] as int,
      trimStartMs: map['trimStartMs'] as int? ?? 0,
      trimEndMs: map['trimEndMs'] as int? ?? 0,
      speed: (map['speed'] as num?)?.toDouble() ?? 1.0,
      isReversed: map['isReversed'] as bool? ?? false,
      effects: map['effects'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'mediaId': mediaId,
      'trackIndex': trackIndex,
      'startTimeMs': startTimeMs,
      'endTimeMs': endTimeMs,
      'durationMs': durationMs,
      'positionMs': positionMs,
      'trimStartMs': trimStartMs,
      'trimEndMs': trimEndMs,
      'speed': speed,
      'isReversed': isReversed,
      'effects': effects,
    };
  }
}
