import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/storage/storage_manager.dart';

/// 存储管理页面 - 查看存储空间和清理缓存
class StorageManagementPage extends StatefulWidget {
  const StorageManagementPage({super.key});

  @override
  State<StorageManagementPage> createState() => _StorageManagementPageState();
}

class _StorageManagementPageState extends State<StorageManagementPage> {
  int _totalCacheSize = 0;
  int _appDataSize = 0;
  bool _isCalculating = true;
  bool _isCleaning = false;

  @override
  void initState() {
    super.initState();
    _calculateStorage();
  }

  Future<void> _calculateStorage() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appDir = await getApplicationDocumentsDirectory();
      
      int cacheSize = await _getDirectorySize(cacheDir);
      int appSize = await _getDirectorySize(appDir);

      setState(() {
        _totalCacheSize = cacheSize;
        _appDataSize = appSize;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  Future<int> _getDirectorySize(Directory directory) async {
    try {
      int totalSize = 0;
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理缓存'),
        content: const Text('确定要清理应用缓存吗？这不会影响您的笔记、草稿和项目数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performClearCache();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清理'),
          ),
        ],
      ),
    );
  }

  Future<void> _performClearCache() async {
    setState(() {
      _isCleaning = true;
    });

    try {
      final cacheDir = await getTemporaryDirectory();
      
      // 删除缓存目录下的所有文件
      await for (final entity in cacheDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          await entity.delete();
        } else if (entity is Directory) {
          await entity.delete(recursive: true);
        }
      }

      // 重新计算大小
      await _calculateStorage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('缓存已清理'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清理失败：$e')),
        );
      }
    } finally {
      setState(() {
        _isCleaning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('存储管理'),
        centerTitle: true,
      ),
      body: _isCalculating
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 16),

                // 存储空间概览卡片
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.storage,
                            size: 56,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '存储空间使用情况',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStorageInfo(
                                icon: Icons.folder,
                                label: '应用数据',
                                size: _formatBytes(_appDataSize),
                                color: theme.colorScheme.primary,
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: theme.dividerColor,
                              ),
                              _buildStorageInfo(
                                icon: Icons.cloud_queue,
                                label: '缓存',
                                size: _formatBytes(_totalCacheSize),
                                color: theme.colorScheme.secondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 缓存清理部分
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '缓存管理',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.cleaning_services,
                                color: theme.colorScheme.secondary,
                              ),
                              title: const Text('清理缓存'),
                              subtitle: const Text('清理临时文件和图片缓存'),
                              trailing: _isCleaning
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      _formatBytes(_totalCacheSize),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              onTap: _isCleaning ? null : _clearCache,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              title: const Text('缓存说明'),
                              subtitle: Text(
                                '缓存包含图片、视频预览等临时文件，清理后会自动重新生成，不会影响重要数据',
                                style: theme.textTheme.bodySmall,
                              ),
                              onTap: () => _showCacheInfoDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 数据存储部分
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '数据存储',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Column(
                          children: [
                            _buildDataInfoTile(
                              icon: Icons.article,
                              title: '图文草稿',
                              subtitle: '保存在本地数据库中',
                              storageManager: StorageManager(),
                              keyName: 'posts_list',
                            ),
                            const Divider(height: 1),
                            _buildDataInfoTile(
                              icon: Icons.note,
                              title: '笔记',
                              subtitle: '保存在本地数据库中',
                              storageManager: StorageManager(),
                              keyName: 'notes_list',
                            ),
                            const Divider(height: 1),
                            _buildDataInfoTile(
                              icon: Icons.video_file,
                              title: '视频项目',
                              subtitle: '保存在本地数据库中',
                              storageManager: StorageManager(),
                              keyName: 'video_projects_list',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 提示信息
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '提示：定期清理缓存可以释放存储空间，提高应用运行速度',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildStorageInfo({
    required IconData icon,
    required String label,
    required String size,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          size,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDataInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required StorageManager storageManager,
    required String keyName,
  }) {
    // 获取数据数量
    final dataList = storageManager.get<List>(keyName);
    final count = dataList is List ? dataList.length : 0;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        '$count 项',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showCacheInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('缓存说明'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('缓存包括以下内容：'),
            SizedBox(height: 8),
            Text('• 图片和视频预览图'),
            Text('• 网络资源临时文件'),
            Text('• 编辑器临时保存的数据'),
            SizedBox(height: 16),
            Text('清理缓存不会影响：'),
            SizedBox(height: 8),
            Text('• 您的笔记内容'),
            Text('• 图文草稿'),
            Text('• 视频项目配置'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
