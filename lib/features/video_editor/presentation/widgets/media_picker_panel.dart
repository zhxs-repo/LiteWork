import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../../data/models/media_item_model.dart';

class MediaPickerPanel extends StatefulWidget {
  const MediaPickerPanel({super.key});

  @override
  State<MediaPickerPanel> createState() => _MediaPickerPanelState();
}

class _MediaPickerPanelState extends State<MediaPickerPanel> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedMedia = [];

  Future<void> _importMedia() async {
    final List<XFile> media = await _picker.pickMultipleMedia();
    if (media.isNotEmpty) {
      setState(() {
        _selectedMedia.addAll(media);
      });

      final mediaItems = media.map((xfile) => MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + xfile.name,
        path: xfile.path,
        type: xfile.name.toLowerCase().endsWith('.mp4') ||
                xfile.name.toLowerCase().endsWith('.mov')
            ? MediaType.video
            : MediaType.image,
        durationMs: 0,
        createdAt: DateTime.now(),
      )).toList();

      if (mounted) {
        context.read<VideoProvider>().importMedia(mediaItems);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入 ${media.length} 个素材')),
        );
      }
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
                    itemBuilder: (context, index) => _MediaFileTile(
                      xfile: _selectedMedia[index],
                      index: index,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MediaFileTile extends StatelessWidget {
  final XFile xfile;
  final int index;
  const _MediaFileTile({required this.xfile, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isVideo = xfile.name.toLowerCase().endsWith('.mp4') ||
        xfile.name.toLowerCase().endsWith('.mov');

    return Container(
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
                child: Text(
                  isVideo ? '视频' : '图片',
                  style: TextStyle(color: cs.onSurface, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
