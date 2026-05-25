/// 视频项目数据模型
class VideoProject {
  final String id;
  final String title;
  final String? description;
  final List<String> mediaPaths;
  final Duration? duration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;

  VideoProject({
    required this.id,
    required this.title,
    this.description,
    this.mediaPaths = const [],
    this.duration,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'mediaPaths': mediaPaths,
        'duration': duration?.inSeconds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'thumbnailPath': thumbnailPath,
      };

  factory VideoProject.fromMap(Map<String, dynamic> map) => VideoProject(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        mediaPaths: List<String>.from(map['mediaPaths'] ?? []),
        duration: map['duration'] != null
            ? Duration(seconds: map['duration'] as int)
            : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        thumbnailPath: map['thumbnailPath'] as String?,
      );
}
