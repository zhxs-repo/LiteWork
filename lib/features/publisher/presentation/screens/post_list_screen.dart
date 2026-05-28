import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../../data/models/post_document_model.dart';

/// 帖子列表屏幕（草稿箱/已发布）
class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图文'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建草稿',
            onPressed: () => context.pushNamed('postEditor'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '草稿'),
            Tab(text: '已发布'),
          ],
        ),
      ),
      body: Consumer<PostProvider>(
        builder: (context, provider, _) {
          if (provider.state == EditorState.loading && provider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              provider.drafts.isEmpty
                  ? const _EmptyView(
                      icon: Icons.edit_note_outlined,
                      text: '暂无草稿',
                      hint: '点击右上角 + 开始创作',
                    )
                  : _PostsList(posts: provider.drafts),
              provider.published.isEmpty
                  ? const _EmptyView(
                      icon: Icons.publish_outlined,
                      text: '暂无已发布内容',
                      hint: '编辑完成后点击导出按钮发布',
                    )
                  : _PostsList(posts: provider.published),
            ],
          );
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
class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String text;
  final String hint;

  const _EmptyView({
    required this.icon,
    required this.text,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(hint, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

/// 帖子列表（复用草稿和已发布）
class _PostsList extends StatelessWidget {
  final List<PostDocumentModel> posts;
  const _PostsList({required this.posts});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) => _PostCard(post: posts[index]),
    );
  }
}

/// 单个帖子卡片（草稿/已发布共用）
class _PostCard extends StatelessWidget {
  final PostDocumentModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDraft = post.status == PostStatus.draft;
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDraft ? Colors.orange[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isDraft ? '草稿' : '已发布',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDraft ? Colors.orange[800] : Colors.green[800],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '更新于 ${_formatDate(post.updatedAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: '编辑',
              onPressed: () => _navigateToEditor(context),
            ),
            if (isDraft)
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
