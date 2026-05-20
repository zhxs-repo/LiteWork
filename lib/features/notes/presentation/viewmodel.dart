/// 笔记模块 - ViewModel (MVVM)

import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../data/note_datasource.dart';
import '../data/datasources/trash_datasource.dart';

/// 回收站项目模型
class TrashItem {
  final String id;
  final String title;
  final String type;
  final Map<String, dynamic> data;
  final DateTime deletedAt;

  TrashItem({
    required this.id,
    required this.title,
    required this.type,
    required this.data,
    required this.deletedAt,
  });

  factory TrashItem.fromMapEntry(MapEntry<String, Map> entry) {
    final data = entry.value;
    return TrashItem(
      id: entry.key,
      title: data['data']?['title'] as String? ?? '未命名',
      type: data['type'] as String,
      data: data['data'] as Map<String, dynamic>,
      deletedAt: DateTime.parse(data['deletedAt'] as String),
    );
  }
}
=======
    required this.title,
    required this.type,
    required this.deletedAt,
  });
>>>>>>> fe8f533 (feat: 添加多平台支持并修复代码错误)
}

/// 笔记管理 ViewModel
class NotesViewModel extends ChangeNotifier {
  final NotesDataSource _dataSource = NotesDataSource();
  final TrashDataSource _trashDataSource = TrashDataSource();
  final List<Note> _notes = [];
  final List<NoteFolder> _folders = [];
  final List<TrashItem> _trashItems = [];
  Note? _currentNote;
  bool _isLoading = false;
  String? _error;
  String? _selectedFolderId;
  bool _isInitialized = false;
  bool _isTrashInitialized = false;
  
  List<Note> get notes => _notes;
  List<NoteFolder> get folders => _folders;
  List<TrashItem> get trashItems => _trashItems;
  Note? get currentNote => _currentNote;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedFolderId => _selectedFolderId;
  bool get isInitialized => _isInitialized;
  
  /// 获取过滤后的笔记列表
  List<Note> get filteredNotes {
    if (_selectedFolderId == null) return _notes;
    return _notes.where((n) => n.folderId == _selectedFolderId).toList();
  }
  
