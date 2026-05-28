import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/base/presentation/providers/user_provider.dart';
import '../../features/base/presentation/screens/profile_screen.dart';
import '../../features/base/presentation/screens/sync_settings_page.dart';
import '../../features/publisher/presentation/screens/post_list_screen.dart';
import '../../features/publisher/presentation/screens/post_editor_screen.dart';
import '../../features/publisher/presentation/providers/post_provider.dart';
import '../../features/notes/presentation/viewmodel.dart';
import '../../features/video_editor/presentation/providers/video_provider.dart';
import '../../features/notes/presentation/screens/trash_screen.dart';
import '../../features/home/widgets/recent_items_list.dart';
import '../../features/notes/presentation/screens/notes_list_screen.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/notes/domain/models.dart';
import '../search/search_screen.dart';
import '../../features/video_editor/presentation/screens/video_list_screen.dart';
import '../../features/video_editor/presentation/screens/video_editor_screen.dart';
import '../di/injection_container.dart' as di;

/// 路由路径常量
class AppRoutes {
  static const String home = '/';
  static const String publisher = '/publisher';
  static const String publisherDrafts = '/publisher/drafts';
  static const String postEditor = '/post/editor';
  static const String videoEditor = '/video-editor';
  static const String videoEditorCreate = '/video-editor/create';
  static const String videoEditorEdit = '/video-editor/edit/:id';
  static const String notes = '/notes';
  static const String notesCreate = '/notes/create';
  static const String notesEdit = '/notes/edit';
  static const String noteDetail = '/notes/:id';
  static const String profile = '/profile';
  static const String syncSettings = '/settings/sync';
  static const String search = '/search';
  static const String trash = '/trash';
}

/// 路由配置
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    refreshListenable: di.sl<UserProvider>(),
    redirect: (context, state) {
      final userProvider = di.sl<UserProvider>();
      final isLoginRequired = state.matchedLocation == AppRoutes.profile;
      
      if (isLoginRequired && !userProvider.isLoggedIn) {
        return AppRoutes.home;
      }
      
      return null;
    },
    routes: [
      // 主页
      ShellRoute(
        builder: (context, state, child) => HomeLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          
          // 个人中心
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
            routes: [
              GoRoute(
                path: 'sync',
                name: 'syncSettings',
                pageBuilder: (context, state) => const MaterialPage(
                  child: SyncSettingsPage(),
                ),
              ),
            ],
          ),
          
          // 图文发布模块
          GoRoute(
            path: AppRoutes.publisher,
            name: 'publisher',
            builder: (context, state) => const PostListScreen(),
            routes: [
              GoRoute(
                path: AppRoutes.postEditor,
                name: 'postEditor',
                pageBuilder: (context, state) {
                  final postId = state.uri.queryParameters['id'];
                  return MaterialPage(
                    child: PostEditorScreen(postId: postId),
                  );
                },
              ),
            ],
          ),
          
          // 视频剪辑模块 - 使用新创建的 VideoListScreen
          GoRoute(
            path: AppRoutes.videoEditor,
            name: 'videoEditor',
            builder: (context, state) => const VideoListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'videoEditorCreate',
                builder: (context, state) => const VideoEditorScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'videoEditorEdit',
                builder: (context, state) {
                  final projectId = state.pathParameters['id'] ?? '';
                  return VideoEditorScreen(projectId: projectId);
                },
              ),
            ],
          ),
          
          // 笔记模块 - 使用新创建的 NotesListScreen
          GoRoute(
            path: AppRoutes.notes,
            name: 'notes',
            builder: (context, state) => const NotesListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'notesCreate',
                builder: (context, state) {
                  final typeParam = state.uri.queryParameters['type'];
                  NoteType? createType;
                  if (typeParam == 'mindmap') {
                    createType = NoteType.mindMap;
                  } else if (typeParam == 'mixed') {
                    createType = NoteType.mixed;
                  } else {
                    createType = NoteType.richText;
                  }
                  return NoteEditorScreen(createType: createType);
                },
              ),
              GoRoute(
                path: ':id',
                name: 'noteDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return NoteEditorScreen(noteId: id);
                },
              ),
            ],
          ),
          
          // 全局搜索
          GoRoute(
            path: AppRoutes.search,
            name: 'search',
            pageBuilder: (context, state) => const MaterialPage(child: SearchScreen()),
          ),
          
          // 回收站
          GoRoute(
            path: AppRoutes.trash,
            name: 'trash',
            pageBuilder: (context, state) => const MaterialPage(child: TrashScreen()),
          ),
        ],
      ),
    ],
  );
}

/// 主页布局（带底部导航）
class HomeLayout extends StatefulWidget {
  final Widget child;
  
  const HomeLayout({super.key, required this.child});
  
  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _selectedIndex = 0;
  
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.publisher);
        break;
      case 2:
        context.go(AppRoutes.videoEditor);
        break;
      case 3:
        context.go(AppRoutes.notes);
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 根据当前路由确定选中的索引
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.publisher)) {
      _selectedIndex = 1;
    } else if (location.startsWith(AppRoutes.videoEditor)) {
      _selectedIndex = 2;
    } else if (location.startsWith(AppRoutes.notes)) {
      _selectedIndex = 3;
    } else {
      _selectedIndex = 0;
    }
    
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.publish_outlined),
            activeIcon: Icon(Icons.publish),
            label: '发布',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            activeIcon: Icon(Icons.video_library),
            label: '剪辑',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: '笔记',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ==================== 空白页面定义 ====================

/// 首页 - 数据概览与快捷入口
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiteWork'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickActions(context),
          const SizedBox(height: 24),
          const RecentItemsList(),
          const SizedBox(height: 24),
          _buildStatsSection(context),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快捷操作',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.note_add,
                label: '新建笔记',
                color: Colors.blue,
                onTap: () => context.pushNamed('notesCreate'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.post_add,
                label: '新建草稿',
                color: Colors.green,
                onTap: () => context.pushNamed('postEditor'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.video_library,
                label: '视频剪辑',
                color: Colors.orange,
                onTap: () => context.push(AppRoutes.videoEditor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.search,
                label: '搜索',
                color: Colors.purple,
                onTap: () => context.push(AppRoutes.search),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final videoProvider = context.watch<VideoProvider>();
    final notesViewModel = context.watch<NotesViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '数据概览',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.article,
                label: '图文草稿',
                count: postProvider.posts.length,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.video_library,
                label: '视频项目',
                count: videoProvider.projects.length,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.note,
                label: '笔记',
                count: notesViewModel.notes.length,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.delete_outline,
                label: '回收站',
                count: notesViewModel.trashItems.length,
                color: Colors.red,
                onTap: () => context.push(AppRoutes.trash),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
