// In liveness_capture.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math' as math;

enum Challenge { initial, leftTurn, rightTurn, blink, center }

class LivenessCaptureScreen extends StatefulWidget {
  final Function(Uint8List?) onCaptureComplete;
  final VoidCallback onCancel;

  const LivenessCaptureScreen({
    super.key,
    required this.onCaptureComplete,
    required this.onCancel,
  });

  @override
  State<LivenessCaptureScreen> createState() => _LivenessCaptureScreenState();
}

class _LivenessCaptureScreenState extends State<LivenessCaptureScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  FaceDetector? _faceDetector;
  Uint8List? modelBuffer;
  bool _isProcessing = false;
  Challenge _currentChallenge = Challenge.initial;
  bool _leftDone = false;
  bool _rightDone = false;
  bool _blinkDone = false;
  Timer? _challengeTimer;
  final int _timeoutSeconds = 15;
  bool _showPreview = true;
  bool _isInitializing = false;
  bool _isDisposed = false;
  bool _isCapturingFinalPhoto = false;
  int _frameCount = 0;
  int _blinkRetryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraAndModel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('AppLifecycleState changed: $state at ${DateTime.now()}');
    if (state == AppLifecycleState.paused && !_isCapturingFinalPhoto) {
      _cleanupResources();
    } else if (state == AppLifecycleState.resumed && _cameraController == null && !_isDisposed && !_isInitializing) {
      _initializeCameraAndModel();
    }
  }

  Future<bool> _checkCameraPermission() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      debugPrint('Camera permission denied at ${DateTime.now()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required for liveness check')),
        );
      }
      return false;
    }
    if (await Permission.camera.status.isPermanentlyDenied) {
      debugPrint('Camera permission permanently denied at ${DateTime.now()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable camera permission in settings')),
        );
      }
      await openAppSettings();
      return false;
    }

    if (Platform.isAndroid) {
      final permission = await _getStoragePermission();
      final storageStatus = await permission.request();
      if (!storageStatus.isGranted) {
        debugPrint('Storage/photos permission denied at ${DateTime.now()}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied. Images will not be saved to gallery, but liveness check can proceed.')),
          );
        }
      }
      if (await permission.isPermanentlyDenied) {
        debugPrint('Storage/photos permission permanently denied at ${DateTime.now()}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable storage/photos permission in settings to save images')),
          );
        }
        await openAppSettings();
      }
    }
    return true;
  }

  Future<Permission> _getStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      return sdkInt >= 33 ? Permission.photos : Permission.storage;
    }
    return Permission.storage;
  }

  Future<void> _initializeCameraAndModel() async {
    if (_isInitializing || _isDisposed) {
      debugPrint('Initialization skipped: _isInitializing=$_isInitializing, _isDisposed=$_isDisposed at ${DateTime.now()}');
      return;
    }
    setState(() => _isInitializing = true);
    try {
      if (!await _checkCameraPermission()) {
        widget.onCaptureComplete(null);
        setState(() => _isInitializing = false);
        return;
      }
      final cameras = await availableCameras();
      if (cameras.length < 2) {
        debugPrint('No front camera available at ${DateTime.now()}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No front camera available')),
          );
        }
        widget.onCaptureComplete(null);
        setState(() => _isInitializing = false);
        return;
      }
      _cameraController = CameraController(cameras[1], ResolutionPreset.low);
      debugPrint('Initializing camera at ${DateTime.now()}...');
      await _cameraController?.initialize().catchError((e) {
        debugPrint('Camera initialization error: $e at ${DateTime.now()}');
        throw e;
      });
      if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) {
        debugPrint('Camera initialization failed or widget unmounted at ${DateTime.now()}');
        await _cleanupResources();
        widget.onCaptureComplete(null);
        setState(() => _isInitializing = false);
        return;
      }
      const modelPath = 'assets/models/mobilefacenet_liveness.tflite';
      _interpreter = await Interpreter.fromAsset(modelPath);
      _interpreter?.allocateTensors();
      debugPrint('Input shape: ${_interpreter?.getInputTensor(0).shape} at ${DateTime.now()}');
      final modelData = await DefaultAssetBundle.of(context).load(modelPath);
      modelBuffer = modelData.buffer.asUint8List();
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableClassification: true,
          enableLandmarks: true,
        ),
      );
      await _cameraController!.startImageStream(_processCameraImage).catchError((e) {
        debugPrint('Error starting image stream: $e at ${DateTime.now()}');
        throw e;
      });
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      debugPrint('Camera and model initialized successfully at ${DateTime.now()}');
    } catch (e) {
      debugPrint('Initialization error: $e at ${DateTime.now()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera or model: $e')),
        );
      }
      widget.onCaptureComplete(null);
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _cleanupResources() async {
    if (_isDisposed || _isCapturingFinalPhoto) {
      debugPrint('Cleanup skipped: _isDisposed=$_isDisposed, _isCapturingFinalPhoto=$_isCapturingFinalPhoto at ${DateTime.now()}');
      return;
    }
    try {
      debugPrint('Cleaning up resources at ${DateTime.now()}...');
      _challengeTimer?.cancel();
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream().catchError((e) {
            debugPrint('Error stopping image stream: $e at ${DateTime.now()}');
          });
        }
        if (_cameraController!.value.isPreviewPaused) {
          await _cameraController!.resumePreview().catchError((e) {
            debugPrint('Error resuming preview: $e at ${DateTime.now()}');
          });
        }
        await _cameraController!.dispose().catchError((e) {
          debugPrint('Error disposing camera: $e at ${DateTime.now()}');
        });
      }
      _interpreter?.close();
      _faceDetector?.close();
      debugPrint('Resources cleaned up successfully at ${DateTime.now()}');
    } catch (e) {
      debugPrint('Cleanup error: $e at ${DateTime.now()}');
    } finally {
      _cameraController = null;
      _interpreter = null;
      _faceDetector = null;
      _challengeTimer = null;
    }
  }

  void _startChallengeSequence() {
    if (_isDisposed || _cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Cannot start challenge: disposed or camera not initialized at ${DateTime.now()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera is not ready. Please try again.')),
        );
      }
      widget.onCaptureComplete(null);
      return;
    }
    setState(() => _currentChallenge = Challenge.leftTurn);
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    _challengeTimer?.cancel();
    _challengeTimer = Timer(Duration(seconds: _timeoutSeconds), _handleTimeout);
  }

  void _handleTimeout() => _handleFailure();

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _currentChallenge == Challenge.initial || _cameraController == null || _isDisposed || _isCapturingFinalPhoto) {
      debugPrint('Skipping image processing: _isProcessing=$_isProcessing, _currentChallenge=$_currentChallenge, _isDisposed=$_isDisposed, _isCapturingFinalPhoto=$_isCapturingFinalPhoto at ${DateTime.now()}');
      return;
    }
    _frameCount++;
    if (_frameCount % 3 != 0) {
      return;
    }
    _isProcessing = true;

    try {
      final bytesList = image.planes.map((plane) => plane.bytes).toList();
      final bytes = Uint8List.fromList(bytesList.expand((i) => i).toList());

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = _cameraController!.description;
      final sensorOrientation = camera.sensorOrientation;
      final imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;

      final InputImageMetadata metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty) {
        debugPrint('No faces detected in image at ${DateTime.now()}');
        _isProcessing = false;
        return;
      }
      final face = faces.first;
      bool detected = false;

      switch (_currentChallenge) {
        case Challenge.leftTurn:
          if (face.headEulerAngleY! > 20) {
            detected = true;
            _leftDone = true;
            _currentChallenge = Challenge.rightTurn;
          }
          break;
        case Challenge.rightTurn:
          if (face.headEulerAngleY! < -20) {
            detected = true;
            _rightDone = true;
            await Future.delayed(const Duration(milliseconds: 500));
            await _cameraController!.pausePreview();
            await Future.delayed(const Duration(milliseconds: 100));
            await _cameraController!.resumePreview();
            _currentChallenge = Challenge.blink;
          }
          break;
        case Challenge.blink:
          if (face.leftEyeOpenProbability! < 0.4 || face.rightEyeOpenProbability! < 0.4) {
            detected = true;
            _blinkDone = true;
            _currentChallenge = Challenge.center;
            _blinkRetryCount = 0;
          } else {
            _blinkRetryCount++;
            if (_blinkRetryCount > 30) {
              debugPrint('Blink detection timeout at ${DateTime.now()}');
              await _handleFailure();
              return;
            }
          }
          break;
        case Challenge.center:
          if (face.headEulerAngleY!.abs() < 10 && face.headEulerAngleZ!.abs() < 10) {
            detected = true;
            await _captureFinalPhoto();
            return;
          }
          break;
        default:
          break;
      }

      if (detected) {
        _challengeTimer?.cancel();
        await _captureAndSaveFrame(face, image);
        _startTimeoutTimer();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Camera image processing error: $e at ${DateTime.now()}');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _captureAndSaveFrame(Face face, CameraImage cameraImage) async {
    if (_isDisposed || _cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Cannot capture frame: disposed or camera not initialized at ${DateTime.now()}');
      return;
    }
    File? tempFile;
    try {
      debugPrint('Capturing frame for ${_currentChallenge.name} at ${DateTime.now()}');
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        debugPrint('No faces detected in captured frame at ${DateTime.now()}');
        return;
      }
      final rect = faces.first.boundingBox;

      final imageBytes = await File(photo.path).readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        debugPrint('Failed to decode captured image at ${DateTime.now()}');
        return;
      }

      final width = decodedImage.width;
      final height = decodedImage.height;
      final cropped = img.copyCrop(
        decodedImage,
        x: rect.left.toInt().clamp(0, width),
        y: rect.top.toInt().clamp(0, height),
        width: rect.width.toInt().clamp(0, width - rect.left.toInt()),
        height: rect.height.toInt().clamp(0, height - rect.top.toInt()),
      );
      final croppedBytes = img.encodePng(cropped);

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/liveness_${_currentChallenge.name}.png';
      tempFile = await File(tempPath).writeAsBytes(croppedBytes);
      try {
        if (Platform.isAndroid) {
          final permission = await _getStoragePermission();
          if (await permission.isGranted) {
            await Gal.putImage(tempPath);
            debugPrint('Saved ${_currentChallenge.name} to gallery at ${DateTime.now()}');
          } else {
            debugPrint('Skipped gallery save for ${_currentChallenge.name} due to missing permission at ${DateTime.now()}');
          }
        } else {
          await Gal.putImage(tempPath);
          debugPrint('Saved ${_currentChallenge.name} to gallery at ${DateTime.now()}');
        }
      } catch (e) {
        debugPrint('Gallery save error for ${_currentChallenge.name}: $e at ${DateTime.now()}');
      }
    } catch (e) {
      debugPrint('Capture and save frame error: $e at ${DateTime.now()}');
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<void> _captureFinalPhoto() async {
    if (_isDisposed || _cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Cannot capture final photo: disposed or camera not initialized at ${DateTime.now()}');
      _handleFailure();
      return;
    }
    setState(() => _isCapturingFinalPhoto = true);
    File? tempFile;
    try {
      debugPrint('Capturing final photo at ${DateTime.now()}...');
      final XFile finalPhoto = await _cameraController!.takePicture();
      debugPrint('Final photo captured: ${finalPhoto.path} at ${DateTime.now()}');
      final imageBytes = await File(finalPhoto.path).readAsBytes();
      final inputImage = InputImage.fromFilePath(finalPhoto.path);
      debugPrint('Processing face detection for final photo at ${DateTime.now()}...');
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        debugPrint('No faces detected in final photo at ${DateTime.now()}');
        _handleFailure();
        return;
      }
      final rect = faces.first.boundingBox;
      debugPrint('Face detected in final photo, bounding box: $rect at ${DateTime.now()}');

      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        debugPrint('Failed to decode final photo at ${DateTime.now()}');
        _handleFailure();
        return;
      }

      final width = decodedImage.width;
      final height = decodedImage.height;
      debugPrint('Final photo dimensions: ${width}x${height} at ${DateTime.now()}');
      final cropped = img.copyCrop(
        decodedImage,
        x: rect.left.toInt().clamp(0, width),
        y: rect.top.toInt().clamp(0, height),
        width: rect.width.toInt().clamp(0, width - rect.left.toInt()),
        height: rect.height.toInt().clamp(0, height - rect.top.toInt()),
      );
      final croppedBytes = img.encodePng(cropped);
      debugPrint('Final photo cropped successfully at ${DateTime.now()}');

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/liveness_final.png';
      tempFile = await File(tempPath).writeAsBytes(croppedBytes);
      debugPrint('Final photo written to: $tempPath at ${DateTime.now()}');
      try {
        if (Platform.isAndroid) {
          final permission = await _getStoragePermission();
          if (await permission.isGranted) {
            await Gal.putImage(tempPath);
            debugPrint('Final face saved to gallery at ${DateTime.now()}');
          } else {
            debugPrint('Skipped gallery save for final photo due to missing permission at ${DateTime.now()}');
          }
        } else {
          await Gal.putImage(tempPath);
          debugPrint('Final face saved to gallery at ${DateTime.now()}');
        }
      } catch (e) {
        debugPrint('Gallery save error for final photo: $e at ${DateTime.now()}');
      }

      // Stop the image stream before calling onCaptureComplete
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream().catchError((e) {
          debugPrint('Error stopping image stream: $e at ${DateTime.now()}');
        });
      }

      if (!mounted || _isDisposed) {
        debugPrint('Widget unmounted or disposed before completing capture at ${DateTime.now()}');
        widget.onCaptureComplete(null);
        return;
      }

      debugPrint('Completing liveness capture with cropped bytes at ${DateTime.now()}');
      widget.onCaptureComplete(croppedBytes);
      await _cleanupResources();
    } catch (e) {
      debugPrint('Capture final photo error: $e at ${DateTime.now()}');
      _handleFailure();
    } finally {
      setState(() => _isCapturingFinalPhoto = false);
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<void> _handleFailure() async {
    if (_isDisposed) {
      debugPrint('Handle failure skipped: already disposed at ${DateTime.now()}');
      return;
    }
    try {
      await _cleanupResources();
      if (!mounted) {
        debugPrint('Widget unmounted during handle failure at ${DateTime.now()}');
        widget.onCaptureComplete(null);
        return;
      }
      setState(() {
        _showPreview = false;
        _currentChallenge = Challenge.initial;
        _leftDone = false;
        _rightDone = false;
        _blinkDone = false;
        _blinkRetryCount = 0;
      });
      final retry = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Liveness Check Failed'),
            content: const Text('We could not detect the required actions. Would you like to try again?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Try Again')),
            ],
          );
        },
      );
      if (retry == true && mounted && !_isDisposed) {
        await _initializeCameraAndModel();
        _startChallengeSequence();
      } else {
        widget.onCaptureComplete(null);
      }
    } catch (e) {
      debugPrint('Handle failure error: $e at ${DateTime.now()}');
      widget.onCaptureComplete(null);
    }
  }

  String _getInstructionText() {
    switch (_currentChallenge) {
      case Challenge.leftTurn:
        return 'Turn your head to your left${_leftDone ? " ✓" : ""}';
      case Challenge.rightTurn:
        return 'Turn your head to your right${_rightDone ? " ✓" : ""}';
      case Challenge.blink:
        return 'Blink your eyes${_blinkDone ? " ✓" : ""}';
      case Challenge.center:
        return 'Center your face';
      default:
        return 'Position your face in the center';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    debugPrint('Disposing LivenessCaptureScreenState at ${DateTime.now()}');
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing || _cameraController == null || !_cameraController!.value.isInitialized || _isDisposed) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_showPreview)
          AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 32),
            onPressed: () async {
              await _cleanupResources();
              widget.onCancel();
            },
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.all(16),
            child: Text(
              _getInstructionText(),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (_currentChallenge == Challenge.initial)
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: (_isInitializing || _isDisposed) ? null : _startChallengeSequence,
                child: const Text('Start Liveness Check'),
              ),
            ),
          ),
      ],
    );
  }
}

