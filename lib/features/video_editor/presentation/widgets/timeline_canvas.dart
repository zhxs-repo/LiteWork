import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:litework/features/video_editor/data/models/timeline_data_model.dart';

/// 真实时间线画布组件
/// 基于 CustomPainter 高性能渲染，支持多轨道、拖拽、缩放
class TimelineCanvas extends StatefulWidget {
  final TimelineData timelineData;
  final Function(int segmentId) onSegmentSelected;
  final Function(double position) onSeek;
  final Function(int segmentId, double newStartTime)? onClipMoved;
  final double zoomLevel; // 像素/秒

  const TimelineCanvas({
    Key? key,
    required this.timelineData,
    required this.onSegmentSelected,
    required this.onSeek,
    this.onClipMoved,
    this.zoomLevel = 50.0,
  }) : super(key: key);

  @override
  State<TimelineCanvas> createState() => _TimelineCanvasState();
}

class _TimelineCanvasState extends State<TimelineCanvas> {
  double _currentPosition = 0.0;
  int? _selectedSegmentId;
  int? _draggedSegmentId;
  double _dragStartX = 0;
  double _dragStartPosition = 0;

  Offset? _localToTime(double globalDx) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final local = renderBox.globalToLocal(Offset(globalDx, 0));
    return local;
  }

  int? _hitTestSegment(double clickTimeSeconds) {
    for (var track in widget.timelineData.tracks) {
      for (var segment in track.segments) {
        if (clickTimeSeconds >= segment.startTime &&
            clickTimeSeconds <= segment.startTime + segment.duration) {
          return segment.id;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final clickTime = localPosition.dx / widget.zoomLevel;

        final clickedId = _hitTestSegment(clickTime);
        if (clickedId != null) {
          setState(() => _selectedSegmentId = clickedId);
          widget.onSegmentSelected(clickedId);
        } else {
          setState(() {
            _selectedSegmentId = null;
            _currentPosition = math.max(0, clickTime);
          });
          widget.onSeek(_currentPosition);
        }
      },
      onLongPressStart: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final clickTime = localPosition.dx / widget.zoomLevel;

        final hitId = _hitTestSegment(clickTime);
        if (hitId != null) {
          setState(() {
            _draggedSegmentId = hitId;
            _selectedSegmentId = hitId;
            _dragStartX = details.globalPosition.dx;
          });
          widget.onSegmentSelected(hitId);
        }
      },
      onLongPressMoveUpdate: (details) {
        if (_draggedSegmentId == null) return;
        final deltaX = details.globalPosition.dx - _dragStartX;
        final deltaSeconds = deltaX / widget.zoomLevel;
        setState(() {
          _dragStartPosition = math.max(0, deltaSeconds);
        });
      },
      onLongPressEnd: (details) {
        if (_draggedSegmentId != null) {
          final moved = _dragStartPosition > 0.5;
          if (moved && widget.onClipMoved != null) {
            final currentStart = () {
              for (var track in widget.timelineData.tracks) {
                for (var segment in track.segments) {
                  if (segment.id == _draggedSegmentId) return segment.startTime;
                }
              }
              return 0.0;
            }();
            final newStart = math.max(0.0, currentStart + _dragStartPosition);
            widget.onClipMoved!(_draggedSegmentId!, newStart);
          }
        }
        setState(() {
          _draggedSegmentId = null;
          _dragStartPosition = 0;
        });
      },
      onHorizontalDragStart: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final clickTime = localPosition.dx / widget.zoomLevel;

        if (_hitTestSegment(clickTime) == null) {
          _dragStartX = details.globalPosition.dx;
          _dragStartPosition = _currentPosition;
        }
      },
      onHorizontalDragUpdate: (details) {
        final deltaX = details.globalPosition.dx - _dragStartX;
        final deltaSeconds = deltaX / widget.zoomLevel;
        setState(() {
          _currentPosition = math.max(0, _dragStartPosition - deltaSeconds);
        });
        widget.onSeek(_currentPosition);
      },
      child: Container(
        color: Colors.grey[900],
        child: CustomPaint(
          size: Size.infinite,
          painter: TimelinePainter(
            timelineData: widget.timelineData,
            currentPosition: _currentPosition,
            selectedSegmentId: _selectedSegmentId,
            draggedSegmentId: _draggedSegmentId,
            dragDelta: _dragStartPosition,
            zoomLevel: widget.zoomLevel,
          ),
        ),
      ),
    );
  }
}

