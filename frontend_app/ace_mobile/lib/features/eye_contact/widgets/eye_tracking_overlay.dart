import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Invisible background widget that opens the front camera, samples every
/// 150 ms, and calls [onGazeYaw] with the **smoothed yaw angle** (in degrees)
/// after applying EMA noise reduction and front-camera mirror correction.
///
/// Positive yaw → child is looking to the RIGHT side of the screen.
/// Negative yaw → child is looking to the LEFT side of the screen.
///
/// Renders as [SizedBox.shrink] — no pixels on screen.
/// On camera permission denial a [SnackBar] is shown via [ScaffoldMessenger].
class EyeTrackingOverlay extends StatefulWidget {
  /// Called whenever a new smoothed yaw angle is determined from a camera frame.
  /// The value is in degrees: negative = looking left, positive = looking right.
  final void Function(double yawAngle)? onGazeYaw;

  const EyeTrackingOverlay({super.key, this.onGazeYaw});

  @override
  State<EyeTrackingOverlay> createState() => _EyeTrackingOverlayState();
}

class _EyeTrackingOverlayState extends State<EyeTrackingOverlay> {
  CameraController? _camera;
  late final FaceDetector _detector;

  /// Guards against overlapping processImage calls.
  bool _processing = false;

  /// Timestamp of the last processed frame — used to enforce the sampling gap.
  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);

  /// Whether the active camera is front-facing (needs mirror correction).
  bool _isFrontCamera = false;

  /// Exponential Moving Average state for yaw smoothing.
  double? _smoothedYaw;

  /// EMA smoothing factor. Lower = smoother but laggier; higher = more responsive.
  /// 0.35 is a good balance for head-tracking at ~7 Hz sampling.
  static const double _emaAlpha = 0.35;

  /// Sampling interval in milliseconds (150 ms ≈ ~7 Hz).
  static const int _sampleIntervalMs = 150;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
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

      _isFrontCamera = front.lensDirection == CameraLensDirection.front;

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
        content: Text('Camera permission denied — eye tracking unavailable.'),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Frame processing ──────────────────────────────────────────────────────

  void _onCameraImage(CameraImage image) {
    final now = DateTime.now();
    if (now.difference(_lastSample).inMilliseconds < _sampleIntervalMs) return;
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

      final rawYaw = face.headEulerAngleY;
      if (rawYaw == null) return;

      // ── Mirror correction ──
      // ML Kit reports yaw relative to the camera sensor.
      // On the front camera the image is mirrored, so we negate the yaw
      // to align with the child's perspective:
      //   positive = child looking to their right (right side of screen)
      //   negative = child looking to their left  (left side of screen)
      final correctedYaw = _isFrontCamera ? -rawYaw : rawYaw;

      // ── EMA smoothing ──
      if (_smoothedYaw == null) {
        _smoothedYaw = correctedYaw;
      } else {
        _smoothedYaw =
            _emaAlpha * correctedYaw + (1 - _emaAlpha) * _smoothedYaw!;
      }

      widget.onGazeYaw?.call(_smoothedYaw!);
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
      bytes = Uint8List.fromList(image.planes.expand((p) => p.bytes).toList());
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
