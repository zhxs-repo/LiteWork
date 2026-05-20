import 'package:get_it/get_it.dart';

import '../storage/storage_manager.dart';
import '../../features/base/data/datasources/user_local_datasource.dart';
import '../../features/base/domain/repositories/user_repository.dart';
import '../../features/base/data/repositories/user_repository_impl.dart';
import '../../features/base/presentation/providers/user_provider.dart';
import '../../features/base/domain/usecases/user_usecases.dart';

import '../../features/video_editor/presentation/providers/video_provider.dart';
import '../../features/video_editor/presentation/viewmodel.dart';
import '../../features/notes/presentation/viewmodel.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // 外部依赖
  sl.registerLazySingleton<StorageManager>(() => StorageManager());

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

  // Notes
  sl.registerFactory<NotesViewModel>(() => NotesViewModel());

  // Video Editor
  sl.registerFactory<VideoEditorViewModel>(() => VideoEditorViewModel());
  sl.registerFactory<VideoProvider>(() => VideoProvider());
}