Future<bool> compareFaces(Uint8List livenessBytes, Uint8List profileBytes) async {
  Interpreter? interpreter;
  try {
    const modelPath = 'assets/models/mobilefacenet_liveness.tflite';
    interpreter = await Interpreter.fromAsset(modelPath);
    interpreter.allocateTensors();
    debugPrint('Loaded mobilefacenet_liveness.tflite successfully at ${DateTime.now()}');
    debugPrint('Input shape: ${interpreter.getInputTensor(0).shape} at ${DateTime.now()}');
    final outputShape = interpreter.getOutputTensor(0).shape;

    final livenessInput = preprocess(livenessBytes);
    final livenessOutput = List.generate(1, (_) => List.generate(outputShape[1], (_) => 0.0));
    try {
      interpreter.run(livenessInput, livenessOutput);
      debugPrint('Inference successful for liveness face, output length: ${livenessOutput.expand((row) => row).length} at ${DateTime.now()}');
    } catch (e) {
      debugPrint('TFLite inference error for liveness face: $e at ${DateTime.now()}');
      return false;
    }
    final livenessEmbedding = livenessOutput.expand((row) => row).toList();

    final profileInput = preprocess(profileBytes);
    final profileOutput = List.generate(1, (_) => List.generate(outputShape[1], (_) => 0.0));
    try {
      interpreter.run(profileInput, profileOutput);
      debugPrint('Inference successful for profile face, output length: ${profileOutput.expand((row) => row).length} at ${DateTime.now()}');
    } catch (e) {
      debugPrint('TFLite inference error for profile face: $e at ${DateTime.now()}');
      return false;
    }
    final profileEmbedding = profileOutput.expand((row) => row).toList();

    if (livenessEmbedding.length != profileEmbedding.length) {
      debugPrint('Embedding length mismatch at ${DateTime.now()}');
      return false;
    }

    final similarity = cosineSimilarity(livenessEmbedding, profileEmbedding);
    debugPrint('Face similarity score: $similarity at ${DateTime.now()}');
    return similarity > 0.5; // Adjust threshold as needed
  } catch (e) {
    debugPrint('Face comparison error: $e at ${DateTime.now()}');
    return false;
  } finally {
    interpreter?.close();
  }
}

