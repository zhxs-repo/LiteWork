import 'package:flutter/material.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 60,
      color: cs.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolbarButton(icon: Icons.cut, label: '分割'),
          _ToolbarButton(icon: Icons.delete, label: '删除'),
          _ToolbarButton(icon: Icons.speed, label: '变速'),
          _ToolbarButton(icon: Icons.flip, label: '倒放'),
          _ToolbarButton(icon: Icons.filter, label: '滤镜'),
          _ToolbarButton(icon: Icons.text_fields, label: '字幕'),
          _ToolbarButton(icon: Icons.music_note, label: '音频'),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ToolbarButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label 功能开发中...')),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: cs.onSurface, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: cs.onSurface, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
