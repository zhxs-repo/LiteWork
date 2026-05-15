import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_editor_provider.dart';
import '../../../base/presentation/widgets/loading_indicator.dart';
import 'widgets/media_picker_panel.dart';
import 'widgets/timeline_view.dart';
import 'widgets/preview_player.dart';
import 'widgets/editor_toolbar.dart';

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
            icon: Icon(Icons.save),
            onPressed: () {
              // TODO: 保存项目
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('项目已保存')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.export),
            onPressed: () {
              // TODO: 导出视频
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('导出功能开发中...')),
              );
            },
          ),
        ],
      ),
      body: Consumer<VideoEditorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return LoadingIndicator();
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
              // 预览区域
              Expanded(
                flex: 3,
                child: PreviewPlayer(),
              ),
              
              // 分隔线
              Divider(height: 1),
              
              // 时间线区域
              Expanded(
                flex: 2,
                child: TimelineView(),
              ),
              
              // 工具栏
              EditorToolbar(),
            ],
          );
        },
      ),
      bottomSheet: MediaPickerPanel(),
    );
  }
}
