import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../viewmodel.dart';
import '../../domain/models.dart';

/// 思维导图编辑器页面
class MindMapEditorScreen extends StatefulWidget {
  final String? noteId;
  final bool createNew;

  const MindMapEditorScreen({
    super.key,
    this.noteId,
    this.createNew = false,
  });

  @override
  State<MindMapEditorScreen> createState() => _MindMapEditorScreenState();
}

class _MindMapEditorScreenState extends State<MindMapEditorScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  MindMapData? _mindMapData;
  String _title = '思维导图';
  bool _isSaving = false;
  String? _selectedNodeId;
  final _titleController = TextEditingController();
  final _nodeTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    if (!widget.createNew && widget.noteId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final viewModel = context.read<NotesViewModel>();
        viewModel.openNote(widget.noteId!);
        final note = viewModel.currentNote;
        if (note != null) {
          setState(() {
            _title = note.title;
            _titleController.text = note.title;
            _mindMapData = note.mindMapData ?? _createDefaultMindMap();
          });
        } else {
          setState(() {
            _mindMapData = _createDefaultMindMap();
          });
        }
      });
    } else {
      _mindMapData = _createDefaultMindMap();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nodeTextController.dispose();
    super.dispose();
  }

  MindMapData _createDefaultMindMap() {
    final root = MindMapNode(
      id: 'root',
      text: '中心主题',
      style: const NodeStyle(
        backgroundColor: '#FF6B6B',
        textColor: '#FFFFFF',
        fontSize: 18,
        fontWeightIndex: 7,
      ),
      x: 400,
      y: 300,
    );
    
    return MindMapData(
      root: root,
      nodes: {'root': root},
      layout: MindMapLayout.horizontal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '思维导图标题',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          onChanged: (value) => _title = value,
        ),
        actions: [
          IconButton(
            icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveMindMap,
            tooltip: '保存',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'add_child', child: Text('添加子节点')),
              const PopupMenuItem(value: 'delete_node', child: Text('删除节点')),
              const PopupMenuItem(value: 'change_layout', child: Text('切换布局')),
              const PopupMenuItem(value: 'export', child: Text('导出')),
              const PopupMenuItem(value: 'convert_to_richtext', child: Text('转换为富文本')),
            ],
          ),
        ],
      ),
      body: _mindMapData == null
          ? const Center(child: CircularProgressIndicator())
          : RepaintBoundary(
              key: _repaintKey,
              child: InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(300),
                minScale: 0.3,
                maxScale: 3.0,
                child: GestureDetector(
                  onTapUp: (details) {
                    final nodeId = _hitTestNode(details.localPosition);
                    if (nodeId != null) {
                      _onNodeTap(nodeId);
                    } else {
                      setState(() => _selectedNodeId = null);
                    }
                  },
                  onDoubleTapDown: (details) {
                    final nodeId = _hitTestNode(details.localPosition);
                    if (nodeId != null) _onNodeDoubleTap(nodeId);
                  },
                  child: SizedBox(
                    width: 3000,
                    height: 3000,
                    child: CustomPaint(
                      painter: MindMapPainter(
                        mindMapData: _mindMapData!,
                        selectedNodeId: _selectedNodeId,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNodeDialog,
        child: const Icon(Icons.add),
        tooltip: '添加节点',
      ),
    );
  }

  void _onNodeTap(String nodeId) {
    setState(() {
      _selectedNodeId = nodeId;
    });
  }

  void _onNodeDoubleTap(String nodeId) {
    _showEditNodeDialog(nodeId);
  }

  void _showAddNodeDialog() {
    if (_selectedNodeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个节点')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加子节点'),
        content: TextField(
          controller: _nodeTextController,
          decoration: const InputDecoration(hintText: '输入节点内容'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (_nodeTextController.text.isNotEmpty) {
                _addChildNode(_selectedNodeId!, _nodeTextController.text);
                _nodeTextController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditNodeDialog(String nodeId) {
    final node = _getNodeById(nodeId);
    if (node == null) return;

    _nodeTextController.text = node.text;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑节点'),
        content: TextField(
          controller: _nodeTextController,
          decoration: const InputDecoration(hintText: '输入节点内容'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (_nodeTextController.text.isNotEmpty) {
                _updateNodeText(nodeId, _nodeTextController.text);
                _nodeTextController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  MindMapNode? _getNodeById(String id) {
    if (id == 'root') return _mindMapData?.root;
    return _mindMapData?.nodes[id];
  }

  void _addChildNode(String parentId, String text) {
    if (_mindMapData == null) return;

    final newNodeId = DateTime.now().millisecondsSinceEpoch.toString();
    final parentNode = _getNodeById(parentId);
    
    if (parentNode == null) return;

    final newNode = MindMapNode(
      id: newNodeId,
      text: text,
      parentId: parentId,
      style: const NodeStyle(
        backgroundColor: '#4ECDC4',
        textColor: '#FFFFFF',
        fontSize: 14,
      ),
      x: parentNode.x != null ? parentNode.x! + 200 : 0,
      y: parentNode.y != null ? parentNode.y! + 50 : 0,
    );

    final updatedNodes = Map<String, MindMapNode>.from(_mindMapData!.nodes);
    updatedNodes[newNodeId] = newNode;

    final updatedParent = parentNode.copyWith(
      childIds: [...parentNode.childIds, newNodeId],
    );

    if (parentId == 'root') {
      updatedNodes['root'] = updatedParent;
    } else {
      updatedNodes[parentId] = updatedParent;
    }

    setState(() {
      _mindMapData = MindMapData(
        root: updatedNodes['root']!,
        nodes: updatedNodes,
        layout: _mindMapData!.layout,
      );
      _selectedNodeId = newNodeId;
    });
  }

  void _updateNodeText(String nodeId, String text) {
    if (_mindMapData == null) return;

    if (nodeId == 'root') {
      final updatedRoot = _mindMapData!.root.copyWith(text: text);
      final updatedNodes = Map<String, MindMapNode>.from(_mindMapData!.nodes);
      updatedNodes['root'] = updatedRoot;
      
      setState(() {
        _mindMapData = MindMapData(
          root: updatedRoot,
          nodes: updatedNodes,
          layout: _mindMapData!.layout,
        );
      });
    } else {
      final node = _mindMapData!.nodes[nodeId];
      if (node != null) {
        final updatedNode = node.copyWith(text: text);
        final updatedNodes = Map<String, MindMapNode>.from(_mindMapData!.nodes);
        updatedNodes[nodeId] = updatedNode;

        setState(() {
          _mindMapData = MindMapData(
            root: _mindMapData!.root,
            nodes: updatedNodes,
            layout: _mindMapData!.layout,
          );
        });
      }
    }
  }

  void _deleteSelectedNode() {
    if (_selectedNodeId == null || _selectedNodeId == 'root') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('不能删除根节点')),
      );
      return;
    }

    if (_mindMapData == null) return;

    final node = _mindMapData!.nodes[_selectedNodeId];
    if (node == null) return;

    final parentId = node.parentId;
    if (parentId != null) {
      final parentNode = _getNodeById(parentId);
      if (parentNode != null) {
        final updatedParent = parentNode.copyWith(
          childIds: parentNode.childIds.where((id) => id != _selectedNodeId).toList(),
        );

        final updatedNodes = Map<String, MindMapNode>.from(_mindMapData!.nodes);
        updatedNodes.remove(_selectedNodeId);
        
        // 递归删除子节点
        _removeChildNodes(updatedNodes, _selectedNodeId!);

        if (parentId == 'root') {
          updatedNodes['root'] = updatedParent;
        } else {
          updatedNodes[parentId] = updatedParent;
        }

        setState(() {
          _mindMapData = MindMapData(
            root: updatedNodes['root']!,
            nodes: updatedNodes,
            layout: _mindMapData!.layout,
          );
          _selectedNodeId = null;
        });
      }
    }
  }

  void _removeChildNodes(Map<String, MindMapNode> nodes, String parentId) {
    final parent = nodes[parentId];
    if (parent == null) return;

    for (final childId in parent.childIds) {
      _removeChildNodes(nodes, childId);
      nodes.remove(childId);
    }
  }

  void _changeLayout() {
    if (_mindMapData == null) return;

    final layouts = MindMapLayout.values;
    final currentIndex = layouts.indexOf(_mindMapData!.layout);
    final nextIndex = (currentIndex + 1) % layouts.length;
    final newLayout = layouts[nextIndex];

    final updatedNodes = Map<String, MindMapNode>.from(_mindMapData!.nodes);
    final cx = 400.0;
    final cy = 300.0;

    // Reposition root
    final root = _mindMapData!.root.copyWith(x: cx, y: cy);

    // Get all child nodes excluding root
    final children = root.childIds
        .map((id) => updatedNodes[id])
        .whereType<MindMapNode>()
        .toList();

    switch (newLayout) {
      case MindMapLayout.horizontal:
        for (int i = 0; i < children.length; i++) {
          final child = children[i];
          updatedNodes[child.id] = child.copyWith(
            x: cx + 250 + (i ~/ 5) * 200,
            y: cy - 100 * ((children.length - 1) / 2 - i),
          );
        }
        break;
      case MindMapLayout.vertical:
        for (int i = 0; i < children.length; i++) {
          final child = children[i];
          updatedNodes[child.id] = child.copyWith(
            x: cx - 100 * ((children.length - 1) / 2 - i),
            y: cy + 120 + (i ~/ 5) * 100,
          );
        }
        break;
      case MindMapLayout.radial:
        for (int i = 0; i < children.length; i++) {
          final angle = (2 * math.pi * i) / children.length - math.pi / 2;
          final r = 200.0;
          final child = children[i];
          updatedNodes[child.id] = child.copyWith(
            x: cx + r * math.cos(angle),
            y: cy + r * math.sin(angle),
          );
        }
        break;
      case MindMapLayout.free:
        // Free layout — keep existing positions
        break;
    }

    updatedNodes['root'] = root;

    setState(() {
      _mindMapData = MindMapData(
        root: root,
        nodes: updatedNodes,
        layout: newLayout,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('布局已切换为：${_getLayoutName(newLayout)}')),
    );
  }

  String _getLayoutName(MindMapLayout layout) {
    switch (layout) {
      case MindMapLayout.horizontal:
        return '水平布局';
      case MindMapLayout.vertical:
        return '垂直布局';
      case MindMapLayout.radial:
        return '辐射布局';
      case MindMapLayout.free:
        return '自由布局';
    }
  }

  Future<void> _saveMindMap() async {
    if (_mindMapData == null) return;

    setState(() => _isSaving = true);

    try {
      final viewModel = context.read<NotesViewModel>();
      final title = _titleController.text.trim().isEmpty 
          ? '无标题思维导图' 
          : _titleController.text.trim();

      final mindMapJson = _mindMapDataToJson(_mindMapData!);

      if (widget.createNew) {
        await viewModel.createNote(
          title: title,
          content: mindMapJson,
          type: NoteType.mindMap,
          folderId: viewModel.selectedFolderId,
        );
      } else if (widget.noteId != null) {
        final note = viewModel.currentNote;
        if (note != null) {
          await viewModel.updateNote(note.copyWith(
            title: title,
            content: mindMapJson,
            mindMapData: _mindMapData,
            updatedAt: DateTime.now(),
          ));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('思维导图已保存'), duration: Duration(seconds: 1)),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  String _mindMapDataToJson(MindMapData data) {
    return '''
{
  "root": {"id": "${data.root.id}", "text": "${data.root.text}"},
  "nodes": ${data.nodes.length},
  "layout": "${data.layout.name}"
}
''';
  }

  String? _hitTestNode(Offset position) {
    if (_mindMapData == null) return null;
    for (final node in _mindMapData!.nodes.values) {
      if (node.x == null || node.y == null) continue;
      final nodeRect = Rect.fromCenter(
        center: Offset(node.x!, node.y!),
        width: 160,
        height: 50,
      );
      if (nodeRect.contains(position)) return node.id;
    }
    final rootRect = Rect.fromCenter(
      center: Offset(_mindMapData!.root.x ?? 0, _mindMapData!.root.y ?? 0),
      width: 180,
      height: 60,
    );
    if (rootRect.contains(position)) return 'root';
    return null;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_child':
        _showAddNodeDialog();
        break;
      case 'delete_node':
        _deleteSelectedNode();
        break;
      case 'change_layout':
        _changeLayout();
        break;
      case 'export':
        _exportMindMap();
        break;
      case 'convert_to_richtext':
        _convertToRichText();
        break;
    }
  }

  void _convertToRichText() async {
    if (_mindMapData == null) return;
    final sb = StringBuffer();
    sb.writeln('# ${_mindMapData!.root.text}');
    for (final childId in _mindMapData!.root.childIds) {
      final child = _mindMapData!.nodes[childId];
      if (child != null) {
        sb.writeln('## ${child.text}');
        for (final grandchildId in child.childIds) {
          final grandchild = _mindMapData!.nodes[grandchildId];
          if (grandchild != null) {
            sb.writeln('- ${grandchild.text}');
          }
        }
      }
    }

    final viewModel = context.read<NotesViewModel>();
    final title = _titleController.text.trim().isEmpty ? '思维导图' : _titleController.text.trim();

    if (widget.noteId != null) {
      final note = viewModel.currentNote;
      if (note != null) {
        await viewModel.updateNote(note.copyWith(
          title: title,
          content: sb.toString(),
          type: NoteType.richText,
          mindMapData: _mindMapData,
          updatedAt: DateTime.now(),
        ));
      }
    } else {
      await viewModel.createNote(
        title: title,
        content: sb.toString(),
        type: NoteType.richText,
        mindMapData: _mindMapData,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已转换为富文本笔记')),
      );
      Navigator.pop(context);
    }
  }

  void _exportMindMap() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在导出思维导图...')),
      );

      // 使用 RepaintBoundary 捕获思维导图为图片
      final RenderRepaintBoundary boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // 保存到应用目录
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/mindmap_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到：$filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }
}

/// 思维导图绘制器
class MindMapPainter extends CustomPainter {
  final MindMapData mindMapData;
  final String? selectedNodeId;

  MindMapPainter({
    required this.mindMapData,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 绘制连接线
    _drawConnections(canvas, mindMapData, paint);

    // 绘制节点
    _drawNode(canvas, mindMapData.root, paint, borderPaint);
    
    for (final node in mindMapData.nodes.values) {
      _drawNode(canvas, node, paint, borderPaint);
    }
  }

  void _drawConnections(Canvas canvas, MindMapData data, Paint paint) {
    paint.color = Colors.grey.shade400;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;

    for (final node in data.nodes.values) {
      if (node.parentId != null) {
        final parentNode = node.parentId == 'root' 
            ? data.root 
            : data.nodes[node.parentId];
        
        if (parentNode != null && node.x != null && node.y != null) {
          canvas.drawLine(
            Offset(node.x!, node.y!),
            Offset(parentNode.x ?? 0, parentNode.y ?? 0),
            paint,
          );
        }
      }
    }

    // 绘制根节点到子节点的连接
    for (final childId in data.root.childIds) {
      final childNode = data.nodes[childId];
      if (childNode != null && childNode.x != null && childNode.y != null) {
        canvas.drawLine(
          Offset(data.root.x ?? 0, data.root.y ?? 0),
          Offset(childNode.x!, childNode.y!),
          paint,
        );
      }
    }
  }

  void _drawNode(Canvas canvas, MindMapNode node, Paint paint, Paint borderPaint) {
    if (node.x == null || node.y == null) return;

    final isSelected = node.id == selectedNodeId;
    final color = node.style.backgroundColor != null 
        ? _hexToColor(node.style.backgroundColor!) 
        : Colors.blue;
    
    paint.color = color;
    borderPaint.color = isSelected ? Colors.orange : Colors.white;

    final textSpan = TextSpan(
      text: node.text,
      style: TextStyle(
        color: node.style.textColor != null 
            ? _hexToColor(node.style.textColor!) 
            : Colors.white,
        fontSize: node.style.fontSize ?? 14,
        fontWeight: node.style.fontWeightIndex != null 
            ? FontWeight.values[node.style.fontWeightIndex!] 
            : FontWeight.normal,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    final padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    final nodeSize = Size(
      textPainter.width + padding.horizontal,
      textPainter.height + padding.vertical,
    );

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(node.x!, node.y!),
        width: nodeSize.width,
        height: nodeSize.height,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        node.x! - textPainter.width / 2,
        node.y! - textPainter.height / 2,
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  bool shouldRepaint(covariant MindMapPainter oldDelegate) {
    return oldDelegate.mindMapData != mindMapData || 
           oldDelegate.selectedNodeId != selectedNodeId;
  }
}
