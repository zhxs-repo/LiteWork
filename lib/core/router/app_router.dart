import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/base/presentation/screens/profile_screen.dart';
import '../../features/publisher/presentation/screens/post_list_screen.dart';
import '../../features/publisher/presentation/screens/post_editor_screen.dart';
import '../../features/notes/presentation/screens/trash_screen.dart';
import '../../features/notes/presentation/screens/notes_list_screen.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/notes/presentation/viewmodel.dart';
import '../../features/notes/domain/models.dart';
import '../search/search_screen.dart';
import '../../features/video_editor/presentation/screens/video_list_screen.dart';

/// 路由路径常量
class AppRoutes {
  static const String home = '/';
  static const String publisher = '/publisher';
  static const String publisherDrafts = '/publisher/drafts';
  static const String postEditor = '/post/editor';
  static const String videoEditor = '/video-editor';
  static const String videoEditorCreate = '/video-editor/create';
  static const String notes = '/notes';
  static const String notesCreate = '/notes/create';
  static const String notesEdit = '/notes/edit';
  static const String noteDetail = '/notes/:id';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String trash = '/trash';
}

/// 简单的认证检查 (实际项目中应从 UserProvider 获取真实状态)
bool _isLoggedIn() {
  // 从真实的 UserProvider 获取登录状态
  // 当前默认允许访问，因为支持免登录
  return true;
}

/// 路由配置
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // 路由守卫：需要登录的页面
      final isLoginRequired = state.matchedLocation == AppRoutes.profile;
      
      if (isLoginRequired && !_isLoggedIn()) {
        return AppRoutes.home; // 未登录重定向到首页
      }
      
      return null; // 允许访问
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
                builder: (context, state) => const VideoEditorCreatePage(),
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

/// 首页
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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspaces_outlined, size: 80, color: Color(0xFF6366F1)),
            SizedBox(height: 24),
            Text(
              '欢迎使用 LiteWork',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '内容创作与管理工具',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 图文发布页面
class PublisherPage extends StatelessWidget {
  const PublisherPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图文发布'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('${AppRoutes.publisher}/create'),
          ),
        ],
      ),
      body: const Center(
        child: Text('图文发布列表'),
      ),
    );
  }
}

class PublisherCreatePage extends StatelessWidget {
  const PublisherCreatePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('创建发布')),
      body: const Center(
        child: Text('创建图文发布内容'),
      ),
    );
  }
}

class PublisherEditPage extends StatelessWidget {
  const PublisherEditPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编辑发布')),
      body: const Center(
        child: Text('编辑图文发布内容'),
      ),
    );
  }
}

/// 视频剪辑页面
class VideoEditorPage extends StatelessWidget {
  const VideoEditorPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频剪辑'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('${AppRoutes.videoEditor}/create'),
          ),
        ],
      ),
      body: const Center(
        child: Text('视频剪辑项目列表'),
      ),
    );
  }
}

class VideoEditorCreatePage extends StatelessWidget {
  const VideoEditorCreatePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建剪辑')),
      body: const Center(
        child: Text('创建视频剪辑项目'),
      ),
    );
  }
}

/// 笔记管理页面（主容器）- 带 Provider
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotesViewModel>(
      create: (_) => NotesViewModel(),
      child: const NotesListScreen(),
    );
  }
}
