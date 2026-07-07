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
  VideoPlayerController? _videoController;

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
    final old = _videoController;
    _videoController = null;
    old?.removeListener(_handleVideoTick);
    await old?.dispose();
  }

  Future<void> _loadVideo(int index) async {
    final videos = _result?.videos ?? const <SignVideo>[];
    if (index < 0 || index >= videos.length) return;

    final token = ++_loadToken;
    final old = _videoController;
    old?.removeListener(_handleVideoTick);
    _videoController = null;

    setState(() {
      _currentIndex = index;
      _videoLoading = true;
      _sequenceFinished = false;
    });

    await old?.dispose();

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(videos[index].url),
    );
    controller.addListener(_handleVideoTick);

    try {
      await controller.initialize();
      if (!mounted || token != _loadToken) {
        controller.removeListener(_handleVideoTick);
        await controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _videoLoading = false;
      });
      await controller.play();
    } catch (e) {
      controller.removeListener(_handleVideoTick);
      await controller.dispose();
      if (!mounted || token != _loadToken) return;
      setState(() {
        _videoLoading = false;
        _error = 'Video error: $e';
      });
    }
  }

  void _handleVideoTick() {
    final controller = _videoController;
    final videos = _result?.videos ?? const <SignVideo>[];
    if (_autoAdvancing ||
        controller == null ||
        !controller.value.isInitialized ||
        videos.isEmpty) {
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
        await _loadVideo(_currentIndex + 1);
      } else {
        setState(() => _sequenceFinished = true);
      }
      _autoAdvancing = false;
    });
  }

  Future<void> _togglePlay() async {
    final controller = _videoController;
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
    final controller = _videoController;
    final videos = _result?.videos ?? const <SignVideo>[];
    final hasVideo = controller != null && controller.value.isInitialized;
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
            aspectRatio: hasVideo ? controller.value.aspectRatio : 16 / 9,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasVideo)
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
                  onPressed: hasVideo ? _togglePlay : null,
                  tooltip:
                      hasVideo && controller.value.isPlaying ? 'Pause' : 'Play',
                  icon: Icon(hasVideo && controller.value.isPlaying
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
