import 'package:flutter/material.dart';

class TimelineView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          // 时间标尺
          Container(
            height: 30,
            color: Colors.grey[800],
            child: Row(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _RulerPainter(),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
          // 轨道区域
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                return _TrackRow(
                  trackIndex: index,
                  trackName: ['主视频', '画中画', '音频', '字幕'][index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final int trackIndex;
  final String trackName;

  const _TrackRow({
    Key? key,
    required this.trackIndex,
    required this.trackName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(vertical: 2),
      color: Colors.grey[850],
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            width: 80,
            child: Center(
              child: Text(
                trackName,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
          Positioned(
            left: 100,
            top: 10,
            child: Container(
              width: 150,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '片段 ${trackIndex + 1}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textStyle: TextStyle(color: Colors.white54, fontSize: 10),
    );

    for (int i = 0; i < 20; i++) {
      final x = i * 50.0;
      canvas.drawLine(Offset(x, 0), Offset(x, 15), paint);
      
      if (i % 5 == 0) {
        textPainter.text = TextSpan(text: '${i}s');
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 2, 18));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
