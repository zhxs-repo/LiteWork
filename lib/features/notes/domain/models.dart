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
}

/// 节点样式模型
class NodeStyle {
  final String? backgroundColor;
  final String? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final String? borderColor;
  final double? borderWidth;
  
  const NodeStyle({
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.borderColor,
    this.borderWidth,
  });
  
  NodeStyle copyWith({
    String? backgroundColor,
    String? textColor,
    double? fontSize,
    FontWeight? fontWeight,
    String? borderColor,
    double? borderWidth,
  }) {
    return NodeStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
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
