import '../../data/datasources/trash_datasource.dart';

class ClearTrashUseCase {
  final TrashDataSource dataSource;

  ClearTrashUseCase(this.dataSource);

  Future<void> call() async {
    await dataSource.clearTrash();
  }
}
