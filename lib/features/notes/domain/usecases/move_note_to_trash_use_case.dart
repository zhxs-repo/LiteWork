/// 移动笔记到回收站用例

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/models.dart';
import '../../domain/repositories/notes_repository.dart';

class MoveNoteToTrashUseCase {
  final NotesRepository repository;

  MoveNoteToTrashUseCase(this.repository);

  Future<Either<Failure, Unit>> call(Note note) async {
    return await repository.moveToTrash(note);
  }
}
