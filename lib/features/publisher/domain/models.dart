/// 图文发布模块 - 数据模型

/// 发布内容模型
class PublishContent {
  final String id;
  final String title;
  final String content;
  final List<String> images;
  final String? coverImage;
  final List<String> tags;
  final PublishStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  PublishContent({
    required this.id,
    required this.title,
    required this.content,
    this.images = const [],
    this.coverImage,
    this.tags = const [],
    this.status = PublishStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });
  
  PublishContent copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? images,
    String? coverImage,
    List<String>? tags,
    PublishStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PublishContent(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      coverImage: coverImage ?? this.coverImage,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 发布状态枚举
enum PublishStatus {
  draft,      // 草稿
  pending,    // 待发布
  published,  // 已发布
  scheduled,  // 定时发布
  failed,     // 发布失败
}

/// 平台类型枚举
enum PlatformType {
  wechat,         // 微信公众号
  weibo,          // 微博
  toutiao,        // 今日头条
  zhihu,          // 知乎
  xiaohongshu,    // 小红书
  douyin,         // 抖音
  bilibili,       // B 站
  custom,         // 自定义平台
}

/// 平台配置模型
class PlatformConfig {
  final PlatformType type;
  final String name;
  final String? accountId;
  final bool isEnabled;
  final Map<String, dynamic> config;
  
  PlatformConfig({
    required this.type,
    required this.name,
    this.accountId,
    this.isEnabled = false,
    this.config = const {},
  });
}
