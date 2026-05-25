import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';

/// 导出配置页面 - 设置分辨率、帧率、比例等
/// 注意：实际视频渲染需要 FFmpeg，当前为模拟导出
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '视频渲染需 FFmpeg 支持。当前为模拟导出，配置将被保存供后续使用。',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSectionTitle('分辨率'),
          _buildRadioList(provider, 'resolution', [
            {'label': '720P (HD)', 'value': '720p'},
            {'label': '1080P (FHD)', 'value': '1080p'},
          ]),
          const Divider(),
          _buildSectionTitle('帧率'),
          _buildRadioList(provider, 'frameRate', [
            {'label': '30 fps', 'value': '30'},
            {'label': '60 fps', 'value': '60'},
          ]),
          const Divider(),
          _buildSectionTitle('画面比例'),
          _buildRadioList(provider, 'aspectRatio', [
            {'label': '9:16 (抖音/快手)', 'value': '9:16'},
            {'label': '16:9 (横屏)', 'value': '16:9'},
            {'label': '1:1 (朋友圈)', 'value': '1:1'},
          ]),
          const Divider(),
          _buildSectionTitle('预估信息'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('预计大小: ${provider.estimatedSize}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text('预计耗时: ${provider.estimatedTime}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('模拟导出 (预览进度)'),
              onPressed: () => provider.startExport(),
            ),
          ),
          if (provider.isExporting) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Center(child: Text('导出中... ${provider.exportProgress}%')),
          ],
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
