/// 笔记管理 ViewModel - 基于 UseCase 的 Clean Architecture 实现

import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../domain/usecases/get_notes_use_case.dart';
import '../domain/usecases/save_note_use_case.dart';
import '../domain/usecases/delete_note_use_case.dart';
import '../domain/usecases/move_note_to_trash_use_case.dart';
import '../domain/usecases/restore_from_trash_use_case.dart';
import '../domain/usecases/get_folders_use_case.dart';
import '../domain/usecases/create_folder_usecase.dart';
import '../domain/usecases/delete_folder_usecase.dart';
import '../domain/usecases/clear_trash_usecase.dart';
import '../domain/usecases/delete_permanently_usecase.dart';

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

/// 笔记管理 ViewModel
class NotesViewModel extends ChangeNotifier {
  final GetNotesUseCase _getNotesUseCase;
  final SaveNoteUseCase _saveNoteUseCase;
  final DeleteNoteUseCase _deleteNoteUseCase;
  final MoveNoteToTrashUseCase _moveNoteToTrashUseCase;
  final RestoreFromTrashUseCase _restoreFromTrashUseCase;
  final GetFoldersUseCase _getFoldersUseCase;
  final CreateFolderUseCase _createFolderUseCase;
  final DeleteFolderUseCase _deleteFolderUseCase;
  final ClearTrashUseCase _clearTrashUseCase;
  final DeletePermanentlyUseCase _deletePermanentlyUseCase;

  final List<Note> _notes = [];
  final List<NoteFolder> _folders = [];
  final List<TrashItem> _trashItems = [];
  Note? _currentNote;
  bool _isLoading = false;
  String? _error;
  String? _selectedFolderId;
  bool _isInitialized = false;
  bool _isTrashInitialized = false;

  NotesViewModel({
    required GetNotesUseCase getNotesUseCase,
    required SaveNoteUseCase saveNoteUseCase,
    required DeleteNoteUseCase deleteNoteUseCase,
    required MoveNoteToTrashUseCase moveNoteToTrashUseCase,
    required RestoreFromTrashUseCase restoreFromTrashUseCase,
    required GetFoldersUseCase getFoldersUseCase,
    required CreateFolderUseCase createFolderUseCase,
    required DeleteFolderUseCase deleteFolderUseCase,
    required ClearTrashUseCase clearTrashUseCase,
    required DeletePermanentlyUseCase deletePermanentlyUseCase,
  })  : _getNotesUseCase = getNotesUseCase,
        _saveNoteUseCase = saveNoteUseCase,
        _deleteNoteUseCase = deleteNoteUseCase,
        _moveNoteToTrashUseCase = moveNoteToTrashUseCase,
        _restoreFromTrashUseCase = restoreFromTrashUseCase,
        _getFoldersUseCase = getFoldersUseCase,
        _createFolderUseCase = createFolderUseCase,
        _deleteFolderUseCase = deleteFolderUseCase,
        _clearTrashUseCase = clearTrashUseCase,
        _deletePermanentlyUseCase = deletePermanentlyUseCase;

  List<Note> get notes => _notes;
  List<NoteFolder> get folders => _folders;
  List<TrashItem> get trashItems => _trashItems;
  Note? get currentNote => _currentNote;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedFolderId => _selectedFolderId;
  bool get isInitialized => _isInitialized;

  /// 获取过滤后的笔记列表（置顶在前）
  List<Note> get filteredNotes {
    final filtered = _selectedFolderId == null
        ? _notes
        : _notes.where((n) => n.folderId == _selectedFolderId).toList();
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return filtered;
  }

