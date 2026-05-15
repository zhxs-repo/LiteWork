/// 搜索结果数据模型
class SearchResult {
  final String id;
  final String title;
  final String contentSnippet;
  final String type; // 'post', 'note', 'video_project'
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  SearchResult({
    required this.id,
    required this.title,
    required this.contentSnippet,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// 从 PostDocumentModel 创建
  factory SearchResult.fromPost(Map<String, dynamic> post) {
    return SearchResult(
      id: post['id'] as String,
      title: post['title'] as String? ?? '无标题',
      contentSnippet: _extractTextFromDelta(post['content']),
      type: 'post',
      createdAt: DateTime.parse(post['createdAt'] as String),
      updatedAt: DateTime.parse(post['updatedAt'] as String),
      metadata: {
        'status': post['status'],
        'platforms': post['platformConfigs'],
      },
    );
  }

  /// 从 Note 创建
  factory SearchResult.fromNote(Map<String, dynamic> note) {
    return SearchResult(
      id: note['id'] as String,
      title: note['title'] as String? ?? '无标题',
      contentSnippet: _extractTextFromDelta(note['content']),
      type: 'note',
      createdAt: DateTime.parse(note['createdAt'] as String),
      updatedAt: DateTime.parse(note['updatedAt'] as String),
      metadata: {
        'folderId': note['folderId'],
        'tags': note['tags'],
      },
    );
  }

  /// 从 VideoProject 创建
  factory SearchResult.fromVideoProject(Map<String, dynamic> project) {
    return SearchResult(
      id: project['id'] as String,
      title: project['name'] as String,
      contentSnippet: '视频项目 - ${project['clips']?.length ?? 0} 个片段',
      type: 'video_project',
      createdAt: DateTime.parse(project['createdAt'] as String),
      updatedAt: DateTime.parse(project['updatedAt'] as String),
      metadata: {
        'duration': project['totalDuration'],
        'resolution': project['resolution'],
      },
    );
  }

  /// 从 Delta 格式提取纯文本
  static String _extractTextFromDelta(dynamic delta) {
    if (delta == null) return '';
    if (delta is String) return delta;
    
    if (delta is Map) {
      final ops = delta['ops'] as List?;
      if (ops == null) return '';
      
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op.containsKey('insert')) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          }
        }
      }
      return buffer.toString();
    }
    
    return '';
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'contentSnippet': contentSnippet,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 从 Map 创建
  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      id: map['id'] as String,
      title: map['title'] as String,
      contentSnippet: map['contentSnippet'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}
