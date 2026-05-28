import '../repositories/notes_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';

class DeleteFolderUseCase {
  final NotesRepository repository;

  DeleteFolderUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String folderId) async {
    return await repository.deleteFolder(folderId);
  }
}
