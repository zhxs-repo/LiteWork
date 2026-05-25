/// 从回收站恢复用例

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/notes_repository.dart';

class RestoreFromTrashUseCase {
  final NotesRepository repository;

  RestoreFromTrashUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String itemId) async {
    return await repository.restoreFromTrash(itemId);
  }
}
