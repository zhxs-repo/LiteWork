import 'package:quill_delta/quill_delta.dart';

/// 图文帖子文档模型
class PostDocumentModel {
  final String id;
  final String title;
  final Delta content; // Quill Delta 格式存储富文本
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverImage;
  final List<String> tags;
  final PostStatus status;

  PostDocumentModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.coverImage,
    this.tags = const [],
    this.status = PostStatus.draft,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'coverImage': coverImage,
      'tags': tags,
      'status': status.name,
    };
  }

  factory PostDocumentModel.fromJson(Map<String, dynamic> json) {
    return PostDocumentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: Delta.fromJson(json['content'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      coverImage: json['coverImage'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      status: PostStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PostStatus.draft,
      ),
    );
  }

  PostDocumentModel copyWith({
    String? id,
    String? title,
    Delta? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverImage,
    List<String>? tags,
    PostStatus? status,
  }) {
    return PostDocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverImage: coverImage ?? this.coverImage,
      tags: tags ?? this.tags,
      status: status ?? this.status,
    );
  }
}

/// 帖子状态
enum PostStatus {
  draft, // 草稿
  published, // 已发布
  scheduled, // 定时发布
  archived, // 已归档
}
