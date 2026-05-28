/// WebDAV 远程数据源 - 笔记同步实现
/// 
/// 负责与 WebDAV 服务器进行笔记数据的上传和下载

import 'dart:convert';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/webdav_client.dart';
import '../../domain/models.dart';

/// 笔记 WebDAV 远程数据源
class NotesRemoteDataSource {
  final WebDavClient _webDavClient;
  
  NotesRemoteDataSource(this._webDavClient);
  
  /// 检查 WebDAV 是否已配置
  bool get isConfigured => _webDavClient.isConfigured;
  
  // ==================== 笔记同步操作 ====================
  
  /// 上传笔记到 WebDAV
  Future<void> uploadNote(Note note) async {
    if (!_webDavClient.isConfigured) {
      throw const NetworkException('WebDAV 未配置，无法同步');
    }
    
    try {
      final noteJson = jsonEncode(_noteToMap(note));
      final remotePath = _webDavClient.getNotePath(note.id);
      
      await _webDavClient.upload(
        remotePath: remotePath,
        data: noteJson,
        contentType: 'application/json',
      );
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('上传笔记失败：$e');
    }
  }
  
  /// 从 WebDAV 下载笔记
  Future<Note> downloadNote(String noteId) async {
    if (!_webDavClient.isConfigured) {
      throw const NetworkException('WebDAV 未配置，无法同步');
    }
    
    try {
      final remotePath = _webDavClient.getNotePath(noteId);
      final noteJson = await _webDavClient.download(remotePath: remotePath);
      final noteMap = jsonDecode(noteJson) as Map<String, dynamic>;
      
      return _mapToNote(noteMap);
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('下载笔记失败：$e');
    }
  }
  
  /// 删除远程笔记
  Future<void> deleteRemoteNote(String noteId) async {
    if (!_webDavClient.isConfigured) {
      throw const NetworkException('WebDAV 未配置，无法同步');
    }
    
    try {
      final remotePath = _webDavClient.getNotePath(noteId);
      await _webDavClient.delete(remotePath: remotePath);
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('删除远程笔记失败：$e');
    }
  }
  
  /// 检查远程笔记是否存在
  Future<bool> noteExists(String noteId) async {
    if (!_webDavClient.isConfigured) return false;
    
    try {
      final remotePath = _webDavClient.getNotePath(noteId);
      return await _webDavClient.exists(remotePath);
    } catch (e) {
      return false;
    }
  }
  
  // ==================== 文件夹同步操作 ====================
  
  /// 上传文件夹到 WebDAV
  Future<void> uploadFolder(NoteFolder folder) async {
    if (!_webDavClient.isConfigured) {
      throw const NetworkException('WebDAV 未配置，无法同步');
    }
    
    try {
      final folderJson = jsonEncode(_folderToMap(folder));
      final remotePath = _webDavClient.getFolderPath(folder.id);
      
      await _webDavClient.upload(
        remotePath: remotePath,
        data: folderJson,
        contentType: 'application/json',
      );
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('上传文件夹失败：$e');
    }
  }
  
  /// 从 WebDAV 下载文件夹
  Future<NoteFolder> downloadFolder(String folderId) async {
    if (!_webDavClient.isConfigured) {
      throw const NetworkException('WebDAV 未配置，无法同步');
    }
    
    try {
      final remotePath = _webDavClient.getFolderPath(folderId);
      final folderJson = await _webDavClient.download(remotePath: remotePath);
      final folderMap = jsonDecode(folderJson) as Map<String, dynamic>;
      
      return _mapToFolder(folderMap);
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('下载文件夹失败：$e');
    }
  }
  
  /// 删除远程文件夹
  Future<void> deleteRemoteFolder(String folderId) async {
    if (!_webDavClient.isConfigured) {
      throw const NetworkException('WebDAV 未配置，无法同步');
    }
    
    try {
      final remotePath = _webDavClient.getFolderPath(folderId);
      await _webDavClient.delete(remotePath: remotePath);
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('删除远程文件夹失败：$e');
    }
  }
  
  // ==================== 全量同步 ====================
  
  /// 获取所有远程笔记 ID 列表
  Future<List<String>> getAllRemoteNoteIds() async {
    if (!_webDavClient.isConfigured) return [];
    
    try {
      final notesDir = _webDavClient.getNotesDir();
      final items = await _webDavClient.listDirectory(notesDir);
      
      // 过滤出 .json 文件并提取 ID
      return items
          .where((item) => item.endsWith('.json'))
          .map((item) => item.replaceAll('.json', '').split('/').last)
          .toList();
    } catch (e) {
      return [];
    }
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
      'isPinned': note.isPinned,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
      if (note.lastSyncedAt != null) 'lastSyncedAt': note.lastSyncedAt!.toIso8601String(),
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
      isPinned: data['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      lastSyncedAt: data['lastSyncedAt'] != null 
          ? DateTime.parse(data['lastSyncedAt'] as String) 
          : null,
    );
  }
  
  Map<String, dynamic> _mindMapToMap(MindMapData mindMap) {
    return {
      'root': _nodeToMap(mindMap.root),
      'nodes': mindMap.nodes.map((k, v) => MapEntry(k, _nodeToMap(v))),
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
      'fontWeightIndex': style.fontWeightIndex,
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
      fontWeightIndex: data['fontWeightIndex'] as int?,
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
}
