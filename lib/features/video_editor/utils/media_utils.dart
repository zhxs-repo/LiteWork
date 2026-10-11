import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/utils/common_utils.dart';

/// 媒体工具类 - 素材落地策略、元数据探测与托管文件清理
class MediaUtils {
  static const Duration _probeTimeout = Duration(seconds: 10);
  static const String _managedDirName = 'media_imports';

  /// 当前写入的托管目录：应用私有位置，不占用用户文档目录
  ///
  /// - Android: 应用专属外部存储（大文件不该挤占 /data，且卸载自动清理）
  /// - 其余桌面/移动平台: Application Support
  static Future<String> managedDirectory() async {
    if (!kIsWeb && Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) return path.join(external.path, _managedDirName);
    }
    final supportDir = await getApplicationSupportDirectory();
    return path.join(supportDir.path, _managedDirName);
  }

  /// 旧版本写入用户文档目录的托管位置，仅用于识别与回收，不再写入
  static Future<String> legacyManagedDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return path.join(docsDir.path, _managedDirName);
  }

  /// 全部托管根目录（写入位 + 历史位）
  static Future<List<String>> managedDirectories() async => [
        await managedDirectory(),
        await legacyManagedDirectory(),
      ];

  static String canonicalPath(String p) {
    final normalized = path.normalize(p).replaceAll('\\', '/');
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  /// 是否位于任一托管根目录下——只有托管文件才允许被清理删除
  static Future<bool> isManagedPath(String targetPath) async {
    final canonical = canonicalPath(targetPath);
    for (final dir in await managedDirectories()) {
      if (canonical.startsWith('${canonicalPath(dir)}/')) return true;
    }
    return false;
  }

  /// 各托管根目录下的文件路径（目录不存在时跳过）
  static Future<List<String>> managedFilePaths() async {
    final result = <String>[];
    for (final dirPath in await managedDirectories()) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;
      result.addAll(dir
          .listSync()
          .whereType<File>()
          .map((f) => f.path));
    }
    return result;
  }

  /// 删除文件并返回释放的字节数，文件不存在时返回 0
  static Future<int> deleteFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return 0;
    final bytes = await file.length();
    await file.delete();
    return bytes;
  }

  /// 源文件是否位于应用临时目录（image_picker 在 iOS/Android 上导出的副本，重启即失效）
  static Future<bool> isEphemeral(String sourcePath) async {
    final tmp = await getTemporaryDirectory();
    return canonicalPath(sourcePath).startsWith('${canonicalPath(tmp.path)}/');
  }

  /// 导入落地策略：
  /// - 临时文件 -> 复制到托管目录，按「同名 + size + mtime」复用已有副本
  /// - 其余（用户原文件、旧托管副本）-> 直接引用原路径，不再复制
  static Future<String> materializeForImport(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      logDebug('源文件不存在：$sourcePath');
      return sourcePath;
    }

    if (!await isEphemeral(sourcePath)) {
      return sourcePath;
    }

    try {
      final stat = await file.stat();
      final baseName = path.basename(sourcePath);
      // 命中已有副本则复用，避免重复复制
      for (final filePath in await managedFilePaths()) {
        if (!path.basename(filePath).endsWith(baseName)) continue;
        final other = await File(filePath).stat();
        if (other.size == stat.size &&
            other.modified.millisecondsSinceEpoch ==
                stat.modified.millisecondsSinceEpoch) {
          logDebug('复用已有副本：$filePath');
          return filePath;
        }
      }

      final managedDir = await managedDirectory();
      await Directory(managedDir).create(recursive: true);
      final destPath = path.join(
        managedDir,
        '${DateTime.now().millisecondsSinceEpoch}_$baseName',
      );
      await file.copy(destPath);
      logDebug('文件已复制到托管目录：$destPath');
      return destPath;
    } catch (e) {
      logDebug('复制文件失败：$e，返回原路径');
      return sourcePath;
    }
  }

  /// 用 media_kit 探测视频时长（毫秒），失败返回 0
  static Future<int> getVideoDuration(String filePath) async {
    final player = Player();
    final detected = Completer<Duration>();
    final subscription = player.stream.duration.listen((value) {
      if (value > Duration.zero && !detected.isCompleted) {
        detected.complete(value);
      }
    });

    try {
      await player.open(Media(filePath), play: false);
      final duration = await detected.future
          .timeout(_probeTimeout, onTimeout: () => Duration.zero);
      logDebug('视频时长：${duration.inMilliseconds}ms, 路径：$filePath');
      return duration.inMilliseconds;
    } catch (e) {
      logDebug('获取视频时长失败：$e');
      return 0;
    } finally {
      await subscription.cancel();
      await player.dispose();
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
