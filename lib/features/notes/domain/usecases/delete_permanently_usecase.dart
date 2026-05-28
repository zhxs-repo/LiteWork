import '../repositories/notes_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';

class DeletePermanentlyUseCase {
  final NotesRepository repository;

  DeletePermanentlyUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String itemId) async {
    return await repository.deletePermanently(itemId);
  }
}
