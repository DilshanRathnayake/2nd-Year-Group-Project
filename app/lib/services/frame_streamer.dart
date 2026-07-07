import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Captures camera frames, JPEG-encodes them off the UI thread, and hands the
/// bytes to a callback (which streams them to the server).
///
/// minInterval is a CEILING, not a fixed rate: the `_busy` flag skips a frame
/// whenever the previous one hasn't finished encoding yet, so actual
/// throughput self-limits to whatever the device can sustain — raising this
/// ceiling can only help (fills the model's 30-frame buffer faster), it can't
/// cause a backlog.
class FrameStreamer {
  CameraController? controller;
  final Duration minInterval;

  int _rotationDegrees = 0;
  bool _streaming = false;
  bool _busy = false;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  void Function(Uint8List jpeg)? _onJpeg;

  FrameStreamer({this.minInterval = const Duration(milliseconds: 40)});

  bool get isInitialized => controller?.value.isInitialized ?? false;

  Future<void> initialize() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _rotationDegrees = front.sensorOrientation;
    controller = CameraController(
      front,
      // Keep enough detail for MediaPipe hand detection on real phones.
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller!.initialize();
  }

  void start(void Function(Uint8List jpeg) onJpeg) {
    if (controller == null || _streaming) return;
    _onJpeg = onJpeg;
    _streaming = true;
    controller!.startImageStream(_onImage);
  }

  Future<void> stop() async {
    if (!_streaming) return;
    _streaming = false;
    try {
      await controller!.stopImageStream();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await controller?.dispose();
    controller = null;
  }

  void _onImage(CameraImage image) async {
    if (!_streaming || _busy) return;
    final now = DateTime.now();
    if (now.difference(_last) < minInterval) return;
    _last = now;
    _busy = true;
    try {
      final payload = _JpegPayload.fromCameraImage(
        image,
        rotationDegrees: _rotationDegrees,
      );
      final jpeg = await compute(_encodeJpeg, payload);
      if (jpeg != null && _streaming) _onJpeg?.call(jpeg);
    } catch (_) {
      // Drop the frame on any conversion error; next one will come along.
    } finally {
      _busy = false;
    }
  }
}

/// Serializable snapshot of a CameraImage, safe to send to an isolate.
class _JpegPayload {
  final int width;
  final int height;
  final bool isYuv420; // true = Android 3-plane YUV, false = BGRA8888 (iOS)

  final Uint8List plane0;
  final Uint8List? plane1;
  final Uint8List? plane2;
  final int bytesPerRow0;
  final int uvRowStride;
  final int uvPixelStride;
  final int rotationDegrees;

  _JpegPayload({
    required this.width,
    required this.height,
    required this.isYuv420,
    required this.plane0,
    required this.bytesPerRow0,
    required this.rotationDegrees,
    this.plane1,
    this.plane2,
    this.uvRowStride = 0,
    this.uvPixelStride = 1,
  });

  factory _JpegPayload.fromCameraImage(
    CameraImage image, {
    required int rotationDegrees,
  }) {
    // Copy plane bytes NOW: the native buffer may be recycled before compute()
    // serializes them to the isolate, which would corrupt the frame.
    final isYuv = image.planes.length >= 3;
    if (isYuv) {
      return _JpegPayload(
        width: image.width,
        height: image.height,
        isYuv420: true,
        plane0: Uint8List.fromList(image.planes[0].bytes),
        bytesPerRow0: image.planes[0].bytesPerRow,
        rotationDegrees: rotationDegrees,
        plane1: Uint8List.fromList(image.planes[1].bytes),
        plane2: Uint8List.fromList(image.planes[2].bytes),
        uvRowStride: image.planes[1].bytesPerRow,
        uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
      );
    }
    // BGRA8888 single plane (iOS fallback).
    return _JpegPayload(
      width: image.width,
      height: image.height,
      isYuv420: false,
      plane0: Uint8List.fromList(image.planes[0].bytes),
      bytesPerRow0: image.planes[0].bytesPerRow,
      rotationDegrees: rotationDegrees,
    );
  }
}

/// Runs in a background isolate. Returns JPEG bytes or null.
Uint8List? _encodeJpeg(_JpegPayload p) {
  try {
    final image = p.isYuv420 ? _yuv420ToImage(p) : _bgraToImage(p);
    final rotation = p.rotationDegrees % 360;
    final upright =
        rotation == 0 ? image : img.copyRotate(image, angle: rotation);
    return Uint8List.fromList(img.encodeJpg(upright, quality: 75));
  } catch (_) {
    return null;
  }
}

img.Image _yuv420ToImage(_JpegPayload p) {
  final w = p.width, h = p.height;
  final out = img.Image(width: w, height: h);
  final y = p.plane0, u = p.plane1!, v = p.plane2!;
  final yStride = p.bytesPerRow0;
  final uvStride = p.uvRowStride;
  final uvPix = p.uvPixelStride;

  for (int row = 0; row < h; row++) {
    final int uvRow = uvStride * (row >> 1);
    final int yRow = row * yStride;
    for (int col = 0; col < w; col++) {
      final int uvIndex = uvRow + uvPix * (col >> 1);
      final int yp = y[yRow + col];
      final int up = u[uvIndex];
      final int vp = v[uvIndex];

      int r = (yp + 1.402 * (vp - 128)).round();
      int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).round();
      int b = (yp + 1.772 * (up - 128)).round();

      out.setPixelRgb(
        col,
        row,
        r < 0 ? 0 : (r > 255 ? 255 : r),
        g < 0 ? 0 : (g > 255 ? 255 : g),
        b < 0 ? 0 : (b > 255 ? 255 : b),
      );
    }
  }
  return out;
}

img.Image _bgraToImage(_JpegPayload p) {
  return img.Image.fromBytes(
    width: p.width,
    height: p.height,
    bytes: p.plane0.buffer,
    order: img.ChannelOrder.bgra,
  );
}
