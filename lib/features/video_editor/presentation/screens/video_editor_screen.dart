import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litework/features/video_editor/presentation/providers/video_editor_provider.dart';
import 'package:litework/features/video_editor/presentation/widgets/media_picker_panel.dart';
import 'package:litework/features/video_editor/presentation/widgets/timeline_view.dart';
import 'package:litework/features/video_editor/presentation/widgets/preview_player.dart';
import 'package:litework/features/video_editor/presentation/widgets/editor_toolbar.dart';

class VideoEditorScreen extends StatefulWidget {
  final String? projectId;

  const VideoEditorScreen({Key? key, this.projectId}) : super(key: key);

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
        title: Text('视频剪辑'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: () {
              final provider = context.read<VideoEditorProvider>();
              provider.saveProject();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('项目已保存')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: () {
              final provider = context.read<VideoEditorProvider>();
              provider.exportVideo();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('正在导出视频，请稍候...')),
              );
            },
          ),
        ],
      ),
      body: Consumer<VideoEditorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('发生错误：${provider.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.clearError(),
                    child: Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (provider.currentProject == null) {
            return Center(child: Text('未找到项目'));
          }

          return Column(
            children: [
              Expanded(
                flex: 3,
                child: const PreviewPlayer(),
              ),
              
              const Divider(height: 1),
              
              Expanded(
                flex: 2,
                child: const TimelineView(),
              ),
              
              const EditorToolbar(),
            ],
          );
        },
      ),
      bottomSheet: const MediaPickerPanel(),
    );
  }
}
