import '../repositories/notes_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';

class ClearTrashUseCase {
  final NotesRepository repository;

  ClearTrashUseCase(this.repository);

  Future<Either<Failure, Unit>> call() async {
    return await repository.clearTrash();
  }
}
