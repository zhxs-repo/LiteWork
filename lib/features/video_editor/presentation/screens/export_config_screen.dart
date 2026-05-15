import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';

/// 导出配置页面 - 设置分辨率、帧率、比例等
class ExportConfigScreen extends StatelessWidget {
  const ExportConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('导出视频'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () => provider.startExport(),
            tooltip: '开始导出',
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