  /// 初始化数据源并加载数据
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
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
      final result = await _getNotesUseCase();
      result.fold(
        (failure) {
          _isLoading = false;
          _error = failure.message;
          notifyListeners();
        },
        (loadedNotes) {
          _notes.clear();
          _notes.addAll(loadedNotes);
          _isLoading = false;
          notifyListeners();
        },
      );
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
      final result = await _getFoldersUseCase();
      result.fold(
        (failure) {
          _isLoading = false;
          _error = failure.message;
          notifyListeners();
        },
        (folders) {
          _folders.clear();
          _folders.addAll(folders);
          _isLoading = false;
          notifyListeners();
        },
      );
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
    MindMapData? mindMapData,
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
        mindMapData: mindMapData,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await _saveNoteUseCase(note);
      result.fold(
        (failure) {
          _isLoading = false;
          _error = failure.message;
          notifyListeners();
        },
        (_) {
          _notes.insert(0, note);
          _currentNote = note;
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 打开笔记
  void openNote(String noteId) {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index == -1) {
      _error = '笔记不存在：$noteId';
      notifyListeners();
      return;
    }
    _currentNote = _notes[index];
    notifyListeners();
  }

  /// 更新笔记
  Future<void> updateNote(Note note) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
      } else {
        _notes.add(updatedNote);
      }
      _currentNote = updatedNote;
      
      final result = await _saveNoteUseCase(updatedNote);
      result.fold(
        (failure) {
          _isLoading = false;
          _error = failure.message;
          notifyListeners();
        },
        (_) {
          _isLoading = false;
          notifyListeners();
        },
      );
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
      final result = await _deleteNoteUseCase(id);
      result.fold(
        (failure) {
          _isLoading = false;
          _error = failure.message;
          notifyListeners();
        },
        (_) {
          _notes.removeWhere((n) => n.id == id);
          if (_currentNote?.id == id) {
            _currentNote = null;
          }
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 切换置顶状态
  Future<void> togglePin(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(isPinned: !_notes[index].isPinned);
      if (_currentNote?.id == noteId) {
        _currentNote = _notes[index];
      }
      notifyListeners();
      await _saveNoteUseCase(_notes[index]);
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(isFavorite: !_notes[index].isFavorite);
      if (_currentNote?.id == noteId) {
        _currentNote = _notes[index];
      }
      notifyListeners();
      await _saveNoteUseCase(_notes[index]);
    }
  }

  /// 选择文件夹
  void selectFolder(String? folderId) {
    _selectedFolderId = folderId;
    notifyListeners();
  }

  /// 移动笔记到回收站
  Future<void> moveToTrash(Note note) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _moveNoteToTrashUseCase(note);
      result.fold(
        (failure) {
          _isLoading = false;
          _error = failure.message;
          notifyListeners();
        },
        (_) {
          _notes.removeWhere((n) => n.id == note.id);
          if (_currentNote?.id == note.id) {
            _currentNote = null;
          }
          _isTrashInitialized = false;
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _error = '移动到回收站失败：${e.toString()}';
      notifyListeners();
    }
  }

  /// 从回收站恢复项目
  Future<void> restoreFromTrash(String itemId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _restoreFromTrashUseCase(itemId);
      result.fold(
        (failure) {
          _isLoading = false;
          _error = failure.message;
          notifyListeners();
        },
        (_) {
          _trashItems.removeWhere((item) => item.id == itemId);
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _error = '恢复失败：${e.toString()}';
      notifyListeners();
    }
  }

  /// 清空错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 创建文件夹
  Future<void> createFolder(String name) async {
    try {
      final folder = NoteFolder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
      );
      final result = await _createFolderUseCase(folder);
      result.fold(
        (failure) {
          _error = failure.message;
          notifyListeners();
        },
        (_) {
          _folders.add(folder);
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 删除文件夹
  Future<void> deleteFolder(String folderId) async {
    try {
      final result = await _deleteFolderUseCase(folderId);
      result.fold(
        (failure) {
          _error = failure.message;
          notifyListeners();
        },
        (_) {
          _folders.removeWhere((f) => f.id == folderId);
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 移动笔记到文件夹
  Future<void> moveNoteToFolder(String noteId, String? folderId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(folderId: folderId);
      if (_currentNote?.id == noteId) {
        _currentNote = _notes[index];
      }
      notifyListeners();
      await _saveNoteUseCase(_notes[index]);
    }
  }

  /// 清空回收站
  Future<void> clearTrash() async {
    try {
      await _clearTrashUseCase();
      _trashItems.clear();
      _isTrashInitialized = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 彻底删除回收站项目
  Future<void> deletePermanently(String itemId) async {
    try {
      await _deletePermanentlyUseCase(itemId);
      _trashItems.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
