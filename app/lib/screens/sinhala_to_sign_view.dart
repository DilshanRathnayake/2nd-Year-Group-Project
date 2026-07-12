import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../app_config.dart';
import '../services/translate_service.dart';

class SinhalaToSignView extends StatefulWidget {
  const SinhalaToSignView({super.key});

  @override
  State<SinhalaToSignView> createState() => _SinhalaToSignViewState();
}

class _SinhalaToSignViewState extends State<SinhalaToSignView> {
  final _controller = TextEditingController();
  final _service = TranslateService();

  TranslateResult? _result;
  List<VideoPlayerController> _preloadControllers = [];

  bool _loading = false;
  bool _videoLoading = false;
  bool _sequenceFinished = false;
  bool _autoAdvancing = false;
  String? _error;
  int _currentIndex = 0;
  int _loadToken = 0;

  @override
  void dispose() {
    _controller.dispose();
    _disposeVideo();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    FocusScope.of(context).unfocus();
    await _disposeVideo();

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _currentIndex = 0;
      _sequenceFinished = false;
    });

    try {
      final host = await AppConfig.getHost();
      final result = await _service.translate(host, text);
      if (!mounted) return;
      setState(() => _result = result);
      if (result.videos.isNotEmpty) {
        await _loadVideo(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disposeVideo() async {
    _loadToken++;
    for (var c in _preloadControllers) {
      c.removeListener(_handleVideoTick);
      await c.dispose();
    }
    _preloadControllers.clear();
  }

  Future<void> _loadVideo(int index) async {
    final videos = _result?.videos ?? const <SignVideo>[];
    if (index < 0 || index >= videos.length) return;

    final token = ++_loadToken;

    if (index == 0) {
      setState(() {
        _currentIndex = 0;
        _videoLoading = true;
        _sequenceFinished = false;
      });

      List<VideoPlayerController> tempControllers = [];
      try {
        for (int i = 0; i < videos.length; i++) {
          final c = VideoPlayerController.networkUrl(Uri.parse(videos[i].url));
          tempControllers.add(c);
        }

        await tempControllers[0].initialize();

        if (!mounted || token != _loadToken) {
          for (var c in tempControllers) await c.dispose();
          return;
        }

        _preloadControllers = tempControllers;
        _preloadControllers[0].addListener(_handleVideoTick);

        setState(() => _videoLoading = false);
        await _preloadControllers[0].play();

        _preloadRemainingVideos(token);

      } catch (e) {
        if (!mounted || token != _loadToken) return;
        setState(() {
          _videoLoading = false;
          _error = 'Video error: $e';
        });
      }
    } else {
      if (_currentIndex < _preloadControllers.length) {
        _preloadControllers[_currentIndex].removeListener(_handleVideoTick);
        await _preloadControllers[_currentIndex].pause();
      }

      setState(() {
        _currentIndex = index;
        _sequenceFinished = false;
      });

      if (index < _preloadControllers.length) {
        final controller = _preloadControllers[index];
        controller.addListener(_handleVideoTick);
        await controller.seekTo(Duration.zero);
        await controller.play();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _preloadRemainingVideos(int currentToken) async {
    for (int i = 1; i < _preloadControllers.length; i++) {
      if (!mounted || currentToken != _loadToken) return;
      try {
        if (!_preloadControllers[i].value.isInitialized) {
          await _preloadControllers[i].initialize();
          if (mounted && currentToken == _loadToken && i == _currentIndex) {
            setState(() {});
          }
        }
      } catch (e) {
        print("Preload warning: $e");
      }
    }
  }

  void _handleVideoTick() {
    if (_preloadControllers.isEmpty || _currentIndex >= _preloadControllers.length) return;

    final controller = _preloadControllers[_currentIndex];
    final videos = _result?.videos ?? const <SignVideo>[];
    if (_autoAdvancing || !controller.value.isInitialized || videos.isEmpty) {
      return;
    }

    final value = controller.value;
    final atEnd = value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 180);

    if (!atEnd || value.isPlaying) return;

    _autoAdvancing = true;
    Future<void>.delayed(Duration.zero, () async {
      if (!mounted) return;
      if (_currentIndex + 1 < videos.length) {
        controller.removeListener(_handleVideoTick);
        setState(() {
          _currentIndex++;
        });

        if (_preloadControllers[_currentIndex].value.isInitialized) {
          _preloadControllers[_currentIndex].addListener(_handleVideoTick);
          await _preloadControllers[_currentIndex].seekTo(Duration.zero);
          await _preloadControllers[_currentIndex].play();
          if (mounted) setState(() {});
        } else {
          await _loadVideo(_currentIndex);
        }
      } else {
        setState(() => _sequenceFinished = true);
      }
      _autoAdvancing = false;
    });
  }

  Future<void> _togglePlay() async {
    if (_preloadControllers.isEmpty || _currentIndex >= _preloadControllers.length) return;
    final controller = _preloadControllers[_currentIndex];
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _replay() async {
    final videos = _result?.videos ?? const <SignVideo>[];
    if (videos.isEmpty) return;
    await _loadVideo(0);
  }

  void _clear() {
    _controller.clear();
    _disposeVideo();
    setState(() {
      _result = null;
      _error = null;
      _currentIndex = 0;
      _sequenceFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        _inputPanel(),
        const SizedBox(height: 14),
        _videoPanel(),
        const SizedBox(height: 14),
        _sequencePanel(),
      ],
    );
  }

  Widget _inputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          style: GoogleFonts.notoSansSinhala(fontSize: 18),
          decoration: InputDecoration(
            labelText: 'සිංහල වාක්‍යය',
            hintText: 'මම කනවා',
            prefixIcon: const Icon(Icons.edit_note),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onSubmitted: (_) => _translate(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _loading ? null : _translate,
                icon: _loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.translate),
                label: const Text('Translate'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _clear,
              tooltip: 'Clear',
              icon: const Icon(Icons.clear),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _videoPanel() {
    final hasVideo = _preloadControllers.isNotEmpty &&
        _currentIndex < _preloadControllers.length &&
        _preloadControllers[_currentIndex].value.isInitialized;
    final controller = hasVideo ? _preloadControllers[_currentIndex] : null;
    final videos = _result?.videos ?? const <SignVideo>[];
    final current = videos.isEmpty ? null : videos[_currentIndex];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: controller != null ? controller.value.aspectRatio : 16 / 9,
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(8)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (controller != null)
                    FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF0E1116),
                      alignment: Alignment.center,
                      child: _videoLoading
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.sign_language,
                          color: Colors.white30, size: 54),
                    ),
                  if (_sequenceFinished)
                    Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: IconButton.filled(
                        onPressed: _replay,
                        tooltip: 'Replay',
                        icon: const Icon(Icons.replay),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: controller != null ? _togglePlay : null,
                  tooltip:
                  controller != null && controller.value.isPlaying ? 'Pause' : 'Play',
                  icon: Icon(controller != null && controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    current?.asset ?? 'No video selected',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                if (videos.isNotEmpty)
                  Text(
                    '${_currentIndex + 1}/${videos.length}',
                    style: const TextStyle(color: Colors.white54),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sequencePanel() {
    final result = _result;
    if (result == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Video sequence',
                  style: TextStyle(color: Colors.white70)),
              const Spacer(),
              if (result.truncated)
                const Icon(Icons.content_cut, size: 18, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 10),
          if (result.videos.isEmpty)
            const Text('No playable videos returned.',
                style: TextStyle(color: Colors.white54))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < result.videos.length; i++)
                  ChoiceChip(
                    label: Text(result.videos[i].asset),
                    selected: i == _currentIndex,
                    onSelected: (_) => _loadVideo(i),
                  ),
              ],
            ),
          if (result.unknownWords.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoLine(
              Icons.help_outline,
              'Unknown words: ${result.unknownWords.join(', ')}',
              Colors.amber,
            ),
          ],
          if (result.missing.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoLine(
              Icons.videocam_off_outlined,
              'Missing videos: ${result.missing.join(', ')}',
              Colors.orangeAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: color, fontSize: 13)),
        ),
      ],
    );
  }
}