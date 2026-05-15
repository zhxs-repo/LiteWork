import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 路由路径常量
class AppRoutes {
  static const String home = '/';
  static const String publisher = '/publisher';
  static const String publisherCreate = '/publisher/create';
  static const String publisherEdit = '/publisher/edit';
  static const String videoEditor = '/video-editor';
  static const String videoEditorCreate = '/video-editor/create';
  static const String notes = '/notes';
  static const String notesCreate = '/notes/create';
  static const String notesEdit = '/notes/edit';
  static const String noteDetail = '/notes/:id';
}

/// 路由配置
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
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
          
          // 图文发布模块
          GoRoute(
            path: AppRoutes.publisher,
            name: 'publisher',
            builder: (context, state) => const PublisherPage(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'publisherCreate',
                builder: (context, state) => const PublisherCreatePage(),
              ),
              GoRoute(
                path: 'edit',
                name: 'publisherEdit',
                builder: (context, state) => const PublisherEditPage(),
              ),
            ],
          ),
          
          // 视频剪辑模块
          GoRoute(
            path: AppRoutes.videoEditor,
            name: 'videoEditor',
            builder: (context, state) => const VideoEditorPage(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'videoEditorCreate',
                builder: (context, state) => const VideoEditorCreatePage(),
              ),
            ],
          ),
          
          // 笔记模块
          GoRoute(
            path: AppRoutes.notes,
            name: 'notes',
            builder: (context, state) => const NotesPage(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'notesCreate',
                builder: (context, state) => const NotesCreatePage(),
              ),
              GoRoute(
                path: 'edit',
                name: 'notesEdit',
                builder: (context, state) => const NotesEditPage(),
              ),
              GoRoute(
                path: ':id',
                name: 'noteDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return NoteDetailPage(noteId: id);
                },
              ),
            ],
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
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
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

/// 笔记页面
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('笔记管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('${AppRoutes.notes}/create'),
          ),
        ],
      ),
      body: const Center(
        child: Text('笔记列表'),
      ),
    );
  }
}

class NotesCreatePage extends StatelessWidget {
  const NotesCreatePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建笔记')),
      body: const Center(
        child: Text('创建新笔记'),
      ),
    );
  }
}

class NotesEditPage extends StatelessWidget {
  const NotesEditPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编辑笔记')),
      body: const Center(
        child: Text('编辑笔记内容'),
      ),
    );
  }
}

class NoteDetailPage extends StatelessWidget {
  final String noteId;
  
  const NoteDetailPage({super.key, required this.noteId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('笔记详情')),
      body: Center(
        child: Text('笔记详情：$noteId'),
      ),
    );
  }
}
