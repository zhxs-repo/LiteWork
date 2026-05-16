import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel.dart';

/// 回收站页面
class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesViewModel>(
      builder: (context, viewModel, _) {
        final trashItems = viewModel.trashItems;
        
        if (trashItems.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('回收站'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () {
                    _showClearConfirm(context, viewModel);
                  },
                  tooltip: '清空回收站',
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '回收站为空',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '删除的笔记会暂时存放在这里',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('回收站'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () {
                  _showClearConfirm(context, viewModel);
                },
                tooltip: '清空回收站',
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: trashItems.length,
            itemBuilder: (context, index) {
              final item = trashItems[index];
              return ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(item.title),
                subtitle: Text('删除时间：${item.deletedAt.toString().substring(0, 19)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () {
                        viewModel.restoreFromTrash(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('笔记已恢复')),
                        );
                      },
                      tooltip: '恢复',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever),
                      onPressed: () {
                        _confirmDeleteForever(context, viewModel, item.id);
                      },
                      tooltip: '彻底删除',
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showClearConfirm(BuildContext context, NotesViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要彻底删除回收站中的所有项目吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // 调用清理逻辑
              viewModel.clearTrash();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('回收站已清空')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteForever(BuildContext context, NotesViewModel viewModel, String itemId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要彻底删除该项目吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.deletePermanently(itemId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('项目已彻底删除')),
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
