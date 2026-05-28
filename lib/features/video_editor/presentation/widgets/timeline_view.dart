import 'package:flutter/material.dart';
import '../../data/models/timeline_data_model.dart';
import 'timeline_canvas.dart';

class TimelineView extends StatefulWidget {
  final TimelineData timelineData;
  final Function(int segmentId)? onSegmentSelected;
  final Function(double position)? onSeek;
  final Function(int segmentId, double newStartTime)? onClipMoved;

  const TimelineView({
    super.key,
    required this.timelineData,
    this.onSegmentSelected,
    this.onSeek,
    this.onClipMoved,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  double _zoomLevel = 50.0;
  
  void _handleZoom(double delta) {
    setState(() {
      _zoomLevel = (_zoomLevel + delta).clamp(20.0, 200.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      child: Column(
        children: [
          // 缩放控制条
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => _handleZoom(-10),
                  tooltip: '缩小',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Text(
                  '${(_zoomLevel / 50 * 100).round()}%',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => _handleZoom(10),
                  tooltip: '放大',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          // 时间线画布
          Expanded(
            child: TimelineCanvas(
              timelineData: widget.timelineData,
              onSegmentSelected: widget.onSegmentSelected ?? (_) {},
              onSeek: widget.onSeek ?? (_) {},
              onClipMoved: widget.onClipMoved,
              zoomLevel: _zoomLevel,
            ),
          ),
        ],
      ),
    );
  }
}
