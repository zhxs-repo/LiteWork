/// 笔记模块 - Repository 实现
/// 
/// 实现 NotesRepository 接口，协调本地和远程数据源

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/models.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/trash_datasource.dart';
import '../note_datasource.dart';
import '../../utils/mind_map_mapper.dart';

/// 笔记仓库实现类
class NotesRepositoryImpl implements NotesRepository {
  final NotesDataSource _localDataSource;
  final TrashDataSource _trashDataSource;

  NotesRepositoryImpl({
    required NotesDataSource localDataSource,
    required TrashDataSource trashDataSource,
  })  : _localDataSource = localDataSource,
        _trashDataSource = trashDataSource;

  @override
  Future<Either<Failure, List<Note>>> getAllNotes() async {
    try {
      final notes = _localDataSource.getAllNotes();
      return Right(notes);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Note>>> getNotesByFolder(String? folderId) async {
    try {
      final notes = _localDataSource.getNotesByFolderId(folderId);
      return Right(notes);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveNote(Note note) async {
    try {
      await _localDataSource.saveNote(note);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteNote(String id) async {
    try {
      await _localDataSource.deleteNote(id);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteFolder>>> getAllFolders() async {
    try {
      final folders = _localDataSource.getAllFolders();
      return Right(folders);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveFolder(NoteFolder folder) async {
    try {
      await _localDataSource.saveFolder(folder);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteFolder(String folderId) async {
    try {
      await _localDataSource.deleteFolder(folderId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> moveToTrash(Note note) async {
    try {
      // 添加到回收站
      await _trashDataSource.add(
        note.id,
        {
          'id': note.id,
          'title': note.title,
          'content': note.content,
          'type': note.type.name,
          'tags': note.tags,
          'folderId': note.folderId,
          'isFavorite': note.isFavorite,
          'isSynced': note.isSynced,
          'isPinned': note.isPinned,
          'createdAt': note.createdAt.toIso8601String(),
          'updatedAt': note.updatedAt.toIso8601String(),
          if (note.mindMapData != null)
            'mindMapData': MindMapMapper.mindMapToMap(note.mindMapData!),
        },
        'note',
      );
      
      // 从正常列表中删除
      await _localDataSource.deleteNote(note.id);
      
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> restoreFromTrash(String itemId) async {
    try {
      final result = await _trashDataSource.restore(itemId);
      if (result == null) {
        return Left(CacheFailure('项目不存在'));
      }

      final type = result['type'] as String;
      final data = result['data'] as Map<String, dynamic>;

      if (type == 'note') {
        MindMapData? mindMapData;
        if (data.containsKey('mindMapData') && data['mindMapData'] != null) {
          mindMapData = MindMapMapper.mapToMindMap(data['mindMapData'] as Map);
        }
        final note = Note(
          id: data['id'] as String,
          title: data['title'] as String,
          content: data['content'] as String,
          type: NoteType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => NoteType.richText,
          ),
          tags: List<String>.from(data['tags'] ?? []),
          folderId: data['folderId'] as String?,
          mindMapData: mindMapData,
          isFavorite: data['isFavorite'] as bool? ?? false,
          isSynced: data['isSynced'] as bool? ?? false,
          isPinned: data['isPinned'] as bool? ?? false,
          createdAt: DateTime.parse(data['createdAt'] as String),
          updatedAt: DateTime.now(),
        );
        await _localDataSource.saveNote(note);
      } else if (type == 'folder') {
        final folder = NoteFolder(
          id: data['id'] as String,
          name: data['name'] as String,
          parentId: data['parentId'] as String?,
          createdAt: DateTime.parse(data['createdAt'] as String),
        );
        await _localDataSource.saveFolder(folder);
      }

      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearTrash() async {
    try {
      await _trashDataSource.clear();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePermanently(String itemId) async {
    try {
      await _trashDataSource.deletePermanently(itemId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> syncNote(String noteId) async {
    try {
      await _localDataSource.syncNote(noteId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
