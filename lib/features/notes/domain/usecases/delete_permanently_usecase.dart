import '../../data/datasources/trash_datasource.dart';

class DeletePermanentlyUseCase {
  final TrashDataSource dataSource;

  DeletePermanentlyUseCase(this.dataSource);

  Future<void> call(String noteId) async {
    await dataSource.deletePermanently(noteId);
  }
}
