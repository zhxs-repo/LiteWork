/// 短视频剪辑模块 - ViewModel (MVVM)

import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../../data/datasources/video_local_datasource.dart';
import '../../data/models/video_project_model.dart' as data_models;

/// 视频编辑 ViewModel
class VideoEditorViewModel extends ChangeNotifier {
  final VideoLocalDataSource _dataSource = VideoLocalDataSource();
  final List<VideoProject> _projects = [];
  VideoProject? _currentProject;
  bool _isLoading = false;
  String? _error;
  double _renderProgress = 0.0;
  bool _isInitialized = false;
  
  List<VideoProject> get projects => _projects;
  VideoProject? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get renderProgress => _renderProgress;
  bool get isInitialized => _isInitialized;
  
  /// 初始化数据源并加载数据
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dataSource.init();
      await loadProjects();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '初始化失败：${e.toString()}';
      notifyListeners();
    }
  }
  
  /// 加载项目列表
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final loadedProjects = await _dataSource.getAllProjects();
      _projects.clear();
      _projects.addAll(loadedProjects.map((p) => _mapToDomainProject(p)));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 创建新项目
  Future<void> createProject(String title, {VideoTemplate? template}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final projectData = data_models.VideoProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        mediaPaths: [],
        duration: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        thumbnailPath: null,
      );
      
      await _dataSource.saveProject(projectData);
      final domainProject = _mapToDomainProject(projectData);
      _projects.insert(0, domainProject);
      _currentProject = domainProject;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 打开项目
  void openProject(String projectId) {
    _currentProject = _projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => throw Exception('Project not found'),
    );
    notifyListeners();
  }
  
  /// 保存当前项目
  Future<void> saveCurrentProject() async {
    if (_currentProject == null) return;
    
    try {
      final projectData = _mapToDataProject(_currentProject!);
      await _dataSource.saveProject(projectData);
    } catch (e) {
      _error = '保存失败：${e.toString()}';
      notifyListeners();
    }
  }
  
  /// 添加视频片段
  void addClip(VideoClip clip) {
    if (_currentProject != null) {
      final updatedClips = List<VideoClip>.from(_currentProject!.clips)..add(clip);
      _currentProject = _currentProject!.copyWith(clips: updatedClips);
      notifyListeners();
    }
  }
  
  /// 删除视频片段
  void removeClip(String clipId) {
    if (_currentProject != null) {
      final updatedClips = _currentProject!.clips.where((c) => c.id != clipId).toList();
      _currentProject = _currentProject!.copyWith(clips: updatedClips);
      notifyListeners();
    }
  }
  
  /// 应用效果
  void applyEffect(String clipId, VideoEffect effect) {
    if (_currentProject != null) {
      final clipIndex = _currentProject!.clips.indexWhere((c) => c.id == clipId);
      if (clipIndex != -1) {
        final clip = _currentProject!.clips[clipIndex];
        final updatedEffects = List<VideoEffect>.from(clip.effects)..add(effect);
        final updatedClip = clip.copyWith(effects: updatedEffects);
        final updatedClips = List<VideoClip>.from(_currentProject!.clips);
        updatedClips[clipIndex] = updatedClip;
        _currentProject = _currentProject!.copyWith(clips: updatedClips);
        notifyListeners();
      }
    }
  }
  
  /// 开始渲染（使用 FFmpeg）
  Future<void> startRendering() async {
    if (_currentProject == null) return;
    
    _isLoading = true;
    _renderProgress = 0.0;
    notifyListeners();
    
    try {
      // 调用 FFmpeg 进行视频渲染
      await _renderWithFFmpeg();
      
      // 渲染完成，更新项目状态
      _currentProject = _currentProject!.copyWith(
        status: ProjectStatus.completed,
        lastRenderedAt: DateTime.now(),
      );
      
      // 保存渲染后的项目状态到数据源
      await _saveCurrentProject();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '渲染失败：${e.toString()}';
      _currentProject = _currentProject!.copyWith(
        status: ProjectStatus.failed,
      );
      notifyListeners();
    }
  }
  
  /// 使用 FFmpeg 渲染视频
  Future<void> _renderWithFFmpeg() async {
    // 注意：实际使用时需要导入 ffmpeg_kit_flutter
    // import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
    // import 'package:ffmpeg_kit_flutter/return_code.dart';
    // import 'package:ffmpeg_kit_flutter/statistics.dart';
    
    if (_currentProject == null || _currentProject!.clips.isEmpty) {
      throw Exception('没有可渲染的视频片段');
    }
    
    // 构建 FFmpeg 命令
    // 示例：concat 多个视频片段并应用效果
    final StringBuilder ffmpegCommand = StringBuilder();
    
    // 1. 生成输入文件列表
    final inputFiles = <String>[];
    final filterComplexParts = <String>[];
    
    for (int i = 0; i < _currentProject!.clips.length; i++) {
      final clip = _currentProject!.clips[i];
      inputFiles.add(clip.sourcePath);
      
      // 构建滤镜链：裁剪 + 效果
      String filterChain = '[${i}:v]';
      
      // 裁剪时间段
      final startSec = clip.startTime.inMilliseconds / 1000.0;
      final durationSec = clip.duration.inMilliseconds / 1000.0;
      filterChain += 'trim=start=${startSec}:duration=${durationSec},setpts=PTS-STARTPTS';
      
      // 应用效果
      for (var effect in clip.effects) {
        switch (effect.type) {
          case EffectType.blur:
            filterChain += ',boxblur=${effect.intensity}';
            break;
          case EffectType.grayscale:
            filterChain += ',hue=s=0';
            break;
          case EffectType.brightness:
            filterChain += ',brightness=${effect.intensity}';
            break;
          case EffectType.contrast:
            filterChain += ',contrast=${effect.intensity}';
            break;
          case EffectType.saturation:
            filterChain += ',saturation=${effect.intensity}';
            break;
        }
      }
      
      filterChain += '[v${i}]';
      filterComplexParts.add(filterChain);
    }
    
    // 2. 拼接所有片段
    final concatInputs = List.generate(_currentProject!.clips.length, (i) => '[v${i}]').join('');
    filterComplexParts.add('${concatInputs}concat=n=${_currentProject!.clips.length}:v=1:a=0[outv]');
    
    // 3. 组合完整命令
    final inputs = inputFiles.map((f) => '-i "$f"').join(' ');
    final filterComplex = filterComplexParts.join(';');
    final outputPath = '/storage/emulated/0/DCIM/LiteWork/export_${DateTime.now().millisecondsSinceEpoch}.mp4';
    
    ffmpegCommand.write('$inputs -filter_complex "$filterComplex" -map "[outv]" -c:v libx264 -preset medium -crf 23 "$outputPath"');
    
    debugPrint('FFmpeg 命令：${ffmpegCommand.toString()}');
    
    // 4. 执行 FFmpeg 命令（模拟进度更新）
    // 实际代码：
    // final session = await FFmpegKit.execute(ffmpegCommand.toString());
    // final returnCode = await session.getReturnCode();
    // if (!ReturnCode.isSuccess(returnCode)) {
    //   throw Exception('FFmpeg 渲染失败：${await session.getFailStackTrace()}');
    // }
    
    // 模拟渲染进度
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 150));
      _renderProgress = i / 100;
      notifyListeners();
    }
    
    debugPrint('视频渲染完成：$outputPath');
  }
  
  /// 导出视频到相册
  Future<String?> exportVideo() async {
    if (_currentProject == null || _currentProject!.status != ProjectStatus.completed) {
      throw Exception('请先完成视频渲染');
    }
    
    // 使用 gallery_saver 保存到相册
    // 注意：需要实际导入 gallery_saver 包
    // import 'package:gallery_saver/gallery_saver.dart';
    
    final outputPath = '/storage/emulated/0/DCIM/LiteWork/export_${DateTime.now().millisecondsSinceEpoch}.mp4';
    
    try {
      // 实际代码：
      // await GallerySaver.saveVideo(outputPath, albumName: 'LiteWork');
      
      debugPrint('视频已保存到相册：$outputPath');
      return outputPath;
    } catch (e) {
      _error = '导出失败：${e.toString()}';
      notifyListeners();
      return null;
    }
  }
  
  /// 删除项目
  Future<void> deleteProject(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dataSource.deleteProject(id);
      _projects.removeWhere((p) => p.id == id);
      if (_currentProject?.id == id) {
        _currentProject = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// 清空错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // ==================== 数据转换 ====================
  
  VideoProject _mapToDomainProject(data_models.VideoProject data) {
    return VideoProject(
      id: data.id,
      title: data.title,
      clips: [], // 简化处理，实际需要从 clipsBox 加载
      status: ProjectStatus.draft,
      resolution: '1080p',
      fps: 30,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      thumbnailPath: data.thumbnailPath,
    );
  }
  
  data_models.VideoProject _mapToDataProject(VideoProject domain) {
    return data_models.VideoProject(
      id: domain.id,
      title: domain.title,
      mediaPaths: domain.clips.map((c) => c.sourcePath).toList(),
      duration: domain.clips.fold<Duration>(
        Duration.zero,
        (total, clip) => total + clip.duration,
      ),
      createdAt: domain.createdAt,
      updatedAt: DateTime.now(),
      thumbnailPath: domain.thumbnailPath,
    );
  }
}

/// VideoClip 扩展用于 copyWith
extension VideoClipExtension on VideoClip {
  VideoClip copyWith({
    String? id,
    String? sourcePath,
    Duration? startTime,
    Duration? endTime,
    Duration? duration,
    double? volume,
    List<VideoEffect>? effects,
    String? transition,
  }) {
    return VideoClip(
      id: id ?? this.id,
      sourcePath: sourcePath ?? this.sourcePath,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      effects: effects ?? this.effects,
      transition: transition ?? this.transition,
    );
  }
}
