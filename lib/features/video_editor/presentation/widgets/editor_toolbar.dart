import 'package:flutter/material.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.grey[850],
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

  const _ToolbarButton({
    Key? key,
    required this.icon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label 功能开发中...')),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
