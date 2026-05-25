import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';

/// 快速创建项目页面
/// 替代之前的假模板，提供自定义项目创建入口
class QuickCreateScreen extends StatefulWidget {
  const QuickCreateScreen({super.key});

  @override
  State<QuickCreateScreen> createState() => _QuickCreateScreenState();
}

class _QuickCreateScreenState extends State<QuickCreateScreen> {
  final _titleController = TextEditingController(text: '新项目');
  String _aspectRatio = '9:16';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<VideoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('快速创建')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '项目名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('画面比例', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...['9:16 (竖屏)', '16:9 (横屏)', '1:1 (方形)'].map((label) {
            final value = label.split(' ')[0];
            return RadioListTile<String>(
              title: Text(label),
              value: value,
              groupValue: _aspectRatio,
              onChanged: (val) => setState(() => _aspectRatio = val!),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('创建项目'),
              onPressed: () {
                final title = _titleController.text.trim().isEmpty
                    ? '新项目'
                    : _titleController.text.trim();
                provider.createProject(title);
                provider.setAspectRatio(_aspectRatio);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
