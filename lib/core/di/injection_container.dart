import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/storage_manager.dart';
import '../../features/base/data/datasources/user_local_datasource.dart';
import '../../features/base/domain/repositories/user_repository.dart';
import '../../features/base/data/repositories/user_repository_impl.dart';
import '../../features/base/presentation/providers/user_provider.dart';

import '../../features/notes/data/datasources/note_local_datasource.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/notes/data/repositories/note_repository_impl.dart';
import '../../features/notes/presentation/viewmodel.dart';

import '../../features/video_editor/data/datasources/video_local_datasource.dart';
import '../../features/video_editor/domain/repositories/video_repository.dart';
import '../../features/video_editor/data/repositories/video_repository_impl.dart';
import '../../features/video_editor/presentation/providers/video_provider.dart';

import '../../features/video_editor/domain/usecases/timeline_edit_usecase.dart';
import '../services/auto_save_service.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // 外部依赖
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => StorageManager(sharedPreferences));

  // 服务层
  sl.registerLazySingleton<AutoSaveService>(
    () => AutoSaveService(sl()),
  );

  // Base / User
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl()));
  sl.registerFactory(() => UserProvider(sl()));

  // Notes
  sl.registerLazySingleton<NoteLocalDataSource>(
    () => NoteLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<NoteRepository>(() => NoteRepositoryImpl(sl()));
  sl.registerFactory(() => NotesViewModel());

  // Video Editor
  sl.registerLazySingleton<VideoLocalDataSource>(
    () => VideoLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<VideoRepository>(() => VideoRepositoryImpl(sl()));
  sl.registerLazySingleton<TimelineEditUseCase>(() => TimelineEditUseCase());
  sl.registerFactory(() => VideoProvider(sl(), sl()));
}
