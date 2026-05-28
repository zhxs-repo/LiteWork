import 'package:get_it/get_it.dart';

import '../storage/storage_manager.dart';
import '../services/theme_notifier.dart';
import '../../features/base/data/datasources/user_local_datasource.dart';
import '../../features/base/domain/repositories/user_repository.dart';
import '../../features/base/data/repositories/user_repository_impl.dart';
import '../../features/base/presentation/providers/user_provider.dart';
import '../../features/base/domain/usecases/user_usecases.dart';

import '../../features/publisher/data/datasources/post_local_datasource.dart';
import '../../features/publisher/data/repositories/post_repository_impl.dart';
import '../../features/publisher/domain/repositories/post_repository.dart';
import '../../features/publisher/domain/usecases/post_usecases.dart';
import '../../features/publisher/presentation/providers/post_provider.dart';

import '../../features/video_editor/presentation/providers/video_provider.dart';
import '../../features/notes/presentation/viewmodel.dart';
import '../../features/notes/data/note_datasource.dart';
import '../../features/notes/data/datasources/trash_datasource.dart';
import '../../features/notes/data/repositories/notes_repository_impl.dart';
import '../../features/notes/domain/repositories/notes_repository.dart';
import '../../features/notes/domain/usecases/get_notes_use_case.dart';
import '../../features/notes/domain/usecases/save_note_use_case.dart';
import '../../features/notes/domain/usecases/delete_note_use_case.dart';
import '../../features/notes/domain/usecases/move_note_to_trash_use_case.dart';
import '../../features/notes/domain/usecases/restore_from_trash_use_case.dart';
import '../../features/notes/domain/usecases/get_folders_use_case.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // 外部依赖
  sl.registerLazySingleton<StorageManager>(() => StorageManager());
  sl.registerFactory<ThemeNotifier>(() => ThemeNotifier());

  // Base / User
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSource(storageManager: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl<UserLocalDataSource>()),
  );
  sl.registerLazySingleton<GetOrCreateGuestUser>(
    () => GetOrCreateGuestUser(sl()),
  );
  sl.registerLazySingleton<GetCurrentUser>(
    () => GetCurrentUser(sl()),
  );
  sl.registerLazySingleton<LogoutUser>(
    () => LogoutUser(sl()),
  );
  sl.registerLazySingleton<CheckIsLoggedIn>(
    () => CheckIsLoggedIn(sl()),
  );
  sl.registerLazySingleton<CheckIsGuest>(
    () => CheckIsGuest(sl()),
  );
  sl.registerFactory<UserProvider>(
    () => UserProvider(
      getOrCreateGuestUser: sl(),
      getCurrentUser: sl(),
      logoutUser: sl(),
      checkIsLoggedIn: sl(),
      checkIsGuest: sl(),
    ),
  );

  // Notes - Data Sources
  sl.registerLazySingleton<NotesDataSource>(() {
    final ds = NotesDataSource();
    ds.init();
    return ds;
  });
  sl.registerLazySingleton<TrashDataSource>(() {
    final ds = TrashDataSource();
    ds.init();
    return ds;
  });

  // Notes - Repository
  sl.registerLazySingleton<NotesRepository>(
    () => NotesRepositoryImpl(
      localDataSource: sl<NotesDataSource>(),
      trashDataSource: sl<TrashDataSource>(),
    ),
  );

  // Notes - Use Cases
  sl.registerLazySingleton<GetNotesUseCase>(() => GetNotesUseCase(sl()));
  sl.registerLazySingleton<SaveNoteUseCase>(() => SaveNoteUseCase(sl()));
  sl.registerLazySingleton<DeleteNoteUseCase>(() => DeleteNoteUseCase(sl()));
  sl.registerLazySingleton<MoveNoteToTrashUseCase>(
    () => MoveNoteToTrashUseCase(sl()),
  );
  sl.registerLazySingleton<RestoreFromTrashUseCase>(
    () => RestoreFromTrashUseCase(sl()),
  );
  sl.registerLazySingleton<GetFoldersUseCase>(
    () => GetFoldersUseCase(sl()),
  );
  // Notes - Use Cases (新增文件夹和回收站相关)
  sl.registerLazySingleton<CreateFolderUseCase>(() => CreateFolderUseCase(sl()));
  sl.registerLazySingleton<DeleteFolderUseCase>(() => DeleteFolderUseCase(sl()));
  sl.registerLazySingleton<ClearTrashUseCase>(() => ClearTrashUseCase(sl()));
  sl.registerLazySingleton<DeletePermanentlyUseCase>(() => DeletePermanentlyUseCase(sl()));

  // Notes - Provider (updated to use UseCases)
  sl.registerFactory<NotesViewModel>(
    () => NotesViewModel(
      getNotesUseCase: sl(),
      saveNoteUseCase: sl(),
      deleteNoteUseCase: sl(),
      moveNoteToTrashUseCase: sl(),
      restoreFromTrashUseCase: sl(),
      getFoldersUseCase: sl(),
      createFolderUseCase: sl(),
      deleteFolderUseCase: sl(),
      clearTrashUseCase: sl(),
      deletePermanentlyUseCase: sl(),
    ),
  );

  // Post / Publisher
  sl.registerLazySingleton<PostLocalDataSource>(() {
    final ds = PostLocalDataSource();
    ds.init();
    return ds;
  });
  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(localDataSource: sl<PostLocalDataSource>()),
  );
  sl.registerLazySingleton<GetAllPostsUseCase>(
    () => GetAllPostsUseCase(sl()),
  );
  sl.registerLazySingleton<GetPostByIdUseCase>(
    () => GetPostByIdUseCase(sl()),
  );
  sl.registerLazySingleton<SavePostUseCase>(
    () => SavePostUseCase(sl()),
  );
  sl.registerLazySingleton<DeletePostUseCase>(
    () => DeletePostUseCase(sl()),
  );
  sl.registerLazySingleton<GetDraftsUseCase>(
    () => GetDraftsUseCase(sl()),
  );
  sl.registerFactory<PostProvider>(
    () => PostProvider(
      getAllPosts: sl(),
      getPostById: sl(),
      savePost: sl(),
      deletePost: sl(),
      getDrafts: sl(),
    ),
  );

  // Video Editor
  sl.registerFactory<VideoProvider>(() => VideoProvider());
}
