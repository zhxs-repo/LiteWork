import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// FFmpeg 服务封装
/// 提供视频剪辑、合并、变速、倒放等核心功能
class FFmpegService {
  /// 裁剪视频 (剪切片段)
  /// [inputPath] 输入文件路径
  /// [startTime] 开始时间 (秒)
  /// [duration] 持续时间 (秒)
  /// [outputPath] 输出文件路径 (可选，默认生成临时文件)
  Future<String?> clipVideo({
    required String inputPath,
    required double startTime,
    required double duration,
    String? outputPath,
    Function(double progress)? onProgress,
  }) async {
    final output = outputPath ?? await _generateTempPath('.mp4');
    
    // FFmpeg 裁剪命令: -ss (start), -t (duration), -c copy (快速拷贝不重编码)
    // 注意：为了精确剪辑，通常需要重编码，这里使用 libx264
    final command = '-y -i "$inputPath" -ss $startTime -t $duration -c:v libx264 -c:a aac "$output"';
    
    return await _executeCommand(command, onProgress);
  }

  /// 变速播放
  /// [speed] 速度倍数 (0.5 = 慢动作, 2.0 = 快进)
  Future<String?> changeSpeed({
    required String inputPath,
    required double speed,
    String? outputPath,
    Function(double progress)? onProgress,
  }) async {
    final output = outputPath ?? await _generateTempPath('.mp4');
    
    // setpts 调整视频时间戳，atempo 调整音频速度 (0.5-2.0 范围，超出需链式调用)
    final videoFilter = 'setpts=${1/speed}*PTS';
    final audioFilter = speed >= 0.5 && speed <= 2.0 
        ? 'atempo=$speed' 
        : 'atempo=${_clampAtempo(speed)}'; // 简化处理，实际需链式
    
    final command = '-y -i "$inputPath" -filter_complex "$videoFilter,$audioFilter" "$output"';
    
    return await _executeCommand(command, onProgress);
  }

  /// 倒放视频
  Future<String?> reverseVideo({
    required String inputPath,
    String? outputPath,
    Function(double progress)? onProgress,
  }) async {
    final output = outputPath ?? await _generateTempPath('.mp4');
    
    // reverse 滤镜 (注意：这非常消耗性能，且需要大量内存)
    final command = '-y -i "$inputPath" -vf reverse -af areverse "$output"';
    
    return await _executeCommand(command, onProgress);
  }

  /// 合并多个视频片段
  Future<String?> mergeVideos({
    required List<String> inputPaths,
    String? outputPath,
    Function(double progress)? onProgress,
  }) async {
    final output = outputPath ?? await _generateTempPath('.mp4');
    
    // 创建临时 concat 文件
    final tempDir = await getTemporaryDirectory();
    final concatFile = File('${tempDir.path}/concat_list.txt');
    final content = inputPaths.map((path) => "file '$path'").join('\n');
    await concatFile.writeAsString(content);
    
    final command = '-y -f concat -safe 0 -i "${concatFile.path}" -c copy "$output"';
    
    final result = await _executeCommand(command, onProgress);
    
    // 清理临时文件
    if (await concatFile.exists()) {
      await concatFile.delete();
    }
    
    return result;
  }

  /// 执行 FFmpeg 命令的通用方法
  Future<String?> _executeCommand(
    String command, 
    Function(double progress)? onProgress,
  ) async {
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // 从命令中提取输出路径 (最后一个引号内的内容)
        final regex = RegExp(r'"([^"]+)"$');
        final match = regex.firstMatch(command);
        return match?.group(1);
      } else {
        final failStackTrace = await session.getFailStackTrace();
        print('FFmpeg Error: $failStackTrace');
        return null;
      }
    } catch (e) {
      print('FFmpeg Exception: $e');
      return null;
    }
  }

  /// 生成临时文件路径
  Future<String> _generateTempPath(String extension) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/litework_edit_$timestamp$extension';
  }

  /// 处理 atempo 滤镜的范围限制 (0.5 - 2.0)
  String _clampAtempo(double speed) {
    if (speed < 0.5) return '0.5';
    if (speed > 2.0) return '2.0';
    return speed.toString();
    // 注意：真实场景若需 >2.0 或 <0.5，需链式调用多个 atempo，此处简化
  }
}
