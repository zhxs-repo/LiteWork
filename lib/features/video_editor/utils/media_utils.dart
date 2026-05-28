import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/utils/common_utils.dart';

/// 媒体工具类 - 用于获取视频/图片的元数据
class MediaUtils {
  /// 获取视频时长（毫秒）
  static Future<int> getVideoDuration(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        logDebug('文件不存在：$path');
        return 0;
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      
      if (controller.value.isInitialized) {
        final duration = controller.value.duration.inMilliseconds;
        await controller.dispose();
        logDebug('视频时长：${duration}ms, 路径：$path');
        return duration;
      }
      
      await controller.dispose();
      logDebug('视频初始化失败：$path');
      return 0;
    } catch (e) {
      logDebug('获取视频时长失败：$e');
      return 0;
    }
  }

  /// 复制文件到应用持久化目录，防止临时文件失效
  static Future<String> copyToAppDirectory(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        logDebug('源文件不存在：$sourcePath');
        return sourcePath;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/media_imports');
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final fileName = path.basename(sourcePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = '${timestamp}_$fileName';
      final destPath = '${mediaDir.path}/$safeFileName';

      await sourceFile.copy(destPath);
      logDebug('文件已复制到持久化目录：$destPath');
      return destPath;
    } catch (e) {
      logDebug('复制文件失败：$e，返回原路径');
      return sourcePath;
    }
  }

  /// 获取图片尺寸
  static Future<Map<String, int>> getImageDimensions(String path) async {
    try {
      // 简单实现，返回默认值
      // 实际项目中可以使用 image 包来获取真实尺寸
      return {'width': 1920, 'height': 1080};
    } catch (e) {
      logDebug('获取图片尺寸失败：$e');
      return {'width': 0, 'height': 0};
    }
  }

  /// 判断文件是否为视频
  static bool isVideoFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mp4') || 
           lowerPath.endsWith('.mov') ||
           lowerPath.endsWith('.avi') ||
           lowerPath.endsWith('.mkv');
  }

  /// 判断文件是否为图片
  static bool isImageFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.jpg') || 
           lowerPath.endsWith('.jpeg') ||
           lowerPath.endsWith('.png') ||
           lowerPath.endsWith('.gif') ||
           lowerPath.endsWith('.webp');
  }
}
