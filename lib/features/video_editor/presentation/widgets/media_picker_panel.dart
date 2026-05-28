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
  final List<XFile> _selectedMedia = [];
  int? _selectedMediaIndex;

  Future<void> _importMedia() async {
    final List<XFile> media = await _picker.pickMultipleMedia();
    if (media.isNotEmpty) {
      setState(() {
        _selectedMedia.addAll(media);
      });

      final mediaItems = <MediaItem>[];
      
      for (final xfile in media) {
        // 先复制到持久化目录
        final persistentPath = await MediaUtils.copyToAppDirectory(xfile.path);
        
        final isVideo = MediaUtils.isVideoFile(persistentPath);
        int durationMs = 0;
        
        // 异步获取视频时长
        if (isVideo) {
          durationMs = await MediaUtils.getVideoDuration(persistentPath);
        } else {
          // 图片默认时长为 3 秒
          durationMs = 3000;
        }

        mediaItems.add(MediaItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + xfile.name,
          path: persistentPath,
          type: isVideo ? MediaType.video : MediaType.image,
          durationMs: durationMs,
          createdAt: DateTime.now(),
        ));
      }

      if (mounted) {
        context.read<VideoProvider>().importMedia(mediaItems);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入 ${media.length} 个素材')),
        );
      }
    }
  }

  Future<void> _addMediaToTimeline(XFile xfile, MediaItem mediaItem, int index) async {
    final provider = context.read<VideoProvider>();
    final currentProject = provider.currentProject;
    
    if (currentProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先创建或打开一个项目')),
      );
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

    // 创建时间线片段
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

    // 添加到时间线
    await provider.addClipToTimeline(clip);
    
    if (mounted) {
      setState(() {
        _selectedMediaIndex = index;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加 "${xfile.name}" 到时间线')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                TextButton(
                  onPressed: _importMedia,
                  child: Text('+ 导入', style: TextStyle(color: cs.primary)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedMedia.isEmpty
                ? Center(
                    child: Text(
                      '点击"+ 导入"添加素材',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedMedia.length,
                    itemBuilder: (context, index) {
                      final xfile = _selectedMedia[index];
                      final isVideo = MediaUtils.isVideoFile(xfile.path);
                      
                      // 查找对应的 MediaItem
                      final provider = context.watch<VideoProvider>();
                      final mediaItem = provider.availableMedia.lastWhere(
                        (m) => m.path == xfile.path,
                        orElse: () => MediaItem(
                          id: '',
                          path: xfile.path,
                          type: isVideo ? MediaType.video : MediaType.image,
                          durationMs: 0,
                          createdAt: DateTime.now(),
                        ),
                      );
                      
                      return _MediaFileTile(
                        xfile: xfile,
                        mediaItem: mediaItem,
                        onTap: () => _addMediaToTimeline(xfile, mediaItem, index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MediaFileTile extends StatelessWidget {
  final XFile xfile;
  final MediaItem mediaItem;
  final VoidCallback onTap;
  
  const _MediaFileTile({
    required this.xfile,
    required this.mediaItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isVideo = MediaUtils.isVideoFile(xfile.path);

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
              Image.file(
                File(xfile.path),
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.primaryContainer,
                  child: Center(
                    child: Icon(
                      isVideo ? Icons.video_library : Icons.image,
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
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.primary.withValues(alpha: 0.5), width: 2),
                    borderRadius: BorderRadius.circular(8),
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
