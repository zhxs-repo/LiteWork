/// 删除笔记用例

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/notes_repository.dart';

class DeleteNoteUseCase {
  final NotesRepository repository;

  DeleteNoteUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String noteId) async {
    return await repository.deleteNote(noteId);
  }
}
