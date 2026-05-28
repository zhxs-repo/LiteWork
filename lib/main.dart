import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/storage_manager.dart';
import 'core/services/theme_notifier.dart';
import 'core/di/injection_container.dart' as di;
import 'features/video_editor/presentation/providers/video_provider.dart';
import 'features/notes/presentation/viewmodel.dart';
import 'features/base/presentation/providers/user_provider.dart';
import 'features/base/presentation/providers/sync_provider.dart';
import 'features/publisher/presentation/providers/post_provider.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive
  await Hive.initFlutter();

  // 打开需要的 Box
  await Future.wait([
    Hive.openBox<Map>('posts_box'),
    Hive.openBox<Map>('notes_box'),
    Hive.openBox<Map>('video_projects_box'),
    Hive.openBox<Map>('trash_box'),
    Hive.openBox<Map>('folders_box'),
    Hive.openBox('onboarding_box'),
  ]);

  // 初始化本地存储
  await StorageManager().init();

  // 初始化依赖注入
  await di.initDependencies();

  runApp(const LiteWorkApp());
}

class LiteWorkApp extends StatelessWidget {
  const LiteWorkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => di.sl<ThemeNotifier>()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<UserProvider>()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<PostProvider>()..loadPosts(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<VideoProvider>()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => di.sl<NotesViewModel>()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncProvider()..init(),
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return _AppContent(themeMode: themeNotifier.themeMode);
        },
      ),
    );
  }
}

class _AppContent extends StatelessWidget {
  final ThemeMode themeMode;

  const _AppContent({required this.themeMode});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('onboarding_box');
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box box, _) {
        final hasCompletedOnboarding =
            box.get('completed', defaultValue: false);

        if (!hasCompletedOnboarding) {
          return MaterialApp(
            title: 'LiteWork',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('en', 'US'),
            ],
            home: OnboardingScreen(
              onComplete: () {
                box.put('completed', true);
              },
            ),
          );
        }

        return MaterialApp.router(
          title: 'LiteWork',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
