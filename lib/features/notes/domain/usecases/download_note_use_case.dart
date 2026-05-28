/// 从云端下载笔记 UseCase
/// 
/// 用于从 WebDAV 服务器下载指定笔记

import '../../../../core/error/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../models/note.dart';
import '../repositories/note_repository.dart';

class DownloadNoteUseCase {
  final NoteRepository repository;

  DownloadNoteUseCase(this.repository);

  Future<Either<Failure, Note>> call(String noteId) async {
    try {
      final note = await repository.downloadNoteFromCloud(noteId);
      return Right(note);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
