// 同步笔记用例

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/notes_repository.dart';

/// 同步单条笔记到云端
class SyncNoteUseCase {
  final NotesRepository repository;

  SyncNoteUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String noteId) async {
    return await repository.syncNote(noteId);
  }
}