List<List<List<List<double>>>> preprocess(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes)!;
  final resized = img.copyResize(image, width: 112, height: 112);
  final bytes = resized.getBytes(order: img.ChannelOrder.rgb);

  final input = List.generate(
    1,
    (_) => List.generate(
      112,
      (_) => List.generate(
        112,
        (_) => List.generate(3, (_) => 0.0),
      ),
    ),
  );

  int idx = 0;
  for (int h = 0; h < 112; h++) {
    for (int w = 0; w < 112; w++) {
      input[0][h][w][0] = (bytes[idx++] / 127.5) - 1.0;
      input[0][h][w][1] = (bytes[idx++] / 127.5) - 1.0;
      input[0][h][w][2] = (bytes[idx++] / 127.5) - 1.0;
    }
  }
  return input;
}

double cosineSimilarity(List<double> a, List<double> b) {
  double dotProduct = 0.0, normA = 0.0, normB = 0.0;
  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
}

// version 2
/* // In liveness_capture.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math' as math;

enum Challenge { initial, leftTurn, rightTurn, blink, center }

class LivenessCaptureScreen extends StatefulWidget {
  final Function(Uint8List?) onCaptureComplete;
  const LivenessCaptureScreen({super.key, required this.onCaptureComplete});

  @override
  State<LivenessCaptureScreen> createState() => _LivenessCaptureScreenState();
}

class _LivenessCaptureScreenState extends State<LivenessCaptureScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  FaceDetector? _faceDetector;
  Uint8List? modelBuffer;
  bool _isProcessing = false;
  Challenge _currentChallenge = Challenge.initial;
  bool _leftDone = false;
  bool _rightDone = false;
  bool _blinkDone = false;
  Timer? _challengeTimer;
  final int _timeoutSeconds = 15;
  bool _showPreview = true;
  bool _isInitializing = false;
  bool _isDisposed = false;
  bool _isCapturingFinalPhoto = false;
  int _frameCount = 0; // Added for frame skipping
  int _blinkRetryCount = 0; // Added for blink detection retries

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraAndModel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Enhanced lifecycle handling to prevent reinitialization conflicts
    if (state == AppLifecycleState.paused && !_isCapturingFinalPhoto) {
      _cleanupResources();
    } else if (state == AppLifecycleState.resumed && _cameraController == null && !_isDisposed && !_isInitializing) {
      _initializeCameraAndModel();
    }
  }

  Future<bool> _checkCameraPermission() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      debugPrint('Camera permission denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required for liveness check')),
        );
      }
      return false;
    }
    if (await Permission.camera.status.isPermanentlyDenied) {
      debugPrint('Camera permission permanently denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable camera permission in settings')),
        );
      }
      openAppSettings();
      return false;
    }

    if (Platform.isAndroid) {
      final permission = await _getStoragePermission();
      final storageStatus = await permission.request();
      if (!storageStatus.isGranted) {
        debugPrint('Storage/photos permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied. Images will not be saved to gallery, but liveness check can proceed.')),
          );
        }
      }
      if (await permission.isPermanentlyDenied) {
        debugPrint('Storage/photos permission permanently denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable storage/photos permission in settings to save images')),
          );
        }
        openAppSettings();
      }
    }
    return true;
  }

  Future<Permission> _getStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 33) {
        return Permission.photos;
      } else {
        return Permission.storage;
      }
    }
    return Permission.storage;
  }

  Future<void> _initializeCameraAndModel() async {
    if (_isInitializing || _isDisposed) {
      debugPrint('Initialization skipped: _isInitializing=$_isInitializing, _isDisposed=$_isDisposed');
      return;
    }
    setState(() => _isInitializing = true);
    try {
      if (!await _checkCameraPermission()) {
        widget.onCaptureComplete(null);
        setState(() => _isInitializing = false);
        return;
      }
      final cameras = await availableCameras();
      if (cameras.length < 2) {
        debugPrint('No front camera available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No front camera available')),
          );
        }
        widget.onCaptureComplete(null);
        setState(() => _isInitializing = false);
        return;
      }
      // Use lower resolution to reduce memory usage
      _cameraController = CameraController(cameras[1], ResolutionPreset.low);
      debugPrint('Initializing camera...');
      await _cameraController?.initialize().catchError((e) {
        debugPrint('Camera initialization error: $e');
        throw e;
      });
      if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) {
        debugPrint('Camera initialization failed or widget unmounted');
        await _cleanupResources();
        widget.onCaptureComplete(null);
        setState(() => _isInitializing = false);
        return;
      }
      const modelPath = 'assets/models/mobilefacenet_liveness.tflite';
      _interpreter = await Interpreter.fromAsset(modelPath);
      _interpreter?.allocateTensors();
      debugPrint('Input shape: ${_interpreter?.getInputTensor(0).shape}');
      final modelData = await DefaultAssetBundle.of(context).load(modelPath);
      modelBuffer = modelData.buffer.asUint8List();
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableClassification: true,
          enableLandmarks: true,
        ),
      );
      await _cameraController!.startImageStream(_processCameraImage).catchError((e) {
        debugPrint('Error starting image stream: $e');
        throw e;
      });
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      debugPrint('Camera and model initialized successfully');
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera or model: $e')),
        );
      }
      widget.onCaptureComplete(null);
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _cleanupResources() async {
    if (_isDisposed || _isCapturingFinalPhoto) {
      debugPrint('Cleanup skipped: _isDisposed=$_isDisposed, _isCapturingFinalPhoto=$_isCapturingFinalPhoto');
      return;
    }
    try {
      debugPrint('Cleaning up resources...');
      _challengeTimer?.cancel();
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream().catchError((e) {
            debugPrint('Error stopping image stream: $e');
          });
        }
        if (_cameraController!.value.isPreviewPaused) {
          await _cameraController!.resumePreview().catchError((e) {
            debugPrint('Error resuming preview: $e');
          });
        }
        await _cameraController!.dispose().catchError((e) {
          debugPrint('Error disposing camera: $e');
        });
      }
      _interpreter?.close();
      _faceDetector?.close();
      debugPrint('Resources cleaned up successfully');
    } catch (e) {
      debugPrint('Cleanup error: $e');
    } finally {
      _cameraController = null;
      _interpreter = null;
      _faceDetector = null;
      _challengeTimer = null;
    }
  }

  void _startChallengeSequence() {
    if (_isDisposed || _cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Cannot start challenge: disposed or camera not initialized');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera is not ready. Please try again.')),
        );
      }
      widget.onCaptureComplete(null);
      return;
    }
    setState(() => _currentChallenge = Challenge.leftTurn);
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    _challengeTimer?.cancel();
    _challengeTimer = Timer(Duration(seconds: _timeoutSeconds), _handleTimeout);
  }

  void _handleTimeout() => _handleFailure();

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _currentChallenge == Challenge.initial || _cameraController == null || _isDisposed) {
      debugPrint('Skipping image processing: _isProcessing=$_isProcessing, _currentChallenge=$_currentChallenge, _isDisposed=$_isDisposed');
      return;
    }
    _frameCount++;
    if (_frameCount % 3 != 0) { // Process every third frame to reduce load
      return;
    }
    _isProcessing = true;

    try {
      final bytesList = image.planes.map((plane) => plane.bytes).toList();
      final bytes = Uint8List.fromList(bytesList.expand((i) => i).toList());

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = _cameraController!.description;
      final sensorOrientation = camera.sensorOrientation;
      final imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;

      final InputImageMetadata metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty) {
        debugPrint('No faces detected in image');
        _isProcessing = false;
        return;
      }
      final face = faces.first;
      bool detected = false;

      switch (_currentChallenge) {
        case Challenge.leftTurn:
          if (face.headEulerAngleY! > 20) {
            detected = true;
            _leftDone = true;
            _currentChallenge = Challenge.rightTurn;
          }
          break;
        case Challenge.rightTurn:
          if (face.headEulerAngleY! < -20) {
            detected = true;
            _rightDone = true;
            await Future.delayed(Duration(milliseconds: 500)); // Allow camera to stabilize
            await _cameraController!.pausePreview();
            await Future.delayed(Duration(milliseconds: 100));
            await _cameraController!.resumePreview();
            _currentChallenge = Challenge.blink;
          }
          break;
        case Challenge.blink:
          // Relaxed threshold for blink detection
          if (face.leftEyeOpenProbability! < 0.4 || face.rightEyeOpenProbability! < 0.4) {
            detected = true;
            _blinkDone = true;
            _currentChallenge = Challenge.center;
            _blinkRetryCount = 0;
          } else {
            _blinkRetryCount++;
            if (_blinkRetryCount > 30) { // ~10 seconds at 3 frames per second
              debugPrint('Blink detection timeout');
              await _handleFailure();
              return;
            }
          }
          break;
        case Challenge.center:
          if (face.headEulerAngleY!.abs() < 10 && face.headEulerAngleZ!.abs() < 10) {
            detected = true;
            await _captureFinalPhoto();
            return;
          }
          break;
        default:
          break;
      }

      if (detected) {
        _challengeTimer?.cancel();
        await _captureAndSaveFrame(face, image);
        _startTimeoutTimer();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Camera image processing error: $e');
      // Optionally integrate with crash reporting (e.g., Firebase Crashlytics)
      // await FirebaseCrashlytics.instance.recordError(e, StackTrace.current, reason: 'Camera image processing failed');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _captureAndSaveFrame(Face face, CameraImage cameraImage) async {
    if (_isDisposed || _cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Cannot capture frame: disposed or camera not initialized');
      return;
    }
    File? tempFile;
    try {
      debugPrint('Capturing frame for ${_currentChallenge.name}');
      final XFile photo = await _cameraController!.takePicture();
      tempFile = File(photo.path);
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        debugPrint('No faces detected in captured frame');
        return;
      }
      final rect = faces.first.boundingBox;

      final imageBytes = await tempFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        debugPrint('Failed to decode captured image');
        return;
      }

      final width = decodedImage.width;
      final height = decodedImage.height;
      final cropped = img.copyCrop(
        decodedImage,
        x: rect.left.toInt().clamp(0, width),
        y: rect.top.toInt().clamp(0, height),
        width: rect.width.toInt().clamp(0, width - rect.left.toInt()),
        height: rect.height.toInt().clamp(0, height - rect.top.toInt()),
      );
      final croppedBytes = img.encodePng(cropped);

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/liveness_${_currentChallenge.name}.png';
      tempFile = await File(tempPath).writeAsBytes(croppedBytes);
      try {
        if (Platform.isAndroid) {
          final permission = await _getStoragePermission();
          if (await permission.isGranted) {
            await Gal.putImage(tempPath);
            debugPrint('Saved ${_currentChallenge.name} to gallery');
          } else {
            debugPrint('Skipped gallery save for ${_currentChallenge.name} due to missing permission');
          }
        } else {
          await Gal.putImage(tempPath);
          debugPrint('Saved ${_currentChallenge.name} to gallery');
        }
      } catch (e) {
        debugPrint('Gallery save error for ${_currentChallenge.name}: $e');
      }
    } catch (e) {
      debugPrint('Capture and save frame error: $e');
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<void> _captureFinalPhoto() async {
    if (_isDisposed || _cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Cannot capture final photo: disposed or camera not initialized');
      _handleFailure();
      return;
    }
    setState(() => _isCapturingFinalPhoto = true);
    File? tempFile;
    try {
      debugPrint('Capturing final photo...');
      final XFile finalPhoto = await _cameraController!.takePicture();
      tempFile = File(finalPhoto.path);
      debugPrint('Final photo captured: ${finalPhoto.path}');
      final inputImage = InputImage.fromFilePath(finalPhoto.path);
      debugPrint('Processing face detection for final photo...');
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        debugPrint('No faces detected in final photo');
        _handleFailure();
        return;
      }
      final rect = faces.first.boundingBox;
      debugPrint('Face detected in final photo, bounding box: $rect');

      final imageBytes = await tempFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        debugPrint('Failed to decode final photo');
        _handleFailure();
        return;
      }

      final width = decodedImage.width;
      final height = decodedImage.height;
      debugPrint('Final photo dimensions: ${width}x${height}');
      final cropped = img.copyCrop(
        decodedImage,
        x: rect.left.toInt().clamp(0, width),
        y: rect.top.toInt().clamp(0, height),
        width: rect.width.toInt().clamp(0, width - rect.left.toInt()),
        height: rect.height.toInt().clamp(0, height - rect.top.toInt()),
      );
      final croppedBytes = img.encodePng(cropped);
      debugPrint('Final photo cropped successfully');

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/liveness_final.png';
      tempFile = await File(tempPath).writeAsBytes(croppedBytes);
      debugPrint('Final photo written to: $tempPath');
      try {
        if (Platform.isAndroid) {
          final permission = await _getStoragePermission();
          if (await permission.isGranted) {
            await Gal.putImage(tempPath);
            debugPrint('Final face saved to gallery');
          } else {
            debugPrint('Skipped gallery save for final photo due to missing permission');
          }
        } else {
          await Gal.putImage(tempPath);
          debugPrint('Final face saved to gallery');
        }
      } catch (e) {
        debugPrint('Gallery save error for final photo: $e');
      }

      if (!mounted || _isDisposed) {
        debugPrint('Widget unmounted or disposed before completing capture');
        widget.onCaptureComplete(null);
        return;
      }

      debugPrint('Completing liveness capture with cropped bytes');
      widget.onCaptureComplete(croppedBytes);
      await _cleanupResources();
    } catch (e) {
      debugPrint('Capture final photo error: $e');
      _handleFailure();
    } finally {
      setState(() => _isCapturingFinalPhoto = false);
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<void> _handleFailure() async {
    if (_isDisposed) {
      debugPrint('Handle failure skipped: already disposed');
      return;
    }
    try {
      await _cleanupResources();
      if (!mounted) {
        debugPrint('Widget unmounted during handle failure');
        widget.onCaptureComplete(null);
        return;
      }
      setState(() {
        _showPreview = false;
        _currentChallenge = Challenge.initial;
        _leftDone = false;
        _rightDone = false;
        _blinkDone = false;
        _blinkRetryCount = 0;
      });
      final retry = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Liveness Check Failed'),
            content: const Text('We could not detect the required actions. Would you like to try again?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Try Again')),
            ],
          );
        },
      );
      if (retry == true && mounted && !_isDisposed) {
        await _initializeCameraAndModel();
        _startChallengeSequence();
      } else {
        widget.onCaptureComplete(null);
      }
    } catch (e) {
      debugPrint('Handle failure error: $e');
      widget.onCaptureComplete(null);
    }
  }

  String _getInstructionText() {
    switch (_currentChallenge) {
      case Challenge.leftTurn:
        return 'Turn your head to your left${_leftDone ? " ✓" : ""}';
      case Challenge.rightTurn:
        return 'Turn your head to your right${_rightDone ? " ✓" : ""}';
      case Challenge.blink:
        return 'Blink your eyes${_blinkDone ? " ✓" : ""}';
      case Challenge.center:
        return 'Center your face';
      default:
        return 'Position your face in the center';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    debugPrint('Disposing LivenessCaptureScreenState');
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing || _cameraController == null || !_cameraController!.value.isInitialized || _isDisposed) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_showPreview)
          AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 32),
            onPressed: () async {
              await _cleanupResources();
              widget.onCaptureComplete(null);
            },
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.all(16),
            child: Text(
              _getInstructionText(),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (_currentChallenge == Challenge.initial)
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: (_isInitializing || _isDisposed) ? null : _startChallengeSequence,
                child: const Text('Start Liveness Check'),
              ),
            ),
          ),
      ],
    );
  }
}

Future<bool> compareFaces(Uint8List livenessBytes, Uint8List profileBytes) async {
  Interpreter? interpreter;
  try {
    const modelPath = 'assets/models/mobilefacenet_liveness.tflite';
    interpreter = await Interpreter.fromAsset(modelPath);
    interpreter.allocateTensors();
    debugPrint('Loaded mobilefacenet_liveness.tflite successfully');
    debugPrint('Input shape: ${interpreter.getInputTensor(0).shape}');
    final outputShape = interpreter.getOutputTensor(0).shape;

    final livenessInput = preprocess(livenessBytes);
    final livenessOutput = List.generate(1, (_) => List.generate(outputShape[1], (_) => 0.0));
    try {
      interpreter.run(livenessInput, livenessOutput);
      debugPrint('Inference successful for liveness face, output length: ${livenessOutput.expand((row) => row).length}');
    } catch (e) {
      debugPrint('TFLite inference error for liveness face: $e');
      return false;
    }
    final livenessEmbedding = livenessOutput.expand((row) => row).toList();

    final profileInput = preprocess(profileBytes);
    final profileOutput = List.generate(1, (_) => List.generate(outputShape[1], (_) => 0.0));
    try {
      interpreter.run(profileInput, profileOutput);
      debugPrint('Inference successful for profile face, output length: ${profileOutput.expand((row) => row).length}');
    } catch (e) {
      debugPrint('TFLite inference error for profile face: $e');
      return false;
    }
    final profileEmbedding = profileOutput.expand((row) => row).toList();

    if (livenessEmbedding.length != profileEmbedding.length) {
      debugPrint('Embedding length mismatch');
      return false;
    }

    final similarity = cosineSimilarity(livenessEmbedding, profileEmbedding);
    debugPrint('Face similarity score: $similarity');
    return similarity > 0.5; // Adjust threshold as needed
  } catch (e) {
    debugPrint('Face comparison error: $e');
    return false;
  } finally {
    interpreter?.close();
  }
}

List<List<List<List<double>>>> preprocess(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes)!;
  final resized = img.copyResize(image, width: 112, height: 112);
  final bytes = resized.getBytes(order: img.ChannelOrder.rgb);

  final input = List.generate(
    1,
    (_) => List.generate(
      112,
      (_) => List.generate(
        112,
        (_) => List.generate(3, (_) => 0.0),
      ),
    ),
  );

  int idx = 0;
  for (int h = 0; h < 112; h++) {
    for (int w = 0; w < 112; w++) {
      input[0][h][w][0] = (bytes[idx++] / 127.5) - 1.0;
      input[0][h][w][1] = (bytes[idx++] / 127.5) - 1.0;
      input[0][h][w][2] = (bytes[idx++] / 127.5) - 1.0;
    }
  }
  return input;
}

double cosineSimilarity(List<double> a, List<double> b) {
  double dotProduct = 0.0, normA = 0.0, normB = 0.0;
  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
} */

