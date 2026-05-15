/// 笔记模块 - ViewModel (MVVM)

import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../data/note_datasource.dart';

/// 笔记管理 ViewModel
class NotesViewModel extends ChangeNotifier {
  final NotesDataSource _dataSource = NotesDataSource();
  final List<Note> _notes = [];
  final List<NoteFolder> _folders = [];
  Note? _currentNote;
  bool _isLoading = false;
  String? _error;
  String? _selectedFolderId;
  bool _isInitialized = false;
  
  List<Note> get notes => _notes;
  List<NoteFolder> get folders => _folders;
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
      await loadNotes();
      await loadFolders();
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
        // TODO: 实现同步逻辑
        await Future.delayed(const Duration(seconds: 1));
        _notes[index] = _notes[index].copyWith(isSynced: true);
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _isLoading = false;
        _error = e.toString();
        notifyListeners();
      }
    }
  }
  
  /// 清空错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
