import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';

/// 特效面板 - 滤镜、转场、字幕样式调节
class EffectPanel extends StatelessWidget {
  final String type; // filter, transition, subtitle
  const EffectPanel({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final isFilter = type == 'filter';
    final isTransition = type == 'transition';
    
    List<Map<String, dynamic>> effects = [];
    if (isFilter) {
      effects = [
        {'name': '原色', 'value': 0},
        {'name': '黑白', 'value': 1},
        {'name': '复古', 'value': 2},
        {'name': '鲜艳', 'value': 3},
        {'name': '冷色', 'value': 4},
        {'name': '暖色', 'value': 5},
      ];
    } else if (isTransition) {
      effects = [
        {'name': '无', 'value': 0},
        {'name': '淡入淡出', 'value': 1},
        {'name': '滑动', 'value': 2},
        {'name': '缩放', 'value': 3},
        {'name': '旋转', 'value': 4},
      ];
    }

    return Container(
      height: 200,
      color: Colors.grey[900],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              isFilter ? '滤镜' : '转场',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: effects.length,
              itemBuilder: (context, index) {
                final effect = effects[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () => provider.applyEffect(type, effect['value']),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Center(
                            child: Text(
                              effect['name'] as String,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          effect['name'] as String,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
