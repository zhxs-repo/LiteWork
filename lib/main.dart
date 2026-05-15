import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/publisher/presentation/viewmodel.dart';
import 'features/video_editor/presentation/viewmodel.dart';
import 'features/notes/presentation/viewmodel.dart';
import 'core/storage/storage_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
        // 图文发布 ViewModel
        ChangeNotifierProvider(create: (_) => PublisherViewModel()),
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
