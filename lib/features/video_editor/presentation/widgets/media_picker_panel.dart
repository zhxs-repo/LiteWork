import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../../data/models/media_item_model.dart';
import '../../data/models/timeline_clip_model.dart';
import '../../utils/media_utils.dart';

class MediaPickerPanel extends StatefulWidget {
  const MediaPickerPanel({super.key});

  @override
  State<MediaPickerPanel> createState() => _MediaPickerPanelState();
}

class _MediaPickerPanelState extends State<MediaPickerPanel> {
  final ImagePicker _picker = ImagePicker();
  bool _isImporting = false;

  Future<void> _importMedia() async {
    final List<XFile> media = await _picker.pickMultipleMedia();
    if (media.isEmpty || !mounted) return;

    setState(() => _isImporting = true);
    final mediaItems = <MediaItem>[];
    for (final xfile in media) {
      // 桌面端直接引用原文件，只有临时文件才落地到托管目录
      final storedPath = await MediaUtils.materializeForImport(xfile.path);
      final isVideo = MediaUtils.isVideoFile(storedPath);
      final stat = await File(storedPath).stat();

      // 图片默认时长 3 秒，视频用 media_kit 探测
      final durationMs = isVideo ? await MediaUtils.getVideoDuration(storedPath) : 3000;

      mediaItems.add(MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + xfile.name,
        path: storedPath,
        type: isVideo ? MediaType.video : MediaType.image,
        durationMs: durationMs,
        sizeBytes: stat.size,
        modifiedMs: stat.modified.millisecondsSinceEpoch,
        name: xfile.name,
        createdAt: DateTime.now(),
      ));
    }

    if (!mounted) return;
    setState(() => _isImporting = false);

    final provider = context.read<VideoProvider>();
    final before = provider.availableMedia.length;
    await provider.importMedia(mediaItems);
    final added = provider.availableMedia.length - before;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已导入 $added 个素材，跳过 ${mediaItems.length - added} 个重复项'),
      ),
    );
  }

  Future<void> _relocateMedia(MediaItem media) async {
    final picked = await _picker.pickMedia();
    if (!mounted) return;
    if (picked == null) return;

    final provider = context.read<VideoProvider>();
    final storedPath = await MediaUtils.materializeForImport(picked.path);
    await provider.relocateMedia(media.id, storedPath);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已重新定位「${media.name ?? media.id}」')),
    );
  }

  Future<void> _cleanupStorage() async {
    final provider = context.read<VideoProvider>();
    final usage = await provider.managedStorageUsage();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清理素材存储'),
        content: Text(
          '托管目录当前占用 ${_formatBytes(usage.bytes)}（${usage.files} 个文件）。\n'
          '将删除不再被任何片段引用的副本，磁盘上的原文件不受影响。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('清理'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final freed = await provider.cleanupUnusedMedia();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已释放 ${_formatBytes(freed.bytes)}（${freed.files} 个文件）')),
    );
  }

  Future<void> _addMediaToTimeline(MediaItem mediaItem) async {
    final provider = context.read<VideoProvider>();
    final currentProject = provider.currentProject;

    if (currentProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先创建或打开一个项目')),
      );
      return;
    }

    if (provider.isMediaOffline(mediaItem)) {
      await _relocateMedia(mediaItem);
      return;
    }

    // 计算添加到时间线的位置（追加到末尾）
    final existingClips = provider.clips;
    int startPositionMs = 0;

    if (existingClips.isNotEmpty) {
      startPositionMs = existingClips.fold<int>(
        0,
        (max, clip) => (clip.positionMs + clip.durationMs) > max
            ? (clip.positionMs + clip.durationMs)
            : max,
      );
    }

    final clip = TimelineClip(
      id: '${currentProject.id}_clip_${DateTime.now().millisecondsSinceEpoch}',
      projectId: currentProject.id,
      mediaId: mediaItem.id,
      trackIndex: 0, // 默认添加到视频轨道
      startTimeMs: 0,
      endTimeMs: mediaItem.durationMs,
      durationMs: mediaItem.durationMs,
      positionMs: startPositionMs,
      trimStartMs: 0,
      trimEndMs: 0,
      speed: 1.0,
      isReversed: false,
    );

    await provider.addClipToTimeline(clip);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加 "${mediaItem.name ?? mediaItem.id}" 到时间线')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<VideoProvider>();
    final media = provider.availableMedia;

    return Container(
      height: 120,
      color: cs.surfaceContainerHighest,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '素材库',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _cleanupStorage,
                      child: Text('清理', style: TextStyle(color: cs.primary)),
                    ),
                    TextButton(
                      onPressed: _isImporting ? null : _importMedia,
                      child: Text(
                        _isImporting ? '导入中…' : '+ 导入',
                        style: TextStyle(color: cs.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: media.isEmpty
                ? Center(
                    child: Text(
                      '点击"+ 导入"添加素材',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: media.length,
                    itemBuilder: (context, index) {
                      final item = media[index];
                      return _MediaTile(
                        mediaItem: item,
                        isOffline: provider.isMediaOffline(item),
                        onTap: () => _addMediaToTimeline(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final MediaItem mediaItem;
  final bool isOffline;
  final VoidCallback onTap;

  const _MediaTile({
    required this.mediaItem,
    required this.isOffline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isVideo = mediaItem.type == MediaType.video;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              if (isVideo || isOffline)
                Container(
                  color: cs.primaryContainer,
                  child: Center(
                    child: Icon(
                      isOffline ? Icons.link_off : Icons.video_library,
                      size: 40,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                )
              else
                Image.file(
                  File(mediaItem.path),
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: cs.primaryContainer,
                    child: Center(
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isVideo)
                        Icon(Icons.play_circle, size: 12, color: cs.onSurface),
                      SizedBox(width: isVideo ? 2 : 0),
                      Text(
                        _formatDuration(mediaItem.durationMs),
                        style: TextStyle(color: cs.onSurface, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              if (isOffline)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: Colors.red.shade700,
                    child: const Text(
                      '脱机·点击定位',
                      style: TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final seconds = (ms / 1000).round();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '0:$remainingSeconds';
  }
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).toStringAsFixed(0)} KB';
}
