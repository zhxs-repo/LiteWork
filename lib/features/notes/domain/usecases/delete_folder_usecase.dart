import '../repositories/notes_repository.dart';

class DeleteFolderUseCase {
  final NotesRepository repository;

  DeleteFolderUseCase(this.repository);

  Future<bool> call(String folderId) async {
    return await repository.deleteFolder(folderId);
  }
}
