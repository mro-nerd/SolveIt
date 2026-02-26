import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Invisible widget that captures camera frames, runs MoveNet pose estimation,
/// and reports detected joint angles via callback.
class CameraPoseDetector extends StatefulWidget {
  final void Function(Map<String, double> angles) onAnglesDetected;
  final void Function(String message) onError;

  const CameraPoseDetector({
    super.key,
    required this.onAnglesDetected,
    required this.onError,
  });

  @override
  State<CameraPoseDetector> createState() => _CameraPoseDetectorState();
}

class _CameraPoseDetectorState extends State<CameraPoseDetector> {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  Timer? _timer;
  bool _isProcessing = false;

  // MoveNet keypoint indices
  static const int _kLeftShoulder = 5;
  static const int _kRightShoulder = 6;
  static const int _kLeftElbow = 7;
  static const int _kRightElbow = 8;
  static const int _kLeftWrist = 9;
  static const int _kRightWrist = 10;
  static const int _kLeftHip = 11;
  static const int _kRightHip = 12;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Load TFLite model
      _interpreter =
          await Interpreter.fromAsset('assets/models/movenet.tflite');

      // Initialize front camera
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await _cameraController!.initialize();

      // Start periodic inference every 500ms
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _captureAndInfer();
      });
    } catch (e) {
      widget.onError(e.toString());
    }
  }

  Future<void> _captureAndInfer() async {
    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }
    _isProcessing = true;

    try {
      // 1. Capture a camera frame
      final xFile = await _cameraController!.takePicture();
      final bytes = await File(xFile.path).readAsBytes();

      // 2. Decode and resize to 256×256
      final original = img.decodeImage(bytes);
      if (original == null) throw Exception('Failed to decode image');
      final resized = img.copyResize(original, width: 256, height: 256);

      // 3. Convert pixel values to uint8 (0–255) as required by MoveNet
      final input = Uint8List(1 * 256 * 256 * 3);
      int pixelIndex = 0;
      for (int y = 0; y < 256; y++) {
        for (int x = 0; x < 256; x++) {
          final pixel = resized.getPixel(x, y);
          input[pixelIndex++] = pixel.r.toInt();
          input[pixelIndex++] = pixel.g.toInt();
          input[pixelIndex++] = pixel.b.toInt();
        }
      }

      // 4. Run inference — output shape [1, 1, 17, 3]
      //    Use runForMultipleInputs to get properly typed output
      final output = List.generate(
        1,
        (_) => List.generate(
          1,
          (_) => List.generate(17, (_) => List.filled(3, 0.0)),
        ),
      );
      final outputMap = <int, Object>{0: output};
      _interpreter!.runForMultipleInputs([input], outputMap);

      // 5. Extract keypoints from output: each is [y, x, confidence]
      final keypoints = output[0][0]; // 17 keypoints, each [y, x, conf]
      List<double> _kp(int idx) => [
            (keypoints[idx][0] as double),
            (keypoints[idx][1] as double),
            (keypoints[idx][2] as double),
          ];

      // 6. Check confidence > 0.3 for all required keypoints
      final requiredIndices = [
        _kLeftShoulder, _kRightShoulder,
        _kLeftElbow, _kRightElbow,
        _kLeftWrist, _kRightWrist,
        _kLeftHip, _kRightHip,
      ];
      final allConfident = requiredIndices.every(
        (i) => _kp(i)[2] > 0.3,
      );
      if (!allConfident) {
        _isProcessing = false;
        return;
      }

      // 7. Calculate joint angles using atan2
      final angles = <String, double>{
        'left_elbow': _angleDeg(
          _kp(_kLeftShoulder),
          _kp(_kLeftElbow),
          _kp(_kLeftWrist),
        ),
        'right_elbow': _angleDeg(
          _kp(_kRightShoulder),
          _kp(_kRightElbow),
          _kp(_kRightWrist),
        ),
        'left_shoulder': _angleDeg(
          _kp(_kLeftHip),
          _kp(_kLeftShoulder),
          _kp(_kLeftElbow),
        ),
        'right_shoulder': _angleDeg(
          _kp(_kRightHip),
          _kp(_kRightShoulder),
          _kp(_kRightElbow),
        ),
      };

      // 8. Fire callback
      widget.onAnglesDetected(angles);
    } catch (e) {
      widget.onError(e.toString());
    } finally {
      _isProcessing = false;
    }
  }

  /// Angle (in degrees) at vertex B in the triangle A → B → C.
  double _angleDeg(List<double> a, List<double> b, List<double> c) {
    // Keypoints are [y, x, confidence]
    final baX = a[1] - b[1];
    final baY = a[0] - b[0];
    final bcX = c[1] - b[1];
    final bcY = c[0] - b[0];

    final angleA = atan2(baY, baX);
    final angleC = atan2(bcY, bcX);

    var diff = (angleA - angleC).abs();
    if (diff > pi) diff = 2 * pi - diff;

    return diff * 180 / pi;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
