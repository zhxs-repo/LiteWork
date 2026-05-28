import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import '../../../../core/components/quill_embed_builders.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/collapsible_toolbar.dart';

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
  Timer? _autoSaveTimer;
  DateTime? _lastSaveTime;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
    _editorFocusNode = FocusNode();
    _editorScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initEditor());
    _startAutoSave();
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _autoSave();
      }
    });
  }

  Future<void> _autoSave() async {
    final provider = context.read<PostProvider>();
    if (provider.currentPost != null) {
      await provider.autoSave();
      setState(() {
        _lastSaveTime = DateTime.now();
      });
    }
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
    _controller.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (!mounted || !_isInitialized) return;
    final provider = context.read<PostProvider>();
    if (provider.currentPost != null) {
      provider.updateContent(_controller.document.toDelta());
    }
  }

  Future<void> _insertImages() async {
    final files = await _picker.pickMultipleMedia();
    if (!mounted || files.isEmpty) return;
    for (final file in files) {
      final index = _controller.selection.baseOffset;
      _controller.document.insert(index, quill.BlockEmbed.image(file.path));
    }
  }

  Future<void> _setCoverImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted || file == null) return;
    context.read<PostProvider>().updateCoverImage(file.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已设置封面图')),
      );
    }
  }

  Future<void> _copyAsText() async {
    final text = _controller.document.toPlainText();
    await Clipboard.setData(ClipboardData(text: text));
  }

  void _showExportSheet(PostProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ExportSheet(
        onCopyText: () {
          Navigator.pop(ctx);
          _copyAsText().then((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已复制内容，请粘贴到目标平台')),
            );
            provider.publishPost();
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller.removeListener(_onContentChanged);
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
                  _buildExportButton(provider),
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

  Widget _buildExportButton(PostProvider provider) {
    return IconButton(
      icon: const Icon(Icons.publish),
      tooltip: '导出',
      onPressed: () async {
        await provider.autoSave();
        if (!mounted) return;
        _showExportSheet(provider);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        return Column(
          children: [
            // 图片工具栏 - 紧凑模式
            SizedBox(
              height: isNarrow ? 36 : 44,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.image, size: 20),
                    tooltip: '插入图片',
                    onPressed: _insertImages,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isNarrow ? 36 : 48,
                      minHeight: isNarrow ? 36 : 48,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image_search, size: 20),
                    tooltip: '设置封面图',
                    onPressed: _setCoverImage,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isNarrow ? 36 : 48,
                      minHeight: isNarrow ? 36 : 48,
                    ),
                  ),
                ],
              ),
            ),
            // 格式工具栏 - 可折叠
            CollapsibleToolbar(
              controller: _controller,
              onInsertImage: _insertImages,
              initiallyExpanded: !isNarrow,
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: quill.QuillEditor(
                  controller: _controller,
                  focusNode: _editorFocusNode,
                  scrollController: _editorScrollController,
                  config: const quill.QuillEditorConfig(
                    embedBuilders: [QuillImageEmbedBuilder()],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Bottom Bar ──────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surfaceColor,
      child: Row(
        children: [
          Icon(
            _lastSaveTime != null ? Icons.cloud_done : Icons.cloud_off,
            size: 16,
            color: _lastSaveTime != null ? Colors.greenAccent : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            _lastSaveTime != null
                ? '已保存 ${_formatTime(_lastSaveTime!)}'
                : '尚未保存',
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

/// 导出选择面板
class _ExportSheet extends StatelessWidget {
  final VoidCallback onCopyText;

  const _ExportSheet({required this.onCopyText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '导出到',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 400;
              final crossAxisCount = isNarrow ? 2 : 3;
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: 3.5,
                children: [
                  _PlatformTile(
                    icon: Icons.content_copy,
                    label: '复制为文本',
                    subtitle: '粘贴到任意平台',
                    color: Colors.blue,
                    onTap: onCopyText,
                  ),
                  _PlatformTile(
                    icon: Icons.chat,
                    label: '微信公众号',
                    subtitle: '复制内容后手动发布',
                    color: Colors.green,
                    onTap: onCopyText,
                  ),
                  _PlatformTile(
                    icon: Icons.book,
                    label: '知乎',
                    subtitle: '复制内容后手动发布',
                    color: Colors.blue,
                    onTap: onCopyText,
                  ),
                  _PlatformTile(
                    icon: Icons.alternate_email,
                    label: '微博',
                    subtitle: '复制内容后手动发布',
                    color: Colors.orange,
                    onTap: onCopyText,
                  ),
                  _PlatformTile(
                    icon: Icons.article,
                    label: '今日头条',
                    subtitle: '复制内容后手动发布',
                    color: Colors.red,
                    onTap: onCopyText,
                  ),
                  _PlatformTile(
                    icon: Icons.auto_stories,
                    label: '小红书',
                    subtitle: '复制内容后手动发布',
                    color: Colors.pink,
                    onTap: onCopyText,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PlatformTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
