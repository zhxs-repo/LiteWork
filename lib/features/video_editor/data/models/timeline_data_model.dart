/// 时间线数据模型（用于 timeline_canvas.dart）
/// 注意：此文件是为了解决 timeline_canvas.dart 中导入的 timeline_data_model.dart 不存在的问题

/// 轨道类型枚举
enum TrackType {
  video,
  audio,
  text,
}

/// 时间线段模型
class TimelineSegment {
  final int id;
  final String name;
  final double startTime;
  final double duration;
  final TrackType type;

  TimelineSegment({
    required this.id,
    required this.name,
    required this.startTime,
    required this.duration,
    required this.type,
  });
}

/// 轨道模型
class Track {
  final String id;
  final TrackType type;
  final List<TimelineSegment> segments;

  Track({
    required this.id,
    required this.type,
    required this.segments,
  });
}

/// 时间线数据模型
class TimelineData {
  final List<Track> tracks;
  final double totalDuration;

  TimelineData({
    required this.tracks,
    this.totalDuration = 0,
  });
}