// version 1
/* // In liveness_capture.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math' as math;

enum Challenge { initial, leftTurn, rightTurn, blink, center }

class LivenessCaptureScreen extends StatefulWidget {
  final Function(Uint8List?) onCaptureComplete;
  const LivenessCaptureScreen({super.key, required this.onCaptureComplete});

  @override
  State<LivenessCaptureScreen> createState() => _LivenessCaptureScreenState();
}

class _LivenessCaptureScreenState extends State<LivenessCaptureScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  FaceDetector? _faceDetector;
  Uint8List? modelBuffer;
  bool _isProcessing = false;
  Challenge _currentChallenge = Challenge.initial;
  bool _leftDone = false;
  bool _rightDone = false;
  bool _blinkDone = false;
  Timer? _challengeTimer;
  final int _timeoutSeconds = 15;
  bool _showPreview = true;
  bool _isInitializing = false;
  bool _isDisposed = false;
  bool _isCapturingFinalPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraAndModel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_isCapturingFinalPhoto) {
      _cleanupResources();
    } else if (state == AppLifecycleState.resumed && _cameraController == null && !_isDisposed) {
      _initializeCameraAndModel();
    }
  }

  Future<bool> _checkCameraPermission() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      debugPrint('Camera permission denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required for liveness check')),
        );
      }
      return false;
    }
    if (await Permission.camera.status.isPermanentlyDenied) {
      debugPrint('Camera permission permanently denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable camera permission in settings')),
        );
      }
      openAppSettings();
      return false;
    }

    if (Platform.isAndroid) {
      final permission = await _getStoragePermission();
      final storageStatus = await permission.request();
      if (!storageStatus.isGranted) {
        debugPrint('Storage/photos permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied. Images will not be saved to gallery, but liveness check can proceed.')),
          );
        }
      }
      if (await permission.isPermanentlyDenied) {
        debugPrint('Storage/photos permission permanently denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable storage/photos permission in settings to save images')),
          );
        }
        openAppSettings();
      }
    }
    return true;
  }

  Future<Permission> _getStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 33) {
        return Permission.photos;
      } else {
        return Permission.storage;
      }
    }
    return Permission.storage;
  }

  Future<void> _initializeCameraAndModel() async {
    if (_isInitializing || _isDisposed) {
      debugPrint('Initialization skipped: _isInitializing=$_isInitializing, _isDisposed=$_isDisposed');
      return;
    }
    setState(() => _isInitializing = true);
    try {
      if (!await _checkCameraPermission()) {
        widget.onCaptureComplete(null);
        setState(() => _isInitializing = false);
        return;
      }
      final cameras = await availableCameras();
      if (cameras.length < 2) {
        debugPrint('No front camera available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No front camera available')),
          );
        }
        widget.onCaptureComplete(null);
        setState(() => _isInitializing = false);
        return;
      }
      _cameraController = CameraController(cameras[1], ResolutionPreset.medium);
      debugPrint('Initializing camera...');
      await _cameraController?.initialize().catchError((e) {
        debugPrint('Camera initialization error: $e');
        throw e;
      });
      if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) {
        debugPrint('Camera initialization failed or widget unmounted');
        await _cleanupResources();
        widget.onCaptureComplete(null);
        setState(() => _isInitializing = false);
        return;
      }
      const modelPath = 'assets/models/mobilefacenet_liveness.tflite';
      _interpreter = await Interpreter.fromAsset(modelPath);
      _interpreter?.allocateTensors();
      debugPrint('Input shape: ${_interpreter?.getInputTensor(0).shape}');
      final modelData = await DefaultAssetBundle.of(context).load(modelPath);
      modelBuffer = modelData.buffer.asUint8List();
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableClassification: true,
          enableLandmarks: true,
        ),
      );
      await _cameraController!.startImageStream(_processCameraImage).catchError((e) {
        debugPrint('Error starting image stream: $e');
        throw e;
      });
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      debugPrint('Camera and model initialized successfully');
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera or model: $e')),
        );
      }
      widget.onCaptureComplete(null);
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _cleanupResources() async {
    if (_isDisposed || _isCapturingFinalPhoto) {
      debugPrint('Cleanup skipped: _isDisposed=$_isDisposed, _isCapturingFinalPhoto=$_isCapturingFinalPhoto');
      return;
    }
    try {
      debugPrint('Cleaning up resources...');
      _challengeTimer?.cancel();
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream().catchError((e) {
          debugPrint('Error stopping image stream: $e');
        });
      }
      if (_cameraController != null) {
        await _cameraController!.dispose().catchError((e) {
          debugPrint('Error disposing camera: $e');
        });
      }
      _interpreter?.close();
      _faceDetector?.close();
      debugPrint('Resources cleaned up successfully');
    } catch (e) {
      debugPrint('Cleanup error: $e');
    } finally {
      _cameraController = null;
      _interpreter = null;
      _faceDetector = null;
      _challengeTimer = null;
    }
  }

  void _startChallengeSequence() {
    if (_isDisposed || _cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Cannot start challenge: disposed or camera not initialized');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera is not ready. Please try again.')),
        );
      }
      widget.onCaptureComplete(null);
      return;
    }
    setState(() => _currentChallenge = Challenge.leftTurn);
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    _challengeTimer?.cancel();
    _challengeTimer = Timer(Duration(seconds: _timeoutSeconds), _handleTimeout);
  }

  void _handleTimeout() => _handleFailure();

  Future<void> _processCameraImage(CameraImage image) async {
  if (_isProcessing || _currentChallenge == Challenge.initial || _cameraController == null || _isDisposed) {
    debugPrint('Skipping image processing: _isProcessing=$_isProcessing, _currentChallenge=$_currentChallenge, _isDisposed=$_isDisposed');
    return;
  }
  _isProcessing = true;

  try {
    // Combine the bytes from all planes
    final bytesList = image.planes.map((plane) => plane.bytes).toList();
    final bytes = Uint8List.fromList(bytesList.expand((i) => i).toList());

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    final imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;

    final InputImageMetadata metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
    final faces = await _faceDetector!.processImage(inputImage);

    if (faces.isEmpty) {
      debugPrint('No faces detected in image');
      _isProcessing = false;
      return;
    }
    final face = faces.first;
    bool detected = false;

    switch (_currentChallenge) {
      case Challenge.leftTurn:
        if (face.headEulerAngleY! > 20) {
          detected = true;
          _leftDone = true;
          _currentChallenge = Challenge.rightTurn;
        }
        break;
      case Challenge.rightTurn:
        if (face.headEulerAngleY! < -20) {
          detected = true;
          _rightDone = true;
          _currentChallenge = Challenge.blink;
        }
        break;
      case Challenge.blink:
        if (face.leftEyeOpenProbability! < 0.3 && face.rightEyeOpenProbability! < 0.3) {
          detected = true;
          _blinkDone = true;
          _currentChallenge = Challenge.center;
        }
        break;
      case Challenge.center:
        if (face.headEulerAngleY!.abs() < 10 && face.headEulerAngleZ!.abs() < 10) {
          detected = true;
          await _captureFinalPhoto();
          return;
        }
        break;
      default:
        break;
    }

    if (detected) {
      _challengeTimer?.cancel();
      await _captureAndSaveFrame(face, image);
      _startTimeoutTimer();
      if (mounted) {
        setState(() {});
      }
    }
  } catch (e) {
    debugPrint('Camera image processing error: $e');
  } finally {
    _isProcessing = false;
  }
}

  Future<void> _captureAndSaveFrame(Face face, CameraImage cameraImage) async {
    if (_isDisposed || _cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Cannot capture frame: disposed or camera not initialized');
      return;
    }
    try {
      debugPrint('Capturing frame for ${_currentChallenge.name}');
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        debugPrint('No faces detected in captured frame');
        return;
      }
      final rect = faces.first.boundingBox;

      final imageBytes = await File(photo.path).readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        debugPrint('Failed to decode captured image');
        return;
      }

      final width = decodedImage.width;
      final height = decodedImage.height;
      final cropped = img.copyCrop(
        decodedImage,
        x: rect.left.toInt().clamp(0, width),
        y: rect.top.toInt().clamp(0, height),
        width: rect.width.toInt().clamp(0, width - rect.left.toInt()),
        height: rect.height.toInt().clamp(0, height - rect.top.toInt()),
      );
      final croppedBytes = img.encodePng(cropped);

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/liveness_${_currentChallenge.name}.png';
      await File(tempPath).writeAsBytes(croppedBytes);
      try {
        if (Platform.isAndroid) {
          final permission = await _getStoragePermission();
          if (await permission.isGranted) {
            await Gal.putImage(tempPath);
            debugPrint('Saved ${_currentChallenge.name} to gallery');
          } else {
            debugPrint('Skipped gallery save for ${_currentChallenge.name} due to missing permission');
          }
        } else {
          await Gal.putImage(tempPath);
          debugPrint('Saved ${_currentChallenge.name} to gallery');
        }
      } catch (e) {
        debugPrint('Gallery save error for ${_currentChallenge.name}: $e');
      }
    } catch (e) {
      debugPrint('Capture and save frame error: $e');
    }
  }

  Future<void> _captureFinalPhoto() async {
    if (_isDisposed || _cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Cannot capture final photo: disposed or camera not initialized');
      _handleFailure();
      return;
    }
    setState(() => _isCapturingFinalPhoto = true);
    try {
      debugPrint('Capturing final photo...');
      final XFile finalPhoto = await _cameraController!.takePicture();
      debugPrint('Final photo captured: ${finalPhoto.path}');
      final imageBytes = await File(finalPhoto.path).readAsBytes();
      final inputImage = InputImage.fromFilePath(finalPhoto.path);
      debugPrint('Processing face detection for final photo...');
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        debugPrint('No faces detected in final photo');
        _handleFailure();
        return;
      }
      final rect = faces.first.boundingBox;
      debugPrint('Face detected in final photo, bounding box: $rect');

      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        debugPrint('Failed to decode final photo');
        _handleFailure();
        return;
      }

      final width = decodedImage.width;
      final height = decodedImage.height;
      debugPrint('Final photo dimensions: ${width}x${height}');
      final cropped = img.copyCrop(
        decodedImage,
        x: rect.left.toInt().clamp(0, width),
        y: rect.top.toInt().clamp(0, height),
        width: rect.width.toInt().clamp(0, width - rect.left.toInt()),
        height: rect.height.toInt().clamp(0, height - rect.top.toInt()),
      );
      final croppedBytes = img.encodePng(cropped);
      debugPrint('Final photo cropped successfully');

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/liveness_final.png';
      await File(tempPath).writeAsBytes(croppedBytes);
      debugPrint('Final photo written to: $tempPath');
      try {
        if (Platform.isAndroid) {
          final permission = await _getStoragePermission();
          if (await permission.isGranted) {
            await Gal.putImage(tempPath);
            debugPrint('Final face saved to gallery');
          } else {
            debugPrint('Skipped gallery save for final photo due to missing permission');
          }
        } else {
          await Gal.putImage(tempPath);
          debugPrint('Final face saved to gallery');
        }
      } catch (e) {
        debugPrint('Gallery save error for final photo: $e');
      }

      if (!mounted || _isDisposed) {
        debugPrint('Widget unmounted or disposed before completing capture');
        widget.onCaptureComplete(null);
        return;
      }

      debugPrint('Completing liveness capture with cropped bytes');
      widget.onCaptureComplete(croppedBytes);
      await _cleanupResources();
    } catch (e) {
      debugPrint('Capture final photo error: $e');
      _handleFailure();
    } finally {
      setState(() => _isCapturingFinalPhoto = false);
    }
  }

  Future<void> _handleFailure() async {
    if (_isDisposed) {
      debugPrint('Handle failure skipped: already disposed');
      return;
    }
    try {
      await _cleanupResources();
      if (!mounted) {
        debugPrint('Widget unmounted during handle failure');
        widget.onCaptureComplete(null);
        return;
      }
      setState(() {
        _showPreview = false;
        _currentChallenge = Challenge.initial;
        _leftDone = false;
        _rightDone = false;
        _blinkDone = false;
      });
      final retry = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Liveness Check Failed'),
            content: const Text('We could not detect the required actions. Would you like to try again?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Try Again')),
            ],
          );
        },
      );
      if (retry == true && mounted && !_isDisposed) {
        await _initializeCameraAndModel();
        _startChallengeSequence();
      } else {
        widget.onCaptureComplete(null);
      }
    } catch (e) {
      debugPrint('Handle failure error: $e');
      widget.onCaptureComplete(null);
    }
  }

  String _getInstructionText() {
    switch (_currentChallenge) {
      case Challenge.leftTurn:
        return 'Turn your head to your left${_leftDone ? " ✓" : ""}';
      case Challenge.rightTurn:
        return 'Turn your head to your right${_rightDone ? " ✓" : ""}';
      case Challenge.blink:
        return 'Blink your eyes${_blinkDone ? " ✓" : ""}';
      case Challenge.center:
        return 'Center your face';
      default:
        return 'Position your face in the center';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    debugPrint('Disposing LivenessCaptureScreenState');
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing || _cameraController == null || !_cameraController!.value.isInitialized || _isDisposed) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_showPreview)
          AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 32),
            onPressed: () async {
              await _cleanupResources();
              widget.onCaptureComplete(null);
            },
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.all(16),
            child: Text(
              _getInstructionText(),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (_currentChallenge == Challenge.initial)
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: (_isInitializing || _isDisposed) ? null : _startChallengeSequence,
                child: const Text('Start Liveness Check'),
              ),
            ),
          ),
      ],
    );
  }
}

Future<bool> compareFaces(Uint8List livenessBytes, Uint8List profileBytes) async {
  Interpreter? interpreter;
  try {
    const modelPath = 'assets/models/mobilefacenet_liveness.tflite';
    interpreter = await Interpreter.fromAsset(modelPath);
    interpreter.allocateTensors();
    debugPrint('Loaded mobilefacenet_liveness.tflite successfully');
    debugPrint('Input shape: ${interpreter.getInputTensor(0).shape}');
    final outputShape = interpreter.getOutputTensor(0).shape;

    final livenessInput = preprocess(livenessBytes);
    final livenessOutput = List.generate(1, (_) => List.generate(outputShape[1], (_) => 0.0));
    try {
      interpreter.run(livenessInput, livenessOutput);
      debugPrint('Inference successful for liveness face, output length: ${livenessOutput.expand((row) => row).length}');
    } catch (e) {
      debugPrint('TFLite inference error for liveness face: $e');
      return false;
    }
    final livenessEmbedding = livenessOutput.expand((row) => row).toList();

    final profileInput = preprocess(profileBytes);
    final profileOutput = List.generate(1, (_) => List.generate(outputShape[1], (_) => 0.0));
    try {
      interpreter.run(profileInput, profileOutput);
      debugPrint('Inference successful for profile face, output length: ${profileOutput.expand((row) => row).length}');
    } catch (e) {
      debugPrint('TFLite inference error for profile face: $e');
      return false;
    }
    final profileEmbedding = profileOutput.expand((row) => row).toList();

    if (livenessEmbedding.length != profileEmbedding.length) {
      debugPrint('Embedding length mismatch');
      return false;
    }

    final similarity = cosineSimilarity(livenessEmbedding, profileEmbedding);
    debugPrint('Face similarity score: $similarity');
    return similarity > 0.5; // Adjust threshold as needed
  } catch (e) {
    debugPrint('Face comparison error: $e');
    return false;
  } finally {
    interpreter?.close();
  }
}

List<List<List<List<double>>>> preprocess(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes)!;
  final resized = img.copyResize(image, width: 112, height: 112);
  final bytes = resized.getBytes(order: img.ChannelOrder.rgb);

  final input = List.generate(
    1,
    (_) => List.generate(
      112,
      (_) => List.generate(
        112,
        (_) => List.generate(3, (_) => 0.0),
      ),
    ),
  );

  int idx = 0;
  for (int h = 0; h < 112; h++) {
    for (int w = 0; w < 112; w++) {
      input[0][h][w][0] = (bytes[idx++] / 127.5) - 1.0;
      input[0][h][w][1] = (bytes[idx++] / 127.5) - 1.0;
      input[0][h][w][2] = (bytes[idx++] / 127.5) - 1.0;
    }
  }
  return input;
}

double cosineSimilarity(List<double> a, List<double> b) {
  double dotProduct = 0.0, normA = 0.0, normB = 0.0;
  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
} */