import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_config.dart';
import '../services/frame_streamer.dart';
import '../services/sign_socket.dart';
import 'settings_screen.dart';
import 'sinhala_to_sign_view.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FrameStreamer _streamer = FrameStreamer();
  final SignSocket _socket = SignSocket();

  StreamSubscription? _msgSub;
  StreamSubscription? _stateSub;

  String _host = AppConfig.defaultHost;
  bool _cameraReady = false;
  bool _permissionDenied = false;
  bool _streaming = false;
  late int _selectedTab = widget.initialTab;

  SocketState _socketState = SocketState.disconnected;

  // Live recognition state (from the server).
  String? _currentWord;
  double _confidence = 0.0;
  String _state = 'idle';
  int _buffer = 0;
  int _seqLength = 30;

  final List<String> _sentence = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }

    _host = await AppConfig.getHost();

    try {
      await _streamer.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);
    } catch (e) {
      _snack('Camera error: $e');
      return;
    }

    _listenSocket();
    await _connectAndStart();
  }

  void _listenSocket() {
    _stateSub?.cancel();
    _stateSub = _socket.state.listen((s) {
      if (mounted) setState(() => _socketState = s);
    });

    _msgSub?.cancel();
    _msgSub = _socket.messages.listen((msg) {
      if (!mounted) return;
      final type = msg['type'];
      if (type == 'update') {
        setState(() {
          _currentWord = msg['current'] as String?;
          _confidence = (msg['confidence'] as num?)?.toDouble() ?? 0.0;
          _state = (msg['state'] as String?) ?? 'idle';
          _buffer = (msg['buffer'] as num?)?.toInt() ?? 0;
          _seqLength = (msg['seq_length'] as num?)?.toInt() ?? 30;

          final committed = msg['committed'];
          if (committed is Map && committed['sinhala'] is String) {
            _sentence.add(committed['sinhala'] as String);
          }
        });
      }
    });
  }

  Future<void> _connectAndStart() async {
    _host = AppConfig.normalizeHost(_host);
    if (!AppConfig.isConfigured(_host)) {
      await _socket.disconnect();
      return;
    }

    await _socket.connect(AppConfig.wsUri(_host));
    if (_socket.current == SocketState.connected) {
      _startStreaming();
    }
  }

  void _startStreaming() {
    if (_streaming) return;
    _streamer.start((jpeg) => _socket.sendFrame(jpeg));
    setState(() => _streaming = true);
  }

  Future<void> _stopStreaming() async {
    if (!_streaming) return;
    await _streamer.stop();
    setState(() => _streaming = false);
  }

  Future<void> _toggleStreaming() async {
    if (_streaming) {
      await _stopStreaming();
    } else {
      if (_socketState != SocketState.connected) {
        await _connectAndStart();
      } else {
        _startStreaming();
      }
    }
  }

  void _clearSentence() {
    _socket.reset();
    setState(() {
      _sentence.clear();
      _currentWord = null;
      _confidence = 0.0;
    });
  }

  void _backspace() {
    if (_sentence.isNotEmpty) setState(() => _sentence.removeLast());
  }

  Future<void> _openSettings() async {
    await _stopStreaming();
    if (!mounted) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    _host = await AppConfig.getHost();
    if (changed == true) {
      await _socket.disconnect();
    }
    if (_selectedTab == 0) {
      await _connectAndStart();
    }
  }

  Future<void> _selectTab(int index) async {
    if (index == _selectedTab) return;

    if (index == 1) {
      await _stopStreaming();
    }

    if (!mounted) return;
    setState(() => _selectedTab = index);

    if (index == 0 && _cameraReady) {
      if (_socketState == SocketState.connected) {
        _startStreaming();
      } else {
        await _connectAndStart();
      }
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopStreaming();
    } else if (state == AppLifecycleState.resumed) {
      if (_selectedTab == 0 &&
          _cameraReady &&
          _socketState == SocketState.connected) {
        _startStreaming();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _msgSub?.cancel();
    _stateSub?.cancel();
    _streamer.dispose();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      appBar: AppBar(
        title: Text(_selectedTab == 0 ? 'Sign → සිංහල' : 'සිංහල → Sign'),
        backgroundColor: const Color(0xFF161B22),
        actions: [
          IconButton(
            tooltip: 'Server settings',
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body:
          _selectedTab == 0 ? _signToSinhalaBody() : const SinhalaToSignView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => _selectTab(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sign_language_outlined),
            selectedIcon: Icon(Icons.sign_language),
            label: 'Sign',
          ),
          NavigationDestination(
            icon: Icon(Icons.subtitles_outlined),
            selectedIcon: Icon(Icons.subtitles),
            label: 'Sinhala',
          ),
        ],
      ),
    );
  }

  Widget _signToSinhalaBody() {
    return _permissionDenied
        ? _permissionView()
        : !_cameraReady
            ? const Center(child: CircularProgressIndicator())
            : _mainView();
  }

  Widget _permissionView() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off, size: 48, color: Colors.white54),
              SizedBox(height: 12),
              Text('Camera permission is required.',
                  style: TextStyle(color: Colors.white70)),
              SizedBox(height: 16),
              FilledButton(
                onPressed: openAppSettings,
                child: Text('Open app settings'),
              ),
            ],
          ),
        ),
      );

  Widget _mainView() {
    return Column(
      children: [
        Expanded(flex: 3, child: _cameraArea()),
        _sentencePanel(),
      ],
    );
  }

  Widget _cameraArea() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed camera preview.
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _streamer.controller!.value.previewSize?.height ?? 480,
            height: _streamer.controller!.value.previewSize?.width ?? 640,
            child: CameraPreview(_streamer.controller!),
          ),
        ),

        // Top status row.
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              _statusChip(),
              const Spacer(),
              _bufferChip(),
            ],
          ),
        ),

        // Current recognized word (center-bottom of preview).
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _currentWordCard(),
        ),
      ],
    );
  }

  Widget _statusChip() {
    late Color c;
    late String t;
    if (!AppConfig.isConfigured(_host)) {
      c = Colors.amber;
      t = 'Set server';
    } else {
      switch (_socketState) {
        case SocketState.connected:
          c = Colors.green;
          t = 'Connected';
          break;
        case SocketState.connecting:
          c = Colors.orange;
          t = 'Connecting…';
          break;
        case SocketState.error:
          c = Colors.red;
          t = 'Server unreachable';
          break;
        case SocketState.disconnected:
          c = Colors.grey;
          t = 'Disconnected';
          break;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(t, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }

  Widget _bufferChip() {
    final ratio =
        _seqLength == 0 ? 0.0 : (_buffer / _seqLength).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: Colors.white24,
            color: ratio >= 1.0 ? Colors.greenAccent : Colors.lightBlueAccent,
          ),
        ),
        const SizedBox(width: 8),
        Text('$_buffer/$_seqLength',
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }

  Widget _currentWordCard() {
    final hasWord = _currentWord != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasWord
                ? _currentWord!
                : (_state == 'analyzing' ? 'විශ්ලේෂණය…' : 'ලකුණක් පෙන්වන්න'),
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansSinhala(
              fontSize: hasWord ? 40 : 24,
              fontWeight: FontWeight.w700,
              color: hasWord ? const Color(0xFF3DFF88) : Colors.white70,
            ),
          ),
          if (hasWord) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _confidence.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white24,
                color: _confidence >= 0.65
                    ? Colors.greenAccent
                    : (_confidence >= 0.45 ? Colors.amber : Colors.redAccent),
              ),
            ),
            const SizedBox(height: 4),
            Text('${(_confidence * 100).round()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _sentencePanel() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('වාක්‍යය',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const Spacer(),
              Text('${_sentence.length} words',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
            child: SingleChildScrollView(
              child: _sentence.isEmpty
                  ? Text('පිළිගත් වචන මෙහි දිස්වේ…',
                      style: GoogleFonts.notoSansSinhala(
                          color: Colors.white38, fontSize: 16))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sentence
                          .map((w) => Chip(
                                backgroundColor: const Color(0xFF243447),
                                label: Text(w,
                                    style: GoogleFonts.notoSansSinhala(
                                        color: Colors.white, fontSize: 18)),
                              ))
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _streaming ? Colors.redAccent : Colors.green,
                  ),
                  onPressed: _toggleStreaming,
                  icon: Icon(_streaming ? Icons.pause : Icons.play_arrow),
                  label: Text(_streaming ? 'Pause' : 'Start'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: _backspace,
                icon: const Icon(Icons.backspace_outlined),
                tooltip: 'Delete last word',
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: _clearSentence,
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear all',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
