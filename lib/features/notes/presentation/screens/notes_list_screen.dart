import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel.dart';
import '../../domain/models.dart';
import 'note_editor_screen.dart';

/// 笔记列表页面
class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  @override
  void initState() {
    super.initState();
    // 延迟初始化以确保上下文可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<NotesViewModel>();
      viewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('笔记管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            onPressed: () => _showFolderManagement(context),
            tooltip: '文件夹管理',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
            tooltip: '搜索笔记',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createNote(context),
            tooltip: '新建笔记',
          ),
        ],
      ),
      body: Consumer<NotesViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && !viewModel.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('加载失败：${viewModel.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.initialize(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final notes = viewModel.filteredNotes;

          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    '暂无笔记',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右上角 + 创建第一篇笔记',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _createNote(context),
                    icon: const Icon(Icons.add),
                    label: const Text('新建笔记'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadNotes(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _buildNoteCard(context, note, viewModel);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note, NotesViewModel viewModel) {
    final typeIcon = _getTypeIcon(note.type);
    final typeColor = _getTypeColor(note.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => _openNote(context, note.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isFavorite)
                    Icon(Icons.star, color: Colors.amber[700], size: 20),
                  if (note.isSynced)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.cloud_done, color: Colors.green[700], size: 18),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (note.content.isNotEmpty)
                Text(
                  note.content.replaceAll(RegExp(r'\s+'), ' '),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onSelected: (value) => _handleMenuAction(context, note, value, viewModel),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                      const PopupMenuItem(value: 'favorite', child: Text('收藏')),
                      const PopupMenuItem(value: 'move', child: Text('移动到文件夹')),
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(NoteType type) {
    switch (type) {
      case NoteType.richText:
        return Icons.description;
      case NoteType.mindMap:
        return Icons.account_tree;
      case NoteType.mixed:
        return Icons.auto_awesome;
    }
  }

  Color _getTypeColor(NoteType type) {
    switch (type) {
      case NoteType.richText:
        return Colors.blue;
      case NoteType.mindMap:
        return Colors.purple;
      case NoteType.mixed:
        return Colors.teal;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  void _createNote(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('富文本笔记'),
              subtitle: const Text('支持格式化文本和图片'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCreate(context, NoteType.richText);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_tree, color: Colors.purple),
              title: const Text('思维导图'),
              subtitle: const Text('可视化思维整理'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCreate(context, NoteType.mindMap);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreate(BuildContext context, NoteType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(createType: type),
      ),
    );
  }

  void _openNote(BuildContext context, String noteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(noteId: noteId),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, Note note, String action, NotesViewModel viewModel) {
    switch (action) {
      case 'edit':
        _openNote(context, note.id);
        break;
      case 'favorite':
        viewModel.toggleFavorite(note.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(note.isFavorite ? '已取消收藏' : '已加入收藏')),
        );
        break;
      case 'move':
        _showMoveToFolderDialog(context, note, viewModel);
        break;
      case 'delete':
        _confirmDelete(context, note, viewModel);
        break;
    }
  }

  void _showFolderManagement(BuildContext context) {
    // TODO: 显示文件夹管理对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('文件夹管理功能开发中...')),
    );
  }

  void _showSearch(BuildContext context) {
    // TODO: 显示搜索界面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('搜索功能开发中...')),
    );
  }

  void _showMoveToFolderDialog(BuildContext context, Note note, NotesViewModel viewModel) {
    final folders = viewModel.folders;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移动到文件夹'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: folders.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('无文件夹'),
                  onTap: () {
                    viewModel.moveNoteToFolder(note.id, null);
                    Navigator.pop(context);
                  },
                );
              }
              final folder = folders[index - 1];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(folder.name),
                onTap: () {
                  viewModel.moveNoteToFolder(note.id, folder.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Note note, NotesViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除笔记'),
        content: Text('确定要删除"${note.title}"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteNote(note.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('笔记已删除')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
