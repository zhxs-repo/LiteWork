import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';

class PreviewPlayer extends StatefulWidget {
  final String? videoPath;
  final Duration? currentPosition;
  final Function(Duration)? onPositionChanged;

  const PreviewPlayer({
    Key? key,
    this.videoPath,
    this.currentPosition,
    this.onPositionChanged,
  }) : super(key: key);

  @override
  State<PreviewPlayer> createState() => _PreviewPlayerState();
}

class _PreviewPlayerState extends State<PreviewPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoPath != null) {
      _initializePlayer(widget.videoPath!);
    }
  }

  @override
  void didUpdateWidget(PreviewPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 视频路径变化时重新初始化
    if (widget.videoPath != null && widget.videoPath != oldWidget.videoPath) {
      _disposeControllers();
      _initializePlayer(widget.videoPath!);
    }
    // 同步播放位置
    if (widget.currentPosition != null && _isInitialized) {
      _seekTo(widget.currentPosition!);
    }
  }

  Future<void> _initializePlayer(String path) async {
    try {
      _videoController = VideoPlayerController.file(File(path));
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: true,
        showControls: true,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: false,
        allowMuting: true,
        placeholder: Container(color: Colors.black),
        deviceOrientationsAfterEnterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      );

      // 监听播放位置变化
      _videoController!.addListener(() {
        if (widget.onPositionChanged != null && _videoController!.value.isInitialized) {
          widget.onPositionChanged!(_videoController!.value.position);
        }
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('初始化视频播放器失败：$e');
      setState(() {
        _isInitialized = false;
      });
    }
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
    _isInitialized = false;
  }

  void _seekTo(Duration position) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.seekTo(position);
    }
  }

  void _togglePlay() {
    if (_chewieController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: GestureDetector(
        onTap: _togglePlay,
        child: _isInitialized && _chewieController != null
            ? Chewie(controller: _chewieController!)
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 64, color: Colors.white70),
          SizedBox(height: 16),
          Text(
            widget.videoPath == null ? '请选择视频素材' : '加载视频中...',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 8),
          Text(
            '点击播放/暂停',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
