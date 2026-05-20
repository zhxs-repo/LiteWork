import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../../data/models/post_document_model.dart';
import '../../../../core/router/app_router.dart';

/// 帖子列表屏幕（草稿箱）
class PostListScreen extends StatelessWidget {
  const PostListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('草稿箱'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建草稿',
            onPressed: () => context.pushNamed('postEditor'),
          ),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, provider, _) {
          if (provider.state == EditorState.loading && provider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.drafts.isEmpty) {
            return const _EmptyDraftsView();
          }
          return _DraftsList(drafts: provider.drafts);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('postEditor'),
        icon: const Icon(Icons.add),
        label: const Text('新建草稿'),
      ),
    );
  }
}

/// 空状态视图
class _EmptyDraftsView extends StatelessWidget {
  const _EmptyDraftsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无草稿', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('点击右下角 + 开始创作', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

/// 草稿列表
class _DraftsList extends StatelessWidget {
  final List<PostDocumentModel> drafts;
  const _DraftsList({required this.drafts});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: drafts.length,
      itemBuilder: (context, index) => _DraftCard(post: drafts[index]),
    );
  }
}

/// 单个草稿卡片
class _DraftCard extends StatelessWidget {
  final PostDocumentModel post;
  const _DraftCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          post.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            '更新于 ${_formatDate(post.updatedAt)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: '编辑',
              onPressed: () => _navigateToEditor(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: '删除',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        onTap: () => _navigateToEditor(context),
      ),
    );
  }

  void _navigateToEditor(BuildContext context) {
    context.pushNamed('postEditor', queryParameters: {'id': post.id});
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这篇草稿吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<PostProvider>().deletePost(post.id);
    }
  }

  static String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}/${date.day}';
  }
}
