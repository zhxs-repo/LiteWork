import 'package:flutter/material.dart';

class EditorToolbar extends StatelessWidget {
  final bool hasSelection;
  final VoidCallback? onSplit;
  final VoidCallback? onDelete;

  const EditorToolbar({
    super.key,
    this.hasSelection = false,
    this.onSplit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 60,
      color: cs.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolbarButton(
            icon: Icons.cut,
            label: '分割',
            enabled: hasSelection,
            onTap: onSplit,
          ),
          _ToolbarButton(
            icon: Icons.delete,
            label: '删除',
            enabled: hasSelection,
            onTap: onDelete,
          ),
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
  final bool enabled;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.enabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = enabled && onTap != null;
    final opacity = isActive ? 1.0 : 0.38;
    return Tooltip(
      message: isActive ? label : '即将上线',
      preferBelow: false,
      child: Opacity(
        opacity: opacity,
        child: InkWell(
          onTap: isActive ? onTap : null,
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
        ),
      ),
    );
  }
}
