/// 笔记模块 - 数据模型

/// 笔记类型枚举
enum NoteType {
  richText,       // 富文本笔记
  mindMap,        // 思维导图
  mixed,          // 混合类型
}

/// 笔记模型
class Note {
  final String id;
  final String title;
  final String content;
  final NoteType type;
  final List<String> tags;
  final String? folderId;
  final MindMapData? mindMapData;
  final bool isFavorite;
  final bool isSynced;
  final bool isPinned;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Note({
    required this.id,
    required this.title,
    required this.content,
    this.type = NoteType.richText,
    this.tags = const [],
    this.folderId,
    this.mindMapData,
    this.isFavorite = false,
    this.isSynced = false,
    this.isPinned = false,
    this.lastSyncedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  
  Note copyWith({
    String? id,
    String? title,
    String? content,
    NoteType? type,
    List<String>? tags,
    String? folderId,
    MindMapData? mindMapData,
    bool? isFavorite,
    bool? isSynced,
    bool? isPinned,
    DateTime? lastSyncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      folderId: folderId ?? this.folderId,
      mindMapData: mindMapData ?? this.mindMapData,
      isFavorite: isFavorite ?? this.isFavorite,
      isSynced: isSynced ?? this.isSynced,
      isPinned: isPinned ?? this.isPinned,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 思维导图数据模型
class MindMapData {
  final MindMapNode root;
  final Map<String, MindMapNode> nodes;
  final MindMapLayout layout;
  
  MindMapData({
    required this.root,
    this.nodes = const {},
    this.layout = MindMapLayout.horizontal,
  });
  
  MindMapData copyWith({
    MindMapNode? root,
    Map<String, MindMapNode>? nodes,
    MindMapLayout? layout,
  }) {
    return MindMapData(
      root: root ?? this.root,
      nodes: nodes ?? this.nodes,
      layout: layout ?? this.layout,
    );
  }
  
  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'root': root.toJson(),
      'nodes': nodes.map((key, value) => MapEntry(key, value.toJson())),
      'layout': layout.name,
    };
  }
  
  /// 从 JSON Map 创建
  factory MindMapData.fromJson(Map<String, dynamic> json) {
    final rootJson = json['root'] as Map<String, dynamic>;
    final root = MindMapNode.fromJson(rootJson);
    final nodesJson = json['nodes'] as Map<String, dynamic>? ?? {};
    final nodes = <String, MindMapNode>{};
    nodesJson.forEach((key, value) {
      nodes[key] = MindMapNode.fromJson(value as Map<String, dynamic>);
    });
    return MindMapData(
      root: root,
      nodes: nodes,
      layout: MindMapLayout.values.firstWhere(
        (e) => e.name == json['layout'],
        orElse: () => MindMapLayout.horizontal,
      ),
    );
  }
}

/// 思维导图节点模型
class MindMapNode {
  final String id;
  final String text;
  final List<String> childIds;
  final String? parentId;
  final NodeStyle style;
  final double? x;
  final double? y;
  
  MindMapNode({
    required this.id,
    required this.text,
    this.childIds = const [],
    this.parentId,
    this.style = const NodeStyle(),
    this.x,
    this.y,
  });
  
  MindMapNode copyWith({
    String? id,
    String? text,
    List<String>? childIds,
    String? parentId,
    NodeStyle? style,
    double? x,
    double? y,
  }) {
    return MindMapNode(
      id: id ?? this.id,
      text: text ?? this.text,
      childIds: childIds ?? this.childIds,
      parentId: parentId ?? this.parentId,
      style: style ?? this.style,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
  
  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'childIds': childIds,
      'parentId': parentId,
      'style': style.toJson(),
      'x': x,
      'y': y,
    };
  }
  
  /// 从 JSON Map 创建
  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      id: json['id'] as String,
      text: json['text'] as String,
      childIds: List<String>.from(json['childIds'] ?? []),
      parentId: json['parentId'] as String?,
      style: json['style'] != null 
          ? NodeStyle.fromJson(json['style'] as Map<String, dynamic>)
          : const NodeStyle(),
      x: json['x'] as double?,
      y: json['y'] as double?,
    );
  }
}

/// 节点样式模型
class NodeStyle {
  final String? backgroundColor;
  final String? textColor;
  final double? fontSize;
  final int? fontWeightIndex;
  final String? borderColor;
  final double? borderWidth;
  
  const NodeStyle({
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.fontWeightIndex,
    this.borderColor,
    this.borderWidth,
  });
  
  NodeStyle copyWith({
    String? backgroundColor,
    String? textColor,
    double? fontSize,
    int? fontWeightIndex,
    String? borderColor,
    double? borderWidth,
  }) {
    return NodeStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      fontWeightIndex: fontWeightIndex ?? this.fontWeightIndex,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }
  
  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'fontSize': fontSize,
      'fontWeightIndex': fontWeightIndex,
      'borderColor': borderColor,
      'borderWidth': borderWidth,
    };
  }
  
  /// 从 JSON Map 创建
  factory NodeStyle.fromJson(Map<String, dynamic> json) {
    return NodeStyle(
      backgroundColor: json['backgroundColor'] as String?,
      textColor: json['textColor'] as String?,
      fontSize: json['fontSize'] as double?,
      fontWeightIndex: json['fontWeightIndex'] as int?,
      borderColor: json['borderColor'] as String?,
      borderWidth: json['borderWidth'] as double?,
    );
  }
}

/// 思维导图布局枚举
enum MindMapLayout {
  horizontal,   // 水平布局
  vertical,     // 垂直布局
  radial,       // 辐射布局
  free,         // 自由布局
}

/// 文件夹模型
class NoteFolder {
  final String id;
  final String name;
  final String? parentId;
  final List<String> noteIds;
  final DateTime createdAt;
  
  NoteFolder({
    required this.id,
    required this.name,
    this.parentId,
    this.noteIds = const [],
    required this.createdAt,
  });
  
  int get noteCount => noteIds.length;
  
  NoteFolder copyWith({
    String? id,
    String? name,
    String? parentId,
    List<String>? noteIds,
    DateTime? createdAt,
  }) {
    return NoteFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      noteIds: noteIds ?? this.noteIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
