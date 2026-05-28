import 'package:ffmpeg_kit_flutter_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_video/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// FFmpeg 视频渲染服务
/// 负责将时间线配置转换为真实的 FFmpeg 命令并执行渲染
class FFmpegRenderService {
  static final FFmpegRenderService _instance = FFmpegRenderService._internal();
  factory FFmpegRenderService() => _instance;
  FFmpegRenderService._internal();

  /// 渲染进度回调
  typedef RenderProgressCallback = void Function(double progress);
  
  /// 渲染完成回调
  typedef RenderCompleteCallback = void Function(String? outputPath, String? error);

  /// 执行视频渲染
  /// 
  /// [clips] - 片段列表，每个片段包含 path, startTimeMs, durationMs, isImage
  /// [outputPath] - 输出文件路径
  /// [resolution] - 分辨率 (1080p, 720p, 480p)
  /// [frameRate] - 帧率 (30, 60, 24)
  /// [onProgress] - 进度回调 (0.0 - 1.0)
  /// 
  /// 返回输出文件路径或 null (失败时)
  Future<String?> renderVideo({
    required List<Map<String, dynamic>> clips,
    required String outputPath,
    required String resolution,
    required String frameRate,
    required String aspectRatio,
    RenderProgressCallback? onProgress,
  }) async {
    try {
      // 创建输出目录
      final outputDir = Directory(outputPath).parent;
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      // 构建 FFmpeg 命令
      final ffmpegCommand = _buildFFmpegCommand(
        clips: clips,
        outputPath: outputPath,
        resolution: resolution,
        frameRate: frameRate,
        aspectRatio: aspectRatio,
      );

      print('执行 FFmpeg 命令：$ffmpegCommand');

      // 执行 FFmpeg
      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print('渲染成功：$outputPath');
        return outputPath;
      } else {
        final failStackTrace = await session.getFailStackTrace();
        print('渲染失败：$failStackTrace');
        return null;
      }
    } catch (e) {
      print('渲染异常：$e');
      return null;
    }
  }

  /// 构建 FFmpeg 命令，支持修剪、图片时长和转场
  String _buildFFmpegCommand({
    required List<Map<String, dynamic>> clips, // 包含 path, startTimeMs, durationMs, isImage
    required String outputPath,
    required String resolution,
    required String frameRate,
    required String aspectRatio,
  }) {
    // 解析分辨率
    final videoSize = _resolveResolution(resolution, aspectRatio);
    
    if (clips.isEmpty) {
      throw Exception('没有可渲染的片段');
    }

    // 单个视频文件直接处理（带修剪）
    if (clips.length == 1 && !clips.first['isImage']) {
      final clip = clips.first;
      final startTimeSec = (clip['startTimeMs'] ?? 0) / 1000.0;
      final durationSec = (clip['durationMs'] ?? 0) / 1000.0;
      
      String command = '-i "${clip['path']}"';
      
      // 添加修剪参数
      if (startTimeSec > 0) {
        command += ' -ss $startTimeSec';
      }
      if (durationSec > 0) {
        command += ' -t $durationSec';
      }
      
      command += ' -c:v libx264 -preset medium -crf 23 -r $frameRate -s ${videoSize.first}x${videoSize.second} -c:a aac -b:a 128k "$outputPath"';
      return command;
    }

    // 多片段或包含图片：使用复杂滤镜链
    final inputs = <String>[];
    final filters = <String>[];
    var outputIndex = 0;

    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final path = clip['path'] as String;
      final startTimeSec = (clip['startTimeMs'] ?? 0) / 1000.0;
      final durationSec = (clip['durationMs'] ?? 0) / 1000.0;
      final isImage = clip['isImage'] as bool? ?? false;

      inputs.add('-i');
      inputs.add(path);
      
      final inputIndex = i + 1; // FFmpeg 输入索引从 1 开始（0 是全局选项）
      final label = 'v$outputIndex';
      
      if (isImage) {
        // 图片：设置循环和时长
        filters.add('[$inputIndex]loop=1:1:${durationSec > 0 ? durationSec : 3},format=yuv420p[$label]');
      } else {
        // 视频：应用修剪
        String filter = '[$inputIndex]';
        if (startTimeSec > 0 || durationSec > 0) {
          filter += 'trim=';
          if (startTimeSec > 0) filter += 'start=$startTimeSec';
          if (durationSec > 0) filter += ',duration=$durationSec';
          filter += ',';
        }
        filter += 'setpts=PTS-STARTPTS[$label]';
        filters.add(filter);
      }
      
      outputIndex++;
    }

    // 连接所有片段
    if (clips.length > 1) {
      final concatInputs = List.generate(clips.length, (i) => '[v$i]').join('');
      filters.add('$concatInputs concat=n=${clips.length}:v=1:a=0[outv]');
      
      final allInputs = inputs.join(' ');
      final filterComplex = filters.join(';');
      
      return '$allInputs -filter_complex "$filterComplex" -map "[outv]" -c:v libx264 -preset medium -crf 23 -r $frameRate -s ${videoSize.first}x${videoSize.second} -c:a aac -b:a 128k "$outputPath"';
    } else {
      // 单个图片
      final filterComplex = filters.join(';');
      final allInputs = inputs.join(' ');
      return '$allInputs -filter_complex "$filterComplex" -map "[v0]" -c:v libx264 -preset medium -crf 23 -r $frameRate -s ${videoSize.first}x${videoSize.second} -c:a aac -b:a 128k "$outputPath"';
    }
  }

  /// 解析分辨率和宽高比
  _ResolutionPair _resolveResolution(String resolution, String aspectRatio) {
    int width, height;
    
    // 基础分辨率
    switch (resolution) {
      case '4K':
        width = 3840;
        height = 2160;
        break;
      case '1080p':
        width = 1920;
        height = 1080;
        break;
      case '720p':
        width = 1280;
        height = 720;
        break;
      case '480p':
        width = 854;
        height = 480;
        break;
      default:
        width = 1920;
        height = 1080;
    }

    // 根据宽高比调整
    switch (aspectRatio) {
      case '9:16': // 竖屏 (抖音/TikTok)
        final temp = width;
        width = height * 9 ~/ 16;
        height = temp;
        // 确保能被 2 整除 (H.264 要求)
        if (width % 2 != 0) width += 1;
        break;
      case '1:1': // 正方形
        width = height;
        break;
      case '16:9': // 横屏 (默认)
        // 保持不变
        break;
      case '4:5': // Instagram 肖像
        width = height * 4 ~/ 5;
        if (width % 2 != 0) width += 1;
        break;
    }

    return _ResolutionPair(width, height);
  }

  /// 获取输出文件路径
  Future<String> getOutputFilePath({
    required String projectName,
    String extension = 'mp4',
  }) async {
    final directory = await getExternalStorageDirectory();
    final dcimDir = Directory('${directory!.parent.parent.parent.path}/DCIM/LiteWork');
    
    if (!await dcimDir.exists()) {
      await dcimDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = projectName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    
    return '${dcimDir.path}/${safeName}_$timestamp.$extension';
  }

  /// 从文件中提取视频信息 (时长、分辨率等)
  Future<Map<String, dynamic>?> getMediaInfo(String filePath) async {
    try {
      // 使用 ffprobe 获取媒体信息
      final session = await FFmpegKit.execute('-v quiet -print_format json -show_format -show_streams "$filePath"');
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        final output = await session.getOutput();
        // 这里需要 JSON 解析，简化处理返回 null
        return {'path': filePath};
      }
      return null;
    } catch (e) {
      print('获取媒体信息失败：$e');
      return null;
    }
  }
}

/// 简单的键值对类
class _ResolutionPair {
  final int first;
  final int second;
  _ResolutionPair(this.first, this.second);
}
