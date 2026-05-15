import 'dart:async';
import 'dart:convert';

import '../../features/notes/data/models/note_model.dart';
import '../storage/storage_manager.dart';

/// 自动保存服务
/// 负责处理防抖逻辑和数据持久化
class AutoSaveService {
  final StorageManager _storageManager;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(seconds: 1);

  AutoSaveService(this._storageManager);

  /// 带防抖的保存方法
  void saveWithDebounce(NoteModel note, Function() onComplete) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _saveNote(note);
      onComplete();
    });
  }

  void _saveNote(NoteModel note) {
    final jsonStr = jsonEncode(note.toJson());
    _storageManager.saveData('note_${note.id}', jsonStr);
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
