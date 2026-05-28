import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../../../../core/components/quill_embed_builders.dart';
import '../viewmodel.dart';
import '../../domain/models.dart';
import 'mind_map_editor_screen.dart';

/// 笔记编辑页面 - 支持富文本和思维导图
class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  final NoteType? createType;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.createType,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isSaving = false;
  bool _isSyncing = false;
  String _title = '';
  final _titleController = TextEditingController();
  bool _hasUnsyncedChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<NotesViewModel>();
      if (widget.noteId != null) {
        viewModel.openNote(widget.noteId!);
        final note = viewModel.currentNote;
        if (note != null) {
          _titleController.text = note.title;
          if (note.type == NoteType.richText && note.content.isNotEmpty) {
            try {
              _controller = quill.QuillController(
                document: quill.Document.fromJson(jsonDecode(note.content)),
                selection: const TextSelection.collapsed(offset: 0),
              );
            } catch (e) {
              _controller = quill.QuillController.basic();
            }
          }
        }
      } else if (widget.createType != null) {
        if (widget.createType == NoteType.mindMap) {
          _navigateToMindMapEditor();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '笔记标题',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          onChanged: (value) => _title = value,
        ),
        actions: [
          // 云同步按钮
          Consumer<NotesViewModel>(
            builder: (context, viewModel, child) {
              final isConfigured = viewModel.isWebDavConfigured;
              if (!isConfigured) return const SizedBox.shrink();
              
              final note = viewModel.currentNote;
              final isSynced = note?.isSynced ?? false;
              final lastSyncedAt = note?.lastSyncedAt;
              
              return IconButton(
                icon: _isSyncing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(
                        isSynced ? Icons.cloud_done : Icons.cloud_off,
                        color: isSynced ? Colors.green : Colors.orange,
                      ),
                onPressed: _isSyncing ? null : _syncCurrentNote,
                tooltip: isSynced 
                    ? '已同步${lastSyncedAt != null ? '\n${_formatLastSynced(lastSyncedAt)}' : ''}'
                    : '同步到云端',
              );
            },
          ),
          // 撤销按钮
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              if (_controller.document.isEmpty()) return;
              _controller.undo();
            },
            tooltip: '撤销',
          ),
          // 重做按钮
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () {
              _controller.redo();
            },
            tooltip: '重做',
          ),
          IconButton(
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveNote,
            tooltip: '保存',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) {
              final note = context.read<NotesViewModel>().currentNote;
              final type = note?.type ?? widget.createType ?? NoteType.richText;
              return [
                const PopupMenuItem(value: 'favorite', child: Text('收藏')),
                const PopupMenuItem(value: 'folder', child: Text('移动到文件夹')),
                PopupMenuItem(
                  value: 'convert_type',
                  child: Text(type == NoteType.mindMap ? '转换为富文本' : '转换为思维导图'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('删除')),
              ];
            },
          ),
        ],
      ),
      body: Consumer<NotesViewModel>(
        builder: (context, viewModel, child) {
          final note = viewModel.currentNote;
          final type = note?.type ?? widget.createType ?? NoteType.richText;

          if (type == NoteType.mindMap) {
            if (widget.noteId != null && note != null) {
              return MindMapEditorScreen(noteId: widget.noteId!);
            } else {
              return MindMapEditorScreen(createNew: true);
            }
          }

          return Column(
            children: [
              _buildToolbar(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: quill.QuillEditor(
                    controller: _controller,
                    focusNode: _focusNode,
                    scrollController: ScrollController(),
                    config: const quill.QuillEditorConfig(
                      embedBuilders: [QuillImageEmbedBuilder()],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: quill.QuillSimpleToolbar(
        controller: _controller,
      ),
    );
  }

  void _navigateToMindMapEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MindMapEditorScreen(createNew: true),
      ),
    );
  }

  Future<void> _saveNote() async {
    setState(() => _isSaving = true);

    try {
      final viewModel = context.read<NotesViewModel>();
      final content = jsonEncode(_controller.document.toDelta().toJson());
      final title = _titleController.text.trim().isEmpty 
          ? '无标题笔记' 
          : _titleController.text.trim();

      if (widget.noteId != null) {
        final note = viewModel.currentNote;
        if (note != null) {
          await viewModel.updateNote(note.copyWith(
            title: title,
            content: content,
            updatedAt: DateTime.now(),
          ));
          // 标记为有未同步的更改
          setState(() {
            _hasUnsyncedChanges = true;
          });
        }
      } else {
        await viewModel.createNote(
          title: title,
          content: content,
          type: NoteType.richText,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('笔记已保存'), duration: Duration(seconds: 1)),
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

  /// 同步当前笔记到云端
  Future<void> _syncCurrentNote() async {
    final viewModel = context.read<NotesViewModel>();
    final note = viewModel.currentNote;
    
    if (note == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有可同步的笔记')),
        );
      }
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final success = await viewModel.syncNote(note.id);
      
      if (mounted) {
        if (success) {
          setState(() {
            _hasUnsyncedChanges = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('同步成功'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('同步失败：${viewModel.error ?? '未知错误'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步异常：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  /// 格式化最后同步时间
  String _formatLastSynced(DateTime lastSyncedAt) {
    final now = DateTime.now();
    final diff = now.difference(lastSyncedAt);
    
    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${lastSyncedAt.month}/${lastSyncedAt.day} ${lastSyncedAt.hour}:${lastSyncedAt.minute.toString().padLeft(2, '0')}';
    }
  }

  void _handleMenuAction(String action) {
    final viewModel = context.read<NotesViewModel>();
    final note = viewModel.currentNote;
    
    if (note == null) return;

    switch (action) {
      case 'favorite':
        viewModel.toggleFavorite(note.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(note.isFavorite ? '已取消收藏' : '已加入收藏')),
        );
        break;
      case 'folder':
        _showMoveToFolderDialog(viewModel, note);
        break;
      case 'delete':
        _confirmDelete(viewModel, note);
        break;
      case 'convert_type':
        _convertNoteType(viewModel, note);
        break;
    }
  }

  void _convertNoteType(NotesViewModel viewModel, Note note) async {
    final newType = note.type == NoteType.mindMap ? NoteType.richText : NoteType.mindMap;
    final label = newType == NoteType.mindMap ? '思维导图' : '富文本';

    final converted = await viewModel.updateNote(note.copyWith(
      type: newType,
      updatedAt: DateTime.now(),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已转换为$label')),
      );
      setState(() {});
    }
  }

  void _showMoveToFolderDialog(NotesViewModel viewModel, Note note) {
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

  void _confirmDelete(NotesViewModel viewModel, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除笔记'),
        content: Text('确定要删除"${note.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteNote(note.id);
              Navigator.pop(context);
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
