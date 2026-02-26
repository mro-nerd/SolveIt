import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/assessment_result.dart';

/// Invisible widget that opens the front camera, samples every 200 ms,
/// and emits [EmotionSample] values via [onEmotionSample].
///
/// Renders as [SizedBox.shrink] — no pixels on screen.
class EmotionCamera extends StatefulWidget {
  /// Called on each sampled frame with the detected emotion probabilities.
  final void Function(EmotionSample sample)? onEmotionSample;

  /// Whether sampling is active. Set to false to pause processing.
  final bool active;

  const EmotionCamera({super.key, this.onEmotionSample, this.active = true});

  @override
  State<EmotionCamera> createState() => _EmotionCameraState();
}

class _EmotionCameraState extends State<EmotionCamera> {
  CameraController? _camera;
  late final FaceDetector _detector;
  bool _processing = false;
  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);

  /// Sampling interval: 200 ms ≈ 5 Hz — enough for emotion tracking.
  static const int _sampleIntervalMs = 200;

  @override
  void initState() {
    super.initState();
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true, // smilingProbability + eyeOpenProbability
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
        ResolutionPreset.low,
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera permission denied — emotion tracking unavailable.',
              ),
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _onCameraImage(CameraImage image) {
    if (!widget.active) return;
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

      final face = faces.reduce(
        (a, b) => a.boundingBox.width > b.boundingBox.width ? a : b,
      );

      final smiling = face.smilingProbability ?? 0.0;
      final leftEye = face.leftEyeOpenProbability ?? 0.5;
      final rightEye = face.rightEyeOpenProbability ?? 0.5;
      final avgEye = (leftEye + rightEye) / 2.0;

      final sample = EmotionSample(
        smilingProbability: smiling,
        avgEyeOpenProbability: avgEye,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      );

      widget.onEmotionSample?.call(sample);
    } catch (_) {
      // Silently swallow per-frame errors.
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

  @override
  void dispose() {
    _camera?.stopImageStream();
    _camera?.dispose();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
