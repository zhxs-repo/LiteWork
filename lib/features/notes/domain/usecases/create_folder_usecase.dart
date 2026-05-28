import '../repositories/notes_repository.dart';
import '../models.dart';

class CreateFolderUseCase {
  final NotesRepository repository;

  CreateFolderUseCase(this.repository);

  Future<bool> call(NoteFolder folder) async {
    return await repository.saveFolder(folder);
  }
}
