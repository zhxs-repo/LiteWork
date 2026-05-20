import 'dart:async';
import 'dart:convert';

import '../../features/notes/domain/models.dart';
import '../storage/storage_manager.dart';

/// 自动保存服务
/// 负责处理防抖逻辑和数据持久化
class AutoSaveService {
  final StorageManager _storageManager;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(seconds: 1);

  AutoSaveService(this._storageManager);

  /// 带防抖的保存方法
  void saveWithDebounce(Note note, Function() onComplete) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _saveNote(note);
      onComplete();
    });
  }

  void _saveNote(Note note) {
    final data = {
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
    };
    final jsonStr = jsonEncode(data);
    _storageManager.save('note_${note.id}', jsonStr);
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
