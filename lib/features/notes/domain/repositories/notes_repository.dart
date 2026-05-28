/// 笔记模块 - Repository 抽象接口
/// 
/// 定义领域层与数据层的契约，确保依赖倒置

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/models.dart';

/// 笔记仓库接口
abstract class NotesRepository {
  /// 获取所有笔记
  Future<Either<Failure, List<Note>>> getAllNotes();
  
  /// 获取指定文件夹的笔记
  Future<Either<Failure, List<Note>>> getNotesByFolder(String? folderId);
  
  /// 保存笔记
  Future<Either<Failure, Unit>> saveNote(Note note);
  
  /// 删除笔记
  Future<Either<Failure, Unit>> deleteNote(String id);
  
  /// 获取所有文件夹
  Future<Either<Failure, List<NoteFolder>>> getAllFolders();
  
  /// 保存文件夹
  Future<Either<Failure, Unit>> saveFolder(NoteFolder folder);
  
  /// 删除文件夹
  Future<Either<Failure, Unit>> deleteFolder(String folderId);
  
  /// 移动笔记到回收站
  Future<Either<Failure, Unit>> moveToTrash(Note note);
  
  /// 从回收站恢复
  Future<Either<Failure, Unit>> restoreFromTrash(String itemId);

  /// 清空回收站
  Future<Either<Failure, Unit>> clearTrash();

  /// 彻底删除回收站项目
  Future<Either<Failure, Unit>> deletePermanently(String itemId);
  
  /// 同步笔记
  Future<Either<Failure, Unit>> syncNote(String noteId);
  
  /// 从云端下载笔记
  Future<Either<Failure, Note>> downloadNoteFromCloud(String noteId);
}
