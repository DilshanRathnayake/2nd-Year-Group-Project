import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

enum SocketState { disconnected, connecting, connected, error }

/// Thin WebSocket client to the inference server.
///
/// Sends JPEG frames as binary messages, receives JSON updates as text.
class SignSocket {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _state = StreamController<SocketState>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messages.stream;
  Stream<SocketState> get state => _state.stream;

  SocketState _current = SocketState.disconnected;
  SocketState get current => _current;

  void _setState(SocketState s) {
    _current = s;
    if (!_state.isClosed) _state.add(s);
  }

  Future<void> connect(Uri uri) async {
    await disconnect();
    _setState(SocketState.connecting);
    try {
      _channel = WebSocketChannel.connect(uri);
      // ready waits for the handshake so we surface connection errors early.
      await _channel!.ready;
      _setState(SocketState.connected);

      _sub = _channel!.stream.listen(
        (data) {
          if (data is String) {
            try {
              final map = jsonDecode(data) as Map<String, dynamic>;
              _messages.add(map);
            } catch (_) {}
          }
        },
        onError: (_) => _setState(SocketState.error),
        onDone: () => _setState(SocketState.disconnected),
        cancelOnError: true,
      );
    } catch (_) {
      _setState(SocketState.error);
    }
  }

  void sendFrame(Uint8List jpeg) {
    if (_current != SocketState.connected) return;
    _channel?.sink.add(jpeg); // binary frame
  }

  void sendControl(Map<String, dynamic> cmd) {
    if (_current != SocketState.connected) return;
    _channel?.sink.add(jsonEncode(cmd)); // text frame
  }

  void reset() => sendControl({'action': 'reset'});

  void setFlip(bool flip) => sendControl({'action': 'config', 'flip': flip});

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {}
    _channel = null;
    if (_current != SocketState.disconnected) {
      _setState(SocketState.disconnected);
    }
  }

  void dispose() {
    disconnect();
    _messages.close();
    _state.close();
  }
}
