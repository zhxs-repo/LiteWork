import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MediaPickerPanel extends StatefulWidget {
  final Function(String path, MediaType type) onMediaSelected;

  const MediaPickerPanel({Key? key, required this.onMediaSelected}) : super(key: key);

  @override
  State<MediaPickerPanel> createState() => _MediaPickerPanelState();
}

class _MediaPickerPanelState extends State<MediaPickerPanel> {
  final ImagePicker _picker = ImagePicker();
  List<MediaFile> _mediaFiles = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.grey[900],
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '素材库',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _pickMedia(ImageSource.gallery),
                      icon: Icon(Icons.photo_library, color: Colors.blue, size: 18),
                      label: const Text(
                        '+ 图片',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _pickMedia(ImageSource.camera),
                      icon: Icon(Icons.videocam, color: Colors.green, size: 18),
                      label: const Text(
                        '+ 视频',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 素材列表
          Expanded(
            child: _mediaFiles.isEmpty
                ? Center(
                    child: Text(
                      '点击"+"导入素材',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mediaFiles.length,
                    itemBuilder: (context, index) {
                      return _MediaThumbnail(
                        file: _mediaFiles[index],
                        onTap: () => widget.onMediaSelected(_mediaFiles[index].path, _mediaFiles[index].type),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        // 拍摄视频
        final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
        if (video != null) {
          setState(() {
            _mediaFiles.add(MediaFile(path: video.path, type: MediaType.video));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('视频已添加到素材库'), duration: Duration(seconds: 1)),
          );
        }
      } else {
        // 从相册选择（支持多选）
        final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
        if (images.isNotEmpty) {
          setState(() {
            for (var image in images) {
              _mediaFiles.add(MediaFile(path: image.path, type: MediaType.image));
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已添加 ${images.length} 张图片到素材库'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择失败：$e')),
      );
    }
  }
}

class MediaFile {
  final String path;
  final MediaType type;

  MediaFile({required this.path, required this.type});
}

enum MediaType { image, video, audio }

class _MediaThumbnail extends StatelessWidget {
  final MediaFile file;
  final VoidCallback? onTap;

  const _MediaThumbnail({Key? key, required this.file, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: file.type == MediaType.image
                  ? Image.file(File(file.path), fit: BoxFit.cover, width: 100, height: 100)
                  : Container(
                      color: Colors.blueGrey[800],
                      child: Icon(Icons.video_library, size: 40, color: Colors.white70),
                    ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  file.type == MediaType.image ? Icons.image : Icons.video_library,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
