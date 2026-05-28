import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litework/features/video_editor/presentation/providers/video_provider.dart';
import 'package:litework/features/video_editor/presentation/widgets/media_picker_panel.dart';
import 'package:litework/features/video_editor/presentation/widgets/timeline_view.dart';
import 'package:litework/features/video_editor/presentation/widgets/preview_player.dart';
import 'package:litework/features/video_editor/presentation/widgets/editor_toolbar.dart';
import 'package:litework/features/video_editor/presentation/screens/export_config_screen.dart';
import 'package:litework/features/video_editor/domain/usecases/timeline_edit_usecase.dart';
import 'package:litework/features/video_editor/data/models/timeline_clip_model.dart';

class VideoEditorScreen extends StatefulWidget {
  final String? projectId;

  const VideoEditorScreen({super.key, this.projectId});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  int? _selectedSegmentId;
  double _playheadPosition = 0;
  final TimelineEditUseCase _editUseCase = TimelineEditUseCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VideoProvider>();
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExportConfigScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<VideoProvider>(
        builder: (context, provider, _) => _buildBody(provider),
      ),
      bottomSheet: const MediaPickerPanel(),
    );
  }

  Widget _buildBody(VideoProvider provider) {
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
    final timelineData = provider.buildTimelineData();
    return Column(
      children: [
        Expanded(
          flex: 3, 
          child: PreviewPlayer(
            videoPath: provider.firstClipPath,
            currentPosition: Duration(milliseconds: (_playheadPosition * 1000).round()),
            onPositionChanged: (position) {
              // 播放时同步更新播放头位置
              setState(() {
                _playheadPosition = position.inMilliseconds / 1000;
              });
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(flex: 2, child: TimelineView(
          timelineData: timelineData,
          onSeek: (pos) => setState(() => _playheadPosition = pos),
          onSegmentSelected: (id) => setState(() => _selectedSegmentId = id),
          onClipMoved: (id, newStart) => _moveClip(provider, id, newStart),
        )),
        EditorToolbar(
          hasSelection: _selectedSegmentId != null,
          onSplit: _selectedSegmentId != null ? () => _splitClip(provider) : null,
          onDelete: _selectedSegmentId != null ? () => _deleteClip(provider) : null,
        ),
      ],
    );
  }

  void _splitClip(VideoProvider provider) {
    if (_selectedSegmentId == null || _selectedSegmentId! >= provider.clips.length) return;

    final clip = provider.clips[_selectedSegmentId!];
    final splitPointMs = (_playheadPosition * 1000).round() - clip.positionMs;

    if (splitPointMs <= 0 || splitPointMs >= clip.durationMs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('播放头位置无法分割此片段')),
      );
      return;
    }

    final result = _editUseCase.splitClip(provider.clips, clip.id, splitPointMs);
    final oldIndex = result.indexWhere((c) => c.id == clip.id);
    if (oldIndex == -1) return;

    provider.deleteClip(clip.id);
    provider.addClipToTimeline(result[oldIndex]);

    final newClipIndex = result.indexWhere((c) => c.id == '${clip.id}_split');
    if (newClipIndex != -1) {
      provider.addClipToTimeline(result[newClipIndex]);
    }

    setState(() => _selectedSegmentId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('片段已分割')),
    );
  }

  void _deleteClip(VideoProvider provider) {
    if (_selectedSegmentId == null || _selectedSegmentId! >= provider.clips.length) return;

    final clip = provider.clips[_selectedSegmentId!];
    provider.deleteClip(clip.id);
    setState(() => _selectedSegmentId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('片段已删除')),
    );
  }

  void _moveClip(VideoProvider provider, int segmentId, double newStartTime) {
    if (segmentId >= provider.clips.length) return;
    final clip = provider.clips[segmentId];
    provider.updateClip(TimelineClip(
      id: clip.id,
      projectId: clip.projectId,
      mediaId: clip.mediaId,
      trackIndex: clip.trackIndex,
      startTimeMs: (newStartTime * 1000).round(),
      endTimeMs: clip.endTimeMs,
      durationMs: clip.durationMs,
      positionMs: (newStartTime * 1000).round(),
      trimStartMs: clip.trimStartMs,
      trimEndMs: clip.trimEndMs,
      speed: clip.speed,
      isReversed: clip.isReversed,
      effects: clip.effects,
    ));
  }

  void _saveProject() {
    context.read<VideoProvider>().saveCurrentProject();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('项目已保存')),
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
