import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/education_item.dart';

class EducationVideoPlayerScreen extends StatefulWidget {
  final EducationItem item;

  const EducationVideoPlayerScreen({super.key, required this.item});

  @override
  State<EducationVideoPlayerScreen> createState() =>
      _EducationVideoPlayerScreenState();
}

class _EducationVideoPlayerScreenState
    extends State<EducationVideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _ready = false;
  bool _finished = false;
  bool _justReplayed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.item.videoAsset)
      ..addListener(_checkFinished)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _ready = true);
          _controller.play();
        }
      });
  }

  void _checkFinished() {
    if (_justReplayed) return;

    final value = _controller.value;
    if (!value.isInitialized) return;

    final atEnd = value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 150);

    if (atEnd && !value.isPlaying && !_finished) {
      setState(() => _finished = true);
    }
  }

  Future<void> _replay() async {
    setState(() {
      _finished = false;
      _justReplayed = true;
    });

    await _controller.seekTo(Duration.zero);
    await _controller.play();

    // Video eka hariyata start unama witharak, aye finished-check eka allow karanna.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _justReplayed = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_checkFinished);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('වීඩියෝව')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.item.sinhalaLabel,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF29C8F2), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _ready
                    ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      if (_finished)
                        Container(
                          color: Colors.black45,
                          child: IconButton(
                            onPressed: _replay,
                            icon: const Icon(
                              Icons.replay,
                              color: Colors.white,
                              size: 56,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    : const SizedBox(
                  width: 250,
                  height: 250,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}