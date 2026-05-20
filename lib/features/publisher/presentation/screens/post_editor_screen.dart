import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../../../../core/theme/app_theme.dart';

/// 富文本编辑器屏幕
class PostEditorScreen extends StatefulWidget {
  final String? postId;

  const PostEditorScreen({this.postId, super.key});

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  late quill.QuillController _controller;
  bool _isInitialized = false;
  TextEditingController? _titleController;
  late final FocusNode _editorFocusNode;
  late final ScrollController _editorScrollController;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
    _editorFocusNode = FocusNode();
    _editorScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initEditor());
  }

  Future<void> _initEditor() async {
    final provider = context.read<PostProvider>();

    if (widget.postId != null) {
      await provider.loadPost(widget.postId!);
      if (!mounted) return;
      final post = provider.currentPost;
      if (post != null) {
        setState(() {
          _controller = quill.QuillController(
            document: quill.Document.fromDelta(post.content),
            selection: const TextSelection.collapsed(offset: 0),
          );
          _titleController = TextEditingController(text: post.title);
          _isInitialized = true;
        });
      }
    } else {
      provider.createPost();
      if (!mounted) return;
      setState(() {
        _titleController = TextEditingController(text: '新草稿');
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController?.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<PostProvider>(
        builder: (context, provider, _) {
          return TextField(
            decoration: const InputDecoration(
              hintText: '输入标题...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            controller: _titleController ?? TextEditingController(),
            onChanged: provider.updateTitle,
          );
        },
      ),
      actions: [
        Consumer<PostProvider>(
          builder: (context, provider, _) {
            return Row(
              children: [
                _buildSaveIndicator(provider),
                _buildPublishButton(provider),
                _buildMoreMenu(provider),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSaveIndicator(PostProvider provider) {
    if (provider.state == EditorState.saving) {
      return const Padding(
        padding: EdgeInsets.only(right: 8.0),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (provider.state == EditorState.saved) {
      return const Padding(
        padding: EdgeInsets.only(right: 8.0),
        child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPublishButton(PostProvider provider) {
    return IconButton(
      icon: const Icon(Icons.publish),
      tooltip: '发布',
      onPressed: () async {
        await provider.autoSave();
        await provider.publishPost();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('发布成功！')),
          );
        }
      },
    );
  }

  Widget _buildMoreMenu(PostProvider provider) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(value, provider),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'save',
          child: Row(
            children: [
              Icon(Icons.save),
              SizedBox(width: 8),
              Text('保存草稿'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleMenuAction(String value, PostProvider provider) async {
    switch (value) {
      case 'save':
        await provider.autoSave();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已保存到草稿箱')),
          );
        }
        break;
      case 'delete':
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
        if (confirm == true && provider.currentPost != null) {
          await provider.deletePost(provider.currentPost!.id);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已删除')),
            );
          }
        }
        break;
    }
  }

  // ─── Body ────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      children: [
        quill.QuillSimpleToolbar(controller: _controller),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: quill.QuillEditor(
              controller: _controller,
              focusNode: _editorFocusNode,
              scrollController: _editorScrollController,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Bottom Bar ──────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surfaceColor,
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '自动保存开启中',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const Spacer(),
          Text(
            '最后更新：${_formatTime(DateTime.now())}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
