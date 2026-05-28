import '../repositories/notes_repository.dart';
import '../models.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';

class CreateFolderUseCase {
  final NotesRepository repository;

  CreateFolderUseCase(this.repository);

  Future<Either<Failure, Unit>> call(NoteFolder folder) async {
    return await repository.saveFolder(folder);
  }
}
