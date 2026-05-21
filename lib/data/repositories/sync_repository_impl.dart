import 'dart:convert';
import 'package:http/http.dart' as http;
import '../datasources/offline_queue_manager.dart';
import '../../../core/storage/storage_manager.dart';

/// 同步仓库实现 - 协调本地数据源和远程数据源，实现离线优先策略
class SyncRepositoryImpl {
  final http.Client _client;
  final StorageManager _localDataSource;
  final OfflineQueueManager _offlineQueueManager;

  // API Base URL
  static const String baseUrl = 'https://api.litework.example.com';

  SyncRepositoryImpl({
    required http.Client client,
    required StorageManager localDataSource,
    required OfflineQueueManager offlineQueueManager,
  })  : _client = client,
        _localDataSource = localDataSource,
        _offlineQueueManager = offlineQueueManager;

  /// 同步所有数据（笔记、帖子、视频项目）
  Future<SyncResult> syncAll() async {
    try {
      // 检查网络状态
      final isOnline = await _offlineQueueManager.checkConnectivity();
      if (!isOnline) {
        return SyncResult(
          success: false,
          message: '当前处于离线模式，仅使用本地数据',
          syncedCount: 0,
        );
      }

      int totalSynced = 0;

      // 并行同步各类数据
      final results = await Future.wait([
        _syncNotes(),
        _syncPosts(),
        _syncVideoProjects(),
      ]);

      totalSynced = results.fold(0, (sum, count) => sum + count);

      return SyncResult(
        success: true,
        message: '同步完成，共更新 $totalSynced 条数据',
        syncedCount: totalSynced,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: '同步失败：${e.toString()}',
        syncedCount: 0,
      );
    }
  }

  /// 同步笔记数据
  Future<int> _syncNotes() async {
    // 1. 获取本地最后同步时间
    final lastSyncTime = _localDataSource.getData<DateTime>('notes_last_sync') ?? DateTime(2000);

    // 2. 从服务器获取变更
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/sync/notes?since=${lastSyncTime.toIso8601String()}'),
    );

    if (response.statusCode != 200) {
      throw Exception('获取笔记同步数据失败');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final notesToCreate = data['created'] as List? ?? [];
    final notesToUpdate = data['updated'] as List? ?? [];
    final notesToDelete = data['deleted'] as List<String>? ?? [];

    int count = 0;

    // 3. 创建新笔记
    for (final noteJson in notesToCreate) {
      await _localDataSource.saveData('note_${noteJson['id']}', noteJson);
      count++;
    }

    // 4. 更新已有笔记
    for (final noteJson in notesToUpdate) {
      await _localDataSource.saveData('note_${noteJson['id']}', noteJson);
      count++;
    }

    // 5. 删除已删除的笔记
    for (final noteId in notesToDelete) {
      await _localDataSource.deleteData('note_$noteId');
      count++;
    }

    // 6. 更新最后同步时间
    await _localDataSource.saveData('notes_last_sync', DateTime.now());

    return count;
  }

  /// 同步帖子数据
  Future<int> _syncPosts() async {
    final lastSyncTime = _localDataSource.getData<DateTime>('posts_last_sync') ?? DateTime(2000);

    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/sync/posts?since=${lastSyncTime.toIso8601String()}'),
    );

    if (response.statusCode != 200) {
      throw Exception('获取帖子同步数据失败');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final postsToCreate = data['created'] as List? ?? [];
    final postsToUpdate = data['updated'] as List? ?? [];
    final postsToDelete = data['deleted'] as List<String>? ?? [];

    int count = 0;

    for (final postJson in postsToCreate) {
      await _localDataSource.saveData('post_${postJson['id']}', postJson);
      count++;
    }

    for (final postJson in postsToUpdate) {
      await _localDataSource.saveData('post_${postJson['id']}', postJson);
      count++;
    }

    for (final postId in postsToDelete) {
      await _localDataSource.deleteData('post_$postId');
      count++;
    }

    await _localDataSource.saveData('posts_last_sync', DateTime.now());

    return count;
  }

  /// 同步视频项目数据
  Future<int> _syncVideoProjects() async {
    final lastSyncTime = _localDataSource.getData<DateTime>('videos_last_sync') ?? DateTime(2000);

    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/sync/videos?since=${lastSyncTime.toIso8601String()}'),
    );

    if (response.statusCode != 200) {
      throw Exception('获取视频项目同步数据失败');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final videosToCreate = data['created'] as List? ?? [];
    final videosToUpdate = data['updated'] as List? ?? [];
    final videosToDelete = data['deleted'] as List<String>? ?? [];

    int count = 0;

    for (final videoJson in videosToCreate) {
      await _localDataSource.saveData('video_${videoJson['id']}', videoJson);
      count++;
    }

    for (final videoJson in videosToUpdate) {
      await _localDataSource.saveData('video_${videoJson['id']}', videoJson);
      count++;
    }

    for (final videoId in videosToDelete) {
      await _localDataSource.deleteData('video_$videoId');
      count++;
    }

    await _localDataSource.saveData('videos_last_sync', DateTime.now());

    return count;
  }

  /// 推送本地变更到服务器（离线操作重放）
  Future<void> pushLocalChanges() async {
    // 获取本地待同步的操作队列
    // 实际实现需要结合 OfflineQueueManager
    print('[SyncRepository] Pushing local changes to server...');
  }
}

/// 同步结果
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
  });
}
