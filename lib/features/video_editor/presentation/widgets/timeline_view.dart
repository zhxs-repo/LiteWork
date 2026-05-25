import 'package:flutter/material.dart';
import '../../data/models/timeline_data_model.dart';
import 'timeline_canvas.dart';

class TimelineView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      child: TimelineCanvas(
        timelineData: timelineData,
        onSegmentSelected: onSegmentSelected ?? (_) {},
        onSeek: onSeek ?? (_) {},
        onClipMoved: onClipMoved,
        zoomLevel: 50.0,
      ),
    );
  }
}
