import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';

/// 导出配置页面 - 设置分辨率、帧率、比例等
/// 已集成 FFmpeg 真实渲染
class ExportConfigScreen extends StatelessWidget {
  const ExportConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('导出配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              provider.saveCurrentProject();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('导出配置已保存')),
              );
            },
            tooltip: '保存配置',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'FFmpeg 渲染引擎已集成，支持真实视频导出。',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSectionTitle('分辨率'),
          _buildRadioList(provider, 'resolution', [
            {'label': '4K (UHD)', 'value': '4K'},
            {'label': '1080P (FHD)', 'value': '1080p'},
            {'label': '720P (HD)', 'value': '720p'},
            {'label': '480P (SD)', 'value': '480p'},
          ]),
          const Divider(),
          _buildSectionTitle('帧率'),
          _buildRadioList(provider, 'frameRate', [
            {'label': '24 fps (电影感)', 'value': '24'},
            {'label': '30 fps (标准)', 'value': '30'},
            {'label': '60 fps (流畅)', 'value': '60'},
          ]),
          const Divider(),
          _buildSectionTitle('画面比例'),
          _buildRadioList(provider, 'aspectRatio', [
            {'label': '9:16 (抖音/快手/TikTok)', 'value': '9:16'},
            {'label': '16:9 (横屏/YouTube)', 'value': '16:9'},
            {'label': '1:1 (朋友圈/Instagram)', 'value': '1:1'},
            {'label': '4:5 (Instagram 肖像)', 'value': '4:5'},
          ]),
          const Divider(),
          _buildSectionTitle('预估信息'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('预计大小：${provider.estimatedSize}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text('预计耗时：${provider.estimatedTime}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.video_library, color: Colors.white),
              label: const Text('开始导出', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: provider.isLoading ? null : () => _startExport(context, provider),
            ),
          ),
          if (provider.isLoading || provider.renderProgress > 0) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(value: provider.renderProgress),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '渲染中... ${(provider.renderProgress * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
          if (provider.lastExportPath != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.blue),
                title: const Text('导出成功！', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('文件已保存至：\n${provider.lastExportPath}', style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('即将打开文件管理器...')),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _startExport(BuildContext context, VideoProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('确认导出'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('分辨率：${provider.resolution}'),
            Text('帧率：${provider.frameRate} fps'),
            Text('比例：${provider.aspectRatio}'),
            const SizedBox(height: 16),
            const Text('确定要开始渲染视频吗？', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.startRendering();
            },
            child: const Text('开始'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRadioList(VideoProvider provider, String type, List<Map<String, String>> options) {
    return Column(
      children: options.map((opt) {
        return RadioListTile<String>(
          title: Text(opt['label']!),
          value: opt['value']!,
          groupValue: type == 'resolution' ? provider.resolution
                   : type == 'frameRate' ? provider.frameRate
                   : provider.aspectRatio,
          onChanged: (val) {
            if (type == 'resolution') provider.setResolution(val!);
            else if (type == 'frameRate') provider.setFrameRate(val!);
            else provider.setAspectRatio(val!);
          },
        );
      }).toList(),
    );
  }
}
