// 从云端下载笔记 UseCase
// 
// 用于从 WebDAV 服务器下载指定笔记

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../models.dart';
import '../repositories/notes_repository.dart';

class DownloadNoteUseCase {
  final NotesRepository repository;

  DownloadNoteUseCase(this.repository);

  Future<Either<Failure, Note>> call(String noteId) async {
    return repository.downloadNoteFromCloud(noteId);
  }
}
