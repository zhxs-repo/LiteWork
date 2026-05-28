import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// 可折叠的富文本工具栏，适配移动端窄屏
class CollapsibleToolbar extends StatefulWidget {
  final quill.QuillController controller;
  final VoidCallback onInsertImage;
  final bool initiallyExpanded;

  const CollapsibleToolbar({
    required this.controller,
    required this.onInsertImage,
    this.initiallyExpanded = true,
    super.key,
  });

  @override
  State<CollapsibleToolbar> createState() => _CollapsibleToolbarState();
}

class _CollapsibleToolbarState extends State<CollapsibleToolbar> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 工具栏内容
        if (_expanded)
          quill.QuillSimpleToolbar(controller: widget.controller)
        else
          // 精简模式：只显示常用按钮
          SizedBox(
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: 8),
                _quickBtn(
                  Icons.format_bold,
                  '加粗',
                  () => _toggleAttribute(quill.AttributeKey.bold),
                ),
                _quickBtn(
                  Icons.format_italic,
                  '斜体',
                  () => _toggleAttribute(quill.AttributeKey.italic),
                ),
                _quickBtn(
                  Icons.format_underline,
                  '下划线',
                  () => _toggleAttribute(quill.AttributeKey.underline),
                ),
                _quickBtn(
                  Icons.image,
                  '图片',
                  widget.onInsertImage,
                ),
                _quickBtn(
                  Icons.link,
                  '链接',
                  () => _insertLink(),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.expand_more, size: 20),
                  tooltip: '展开全部工具',
                  onPressed: () => setState(() => _expanded = true),
                ),
              ],
            ),
          ),
        // 展开时显示收起按钮
        if (_expanded)
          GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: Container(
              height: 20,
              alignment: Alignment.center,
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.expand_less, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '收起工具栏',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _quickBtn(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  void _toggleAttribute(quill.AttributeKey key) {
    final isApplied = widget.controller.selectionStyle?.attributes.containsKey(key) ?? false;
    widget.controller.formatSelection(quill.Attribute(key, !isApplied));
  }

  void _insertLink() {
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('插入链接'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'https://example.com'),
          autofocus: true,
          onSubmitted: (url) {
            Navigator.pop(ctx, url);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final text = (ctx.findRenderObject() as RenderObject?)?.toString();
              Navigator.pop(ctx, url);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    ).then((url) {
      if (url != null && url.isNotEmpty) {
        widget.controller.formatSelection(quill.Attribute.link(url));
      }
    });
  }
}
