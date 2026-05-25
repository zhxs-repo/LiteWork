/// 保存笔记用例

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/models.dart';
import '../../domain/repositories/notes_repository.dart';

class SaveNoteUseCase {
  final NotesRepository repository;

  SaveNoteUseCase(this.repository);

  Future<Either<Failure, Unit>> call(Note note) async {
    return await repository.saveNote(note);
  }
}
