import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PreviewPlayer extends StatefulWidget {
  final String? videoPath;
  final Duration? currentPosition;
  final Function(Duration)? onPositionChanged;

  const PreviewPlayer({
    super.key,
    this.videoPath,
    this.currentPosition,
    this.onPositionChanged,
  });

  @override
  State<PreviewPlayer> createState() => _PreviewPlayerState();
}

class _PreviewPlayerState extends State<PreviewPlayer> {
  Player? _player;
  VideoController? _controller;
  StreamSubscription<Duration>? _positionSubscription;
  Duration _lastReported = Duration.zero;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoPath != null) {
      _open(widget.videoPath!);
    }
  }

  @override
  void didUpdateWidget(PreviewPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoPath != oldWidget.videoPath) {
      if (widget.videoPath == null) {
        _releasePlayer();
      } else {
        _open(widget.videoPath!);
      }
    }
    // 处理播放头跳转
    if (widget.currentPosition != null &&
        widget.currentPosition != oldWidget.currentPosition &&
        _isReady) {
      _player?.seek(widget.currentPosition!);
    }
  }

  Future<void> _open(String path) async {
    await _releasePlayer();
    final player = Player();
    final controller = VideoController(player);
    _player = player;
    _controller = controller;

    _positionSubscription = player.stream.position.listen((position) {
      // 防抖处理，避免频繁更新
      if ((position - _lastReported).inMilliseconds.abs() > 50) {
        _lastReported = position;
        widget.onPositionChanged?.call(position);
      }
    });
    await player.setPlaylistMode(PlaylistMode.loop);

    try {
      await player.open(Media(path));
      if (!mounted) return;
      setState(() => _isReady = true);
    } catch (e) {
      debugPrint('初始化视频播放器失败：$e');
      if (!mounted) return;
      setState(() => _isReady = false);
    }
  }

  Future<void> _releasePlayer() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _player?.dispose();
    _player = null;
    _controller = null;
    _lastReported = Duration.zero;
    if (mounted) setState(() => _isReady = false);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controller = _controller;
    return Container(
      color: Colors.black,
      child: GestureDetector(
        onTap: () => _player?.playOrPause(),
        child: _isReady && controller != null
            ? Video(controller: controller)
            : _buildPlaceholder(cs),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 64, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('预览播放器', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            '点击播放/暂停',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
