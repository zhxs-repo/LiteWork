import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litework/features/video_editor/presentation/providers/video_editor_provider.dart';
import 'package:litework/features/video_editor/presentation/widgets/media_picker_panel.dart';
import 'package:litework/features/video_editor/presentation/widgets/timeline_view.dart';
import 'package:litework/features/video_editor/presentation/widgets/preview_player.dart';
import 'package:litework/features/video_editor/presentation/widgets/editor_toolbar.dart';

class VideoEditorScreen extends StatefulWidget {
  final String? projectId;

  const VideoEditorScreen({super.key, this.projectId});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VideoEditorProvider>();
      if (widget.projectId != null) {
        provider.loadProject(widget.projectId!);
      } else {
        provider.createProject('新项目');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频剪辑'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _saveProject,
          ),
          IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: _exportVideo,
          ),
        ],
      ),
      body: Consumer<VideoEditorProvider>(
        builder: (context, provider, _) => _buildBody(provider),
      ),
      bottomSheet: const MediaPickerPanel(),
    );
  }

  Widget _buildBody(VideoEditorProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return _ErrorView(
        message: provider.error!,
        onRetry: provider.clearError,
      );
    }
    if (provider.currentProject == null) {
      return const Center(child: Text('未找到项目'));
    }
    return const Column(
      children: [
        Expanded(flex: 3, child: PreviewPlayer()),
        Divider(height: 1),
        Expanded(flex: 2, child: TimelineView()),
        EditorToolbar(),
      ],
    );
  }

  void _saveProject() {
    context.read<VideoEditorProvider>().saveProject();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('项目已保存')),
    );
  }

  void _exportVideo() {
    context.read<VideoEditorProvider>().exportVideo();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在导出视频，请稍候...')),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text('发生错误：$message'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
