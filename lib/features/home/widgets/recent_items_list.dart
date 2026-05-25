import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../notes/presentation/viewmodel.dart';
import '../../notes/domain/models.dart';
import '../../publisher/presentation/providers/post_provider.dart';
import '../../publisher/data/models/post_document_model.dart';
import '../../video_editor/presentation/providers/video_provider.dart';

class _RecentItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime updatedAt;
  final String type; // 'note', 'post', 'video'

  const _RecentItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.updatedAt,
    required this.type,
  });
}

class RecentItemsList extends StatelessWidget {
  const RecentItemsList({super.key});

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final notesViewModel = context.watch<NotesViewModel>();
    final videoProvider = context.watch<VideoProvider>();

    final List<_RecentItem> allItems = [];

    for (final post in postProvider.posts) {
      allItems.add(_RecentItem(
        id: post.id,
        title: post.title,
        subtitle: post.status == PostStatus.draft ? '草稿' : '已发布',
        icon: Icons.article,
        color: Colors.green,
        updatedAt: post.updatedAt,
        type: 'post',
      ));
    }

    for (final note in notesViewModel.notes) {
      final typeLabel = note.type == NoteType.mindMap ? '思维导图' : '笔记';
      allItems.add(_RecentItem(
        id: note.id,
        title: note.title,
        subtitle: typeLabel,
        icon: note.type == NoteType.mindMap ? Icons.account_tree : Icons.note,
        color: Colors.blue,
        updatedAt: note.updatedAt,
        type: 'note',
      ));
    }

    for (final project in videoProvider.projects) {
      allItems.add(_RecentItem(
        id: project.id,
        title: project.title,
        subtitle: '视频项目',
        icon: Icons.video_library,
        color: Colors.orange,
        updatedAt: project.updatedAt,
        type: 'video',
      ));
    }

    allItems.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recentItems = allItems.take(10).toList();

    if (recentItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最近编辑',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...recentItems.map((item) => _RecentItemTile(item: item)),
      ],
    );
  }
}

class _RecentItemTile extends StatelessWidget {
  final _RecentItem item;

  const _RecentItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(item.icon, color: item.color),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(item.subtitle),
        trailing: Text(
          _formatTime(item.updatedAt),
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        onTap: () => _navigate(context),
      ),
    );
  }

  void _navigate(BuildContext context) {
    switch (item.type) {
      case 'note':
        context.push('/notes/${item.id}');
        break;
      case 'post':
        context.push('/post/editor?id=${item.id}');
        break;
      case 'video':
        context.push('/video-editor/edit/${item.id}');
        break;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }
}
