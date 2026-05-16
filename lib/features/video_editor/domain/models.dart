/// 短视频剪辑模块 - 数据模型

/// 视频项目模型
class VideoProject {
  final String id;
  final String title;
  final String? description;
  final List<VideoClip> clips;
  final VideoTemplate? template;
  final ProjectStatus status;
  final Duration totalDuration;
  final String? thumbnailPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  VideoProject({
    required this.id,
    required this.title,
    this.description,
    this.clips = const [],
    this.template,
    this.status = ProjectStatus.draft,
    this.totalDuration = Duration.zero,
    this.thumbnailPath,
    required this.createdAt,
    required this.updatedAt,
  });
  
  VideoProject copyWith({
    String? id,
    String? title,
    String? description,
    List<VideoClip>? clips,
    VideoTemplate? template,
    ProjectStatus? status,
    Duration? totalDuration,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoProject(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      clips: clips ?? this.clips,
      template: template ?? this.template,
      status: status ?? this.status,
      totalDuration: totalDuration ?? this.totalDuration,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 视频片段模型
class VideoClip {
  final String id;
  final String sourcePath;
  final Duration startTime;
  final Duration endTime;
  final Duration duration;
  final double? volume;
  final List<VideoEffect> effects;
  final String? transition;
  
  VideoClip({
    required this.id,
    required this.sourcePath,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.volume,
    this.effects = const [],
    this.transition,
  });
}

/// 视频效果模型
class VideoEffect {
  final EffectType type;
  final Map<String, dynamic> parameters;
  
  VideoEffect({
    required this.type,
    this.parameters = const {},
  });
}

/// 效果类型枚举
enum EffectType {
  filter,       // 滤镜
  text,         // 文字
  sticker,      // 贴纸
  transition,   // 转场
  audio,        // 音频
  speed,        // 速度
}

/// 视频模板模型
class VideoTemplate {
  final String id;
  final String name;
  final String thumbnail;
  final Duration duration;
  final List<TemplateSegment> segments;
  final bool isPremium;
  
  VideoTemplate({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.duration,
    required this.segments,
    this.isPremium = false,
  });
}

/// 模板片段模型
class TemplateSegment {
  final Duration startTime;
  final Duration endTime;
  final String? effectId;
  final String? transitionId;
  
  TemplateSegment({
    required this.startTime,
    required this.endTime,
    this.effectId,
    this.transitionId,
  });
}

/// 项目状态枚举
enum ProjectStatus {
  draft,        // 草稿
  editing,      // 编辑中
  rendering,    // 渲染中
  completed,    // 已完成
  failed,       // 失败
}
