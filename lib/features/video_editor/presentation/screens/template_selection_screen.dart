import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';

/// 模板选择页面 - 提供一键成片模板库
class TemplateSelectionScreen extends StatelessWidget {
  const TemplateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final templates = [
      {'name': '生活记录', 'icon': Icons.home, 'color': Colors.orange},
      {'name': '美食探店', 'icon': Icons.restaurant, 'color': Colors.red},
      {'name': '知识分享', 'icon': Icons.school, 'color': Colors.blue},
      {'name': '旅行Vlog', 'icon': Icons.flight_takeoff, 'color': Colors.teal},
      {'name': '时尚穿搭', 'icon': Icons.checkroom, 'color': Colors.purple},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('选择模板')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => provider.applyTemplate(template['name'] as String),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    template['icon'] as IconData,
                    size: 48,
                    color: template['color'] as Color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    template['name'] as String,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('点击应用', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
