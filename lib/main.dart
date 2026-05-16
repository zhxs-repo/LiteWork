import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/storage_manager.dart';
import 'features/video_editor/presentation/viewmodel.dart';
import 'features/notes/presentation/viewmodel.dart';
import 'features/base/data/datasources/user_local_datasource.dart';
import 'features/base/data/repositories/user_repository_impl.dart';
import 'features/base/domain/usecases/user_usecases.dart';
import 'features/base/presentation/providers/user_provider.dart';
import 'features/publisher/data/datasources/post_local_datasource.dart';
import 'features/publisher/data/repositories/post_repository_impl.dart';
import 'features/publisher/domain/usecases/post_usecases.dart';
import 'features/publisher/presentation/providers/post_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Hive
  await Hive.initFlutter();
  
  // 打开需要的 Box
  await Future.wait([
    Hive.openBox('posts_box'),
    Hive.openBox('notes_box'),
    Hive.openBox('video_projects_box'),
    Hive.openBox('trash_box'),
    Hive.openBox('folders_box'),
  ]);
  
  // 初始化本地存储
  await StorageManager().init();
  
  runApp(const LiteWorkApp());
}

class LiteWorkApp extends StatelessWidget {
  const LiteWorkApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 用户 Provider (基础模块)
        ChangeNotifierProvider(
          create: (context) {
            final storageManager = StorageManager();
            final localDataSource = UserLocalDataSource(storageManager: storageManager);
            final repository = UserRepositoryImpl(localDataSource: localDataSource);
            
            return UserProvider(
              getOrCreateGuestUser: GetOrCreateGuestUser(repository),
              getCurrentUser: GetCurrentUser(repository),
              logoutUser: LogoutUser(repository),
              checkIsLoggedIn: CheckIsLoggedIn(repository),
              checkIsGuest: CheckIsGuest(repository),
            )..initialize(); // 自动初始化用户状态
          },
        ),
        // 帖子 Provider (图文发布模块)
        ChangeNotifierProvider(
          create: (context) {
            final storageManager = StorageManager();
            final localDataSource = PostLocalDataSource(storageManager: storageManager);
            final repository = PostRepositoryImpl(localDataSource: localDataSource);
            
            return PostProvider(
              getAllPosts: GetAllPostsUseCase(repository),
              getPostById: GetPostByIdUseCase(repository),
              savePost: SavePostUseCase(repository),
              deletePost: DeletePostUseCase(repository),
              getDrafts: GetDraftsUseCase(repository),
            )..loadPosts(); // 自动加载帖子列表
          },
        ),
        // 视频编辑 ViewModel
        ChangeNotifierProvider(create: (_) => VideoEditorViewModel()),
        // 笔记管理 ViewModel
        ChangeNotifierProvider(create: (_) => NotesViewModel()),
      ],
      child: MaterialApp.router(
        title: 'LiteWork',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