  /// 初始化数据源并加载数据
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dataSource.init();
      await _trashDataSource.init();
      await loadNotes();
      await loadFolders();
      await loadTrashItems();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '初始化失败：${e.toString()}';
      notifyListeners();
    }
  }
  
  /// 加载笔记列表
  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final loadedNotes = _dataSource.getAllNotes();
      _notes.clear();
      _notes.addAll(loadedNotes);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 加载文件夹列表
  Future<void> loadFolders() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final loadedFolders = _dataSource.getAllFolders();
      _folders.clear();
      _folders.addAll(loadedFolders);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 创建新笔记
  Future<void> createNote({
    required String title,
    String content = '',
    NoteType type = NoteType.richText,
    String? folderId,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final note = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        type: type,
        folderId: folderId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _dataSource.saveNote(note);
      _notes.insert(0, note);
      _currentNote = note;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 打开笔记
  void openNote(String noteId) {
    _currentNote = _notes.firstWhere(
      (n) => n.id == noteId,
      orElse: () => throw Exception('Note not found'),
    );
    notifyListeners();
  }
  
  /// 更新笔记
  Future<void> updateNote(Note note) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final updatedNote = note.copyWith(
        updatedAt: DateTime.now(),
      );
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
        _currentNote = updatedNote;
      } else {
        _notes.add(updatedNote);
        _currentNote = updatedNote;
      }
      await _dataSource.saveNote(updatedNote);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 删除笔记
  Future<void> deleteNote(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dataSource.deleteNote(id);
      _notes.removeWhere((n) => n.id == id);
      if (_currentNote?.id == id) {
        _currentNote = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 切换收藏状态
  void toggleFavorite(String noteId) {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        isFavorite: !_notes[index].isFavorite,
      );
      if (_currentNote?.id == noteId) {
        _currentNote = _notes[index];
      }
      notifyListeners();
    }
  }
  
  /// 选择文件夹
  void selectFolder(String? folderId) {
    _selectedFolderId = folderId;
    notifyListeners();
  }
  
  /// 创建文件夹
  Future<void> createFolder(String name, {String? parentId}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final folder = NoteFolder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        parentId: parentId,
        createdAt: DateTime.now(),
      );
      
      await _dataSource.saveFolder(folder);
      _folders.add(folder);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 移动笔记到文件夹
  Future<void> moveNoteToFolder(String noteId, String? folderId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      final updatedNote = _notes[index].copyWith(folderId: folderId);
      _notes[index] = updatedNote;
      await _dataSource.saveNote(updatedNote);
      notifyListeners();
    }
  }
  
  /// 删除文件夹
  Future<void> deleteFolder(String folderId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dataSource.deleteFolder(folderId);
      _folders.removeWhere((f) => f.id == folderId);
      // 同时更新该文件夹下的笔记
      for (var i = 0; i < _notes.length; i++) {
        if (_notes[i].folderId == folderId) {
          final updatedNote = _notes[i].copyWith(folderId: null);
          _notes[i] = updatedNote;
          await _dataSource.saveNote(updatedNote);
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 同步笔记
  Future<void> syncNote(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _isLoading = true;
      notifyListeners();
      
      try {
        await _dataSource.syncNote(noteId);
        _notes[index] = _notes[index].copyWith(isSynced: true, lastSyncedAt: DateTime.now());
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _isLoading = false;
        _error = e.toString();
        notifyListeners();
      }
    }
  }
  
  /// 加载回收站项目
  Future<void> loadTrashItems() async {
<<<<<<< HEAD
    if (_isTrashInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _trashDataSource.init();
      final items = _trashDataSource.getAll();
      _trashItems.clear();
      _trashItems.addAll(items.map((e) => TrashItem.fromMapEntry(e)).toList());
      _isTrashInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
=======
    try {
      final items = _trashDataSource.getAll();
      _trashItems.clear();
      for (final entry in items) {
        final data = entry.value;
        _trashItems.add(TrashItem(
          id: data['id'] as String,
          title: data['data']?['title'] as String? ?? '未命名',
          type: data['type'] as String,
          deletedAt: DateTime.parse(data['deletedAt'] as String),
        ));
      }
      notifyListeners();
    } catch (e) {
>>>>>>> fe8f533 (feat: 添加多平台支持并修复代码错误)
      _error = '加载回收站失败：${e.toString()}';
      notifyListeners();
    }
  }
  
<<<<<<< HEAD
  /// 从回收站恢复项目
  Future<void> restoreFromTrash(String itemId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _trashDataSource.restore(itemId);
      if (result == null) {
        throw Exception('项目不存在');
      }
      
      final type = result['type'] as String;
      final data = result['data'] as Map<String, dynamic>;
      
      if (type == 'note') {
        // 恢复笔记
        final note = Note(
          id: data['id'] as String,
          title: data['title'] as String,
          content: data['content'] as String,
          type: NoteType.values.firstWhere((e) => e.name == data['type'], orElse: () => NoteType.richText),
          folderId: data['folderId'] as String?,
          isFavorite: data['isFavorite'] as bool? ?? false,
          isSynced: data['isSynced'] as bool? ?? false,
          createdAt: DateTime.parse(data['createdAt'] as String),
          updatedAt: DateTime.now(),
        );
        await _dataSource.saveNote(note);
        final existingIndex = _notes.indexWhere((n) => n.id == note.id);
        if (existingIndex != -1) {
          _notes[existingIndex] = note;
        } else {
          _notes.insert(0, note);
        }
      } else if (type == 'folder') {
        // 恢复文件夹
        final folder = NoteFolder(
          id: data['id'] as String,
          name: data['name'] as String,
          parentId: data['parentId'] as String?,
          createdAt: DateTime.parse(data['createdAt'] as String),
        );
        await _dataSource.saveFolder(folder);
        final existingIndex = _folders.indexWhere((f) => f.id == folder.id);
        if (existingIndex != -1) {
          _folders[existingIndex] = folder;
        } else {
          _folders.add(folder);
        }
      }
      
      // 从本地缓存移除
      _trashItems.removeWhere((item) => item.id == itemId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
=======
  /// 移动到回收站
  Future<void> moveToTrash(Note note) async {
    try {
      await _trashDataSource.add(
        note.id,
        {
          'id': note.id,
          'title': note.title,
          'content': note.content,
          'type': note.type.index,
          'tags': note.tags,
          'folderId': note.folderId,
          'createdAt': note.createdAt.toIso8601String(),
          'updatedAt': note.updatedAt.toIso8601String(),
        },
        'note',
      );
      await _dataSource.deleteNote(note.id);
      _notes.removeWhere((n) => n.id == note.id);
      if (_currentNote?.id == note.id) {
        _currentNote = null;
      }
      await loadTrashItems();
      notifyListeners();
    } catch (e) {
      _error = '移动到回收站失败：${e.toString()}';
      notifyListeners();
    }
  }
  
  /// 从回收站恢复
  Future<void> restoreFromTrash(String itemId) async {
    try {
      final result = await _trashDataSource.restore(itemId);
      if (result != null) {
        final data = result['data'] as Map<String, dynamic>;
        final restoredNote = Note(
          id: data['id'] as String,
          title: data['title'] as String,
          content: data['content'] as String,
          type: NoteType.values[data['type'] as int],
          tags: List<String>.from(data['tags'] ?? []),
          folderId: data['folderId'] as String?,
          createdAt: DateTime.parse(data['createdAt'] as String),
          updatedAt: DateTime.parse(data['updatedAt'] as String),
        );
        await _dataSource.saveNote(restoredNote);
        _notes.insert(0, restoredNote);
        await loadTrashItems();
        notifyListeners();
      }
    } catch (e) {
>>>>>>> fe8f533 (feat: 添加多平台支持并修复代码错误)
      _error = '恢复失败：${e.toString()}';
      notifyListeners();
    }
  }
  
<<<<<<< HEAD
  /// 彻底删除回收站项目
  Future<void> deletePermanently(String itemId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _trashDataSource.deletePermanently(itemId);
      _trashItems.removeWhere((item) => item.id == itemId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
=======
  /// 彻底删除
  Future<void> deletePermanently(String itemId) async {
    try {
      await _trashDataSource.deletePermanently(itemId);
      _trashItems.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
>>>>>>> fe8f533 (feat: 添加多平台支持并修复代码错误)
      _error = '删除失败：${e.toString()}';
      notifyListeners();
    }
  }
  
  /// 清空回收站
  Future<void> clearTrash() async {
<<<<<<< HEAD
    _isLoading = true;
    notifyListeners();
    
    try {
      await _trashDataSource.clear();
      _trashItems.clear();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
=======
    try {
      await _trashDataSource.clear();
      _trashItems.clear();
      notifyListeners();
    } catch (e) {
>>>>>>> fe8f533 (feat: 添加多平台支持并修复代码错误)
      _error = '清空回收站失败：${e.toString()}';
      notifyListeners();
    }
  }
  
  /// 清空错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