class TimelinePainter extends CustomPainter {
  final TimelineData timelineData;
  final double currentPosition;
  final int? selectedSegmentId;
  final int? draggedSegmentId;
  final double dragDelta;
  final double zoomLevel;

  TimelinePainter({
    required this.timelineData,
    required this.currentPosition,
    required this.selectedSegmentId,
    this.draggedSegmentId,
    this.dragDelta = 0,
    required this.zoomLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()..color = Colors.white12..strokeWidth = 1;
    final paintPlayhead = Paint()..color = Colors.red..strokeWidth = 2;
    final paintText = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 1. 绘制时间刻度
    final totalSeconds = (size.width / zoomLevel).ceil();
    for (int i = 0; i <= totalSeconds; i++) {
      final x = i * zoomLevel;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
      
      paintText.text = TextSpan(
        text: _formatTime(i.toDouble()),
        style: const TextStyle(color: Colors.white54, fontSize: 10),
      );
      paintText.layout();
      paintText.paint(canvas, Offset(x - paintText.width / 2, 5));
    }

    // 2. 绘制轨道和片段
    final trackHeight = 60.0;
    final trackGap = 10.0;
    
    for (int i = 0; i < timelineData.tracks.length; i++) {
      final track = timelineData.tracks[i];
      final yOffset = i * (trackHeight + trackGap) + 40; // 留出刻度高度

      // 轨道背景
      canvas.drawRect(
        Rect.fromLTWH(0, yOffset, size.width, trackHeight),
        Paint()..color = Colors.grey[850]!,
      );

      // 绘制片段
      for (var segment in track.segments) {
        var x = segment.startTime * zoomLevel;
        final w = segment.duration * zoomLevel;
        final isSelected = segment.id == selectedSegmentId;
        final isDragged = segment.id == draggedSegmentId;

        if (isDragged) {
          x += dragDelta * zoomLevel;
        }

        // 片段背景
        canvas.drawRect(
          Rect.fromLTWH(x, yOffset + 2, w - 2, trackHeight - 4),
          Paint()..color = isDragged ? Colors.orange : (isSelected ? Colors.blue : _getTrackColor(track.type)),
        );

        // 选中边框
        if (isSelected && !isDragged) {
          canvas.drawRect(
            Rect.fromLTWH(x, yOffset + 2, w - 2, trackHeight - 4),
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }

        if (isDragged) {
          canvas.drawRect(
            Rect.fromLTWH(x, yOffset + 2, w - 2, trackHeight - 4),
            Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 2,
          );
        }

        // 片段文本 (文件名)
        paintText.text = TextSpan(
          text: segment.name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70, 
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          ),
        );
        paintText.layout(maxWidth: w - 10);
        paintText.paint(canvas, Offset(x + 5, yOffset + trackHeight / 2 - paintText.height / 2));
      }
    }

    // 3. 绘制播放头
    final playheadX = currentPosition * zoomLevel;
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      paintPlayhead,
    );
    
    // 播放头三角形
    final path = Path();
    path.moveTo(playheadX - 5, 0);
    path.lineTo(playheadX + 5, 0);
    path.lineTo(playheadX, 10);
    path.close();
    canvas.drawPath(path, paintPlayhead);
  }

  Color _getTrackColor(TrackType type) {
    switch (type) {
      case TrackType.video:
        return Colors.teal;
      case TrackType.audio:
        return Colors.orange;
      case TrackType.text:
        return Colors.purple;
    }
  }

  String _formatTime(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.currentPosition != currentPosition ||
           oldDelegate.selectedSegmentId != selectedSegmentId ||
           oldDelegate.draggedSegmentId != draggedSegmentId ||
           oldDelegate.dragDelta != dragDelta ||
           oldDelegate.timelineData != timelineData;
  }
}
