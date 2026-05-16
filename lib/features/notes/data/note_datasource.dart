import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models.dart';
import '../../../core/storage/storage_manager.dart';

/// 笔记数据源 - Hive 实现
class NotesDataSource {
  late Box<Map> _notesBox;
  late Box<Map> _foldersBox;

  /// 初始化数据源
  Future<void> init() async {
    _notesBox = await Hive.openBox<Map>(StorageKeys.notesBox);
    _foldersBox = await Hive.openBox<Map>(StorageKeys.foldersBox);
  }

  // ==================== 笔记操作 ====================

  /// 获取所有笔记
  List<Note> getAllNotes() {
    return _notesBox.values.map((data) => _mapToNote(data)).toList();
  }

  /// 根据 ID 获取笔记
  Note? getNoteById(String id) {
    final data = _notesBox.get(id);
    if (data == null) return null;
    return _mapToNote(data);
  }

  /// 保存笔记
  Future<void> saveNote(Note note) async {
    await _notesBox.put(note.id, _noteToMap(note));
  }

  /// 删除笔记
  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  /// 批量保存笔记
  Future<void> saveAllNotes(List<Note> notes) async {
    final batch = <String, Map<String, dynamic>>{};
    for (final note in notes) {
      batch[note.id] = _noteToMap(note);
    }
    await _notesBox.putAll(batch);
  }

  /// 根据文件夹 ID 获取笔记
  List<Note> getNotesByFolderId(String? folderId) {
    return getAllNotes().where((note) => note.folderId == folderId).toList();
  }

  /// 搜索笔记
  List<Note> searchNotes(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllNotes().where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// 同步笔记到云端
  Future<void> syncNote(String noteId) async {
    final note = getNoteById(noteId);
    if (note == null) throw Exception('笔记不存在：$noteId');
    
    // 调用云同步数据源上传笔记数据
    // 实际项目中需要注入 SyncDataSource
    await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟
    
    // 标记为已同步
    final updatedNote = note.copyWith(isSynced: true, lastSyncedAt: DateTime.now());
    await saveNote(updatedNote);
  }

  // ==================== 文件夹操作 ====================

  /// 获取所有文件夹
  List<NoteFolder> getAllFolders() {
    return _foldersBox.values.map((data) => _mapToFolder(data)).toList();
  }

  /// 根据 ID 获取文件夹
  NoteFolder? getFolderById(String id) {
    final data = _foldersBox.get(id);
    if (data == null) return null;
    return _mapToFolder(data);
  }

  /// 保存文件夹
  Future<void> saveFolder(NoteFolder folder) async {
    await _foldersBox.put(folder.id, _folderToMap(folder));
  }

  /// 删除文件夹
  Future<void> deleteFolder(String id) async {
    await _foldersBox.delete(id);
  }

  /// 获取子文件夹
  List<NoteFolder> getChildFolders(String parentId) {
    return getAllFolders().where((f) => f.parentId == parentId).toList();
  }

  // ==================== 数据转换 ====================

  Map<String, dynamic> _noteToMap(Note note) {
    return {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'type': note.type.index,
      'tags': note.tags,
      'folderId': note.folderId,
      'isFavorite': note.isFavorite,
      'isSynced': note.isSynced,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
      if (note.mindMapData != null) 'mindMapData': _mindMapToMap(note.mindMapData!),
    };
  }

  Note _mapToNote(Map data) {
    MindMapData? mindMapData;
    if (data.containsKey('mindMapData') && data['mindMapData'] != null) {
      mindMapData = _mapToMindMap(data['mindMapData']);
    }

    return Note(
      id: data['id'] as String,
      title: data['title'] as String,
      content: data['content'] as String,
      type: NoteType.values[data['type'] as int],
      tags: List<String>.from(data['tags'] ?? []),
      folderId: data['folderId'] as String?,
      mindMapData: mindMapData,
      isFavorite: data['isFavorite'] as bool? ?? false,
      isSynced: data['isSynced'] as bool? ?? false,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
    );
  }

  Map<String, dynamic> _mindMapToMap(MindMapData mindMap) {
    return {
      'root': _nodeToMap(mindMap.root),
      'nodes': mindMap.nodes.map((k, v) => MapEntry(k, _nodeToMap(v))).toMap(),
      'layout': mindMap.layout.index,
    };
  }

  MindMapData _mapToMindMap(Map data) {
    final root = _mapToNode(data['root'] as Map);
    final nodesMap = <String, MindMapNode>{};
    if (data.containsKey('nodes')) {
      final nodesData = data['nodes'] as Map;
      nodesData.forEach((key, value) {
        nodesMap[key as String] = _mapToNode(value as Map);
      });
    }
    return MindMapData(
      root: root,
      nodes: nodesMap,
      layout: MindMapLayout.values[data['layout'] as int],
    );
  }

  Map<String, dynamic> _nodeToMap(MindMapNode node) {
    return {
      'id': node.id,
      'text': node.text,
      'childIds': node.childIds,
      'parentId': node.parentId,
      'style': _styleToMap(node.style),
      'x': node.x,
      'y': node.y,
    };
  }

  MindMapNode _mapToNode(Map data) {
    return MindMapNode(
      id: data['id'] as String,
      text: data['text'] as String,
      childIds: List<String>.from(data['childIds'] ?? []),
      parentId: data['parentId'] as String?,
      style: _mapToStyle(data['style'] as Map?),
      x: data['x'] as double?,
      y: data['y'] as double?,
    );
  }

  Map<String, dynamic> _styleToMap(NodeStyle style) {
    return {
      'backgroundColor': style.backgroundColor,
      'textColor': style.textColor,
      'fontSize': style.fontSize,
      'fontWeight': style.fontWeight?.index,
      'borderColor': style.borderColor,
      'borderWidth': style.borderWidth,
    };
  }

  NodeStyle _mapToStyle(Map? data) {
    if (data == null) return const NodeStyle();
    return NodeStyle(
      backgroundColor: data['backgroundColor'] as String?,
      textColor: data['textColor'] as String?,
      fontSize: data['fontSize'] as double?,
      fontWeight: data['fontWeight'] != null 
          ? FontWeight.values[data['fontWeight'] as int] 
          : null,
      borderColor: data['borderColor'] as String?,
      borderWidth: data['borderWidth'] as double?,
    );
  }

  Map<String, dynamic> _folderToMap(NoteFolder folder) {
    return {
      'id': folder.id,
      'name': folder.name,
      'parentId': folder.parentId,
      'noteIds': folder.noteIds,
      'createdAt': folder.createdAt.toIso8601String(),
    };
  }

  NoteFolder _mapToFolder(Map data) {
    return NoteFolder(
      id: data['id'] as String,
      name: data['name'] as String,
      parentId: data['parentId'] as String?,
      noteIds: List<String>.from(data['noteIds'] ?? []),
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    await _notesBox.clear();
    await _foldersBox.clear();
  }
}
