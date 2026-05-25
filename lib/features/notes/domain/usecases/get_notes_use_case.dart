/// 获取所有笔记用例
/// 
/// Clean Architecture UseCase - 单一职责

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/models.dart';
import '../../domain/repositories/notes_repository.dart';

class GetNotesUseCase {
  final NotesRepository repository;

  GetNotesUseCase(this.repository);

  /// 执行用例 - 获取所有笔记
  Future<Either<Failure, List<Note>>> call() async {
    return await repository.getAllNotes();
  }
}
