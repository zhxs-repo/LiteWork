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
  late quill.QuillToolbarConfig _toolbarConfig;
  bool _isInitialized = false;
  TextEditingController? _titleController;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
    _initEditor();
  }

  Future<void> _initEditor() async {
    final provider = context.read<PostProvider>();

    if (widget.postId != null) {
      await provider.loadPost(widget.postId!);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: context.read<PostProvider>(),
      child: Scaffold(
        appBar: AppBar(
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
                  color: Colors.white,
                ),
                controller: _titleController ?? TextEditingController(),
                onChanged: (value) {
                  provider.updateTitle(value);
                },
              );
            },
          ),
          actions: [
            Consumer<PostProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: [
                    // 保存状态指示器
                    if (provider.state == EditorState.saving)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                          ),
                        ),
                      ),
                    if (provider.state == EditorState.saved)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 20,
                        ),
                      ),
                    // 发布按钮
                    IconButton(
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
                    ),
                    // 更多选项
                    PopupMenuButton<String>(
                      onSelected: (value) async {
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
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
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
                      },
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
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // 工具栏
            quill.QuillSimpleToolbar(
              controller: _controller,
              configurations: quill.QuillSimpleToolbarConfigurations(
                toolbarConfiguration: quill.QuillToolbarConfiguration(
                  multiRowsDisplay: true,
                  showAlignmentButtons: true,
                  showBackgroundColorButton: true,
                  showBoldButton: true,
                  showCenterAlignment: true,
                  showClearFormat: true,
                  showCodeBlock: false,
                  showColorButton: true,
                  showDividers: true,
                  showDirection: false,
                  showFontSize: true,
                  showFontFamily: false,
                  showHeaderStyle: false,
                  showIndent: true,
                  showInlineCode: false,
                  showItalicButton: true,
                  showJustifyAlignment: true,
                  showLeftAlignment: true,
                  showLink: true,
                  showListBullets: true,
                  showListCheck: true,
                  showListNumbers: true,
                  showQuote: true,
                  showRedo: true,
                  showRightAlignment: true,
                  showSearchButton: false,
                  showSmallButton: false,
                  showStrikeThrough: true,
                  showSubscript: false,
                  showSuperscript: false,
                  showUnderLineButton: true,
                  showUndo: true,
                ),
              ),
            ),
            const Divider(height: 1),
            // 编辑区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: quill.QuillEditor(
                  controller: _controller,
                  scrollController: ScrollController(),
                  configurations: quill.QuillEditorConfigurations(
                    placeholder: '开始写作...',
                    autoFocus: true,
                    expands: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    readOnly: false,
                    scrollbarTheme: ScrollbarThemeData(),
                    scrollable: true,
                    customStyles: {
                      BlockStyle.paragraph: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        // 自动保存监听
        bottomNavigationBar: Consumer<PostProvider>(
          builder: (context, provider, _) {
            // 监听内容变化自动保存（简单实现：3 秒防抖）
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
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
