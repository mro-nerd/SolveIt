import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Invisible background widget that opens the front camera, samples every
/// 300 ms, and calls [onGazeDirection] with `'left'`, `'right'`, or
/// `'center'` based on the user's head Euler-Y angle.
///
/// Renders as [SizedBox.shrink] — no pixels on screen.
/// On camera permission denial a [SnackBar] is shown via [ScaffoldMessenger].
class EyeTrackingOverlay extends StatefulWidget {
  /// Called whenever a new gaze direction is determined from a camera frame.
  /// Direction is one of `'left'`, `'right'`, or `'center'`.
  final void Function(String direction)? onGazeDirection;

  const EyeTrackingOverlay({super.key, this.onGazeDirection});

  @override
  State<EyeTrackingOverlay> createState() => _EyeTrackingOverlayState();
}

class _EyeTrackingOverlayState extends State<EyeTrackingOverlay> {
  CameraController? _camera;
  late final FaceDetector _detector;

  /// Guards against overlapping processImage calls.
  bool _processing = false;

  /// Timestamp of the last processed frame — used to enforce the 300 ms gap.
  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true, // gives leftEyeOpenProbability etc.
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final ctrl = CameraController(
        front,
        ResolutionPreset.low, // ~240 p — enough for face detection
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }

      _camera = ctrl;
      await ctrl.startImageStream(_onCameraImage);
    } on CameraException catch (e) {
      if (e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt' ||
          e.code == 'permissionDenied') {
        _showPermissionSnackBar();
      }
      // Other errors (e.g. no front camera) are silently ignored.
    }
  }

  void _showPermissionSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Camera permission denied — eye tracking unavailable.',
        ),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Frame processing ──────────────────────────────────────────────────────

  void _onCameraImage(CameraImage image) {
    final now = DateTime.now();
    if (now.difference(_lastSample).inMilliseconds < 300) return;
    if (_processing) return;
    _lastSample = now;
    _processing = true;
    _processFrame(image).whenComplete(() => _processing = false);
  }

  Future<void> _processFrame(CameraImage image) async {
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;

      final faces = await _detector.processImage(inputImage);
      if (faces.isEmpty) return;

      // Use the most-prominent face (largest bounding box).
      final face = faces.reduce(
        (a, b) => a.boundingBox.width > b.boundingBox.width ? a : b,
      );

      final yaw = face.headEulerAngleY;
      if (yaw == null) return;

      // headEulerAngleY > 0 → face turned to its left  (looking at their right)
      // headEulerAngleY < 0 → face turned to its right (looking at their left)
      // ±10 ° dead-band = 'center'
      final String direction;
      if (yaw > 10) {
        direction = 'right';
      } else if (yaw < -10) {
        direction = 'left';
      } else {
        direction = 'center';
      }

      widget.onGazeDirection?.call(direction);
    } catch (_) {
      // Silently swallow per-frame errors — never crash the image stream.
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final sensor = _camera!.description;

    final rotation =
        InputImageRotationValue.fromRawValue(sensor.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    // Concatenate all planes into a single byte buffer.
    // NV21 (Android): Y plane + interleaved VU plane.
    // BGRA8888 (iOS): single plane.
    final Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = image.planes.first.bytes;
    } else {
      bytes = Uint8List.fromList(
        image.planes.expand((p) => p.bytes).toList(),
      );
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _camera?.stopImageStream();
    _camera?.dispose();
    _detector.close();
    super.dispose();
  }

  // ── Build — intentionally invisible ──────────────────────────────────────

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
