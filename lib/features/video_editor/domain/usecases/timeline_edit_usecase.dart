import '../../data/models/timeline_clip_model.dart';

/// 时间线编辑用例
/// 负责处理时间线相关的业务逻辑，如片段排序、时长计算等
class TimelineEditUseCase {
  
  /// 计算总时长 (毫秒)
  int calculateTotalDuration(List<TimelineClip> clips) {
    if (clips.isEmpty) return 0;
    return clips.fold<int>(0, (total, clip) => total + clip.durationMs);
  }

  /// 检查时间线冲突
  bool hasOverlap(List<TimelineClip> clips) {
    if (clips.length < 2) return false;
    
    final sortedClips = List<TimelineClip>.from(clips)
      ..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));

    for (int i = 0; i < sortedClips.length - 1; i++) {
      final current = sortedClips[i];
      final next = sortedClips[i + 1];
      
      if (current.startTimeMs + current.durationMs > next.startTimeMs) {
        return true;
      }
    }
    return false;
  }

  /// 分割片段
  List<TimelineClip> splitClip(
    List<TimelineClip> clips, 
    String clipId, 
    int splitPointMs
  ) {
    final index = clips.indexWhere((c) => c.id == clipId);
    if (index == -1) return clips;

    final clip = clips[index];
    if (splitPointMs <= 0 || splitPointMs >= clip.durationMs) return clips;

    final firstHalf = TimelineClip(
      id: clip.id,
      projectId: clip.projectId,
      mediaId: clip.mediaId,
      trackIndex: clip.trackIndex,
      startTimeMs: clip.startTimeMs,
      endTimeMs: clip.startTimeMs + splitPointMs,
      durationMs: splitPointMs,
      positionMs: clip.positionMs,
      trimStartMs: clip.trimStartMs,
      trimEndMs: clip.trimEndMs,
      speed: clip.speed,
      isReversed: clip.isReversed,
      effects: clip.effects,
    );

    final secondHalf = TimelineClip(
      id: '${clip.id}_split',
      projectId: clip.projectId,
      mediaId: clip.mediaId,
      trackIndex: clip.trackIndex,
      startTimeMs: clip.startTimeMs + splitPointMs,
      endTimeMs: clip.endTimeMs,
      durationMs: clip.durationMs - splitPointMs,
      positionMs: clip.positionMs + splitPointMs,
      trimStartMs: clip.trimStartMs,
      trimEndMs: clip.trimEndMs,
      speed: clip.speed,
      isReversed: clip.isReversed,
      effects: clip.effects,
    );

    final result = List<TimelineClip>.from(clips);
    result.removeAt(index);
    result.insertAll(index, [firstHalf, secondHalf]);
    
    return result;
  }
}
