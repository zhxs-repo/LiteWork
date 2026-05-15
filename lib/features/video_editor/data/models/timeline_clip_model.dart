import 'package:hive/hive.dart';

part 'timeline_clip_model.g.dart';

@HiveType(typeId: 22)
class TimelineClip extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String mediaId; // 关联的 MediaItem ID

  @HiveField(2)
  int trackIndex; // 轨道索引 (0=主视频，1=画中画，2=音频，3=字幕)

  @HiveField(3)
  int startTimeMs; // 在时间线上的开始位置

  @HiveField(4)
  int durationMs; // 剪辑片段时长

  @HiveField(5)
  int trimStartMs; // 原始素材裁剪起始点

  @HiveField(6)
  int trimEndMs; // 原始素材裁剪结束点

  @HiveField(7)
  double speed; // 播放速度 (0.5x - 2.0x)

  @HiveField(8)
  bool isReversed; // 是否倒放

  @HiveField(9)
  Map<String, dynamic>? effects; // 滤镜、转场等配置

  TimelineClip({
    required this.id,
    required this.mediaId,
    required this.trackIndex,
    required this.startTimeMs,
    required this.durationMs,
    this.trimStartMs = 0,
    this.trimEndMs = 0,
    this.speed = 1.0,
    this.isReversed = false,
    this.effects,
  });

  factory TimelineClip.fromMap(Map<String, dynamic> map) {
    return TimelineClip(
      id: map['id'] as String,
      mediaId: map['mediaId'] as String,
      trackIndex: map['trackIndex'] as int,
      startTimeMs: map['startTimeMs'] as int,
      durationMs: map['durationMs'] as int,
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
      'mediaId': mediaId,
      'trackIndex': trackIndex,
      'startTimeMs': startTimeMs,
      'durationMs': durationMs,
      'trimStartMs': trimStartMs,
      'trimEndMs': trimEndMs,
      'speed': speed,
      'isReversed': isReversed,
      'effects': effects,
    };
  }
}
