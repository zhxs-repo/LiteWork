import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../models.dart';
import '../repositories/notes_repository.dart';

class GetFoldersUseCase {
  final NotesRepository repository;

  GetFoldersUseCase(this.repository);

  Future<Either<Failure, List<NoteFolder>>> call() async {
    return await repository.getAllFolders();
  }
}
