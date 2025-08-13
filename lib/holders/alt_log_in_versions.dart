///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Dont delete the drivers license versions becuase that code can be used for client side user liveness testing  //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* version 1
// // import 'dart:convert';
// // import 'dart:typed_data';
// // import 'package:crypto/crypto.dart'; // For hashing
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart'; // For Firebase Firestore
// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart'; // For ID photo upload
// // import 'package:camera/camera.dart'; // For selfie capture (initialize in main.dart)

// // class LogIn extends StatefulWidget {
// //   final Function(int, [int?]) switchPage; // For after login/create
// //   final VoidCallback enterDemo; // NEW: For entering demo mode
// //   const LogIn({super.key, required this.switchPage, required this.enterDemo});

// //   @override
// //   State<LogIn> createState() => _LogInState();
// // }

// // class _LogInState extends State<LogIn> {
// //   final _emailController = TextEditingController();
// //   final _passwordController = TextEditingController();

// //   Future<void> _login() async {
// //     try {
// //       await FirebaseAuth.instance.signInWithEmailAndPassword(
// //         email: _emailController.text.trim(),
// //         password: _passwordController.text.trim(),
// //       );
// //       widget.switchPage(0); // Switch to database page on success
// //     } catch (e) {
// //       // Handle errors (e.g., show Snackbar: "Invalid credentials")
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
// //     }
// //   }

// //   void _showIdVerificationDialog() {
// //     showDialog(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return AlertDialog(
// //           title: const Text('ID Verification Required'),
// //           content: const Text('To create an account, we need to verify your ID. This includes uploading a photo ID and taking a selfie for matching.'),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.of(context).pop(),
// //               child: const Text('Cancel'),
// //             ),
// //             TextButton(
// //               onPressed: () async {
// //                 Navigator.of(context).pop();
// //                 await _performIdVerification();
// //               },
// //               child: const Text('Proceed'),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }

// //   Future<void> _performIdVerification() async {
// //     try {
// //       // Step 1: Upload photo ID (e.g., driver's license)
// //       final picker = ImagePicker();
// //       final idPhoto = await picker.pickImage(source: ImageSource.gallery); // Or camera
// //       if (idPhoto == null) return;

// //       // Step 2: Capture selfie
// //       // Assume cameras are initialized globally; use first camera for selfie
// //       final cameras = await availableCameras();
// //       final camera = cameras.first;
// //       // Placeholder for selfie capture (implement with camera plugin)
// //       // final selfieBytes = await captureSelfie(camera); // Implement this function
// //       Uint8List selfieBytes = Uint8List(0); // Replace with real data

// //       // Step 3: Send to verification API (e.g., iDenfy or Stripe)
// //       // Example with placeholder API call
// //       // final verificationResult = await verifyId(idPhoto.path, selfieBytes); // Implement API call
// //       // if (!verificationResult.isMatch) throw Exception('ID and selfie do not match');

// //       // Step 4: Extract license number via OCR (from API or ML Kit)
// //       // String licenseNumber = verificationResult.licenseNumber; // From API response
// //       String licenseNumber = 'EXTRACTED_LICENSE_NUMBER'; // Placeholder

// //       // Step 5: Hash the license number for uniqueness
// //       final hash = sha256.convert(utf8.encode(licenseNumber)).toString();

// //       // Step 6: Check Firebase for duplicate
// //       final firestore = FirebaseFirestore.instance;
// //       final doc = await firestore.collection('user_ids').doc(hash).get();
// //       if (doc.exists) {
// //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account already exists for this ID')));
// //         return;
// //       }

// //       // Step 7: Create account if unique
// //       await FirebaseAuth.instance.createUserWithEmailAndPassword(
// //         email: _emailController.text.trim(),
// //         password: _passwordController.text.trim(),
// //       );

// //       // Step 8: Store hash in Firebase
// //       await firestore.collection('user_ids').doc(hash).set({'created_at': Timestamp.now()});

// //       widget.switchPage(0); // Switch to database page
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
// //     }
// //   }
*/

/* version 2
// import 'dart:convert';
// import 'dart:io'; // Added for File class and Platform
// import 'dart:math'; // For distance calculation
// import 'dart:typed_data';
// import 'package:crypto/crypto.dart'; // For hashing
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // For Firebase Firestore
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // For ID photo upload/camera
// import 'package:camera/camera.dart'; // For selfie capture
// import 'package:image/image.dart' as img; // For cropping
// import 'package:tflite_flutter/tflite_flutter.dart'; // For MobileFaceNet/ArcFace
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'; // For DL# parsing
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:exif/exif.dart'; // For reading EXIF orientation

// class LogIn extends StatefulWidget {
//   final Function(int, [int?]) switchPage; // For after login/create
//   final VoidCallback enterDemo; // NEW: For entering demo mode
//   const LogIn({super.key, required this.switchPage, required this.enterDemo});

//   @override
//   State<LogIn> createState() => _LogInState();
// }

// class _LogInState extends State<LogIn> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   @override

//   void initState() {
//     super.initState();
//     _retrieveLostData(); // Recover from potential memory kills
//   }

//   Future<void> _retrieveLostData() async {
//     final picker = ImagePicker();
//     final LostDataResponse response = await picker.retrieveLostData();
//     if (response.isEmpty) {
//       return;
//     }
//     if (response.file != null) {
//       // Handle the recovered file (e.g., set as dlPhotoFile)
//       print('Recovered lost image: ${response.file?.path}');
//       // You can process it here if needed
//     } else if (response.exception != null) {
//       print('Lost data error: ${response.exception?.message}');
//     }
//   }

//   Future<void> _login() async {
//     try {
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//       widget.switchPage(0); // Switch to database page on success
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
//     }
//   }

//   void _showIdVerificationDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('ID Verification Required'),
//           content: const Text('To create an account, we need to verify your ID. This includes taking a photo of your DL and a selfie for matching.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await _performIdVerification();
//               },
//               child: const Text('Proceed'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _performIdVerification() async {
//     try {
//       // Step 1: Capture DL photo
//       final dlPhotoFile = await _captureDlPhoto();
//       if (dlPhotoFile == null) throw Exception('DL photo capture failed');

//       // Step 1.5: Crop face from DL
//       final croppedDlFace = await _cropDlFace(dlPhotoFile.path);
//       if (croppedDlFace == null) throw Exception('No face detected on DL');

//       // Step 2: Capture selfie with liveness
//       final selfieBytes = await _captureSelfieWithLiveness();
//       if (selfieBytes == null) throw Exception('Liveness check failed');

//       // Step 3: Match faces
//       final isMatch = await _compareFaces(croppedDlFace, selfieBytes);
//       if (!isMatch) throw Exception('Faces do not match');

//       // Step 4: Parse DL#
//       final parsedDlNumber = await _extractLicenseNumber(dlPhotoFile.path);
//       if (parsedDlNumber.isEmpty) throw Exception('Could not extract DL number');

//       // Step 5: Prompt manual entry
//       final enteredDlNumber = await _promptManualDlEntry(parsedDlNumber);
//       if (enteredDlNumber != parsedDlNumber) throw Exception('DL numbers do not match');

//       // Step 6: Hash and check Firebase
//       final hash = enteredDlNumber != null ? sha256.convert(utf8.encode(enteredDlNumber)).toString() : '';
//       final firestore = FirebaseFirestore.instance;
//       final doc = await firestore.collection('user_ids').doc(hash).get();
//       if (doc.exists) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account already exists for this ID')));
//         return;
//       }

//       // Step 7: Create account
//       await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//       await firestore.collection('user_ids').doc(hash).set({'created_at': Timestamp.now()});
//       widget.switchPage(0); // Switch to database page
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
//     }
//   }

//   Future<XFile?> _captureDlPhoto() async {
//     try {
//       final picker = ImagePicker();
//       // Limit resolution to reduce memory usage
//       final photo = await picker.pickImage(
//         source: ImageSource.camera,
//         maxWidth: 1280, // Reduce resolution
//         maxHeight: 720,
//         imageQuality: 85, // Compress image
//       );
//       if (photo == null) {
//         print('No photo captured');
//         return null;
//       }
//       final bytes = await photo.readAsBytes();
//       print('Captured photo size: ${bytes.length} bytes');
//       return photo;
//     } catch (e) {
//       print('Camera error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to capture photo: $e')),
//       );
//       return null;
//     }
//   }

//   Future<InputImage?> _createInputImageFromFile(String path) async {
//     try {
//       final fileBytes = await File(path).readAsBytes();
//       final exifData = await readExifFromBytes(fileBytes);

//       int orientation = 1;
//       if (exifData.containsKey('Image Orientation')) {
//         orientation = exifData['Image Orientation']!.values.firstAsInt();
//       }

//       InputImageRotation rotation;
//       switch (orientation) {
//         case 3:
//           rotation = InputImageRotation.rotation180deg;
//           break;
//         case 6:
//           rotation = InputImageRotation.rotation90deg;
//           break;
//         case 8:
//           rotation = InputImageRotation.rotation270deg;
//           break;
//         default:
//           rotation = InputImageRotation.rotation0deg;
//           break;
//       }

//       final image = img.decodeImage(fileBytes);
//       if (image == null) {
//         print('Failed to decode image');
//         return null;
//       }
//       final width = image.width;
//       final height = image.height;
//       final rgbaBytes = image.getBytes();
//       print('Width: $width, Height: $height, Bytes length: ${rgbaBytes.length}');
//       if (rgbaBytes.length != width * height * 4) {
//         print('Invalid RGBA bytes length');
//         return null;
//       }

//       Uint8List inputBytes;
//       InputImageFormat format;
//       int bytesPerRow;

//       if (Platform.isAndroid) {
//         inputBytes = _rgbToNv21(image, rgbaBytes, width, height);
//         format = InputImageFormat.nv21;
//         bytesPerRow = width;
//       } else {
//         inputBytes = Uint8List(rgbaBytes.length);
//         for (int i = 0; i < rgbaBytes.length; i += 4) {
//           inputBytes[i] = rgbaBytes[i + 2]; // B
//           inputBytes[i + 1] = rgbaBytes[i + 1]; // G
//           inputBytes[i + 2] = rgbaBytes[i]; // R
//           inputBytes[i + 3] = rgbaBytes[i + 3]; // A
//         }
//         format = InputImageFormat.bgra8888;
//         bytesPerRow = width * 4;
//       }

//       return InputImage.fromBytes(
//         bytes: inputBytes,
//         metadata: InputImageMetadata(
//           size: Size(width.toDouble(), height.toDouble()),
//           rotation: rotation,
//           format: format,
//           bytesPerRow: bytesPerRow,
//         ),
//       );
//     } catch (e) {
//       print('Error creating InputImage: $e');
//       return null;
//     }
//   }

//   Uint8List _rgbToNv21(img.Image image, Uint8List rgbaBytes, int width, int height) {
//     final ySize = width * height;
//     final uvSize = ((width + 1) ~/ 2) * ((height + 1) ~/ 2) * 2; // Use ceil to allocate enough
//     final nv21 = Uint8List(ySize + uvSize);

//     int yIndex = 0;
//     int uvIndex = ySize;
//     int pixelIndex = 0;

//     for (int j = 0; j < height; j++) {
//       for (int i = 0; i < width; i++) {
//         final r = rgbaBytes[pixelIndex++];
//         final g = rgbaBytes[pixelIndex++];
//         final b = rgbaBytes[pixelIndex++];
//         pixelIndex++; // Skip alpha

//         final y = (0.299 * r + 0.587 * g + 0.114 * b).toInt().clamp(0, 255);
//         nv21[yIndex++] = y;

//         if (j % 2 == 0 && i % 2 == 0 && j + 1 < height && i + 1 < width) {
//           final u = (-0.147 * r - 0.289 * g + 0.436 * b + 128).toInt().clamp(0, 255);
//           final v = (0.615 * r - 0.515 * g - 0.100 * b + 128).toInt().clamp(0, 255);
//           nv21[uvIndex++] = v;
//           nv21[uvIndex++] = u;
//         }
//       }
//     }
//     return nv21;
//   }

//   Future<Uint8List?> _cropDlFace(String path) async {
//     try {
//       final inputImage = await _createInputImageFromFile(path);
//       if (inputImage == null) return null;

//       // Initialize face detector
//       final faceDetector = FaceDetector(
//         options: FaceDetectorOptions(
//           enableLandmarks: false,
//           performanceMode: FaceDetectorMode.accurate,
//         ),
//       );

//       // Detect faces
//       final faces = await faceDetector.processImage(inputImage);
//       await faceDetector.close();

//       if (faces.isEmpty) {
//         print('No faces detected');
//         return null;
//       }

//       // Get first face's bounding box
//       final face = faces.first;
//       final rect = face.boundingBox;
//       print('Face bounding box: ${rect.left}, ${rect.top}, ${rect.width}, ${rect.height}');

//       // Load and decode the image for cropping
//       final dlImageBytes = await File(path).readAsBytes();
//       final image = img.decodeImage(dlImageBytes);
//       if (image == null) {
//         print('Failed to decode image');
//         return null;
//       }
//       final width = image.width;
//       final height = image.height;
//       print('Image dimensions: ${width}x${height}');

//       // Crop the face
//       final cropped = img.copyCrop(
//         image,
//         x: rect.left.toInt().clamp(0, width),
//         y: rect.top.toInt().clamp(0, height),
//         width: rect.width.toInt().clamp(0, width - rect.left.toInt()),
//         height: rect.height.toInt().clamp(0, height - rect.top.toInt()),
//       );

//       // Encode as PNG and save for debugging
//       final croppedBytes = img.encodePng(cropped);
//       await File('cropped_face.png').writeAsBytes(croppedBytes);
//       return croppedBytes;
//     } catch (e) {
//       print('Face cropping error: $e');
//       return null;
//     }
//   }

//   Future<String> _extractLicenseNumber(String path) async {
//     try {
//       final inputImage = await _createInputImageFromFile(path);
//       if (inputImage == null) return '';

//       // Initialize text recognizer
//       final textRecognizer = TextRecognizer();

//       // Process image for text recognition
//       final recognizedText = await textRecognizer.processImage(inputImage);
//       await textRecognizer.close();

//       // Extract DL number using regex
//       final dlRegex = RegExp(r'(?i)DL\s*(\d{8,10})');
//       final match = dlRegex.firstMatch(recognizedText.text);
//       return match?.group(1) ?? '';
//     } catch (e) {
//       print('Text recognition error: $e');
//       return '';
//     }
//   }

//   Future<Uint8List?> _captureSelfieWithLiveness() async {
//     try {
//       final cameras = await availableCameras();
//       final cameraController = CameraController(cameras[1], ResolutionPreset.high); // Front camera
//       await cameraController.initialize();
//       final interpreter = await Interpreter.fromAsset('mobilefacenet_liveness.tflite');
//       final faceDetector = FaceDetector(
//         options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
//       );

//       // Allocate output buffer
//       final outputShape = interpreter.getOutputTensor(0).shape;
//       final outputBuffer = Float32List(outputShape.reduce((a, b) => a * b));

//       final frames = <Uint8List>[];
//       final embeddings = <List<double>>[]; // To store embeddings for motion detection

//       for (int i = 0; i < 5; i++) {
//         final image = await cameraController.takePicture();
//         final inputImage = await _createInputImageFromFile(image.path);
//         if (inputImage == null) continue;
//         final faces = await faceDetector.processImage(inputImage);
//         if (faces.isEmpty) continue;

//         // Crop the first detected face
//         final face = faces.first;
//         final rect = face.boundingBox;
//         final imageBytes = await File(image.path).readAsBytes();
//         final decodedImage = img.decodeImage(imageBytes);
//         if (decodedImage == null) continue;
//         final width = decodedImage.width;
//         final height = decodedImage.height;
//         final cropped = img.copyCrop(
//           decodedImage,
//           x: rect.left.toInt().clamp(0, width),
//           y: rect.top.toInt().clamp(0, height),
//           width: rect.width.toInt().clamp(0, width - rect.left.toInt()),
//           height: rect.height.toInt().clamp(0, height - rect.top.toInt()),
//         );
//         final croppedBytes = img.encodePng(cropped);
//         frames.add(croppedBytes);

//         // Preprocess and run inference
//         final preprocessedImage = preprocess(croppedBytes); // Returns Float32List
//         interpreter.run(preprocessedImage, outputBuffer);
//         final embedding = outputBuffer.toList();
//         embeddings.add(embedding);

//         if (i > 0 && _detectMotion(frames[i - 1], frames[i], embeddings[i - 1], embeddings[i])) {
//           await cameraController.dispose();
//           interpreter.close();
//           await faceDetector.close();
//           return frames.last;
//         }
//         await Future.delayed(const Duration(milliseconds: 400));
//       }

//       await cameraController.dispose();
//       interpreter.close();
//       await faceDetector.close();
//       return null; // No liveness detected
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Liveness failed: $e')));
//       return null;
//     }
//   }
  
//   bool _detectMotion(Uint8List prevFrame, Uint8List currFrame, List<double> prevEmbedding, List<double> currEmbedding) {
//     // Compare embedding differences for motion (e.g., blink or head turn)
//     final distance = cosineSimilarity(prevEmbedding, currEmbedding); // Reuse cosine, but actually for difference, perhaps 1 - similarity > threshold
//     return distance < 0.9; // Adjust threshold; lower similarity means more change/motion
//   }

//   Float32List preprocess(Uint8List imageBytes) {
//     // Decode the image
//     final image = img.decodeImage(imageBytes)!;
    
//     // Resize to 112x112 (MobileFaceNet typically expects this size)
//     final resized = img.copyResize(image, width: 112, height: 112);
    
//     // Normalize to [0, 1] range and convert to Float32List (RGB only)
//     final input = Float32List(112 * 112 * 3);
//     final bytes = resized.getBytes(); // RGBA
//     int idx = 0;
//     for (int i = 0; i < bytes.length; i += 4) {
//       input[idx++] = bytes[i] / 255.0;     // R
//       input[idx++] = bytes[i + 1] / 255.0; // G
//       input[idx++] = bytes[i + 2] / 255.0; // B
//       // Skip alpha
//     }
    
//     return input;
//   }

//   Future<bool> _compareFaces(Uint8List dlFaceBytes, Uint8List selfieBytes) async {
//     try {
//       final interpreter = await Interpreter.fromAsset('arcface.tflite'); // Or mobilefacenet.tflite
      
//       // Allocate output buffer based on model output shape
//       final outputShape = interpreter.getOutputTensor(0).shape; // e.g., [1, 512]
//       final outputBuffer = Float32List(outputShape.reduce((a, b) => a * b));
      
//       // Preprocess and run inference for DL face
//       final dlInput = preprocess(dlFaceBytes); // Returns Float32List
//       interpreter.run(dlInput, outputBuffer);
//       final dlEmbedding = outputBuffer.toList(); // Copy to List<double>
      
//       // Preprocess and run inference for selfie
//       final selfieInput = preprocess(selfieBytes); // Returns Float32List
//       interpreter.run(selfieInput, outputBuffer); // Reuse buffer
//       final selfieEmbedding = outputBuffer.toList(); // Copy to List<double>
      
//       // Compute cosine similarity
//       double similarity = cosineSimilarity(dlEmbedding, selfieEmbedding);
      
//       interpreter.close();
//       return similarity > 0.6; // Adjust threshold based on testing
//     } catch (e) {
//       print('Face comparison error: $e');
//       return false;
//     }
//   }

//   double cosineSimilarity(List<double> a, List<double> b) {
//     double dotProduct = 0.0, normA = 0.0, normB = 0.0;
//     for (int i = 0; i < a.length; i++) {
//       dotProduct += a[i] * b[i];
//       normA += a[i] * a[i];
//       normB += b[i] * b[i];
//     }
//     return dotProduct / (sqrt(normA) * sqrt(normB));
//   }

//   Future<String?> _promptManualDlEntry(String parsedDlNumber) async {
//     final controller = TextEditingController();
//     return await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Enter DL Number'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(labelText: 'Enter the DL# from your license'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, controller.text.trim()),
//             child: const Text('Submit'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showDemoPopup() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Welcome to Integridate!', textAlign: TextAlign.center),
//           content: const Text(
//             'This is an app demo complete with fake accounts,\n\n'
//             'so you can see what makes Integridate different\n'
//             'from all the other dating apps\n\n'
//             'without having to create an account.\n\n'
//             'Would you like to enter the demo?',
//             textAlign: TextAlign.center,
//           ),
//           actionsAlignment: MainAxisAlignment.spaceBetween,
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Dismiss dialog
//                 widget.enterDemo(); // Enter demo mode
//               },
//               child: const Text('Yes'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Dismiss dialog
//               },
//               child: const Text('No'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 40.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               'Integridate',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 40),
//             TextField(
//               controller: _emailController,
//               keyboardType: TextInputType.emailAddress,
//               decoration: const InputDecoration(
//                 labelText: 'email',
//               ),
//               style: const TextStyle(color: Colors.white),
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 labelText: 'password',
//               ),
//               style: const TextStyle(color: Colors.white),
//             ),
//             const SizedBox(height: 40),
//             TextButton(
//               onPressed: _login,
//               style: TextButton.styleFrom(
//                 backgroundColor: Colors.transparent,
//                 side: const BorderSide(color: Colors.white),
//                 shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.zero,
//                 ),
//               ),
//               child: const Text(
//                 'log in',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//             const SizedBox(height: 10),
//             TextButton(
//               onPressed: _showIdVerificationDialog,
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.transparent,
//               ),
//               child: const Text('create account'),
//             ),
//             const SizedBox(height: 10),
//             TextButton(
//               onPressed: _showDemoPopup,
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.transparent,
//               ),
//               child: const Text('try demo'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
*/

/* // import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
// import 'dart:typed_data';
// import 'package:crypto/crypto.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:camera/camera.dart';
// import 'package:image/image.dart' as img;
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:device_info_plus/device_info_plus.dart'; // For Android version check

// class LogIn extends StatefulWidget {
//   final Function(int, [int?]) switchPage;
//   final VoidCallback enterDemo;
//   const LogIn({super.key, required this.switchPage, required this.enterDemo});

//   @override
//   State<LogIn> createState() => _LogInState();
// }

// class _LogInState extends State<LogIn> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _retrieveLostData();
//   }

//   Future<void> _retrieveLostData() async {
//     final picker = ImagePicker();
//     final LostDataResponse response = await picker.retrieveLostData();
//     if (response.isEmpty) {
//       return;
//     }
//     if (response.file != null) {
//       print('Recovered lost image: ${response.file?.path}');
//     } else if (response.exception != null) {
//       print('Lost data error: ${response.exception?.message}');
//     }
//   }

//   Future<void> _login() async {
//     try {
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//       widget.switchPage(0);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
//     }
//   }

//   void _showIdVerificationDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('ID Verification Required'),
//           content: const Text('To create an account, we need to verify your ID. This includes taking a photo of your DL and a selfie for matching.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await _performIdVerification();
//               },
//               child: const Text('Proceed'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _performIdVerification() async {
//     try {
//       final dlPhotoFile = await _captureDlPhoto();
//       if (dlPhotoFile == null) throw Exception('DL photo capture failed');

//       final croppedDlFace = await isolateCropDlFace(dlPhotoFile.path);
//       if (croppedDlFace == null) throw Exception('No face detected on DL');

//       await Future.delayed(const Duration(milliseconds: 500));

//       final selfieBytes = await _captureSelfieWithLiveness();
//       if (selfieBytes == null) throw Exception('Liveness check failed');

//       final isMatch = await _compareFaces(croppedDlFace, selfieBytes);
//       if (!isMatch) throw Exception('Faces do not match');

//       final parsedDlNumber = await _extractLicenseNumber(dlPhotoFile.path);
//       if (parsedDlNumber.isEmpty) throw Exception('Could not extract DL number');

//       final enteredDlNumber = await _promptManualDlEntry(parsedDlNumber);
//       if (enteredDlNumber != parsedDlNumber) throw Exception('DL numbers do not match');

//       final hash = enteredDlNumber != null ? sha256.convert(utf8.encode(enteredDlNumber)).toString() : '';
//       final firestore = FirebaseFirestore.instance;
//       final doc = await firestore.collection('user_ids').doc(hash).get();
//       if (doc.exists) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account already exists for this ID')));
//         return;
//       }

//       await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//       await firestore.collection('user_ids').doc(hash).set({'created_at': Timestamp.now()});
//       widget.switchPage(0);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
//     }
//   }

//   Future<XFile?> _captureDlPhoto() async {
//     try {
//       // Check Android version for storage permission
//       bool needStoragePermission = false;
//       if (Platform.isAndroid) {
//         final deviceInfo = DeviceInfoPlugin();
//         final androidInfo = await deviceInfo.androidInfo;
//         needStoragePermission = androidInfo.version.sdkInt <= 32; // Android 12 or lower
//       }

//       final cameraStatus = await Permission.camera.request();
//       PermissionStatus? storageStatus;
//       if (needStoragePermission) {
//         storageStatus = await Permission.storage.request();
//       } else {
//         storageStatus = PermissionStatus.granted; // Skip storage permission on Android 13+
//       }

//       print('Camera permission status: $cameraStatus');
//       print('Storage permission status: $storageStatus');

//       if (!cameraStatus.isGranted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Camera permission denied. Please enable it in settings.')),
//         );
//         return null;
//       }
//       if (needStoragePermission && !storageStatus.isGranted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Storage permission denied. Please enable it in settings.')),
//         );
//         return null;
//       }

//       final picker = ImagePicker();
//       final photo = await picker.pickImage(
//         source: ImageSource.camera,
//         maxWidth: 1280,
//         maxHeight: 720,
//         imageQuality: 85,
//       );
//       if (photo == null) {
//         print('No photo captured');
//         return null;
//       }
//       final bytes = await photo.readAsBytes();
//       print('Captured photo size: ${bytes.length} bytes');
//       return photo;
//     } catch (e) {
//       print('Camera error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to capture photo: $e')),
//       );
//       return null;
//     }
//   }

//   Future<Uint8List?> isolateCropDlFace(String path) async {
//     try {
//       final inputImage = InputImage.fromFilePath(path);
//       final faceDetector = FaceDetector(
//         options: FaceDetectorOptions(
//           enableLandmarks: false,
//           performanceMode: FaceDetectorMode.fast,
//         ),
//       );
//       final faces = await faceDetector.processImage(inputImage);
//       await faceDetector.close();

//       if (faces.isEmpty) {
//         print('No faces detected');
//         return null;
//       }

//       final face = faces.first;
//       final rect = face.boundingBox;

//       final tempDir = (await getTemporaryDirectory()).path;
//       final croppedImagePath = '$tempDir/cropped_face.png';

//       final cropData = {
//         'path': path,
//         'left': rect.left.toInt(),
//         'top': rect.top.toInt(),
//         'width': rect.width.toInt(),
//         'height': rect.height.toInt(),
//         'outputPath': croppedImagePath,
//       };

//       return await compute(_cropDlFaceIsolate, cropData);
//     } catch (e) {
//       print('Isolate error: $e');
//       return null;
//     }
//   }

//   /* // Future<Uint8List?> _captureSelfieWithLiveness() async {
//   //   try {
//   //     bool needStoragePermission = false;
//   //     if (Platform.isAndroid) {
//   //       final deviceInfo = DeviceInfoPlugin();
//   //       final androidInfo = await deviceInfo.androidInfo;
//   //       needStoragePermission = androidInfo.version.sdkInt <= 32;
//   //     }

//   //     final cameraStatus = await Permission.camera.request();
//   //     PermissionStatus? storageStatus;
//   //     if (needStoragePermission) {
//   //       storageStatus = await Permission.storage.request();
//   //     } else {
//   //       storageStatus = PermissionStatus.granted;
//   //     }

//   //     print('Selfie camera permission status: $cameraStatus');
//   //     print('Selfie storage permission status: $storageStatus');

//   //     if (!cameraStatus.isGranted) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(content: Text('Camera permission denied for selfie. Please enable it in settings.')),
//   //       );
//   //       return null;
//   //     }
//   //     if (needStoragePermission && !storageStatus.isGranted) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(content: Text('Storage permission denied for selfie. Please enable it in settings.')),
//   //       );
//   //       return null;
//   //     }

//   //     final cameras = await availableCameras();
//   //     final cameraController = CameraController(cameras[1], ResolutionPreset.medium);
//   //     await cameraController.initialize();
//   //     final interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet_liveness.tflite');
//   //     final faceDetector = FaceDetector(
//   //       options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
//   //     );

//   //     final outputShape = interpreter.getOutputTensor(0).shape;
//   //     final outputBuffer = Float32List(outputShape.reduce((a, b) => a * b));

//   //     final frames = <Uint8List>[];
//   //     final embeddings = <List<double>>[];

//   //     for (int i = 0; i < 5; i++) {
//   //       final image = await cameraController.takePicture();
//   //       final inputImage = InputImage.fromFilePath(image.path);
//   //       final faces = await faceDetector.processImage(inputImage);
//   //       if (faces.isEmpty) continue;

//   //       final face = faces.first;
//   //       final rect = face.boundingBox;
//   //       final imageBytes = await image.readAsBytes();
//   //       final decodedImage = img.decodeImage(imageBytes);
//   //       if (decodedImage == null) continue;
//   //       final width = decodedImage.width;
//   //       final height = decodedImage.height;
//   //       final cropped = img.copyCrop(
//   //         decodedImage,
//   //         x: rect.left.toInt().clamp(0, width),
//   //         y: rect.top.toInt().clamp(0, height),
//   //         width: rect.width.toInt().clamp(0, width - rect.left.toInt()),
//   //         height: rect.height.toInt().clamp(0, height - rect.top.toInt()),
//   //       );
//   //       final croppedBytes = img.encodePng(cropped);
//   //       frames.add(croppedBytes);

//   //       final embedding = await compute(_runTFLiteInference, {
//   //         'imageBytes': croppedBytes,
//   //         'interpreterAddress': interpreter.address,
//   //         'outputShape': outputShape,
//   //       });
//   //       if (embedding == null) continue;
//   //       embeddings.add(embedding);

//   //       if (i > 0 && _detectMotion(frames[i - 1], frames[i], embeddings[i - 1], embeddings[i])) {
//   //         await cameraController.dispose();
//   //         interpreter.close();
//   //         await faceDetector.close();
//   //         return frames.last;
//   //       }
//   //       await Future.delayed(const Duration(milliseconds: 400));
//   //     }

//   //     await cameraController.dispose();
//   //     interpreter.close();
//   //     await faceDetector.close();
//   //     return null;
//   //   } catch (e) {
//   //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Liveness failed: $e')));
//   //     return null;
//   //   }
//   // } */

//   Future<Uint8List?> _captureSelfieWithLiveness() async {
//   CameraController? cameraController;
//   Interpreter? interpreter;
//   FaceDetector? faceDetector;
//   try {
//     bool needStoragePermission = false;
//     if (Platform.isAndroid) {
//       final deviceInfo = DeviceInfoPlugin();
//       final androidInfo = await deviceInfo.androidInfo;
//       needStoragePermission = androidInfo.version.sdkInt <= 32;
//     }

//     final cameraStatus = await Permission.camera.request();
//     PermissionStatus? storageStatus;
//     if (needStoragePermission) {
//       storageStatus = await Permission.storage.request();
//     } else {
//       storageStatus = PermissionStatus.granted;
//     }

//     print('Selfie camera permission status: $cameraStatus');
//     print('Selfie storage permission status: $storageStatus');

//     if (!cameraStatus.isGranted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Camera permission denied for selfie. Please enable it in settings.')),
//       );
//       return null;
//     }
//     if (needStoragePermission && !storageStatus.isGranted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Storage permission denied for selfie. Please enable it in settings.')),
//       );
//       return null;
//     }

//     final cameras = await availableCameras();
//     if (cameras.length < 2) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No front camera available')),
//       );
//       return null;
//     }

//     cameraController = CameraController(cameras[1], ResolutionPreset.medium);
//     try {
//       await cameraController.initialize();
//       print('Camera initialized successfully');
//     } catch (e) {
//       print('Camera initialization error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to initialize camera: $e')),
//       );
//       return null;
//     }

//     final modelPath = 'assets/models/mobilefacenet_liveness.tflite';
//     try {
//       await DefaultAssetBundle.of(context).load(modelPath);
//       print('Model file exists: $modelPath');
//     } catch (e) {
//       print('Model file not found: $modelPath, error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Model file not found: $modelPath')),
//       );
//       return null;
//     }

//     try {
//       interpreter = await Interpreter.fromAsset(modelPath);
//       print('Loaded mobilefacenet_liveness.tflite successfully');
//     } catch (e) {
//       print('Failed to load TFLite model mobilefacenet_liveness.tflite: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load liveness model: $e')),
//       );
//       return null;
//     }

//     faceDetector = FaceDetector(
//       options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
//     );

//     final outputShape = interpreter.getOutputTensor(0).shape;
//     final outputBuffer = Float32List(outputShape.reduce((a, b) => a * b));

//     final frames = <Uint8List>[];
//     final embeddings = <List<double>>[];

//     for (int i = 0; i < 3; i++) {
//       final image = await cameraController.takePicture();
//       final inputImage = InputImage.fromFilePath(image.path);
//       final faces = await faceDetector.processImage(inputImage);
//       if (faces.isEmpty) continue;

//       final face = faces.first;
//       final rect = face.boundingBox;
//       final imageBytes = await image.readAsBytes();
//       final decodedImage = img.decodeImage(imageBytes);
//       if (decodedImage == null) continue;
//       final width = decodedImage.width;
//       final height = decodedImage.height;
//       final cropped = img.copyCrop(
//         decodedImage,
//         x: rect.left.toInt().clamp(0, width),
//         y: rect.top.toInt().clamp(0, height),
//         width: rect.width.toInt().clamp(0, width - rect.left.toInt()),
//         height: rect.height.toInt().clamp(0, height - rect.top.toInt()),
//       );
//       final croppedBytes = img.encodePng(cropped);
//       frames.add(croppedBytes);

//       final embedding = await compute(_runTFLiteInference, {
//         'imageBytes': croppedBytes,
//         'interpreterAddress': interpreter.address,
//         'outputShape': outputShape,
//       });
//       if (embedding == null) continue;
//       embeddings.add(embedding);

//       if (i > 0 && _detectMotion(frames[i - 1], frames[i], embeddings[i - 1], embeddings[i])) {
//         await cameraController.dispose();
//         interpreter.close();
//         await faceDetector.close();
//         return frames.last;
//       }
//       await Future.delayed(const Duration(milliseconds: 400));
//     }

//     await cameraController.dispose();
//     interpreter.close();
//     await faceDetector.close();
//     return null;
//   } catch (e) {
//     print('Liveness check error: $e');
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Liveness failed: $e')));
//     await cameraController?.dispose();
//     interpreter?.close();
//     faceDetector?.close();
//     return null;
//   }
// }

//   bool _detectMotion(Uint8List prevFrame, Uint8List currFrame, List<double> prevEmbedding, List<double> currEmbedding) {
//     final distance = cosineSimilarity(prevEmbedding, currEmbedding);
//     return distance < 0.9;
//   }

//   /* // Future<bool> _compareFaces(Uint8List dlFaceBytes, Uint8List selfieBytes) async {
//   //   try {
//   //     final interpreter = await Interpreter.fromAsset('arcface.tflite');
//   //     final outputShape = interpreter.getOutputTensor(0).shape;
//   //     final outputBuffer = Float32List(outputShape.reduce((a, b) => a * b));
//   //     final dlInput = preprocess(dlFaceBytes);
//   //     interpreter.run(dlInput, outputBuffer);
//   //     final dlEmbedding = outputBuffer.toList();
//   //     final selfieInput = preprocess(selfieBytes);
//   //     interpreter.run(selfieInput, outputBuffer);
//   //     final selfieEmbedding = outputBuffer.toList();
//   //     double similarity = cosineSimilarity(dlEmbedding, selfieEmbedding);
//   //     interpreter.close();
//   //     return similarity > 0.6;
//   //   } catch (e) {
//   //     print('Face comparison error: $e');
//   //     return false;
//   //   }
//   // } */

//   Future<bool> _compareFaces(Uint8List dlFaceBytes, Uint8List selfieBytes) async {
//   Interpreter? interpreter;
//     try {
//       final modelPath = 'assets/models/arcface.tflite';
//       try {
//         await DefaultAssetBundle.of(context).load(modelPath);
//         print('Model file exists: $modelPath');
//       } catch (e) {
//         print('Model file not found: $modelPath, error: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Model file not found: $modelPath')),
//         );
//         return false;
//       }

//       try {
//         interpreter = await Interpreter.fromAsset(modelPath);
//         print('Loaded arcface.tflite successfully');
//       } catch (e) {
//         print('Failed to load TFLite model arcface.tflite: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load face comparison model: $e')),
//         );
//         return false;
//       }

//       final outputShape = interpreter.getOutputTensor(0).shape;
//       final outputBuffer = Float32List(outputShape.reduce((a, b) => a * b));

//       final dlInput = preprocess(dlFaceBytes);
//       try {
//         interpreter.run(dlInput, outputBuffer);
//         print('Inference successful for DL face, output length: ${outputBuffer.length}');
//       } catch (e) {
//         print('TFLite inference error for DL face: $e');
//         interpreter.close();
//         return false;
//       }
//       final dlEmbedding = outputBuffer.toList();

//       final selfieInput = preprocess(selfieBytes);
//       try {
//         interpreter.run(selfieInput, outputBuffer);
//         print('Inference successful for selfie, output length: ${outputBuffer.length}');
//       } catch (e) {
//         print('TFLite inference error for selfie: $e');
//         interpreter.close();
//         return false;
//       }
//       final selfieEmbedding = outputBuffer.toList();

//       double similarity = cosineSimilarity(dlEmbedding, selfieEmbedding);
//       interpreter.close();
//       return similarity > 0.6;
//     } catch (e) {
//       print('Face comparison error: $e');
//       interpreter?.close();
//       return false;
//     }
//   }

//   double cosineSimilarity(List<double> a, List<double> b) {
//     double dotProduct = 0.0, normA = 0.0, normB = 0.0;
//     for (int i = 0; i < a.length; i++) {
//       dotProduct += a[i] * b[i];
//       normA += a[i] * a[i];
//       normB += b[i] * b[i];
//     }
//     return dotProduct / (sqrt(normA) * sqrt(normB));
//   }

//   Future<String> _extractLicenseNumber(String path) async {
//     try {
//       final inputImage = InputImage.fromFilePath(path);
//       final textRecognizer = TextRecognizer();
//       final recognizedText = await textRecognizer.processImage(inputImage);
//       await textRecognizer.close();
//       final dlRegex = RegExp(r'(?i)DL\s*(\d{8,10})');
//       final match = dlRegex.firstMatch(recognizedText.text);
//       return match?.group(1) ?? '';
//     } catch (e) {
//       print('Text recognition error: $e');
//       return '';
//     }
//   }

//   Future<String?> _promptManualDlEntry(String parsedDlNumber) async {
//     final controller = TextEditingController();
//     return await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Enter DL Number'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(labelText: 'Enter the DL# from your license'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, controller.text.trim()),
//             child: const Text('Submit'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showDemoPopup() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Welcome to Integridate!', textAlign: TextAlign.center),
//           content: const Text(
//             'This is an app demo complete with fake accounts,\n\n'
//             'so you can see what makes Integridate different\n'
//             'from all the other dating apps\n\n'
//             'without having to create an account.\n\n'
//             'Would you like to enter the demo?',
//             textAlign: TextAlign.center,
//           ),
//           actionsAlignment: MainAxisAlignment.spaceBetween,
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 widget.enterDemo();
//               },
//               child: const Text('Yes'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('No'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 40.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               'Integridate',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 40),
//             TextField(
//               controller: _emailController,
//               keyboardType: TextInputType.emailAddress,
//               decoration: const InputDecoration(
//                 labelText: 'email',
//               ),
//               style: const TextStyle(color: Colors.white),
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 labelText: 'password',
//               ),
//               style: const TextStyle(color: Colors.white),
//             ),
//             const SizedBox(height: 40),
//             TextButton(
//               onPressed: _login,
//               style: TextButton.styleFrom(
//                 backgroundColor: Colors.transparent,
//                 side: const BorderSide(color: Colors.white),
//                 shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.zero,
//                 ),
//               ),
//               child: const Text(
//                 'log in',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//             const SizedBox(height: 10),
//             TextButton(
//               onPressed: _showIdVerificationDialog,
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.transparent,
//               ),
//               child: const Text('create account'),
//             ),
//             const SizedBox(height: 10),
//             TextButton(
//               onPressed: _showDemoPopup,
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.transparent,
//               ),
//               child: const Text('try demo'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// Float32List preprocess(Uint8List imageBytes) {
//   final image = img.decodeImage(imageBytes)!;
//   final resized = img.copyResize(image, width: 112, height: 112);
//   final input = Float32List(112 * 112 * 3);
//   final bytes = resized.getBytes();
//   int idx = 0;
//   for (int i = 0; i < bytes.length; i += 4) {
//     input[idx++] = bytes[i] / 255.0;
//     input[idx++] = bytes[i + 1] / 255.0;
//     input[idx++] = bytes[i + 2] / 255.0;
//   }
//   return input;
// }

// // Uint8List? _cropDlFaceIsolate(Map<String, dynamic> cropData) {
// //   try {
// //     final path = cropData['path'] as String;
// //     final left = cropData['left'] as int;
// //     final top = cropData['top'] as int;
// //     final width = cropData['width'] as int;
// //     final height = cropData['height'] as int;
// //     final outputPath = cropData['outputPath'] as String;

// //     final dlImageBytes = File(path).readAsBytesSync();
// //     final image = img.decodeImage(dlImageBytes);
// //     if (image == null) {
// //       print('Failed to decode image');
// //       return null;
// //     }
// //     final imgWidth = image.width;
// //     final imgHeight = image.height;
// //     print('Image dimensions: ${imgWidth}x${imgHeight}');

// //     final cropped = img.copyCrop(
// //       image,
// //       x: left.clamp(0, imgWidth),
// //       y: top.clamp(0, imgHeight),
// //       width: width.clamp(0, imgWidth - left),
// //       height: height.clamp(0, imgHeight - top),
// //     );

// //     final croppedBytes = img.encodePng(cropped);
// //     File(outputPath).writeAsBytesSync(croppedBytes);
    
// //     return croppedBytes;
// //   } catch (e) {
// //     print('Face cropping error in isolate: $e');
// //     return null;
// //   }
// // }

// Uint8List? _cropDlFaceIsolate(Map<String, dynamic> cropData) {
//   try {
//     final path = cropData['path'] as String;
//     final left = cropData['left'] as int;
//     final top = cropData['top'] as int;
//     final width = cropData['width'] as int;
//     final height = cropData['height'] as int;

//     // Get the documents directory synchronously for debugging
//     final docsDir = Directory.systemTemp; // Fallback to temp dir for sync access
//     final outputPath = '${docsDir.path}/assets/cropped_face.png'; // Save as assets/cropped_face.png

//     final dlImageBytes = File(path).readAsBytesSync();
//     final image = img.decodeImage(dlImageBytes);

//     if (image == null) {
//       print('Failed to decode image');
//       return null;
//     }

//     final imgWidth = image.width;
//     final imgHeight = image.height;
//     print('Image dimensions: ${imgWidth}x${imgHeight}');

//     final cropped = img.copyCrop(
//       image,
//       x: left.clamp(0, imgWidth),
//       y: top.clamp(0, imgHeight),
//       width: width.clamp(0, imgWidth - left),
//       height: height.clamp(0, imgHeight - top),
//     );

//     final croppedBytes = img.encodePng(cropped);
//     // Create the assets directory if it doesn't exist
//     Directory('${docsDir.path}/assets').createSync(recursive: true);
//     File(outputPath).writeAsBytesSync(croppedBytes);

//     print('Cropped face saved for debugging at: $outputPath');
//     return croppedBytes;
//   } catch (e) {
//     print('Face cropping error in isolate: $e');
//     return null;
//   }
// }

// List<double>? _runTFLiteInference(Map<String, dynamic> data) {
//   try {
//     final imageBytes = data['imageBytes'] as Uint8List;
//     final interpreterAddress = data['interpreterAddress'] as int;
//     final outputShape = data['outputShape'] as List<int>;

//     final interpreter = Interpreter.fromAddress(interpreterAddress);
//     final input = preprocess(imageBytes);
//     final outputBuffer = Float32List(outputShape.reduce((a, b) => a * b));
//     interpreter.run(input, outputBuffer);
//     return outputBuffer.toList();
//   } catch (e) {
//     print('TFLite inference error in isolate: $e');
//     return null;
//   }
// }
 */

// version 4
/* import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Keep for gallery if needed elsewhere, but not used for camera now
import 'package:camera/camera.dart'; // NEW: Add this import
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart'; // For Android version check
import 'package:gal/gal.dart'; // For saving to gallery
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';

enum Challenge { initial, leftTurn, rightTurn, blink, center }

class LogIn extends StatefulWidget {
  final Function(int, [int?]) switchPage;
  final VoidCallback enterDemo;
  const LogIn({super.key, required this.switchPage, required this.enterDemo});
  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _retrieveLostData();
    }
  }
  Future<void> _retrieveLostData() async {
    final picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      print('Recovered lost image: ${response.file?.path}');
    } else if (response.exception != null) {
      print('Lost data error: ${response.exception?.message}');
    }
  }
  
  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      widget.switchPage(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }
  
  void _showIdVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ID Verification Required'),
          content: const Text('To create an account, we need to verify your ID. This includes taking a photo of your DL and a selfie for matching.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performIdVerification();
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }
  
  /* Future<void> _performIdVerification() async {
    try {
      final dlPhotoFile = await showDialog<XFile?>(
        context: context,
        builder: (context) => DlCaptureScreen(
          onCaptureComplete: (file) {
            Navigator.pop(context, file);
          },
        ),
      );

      if (dlPhotoFile == null) throw Exception('DL photo capture failed');
      final croppedDlFace = await isolateCropDlFace(dlPhotoFile.path);

      if (croppedDlFace == null) throw Exception('No face detected on DL');
      await Future.delayed(const Duration(milliseconds: 500));
     
      final selfieBytes = await showDialog<Uint8List>(
        context: context,
        builder: (context) => LivenessCaptureScreen(
          onCaptureComplete: (bytes) {
            Navigator.pop(context, bytes);
          },
        ),
      );

      if (selfieBytes == null) throw Exception('Liveness check failed');

      final isMatch = await _compareFaces(croppedDlFace, selfieBytes);
      if (!isMatch) throw Exception('Faces do not match');

      final parsedDlNumber = await _extractLicenseNumber(dlPhotoFile.path);
      if (parsedDlNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not extract DL number automatically. Please enter manually.')));
      }

      final enteredDlNumber = await _promptManualDlEntry(parsedDlNumber);
      if (enteredDlNumber != parsedDlNumber && parsedDlNumber.isNotEmpty) {
        // Optional: Add fuzzy matching here if desired, e.g., Levenshtein distance
        throw Exception('DL numbers do not match');
      }

      final hash = enteredDlNumber != null ? sha256.convert(utf8.encode('salt$enteredDlNumber')).toString() : '';
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('user_ids').doc(hash).get();
      if (doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account already exists for this ID')));
        return;
      }
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await firestore.collection('user_ids').doc(hash).set({'created_at': Timestamp.now()});
      widget.switchPage(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    }
  } */

  Future<void> _performIdVerification() async {
    try {
      final dlPhotoFile = await showDialog<XFile?>(
        context: context,
        builder: (context) => DlCaptureScreen(
          onCaptureComplete: (file) {
            Navigator.pop(context, file);
          },
        ),
      );

      if (dlPhotoFile == null) throw Exception('DL photo capture failed');

      // Extract DL number BEFORE cropping/face matching or closing camera
      final dlData = await _extractLicenseNumber(dlPhotoFile.path);
      final String parsedDlNumber = dlData['dlNumber'] ?? '';
      final String fullText = dlData['fullText'] ?? '';

      bool confirmed = false;
      
      if (parsedDlNumber.isEmpty) {
        String message = 'Could not extract DL number automatically.';
        if (fullText.isNotEmpty) {
          message += '\nRecognized text: $fullText';
        }

        message += '\nWould you like to retry capturing the photo?';
        final retry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Extraction Failed'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
        if (retry == true) {
          return _performIdVerification(); // Retry capture
        } else {
          throw Exception('DL number extraction failed');
        }
      } else {
        String message = 'We extracted this DL number: $parsedDlNumber';
        if (fullText.isNotEmpty) {
          message += '\nFull recognized text: $fullText';
        }
        message += '\nIs this correct?';
        confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verify DL Number'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ?? false;
        if (!confirmed) {
          throw Exception('DL number incorrect, please retry photo');
        }
      }

      // Now proceed with face cropping/matching (crash-prone part) AFTER dialog
      final croppedDlFace = await isolateCropDlFace(dlPhotoFile.path);
      if (croppedDlFace == null) throw Exception('No face detected on DL');
      await Future.delayed(const Duration(milliseconds: 500));

      final selfieBytes = await showDialog<Uint8List>(
        context: context,
        builder: (context) => LivenessCaptureScreen(
          onCaptureComplete: (bytes) {
            Navigator.pop(context, bytes);
          },
        ),
      );

      if (selfieBytes == null) throw Exception('Liveness check failed');

      final isMatch = await _compareFaces(croppedDlFace, selfieBytes);
      if (!isMatch) throw Exception('Faces do not match');

      final hash = sha256.convert(utf8.encode('salt$parsedDlNumber')).toString();
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('user_ids').doc(hash).get();
      if (doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account already exists for this ID')));
        return;
      }
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await firestore.collection('user_ids').doc(hash).set({'created_at': Timestamp.now()});
      widget.switchPage(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    }
  }

  Future<Uint8List?> isolateCropDlFace(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();
      if (faces.isEmpty) {
        print('No faces detected');
        return null;
      }
      final face = faces.first;
      final rect = face.boundingBox;
      final docsDir = await getApplicationDocumentsDirectory(); // Use documents dir for persistence
      final croppedImagePath = '${docsDir.path}/cropped_face.png';
      final cropData = {
        'path': path,
        'left': rect.left.toInt(),
        'top': rect.top.toInt(),
        'width': rect.width.toInt(),
        'height': rect.height.toInt(),
        'outputPath': croppedImagePath,
      };
      final croppedBytes = await compute(_cropDlFaceIsolate, cropData);
      if (croppedBytes != null) {
        try {
          final tempDir = await getTemporaryDirectory();
          final tempPath = '${tempDir.path}/temp_cropped.png';
          await File(tempPath).writeAsBytes(croppedBytes);
          await Gal.putImage(tempPath); // Saves to gallery; handles permissions internally if needed
          print('Cropped face saved to gallery');
        } catch (e) {
          print('Gallery save error: $e');
        }
      }
      return croppedBytes;
    } catch (e) {
      print('Isolate error: $e');
      return null;
    }
  }
  
  Future<bool> _compareFaces(Uint8List dlFaceBytes, Uint8List selfieBytes) async {
    Interpreter? interpreter;
    try {
      final modelPath = 'assets/models/mobilefacenet_liveness.tflite';
      try {
        await DefaultAssetBundle.of(context).load(modelPath);
        print('Model file exists: $modelPath');
      } catch (e) {
        print('Model file not found: $modelPath, error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model file not found: $modelPath')),
        );
        return false;
      }
      interpreter = await Interpreter.fromAsset(modelPath);
      interpreter.allocateTensors();
      print('Loaded mobilefacenet_liveness.tflite successfully');
      print('Input shape: ${interpreter.getInputTensor(0).shape}');
      final outputShape = interpreter.getOutputTensor(0).shape;
      final dlInput = preprocess(dlFaceBytes);
      final dlOutput = List.generate(1, (_) => List.generate(outputShape[1], (_) => 0.0));
      try {
        interpreter.run(dlInput, dlOutput);
        print('Inference successful for DL face, output length: ${dlOutput.expand((row) => row).length}');
      } catch (e) {
        print('TFLite inference error for DL face: $e');
        interpreter.close();
        return false;
      }
      final dlEmbedding = dlOutput.expand((row) => row).toList();
      final selfieInput = preprocess(selfieBytes);
      final selfieOutput = List.generate(1, (_) => List.generate(outputShape[1], (_) => 0.0));
      try {
        interpreter.run(selfieInput, selfieOutput);
        print('Inference successful for selfie, output length: ${selfieOutput.expand((row) => row).length}');
      } catch (e) {
        print('TFLite inference error for selfie: $e');
        interpreter.close();
        return false;
      }
      final selfieEmbedding = selfieOutput.expand((row) => row).toList();
      if (dlEmbedding.length != selfieEmbedding.length) {
        throw Exception('Embedding length mismatch');
      }
      double similarity = cosineSimilarity(dlEmbedding, selfieEmbedding);
      print('Face similarity score: $similarity');
      interpreter.close();
      return similarity > 0.5; // Adjusted threshold based on typical MobileFaceNet values; test and tune
    } catch (e) {
      print('Face comparison error: $e');
      interpreter?.close();
      return false;
    }
  }
  
  double cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
  
  Future<Map<String, dynamic>> _extractLicenseNumber(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      final cleanedText = recognizedText.text.replaceAll(RegExp(r'\s+'), ' ');
      print('Recognized text: $cleanedText');
      
      // Use a regex for numeric DL numbers if int is required
      final dlRegex = RegExp(r'(?i)(?:DL|DRIVER LICENSE|ID)\s*#?\s*([0-9]{6,16})');
      final match = dlRegex.firstMatch(cleanedText);
      final dlNumberStr = match?.group(1) ?? '';
      
      // Try to parse as int, if required
      int? dlNumber;
      if (dlNumberStr.isNotEmpty) {
        try {
          dlNumber = int.parse(dlNumberStr);
        } catch (e) {
          print('Failed to parse DL number as int: $e');
          // If parsing fails, you can decide to throw an error or keep as string
          // For now, we'll return the string to avoid breaking existing logic
        }
      }

      return {
        'dlNumber': dlNumber ?? dlNumberStr, // Return int if parsed, else string
        'fullText': cleanedText,
      };
    } catch (e) {
      print('Text recognition error: $e');
      return {
        'dlNumber': null,
        'fullText': '',
      };
    }
  }
  
  Future<String?> _promptManualDlEntry(String parsedDlNumber) async {
    final controller = TextEditingController(text: parsedDlNumber);
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter DL Number'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Enter the DL# from your license'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
 
  void _showDemoPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to Integridate!', textAlign: TextAlign.center),
          content: const Text(
            'This is an app demo complete with fake accounts,\n\n'
            'so you can see what makes Integridate different\n'
            'from all the other dating apps\n\n'
            'without having to create an account.\n\n'
            'Would you like to enter the demo?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.enterDemo();
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Integridate',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'email',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'password',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: _login,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text(
                'log in',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _showIdVerificationDialog,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
              ),
              child: const Text('create account'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _showDemoPopup,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
              ),
              child: const Text('try demo'),
            ),
          ],
        ),
      ),
    );
  }
}

List<List<List<List<double>>>> preprocess(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes)!;
  final resized = img.copyResize(image, width: 112, height: 112);
  final bytes = resized.getBytes(order: img.ChannelOrder.rgb); // Force RGB, length=37632
 
  final input = List.generate(1, (_) =>
    List.generate(112, (_) =>
      List.generate(112, (_) =>
        List.generate(3, (_) => 0.0)
      )
    )
  );
 
  int idx = 0;
  for (int h = 0; h < 112; h++) {
    for (int w = 0; w < 112; w++) {
      input[0][h][w][0] = (bytes[idx++] / 127.5) - 1.0; // R, normalized to [-1,1]
      input[0][h][w][1] = (bytes[idx++] / 127.5) - 1.0; // G
      input[0][h][w][2] = (bytes[idx++] / 127.5) - 1.0; // B
    }
  }
  return input;
}

Uint8List? _cropDlFaceIsolate(Map<String, dynamic> cropData) {
  try {
    final path = cropData['path'] as String;
    final left = cropData['left'] as int;
    final top = cropData['top'] as int;
    final width = cropData['width'] as int;
    final height = cropData['height'] as int;
    final outputPath = cropData['outputPath'] as String;
    final dlImageBytes = File(path).readAsBytesSync();
    final image = img.decodeImage(dlImageBytes);
    if (image == null) {
      print('Failed to decode image');
      return null;
    }
    final imgWidth = image.width;
    final imgHeight = image.height;
    print('Image dimensions: ${imgWidth}x${imgHeight}');
    final cropped = img.copyCrop(
      image,
      x: left.clamp(0, imgWidth),
      y: top.clamp(0, imgHeight),
      width: width.clamp(0, imgWidth - left),
      height: height.clamp(0, imgHeight - top),
    );
    final croppedBytes = img.encodePng(cropped);
    final outputDir = File(outputPath).parent;
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
    File(outputPath).writeAsBytesSync(croppedBytes);
    print('Cropped face saved for debugging at: $outputPath');
    return croppedBytes;
  } catch (e) {
    print('Face cropping error in isolate: $e');
    return null;
  }
}

List<double>? _runTFLiteInference(Map<String, dynamic> data) {  // This was used in an earlier performIdVerification to compute face matching for each of 5 frames, but is not needed as the model is now used in stream one time when the user finishes the liveness check
  try {
    final imageBytes = data['imageBytes'] as Uint8List;
    final modelBuffer = data['modelBuffer'] as Uint8List;
    final interpreter = Interpreter.fromBuffer(modelBuffer);
    interpreter.allocateTensors();
    final input = preprocess(imageBytes);
    final outputShape = interpreter.getOutputTensor(0).shape;
    final output = List.generate(1, (_) => List.generate(outputShape[1], (_) => 0.0));
    interpreter.run(input, output);
    interpreter.close();
    return output.expand((row) => row).toList();
  } catch (e) {
    print('TFLite inference error in isolate: $e');
    return null;
  }
}

/* class LivenessCaptureScreen extends StatefulWidget {
  final Function(Uint8List?) onCaptureComplete;
  const LivenessCaptureScreen({super.key, required this.onCaptureComplete});
  @override
  State<LivenessCaptureScreen> createState() => _LivenessCaptureScreenState();
}

class _LivenessCaptureScreenState extends State<LivenessCaptureScreen> {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  FaceDetector? _faceDetector;
  bool _isCapturing = false;
  Uint8List? modelBuffer;

  @override
  void initState() {
    super.initState();
    _initializeCameraAndModel();
  }

  Future<void> _initializeCameraAndModel() async {
    // Permissions already checked in parent; assume granted
    final cameras = await availableCameras();
    if (cameras.length < 2) {
      widget.onCaptureComplete(null);
      return;
    }
    _cameraController = CameraController(cameras[1], ResolutionPreset.medium);
    await _cameraController?.initialize();
    final modelPath = 'assets/models/mobilefacenet_liveness.tflite';
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      _interpreter?.allocateTensors();
      print('Input shape: ${_interpreter?.getInputTensor(0).shape}');
      final modelData = await rootBundle.load(modelPath);
      modelBuffer = modelData.buffer.asUint8List();
    } catch (e) {
      print('Model load error: $e');
      widget.onCaptureComplete(null);
      return;
    }
    _faceDetector = FaceDetector(options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableClassification: true, // For eye open probabilities
    ));
    setState(() {});
  }

  Future<void> _startCapture() async {
    setState(() => _isCapturing = true);
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final frames = <Uint8List>[];
    final embeddings = <List<double>>[];
    bool blinkDetected = false;

    for (int i = 0; i < 5; i++) { // Increased to 5 frames for better detection
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) continue;
      final face = faces.first;
      final rect = face.boundingBox;
      if (face.leftEyeOpenProbability != null && face.leftEyeOpenProbability! < 0.2) {
        blinkDetected = true; // Detect blink for added liveness
      }

      final imageBytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) continue;
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
      frames.add(croppedBytes);
      final embedding = await compute(_runTFLiteInference, {
        'imageBytes': croppedBytes,
        'modelBuffer': modelBuffer!,
      });

      if (embedding == null) {
        widget.onCaptureComplete(null);
        return;
      }

      embeddings.add(embedding);
      if (i > 0) {
        final isLive = _detectMotion(frames[i - 1], frames[i], embeddings[i - 1], embeddings[i]);
        if (isLive || blinkDetected) {
          await _cameraController!.dispose();
          _interpreter!.close();
          await _faceDetector!.close();
          widget.onCaptureComplete(frames.last);
          return;
        }
      }
      await Future.delayed(const Duration(milliseconds: 500)); // Increased delay
    }

    await _cameraController!.dispose();
    _interpreter!.close();
    await _faceDetector!.close();
    widget.onCaptureComplete(null);
  }

  bool _detectMotion(Uint8List prevFrame, Uint8List currFrame, List<double> prevEmbedding, List<double> currEmbedding) {
    final similarity = cosineSimilarity(prevEmbedding, currEmbedding);
    print('Frame similarity: $similarity');
    return similarity < 0.99; // Detect small differences as motion (live)
  }
  
  double cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    _faceDetector?.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
        if (!_isCapturing)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Position your face in the center of the screen',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _startCapture,
                  child: const Text('Ready'),
                ),
              ],
            ),
          ),

        if (_isCapturing)
          const Center(
            child: Text(
              'Capturing... Move your head slightly or blink',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
      ],
    );
  }
} */

class LivenessCaptureScreen extends StatefulWidget {
  final Function(Uint8List?) onCaptureComplete;
  const LivenessCaptureScreen({super.key, required this.onCaptureComplete});
  @override
  State<LivenessCaptureScreen> createState() => _LivenessCaptureScreenState();
}

class _LivenessCaptureScreenState extends State<LivenessCaptureScreen> {
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
  final int _timeoutSeconds = 15; // Timeout per challenge

  @override
  void initState() {
    super.initState();
    _initializeCameraAndModel();
  }

  Future<void> _initializeCameraAndModel() async {
    final cameras = await availableCameras();
    if (cameras.length < 2) {
      widget.onCaptureComplete(null);
      return;
    }
    _cameraController = CameraController(cameras[1], ResolutionPreset.medium); // Front camera
    await _cameraController?.initialize();
    final modelPath = 'assets/models/mobilefacenet_liveness.tflite';
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      _interpreter?.allocateTensors();
      print('Input shape: ${_interpreter?.getInputTensor(0).shape}');
      final modelData = await rootBundle.load(modelPath);
      modelBuffer = modelData.buffer.asUint8List();
    } catch (e) {
      print('Model load error: $e');
      widget.onCaptureComplete(null);
      return;
    }
    _faceDetector = FaceDetector(options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableClassification: true,
      enableLandmarks: true, // Helps with pose accuracy
    ));
    await _cameraController!.startImageStream(_processCameraImage);
    setState(() {});
  }

  void _startChallengeSequence() {
    _currentChallenge = Challenge.leftTurn;
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    _challengeTimer?.cancel();
    _challengeTimer = Timer(Duration(seconds: _timeoutSeconds), _handleTimeout);
  }

  void _handleTimeout() {
    _handleFailure();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _currentChallenge == Challenge.initial) return;
    _isProcessing = true;

    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (imageRotation == null) imageRotation = InputImageRotation.rotation0deg;

    // For front camera, flip horizontally
    final bool isFront = camera.lensDirection == CameraLensDirection.front;
    final InputImageMetadata metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);

    final faces = await _faceDetector!.processImage(inputImage);
    if (faces.isEmpty) {
      _isProcessing = false;
      return;
    }
    final face = faces.first;

    bool detected = false;

    switch (_currentChallenge) {
      case Challenge.leftTurn:
        if (face.headEulerAngleY! < -20) { // Negative: looking left of camera (user's right? Wait, per docs: negative = looking left
          // Per docs: negative Y = looking to the left of the camera
          // For "turn head to the left" (user's left), face looks to camera's right? Wait.
          // Assuming: user turns head left -> face yaw positive? But from docs, positive = looking right of camera.
          // To match user expectation: "turn left" means user turns head to their left, face looks left from user view, but camera sees face looking right (since front mirror).
          // But angles are not mirrored; ML Kit gives absolute.
          // Common practice: positive Y >20 for right turn (looking right), negative < -20 for left.
          // I'll set "turn left" as negative Y (looking left).
          detected = true;
          _leftDone = true;
          _currentChallenge = Challenge.rightTurn;
        }
        break;
      case Challenge.rightTurn:
        if (face.headEulerAngleY! > 20) {
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
      await _captureAndSaveFrame(face, image); // Capture and save on detection
      _startTimeoutTimer(); // Reset timer for next
      setState(() {});
    }

    _isProcessing = false;
  }

  Future<void> _captureAndSaveFrame(Face face, CameraImage cameraImage) async {
    // Convert CameraImage to img.Image for cropping (complex, but for save)
    // Alternative: takePicture for high-res
    final XFile photo = await _cameraController!.takePicture();
    final inputImage = InputImage.fromFilePath(photo.path);
    final faces = await _faceDetector!.processImage(inputImage);
    if (faces.isEmpty) return;
    final rect = faces.first.boundingBox;

    final imageBytes = await File(photo.path).readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) return;

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

    // Save to gallery
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/liveness_${_currentChallenge.name}.png';
      await File(tempPath).writeAsBytes(croppedBytes);
      await Gal.putImage(tempPath);
      print('Saved ${_currentChallenge.name} to gallery');
    } catch (e) {
      print('Gallery save error: $e');
    }
  }

  Future<void> _captureFinalPhoto() async {
    final XFile finalPhoto = await _cameraController!.takePicture();
    final imageBytes = await File(finalPhoto.path).readAsBytes();
    // Crop face for embedding, but since onComplete passes bytes, crop here if needed
    final inputImage = InputImage.fromFilePath(finalPhoto.path);
    final faces = await _faceDetector!.processImage(inputImage);
    if (faces.isEmpty) {
      _handleFailure();
      return;
    }
    final rect = faces.first.boundingBox;

    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      _handleFailure();
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

    // Save final to gallery
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/liveness_final.png';
      await File(tempPath).writeAsBytes(croppedBytes);
      await Gal.putImage(tempPath);
      print('Final face saved to gallery');
    } catch (e) {
      print('Gallery save error for final: $e');
    }

    await _cameraController!.stopImageStream();
    _interpreter!.close();
    await _faceDetector!.close();
    widget.onCaptureComplete(croppedBytes); // Pass cropped for matching
  }

  void _handleFailure() async {
    _challengeTimer?.cancel();
    await _cameraController!.stopImageStream();
    setState(() {
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
    if (retry == true) {
      await _cameraController!.startImageStream(_processCameraImage);
      _startChallengeSequence();
    } else {
      widget.onCaptureComplete(null);
    }
  }

  String _getInstructionText() {
    switch (_currentChallenge) {
      case Challenge.leftTurn:
        return 'Turn your head to the left${_leftDone ? " ✓" : ""}';
      case Challenge.rightTurn:
        return 'Turn your head to the right${_rightDone ? " ✓" : ""}';
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
    _challengeTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _interpreter?.close();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 32),
            onPressed: () {
              widget.onCaptureComplete(null);
            },
          ),
        ),

        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
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
                onPressed: _startChallengeSequence,
                child: const Text('Ready'),
              ),
            ),
          ),
      ],
    );
  }
}

class DlCaptureScreen extends StatefulWidget {
  final Function(XFile?) onCaptureComplete;
  const DlCaptureScreen({super.key, required this.onCaptureComplete});
  @override
  State<DlCaptureScreen> createState() => _DlCaptureScreenState();
}

class _DlCaptureScreenState extends State<DlCaptureScreen> {
  CameraController? _cameraController;
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      widget.onCaptureComplete(null);
      return;
    }
    _cameraController = CameraController(
      cameras[0], // Rear camera
      ResolutionPreset.high, // Higher res for DL scanning
      enableAudio: false,
    );
    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _capturePhoto() async {
    try {
      final image = await _cameraController!.takePicture();
      widget.onCaptureComplete(image);
    } catch (e) {
      print('Capture error: $e');
      widget.onCaptureComplete(null);
    }
  }

  @override
  void dispose() {
    try {
      _cameraController?.dispose();
    } catch (e) {
      print('Camera dispose error: $e'); // Catch teardown crash
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _capturePhoto,
              child: const Text('Capture DL Photo'),
            ),
          ),
        ),
      ],
    );
  }
}
/* // NEW: In-app screen for DL photo capture (rear camera)
class DlCaptureScreen extends StatefulWidget {
  final Function(XFile?) onCaptureComplete;
  const DlCaptureScreen({super.key, required this.onCaptureComplete});
  @override
  State<DlCaptureScreen> createState() => _DlCaptureScreenState();
}
class _DlCaptureScreenState extends State<DlCaptureScreen> {
  CameraController? _cameraController;
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      widget.onCaptureComplete(null);
      return;
    }
    _cameraController = CameraController(
      cameras[0], // Rear camera
      ResolutionPreset.high, // Higher res for DL scanning
      enableAudio: false,
    );
    await _cameraController!.initialize();
    setState(() {});
  }
  Future<void> _capturePhoto() async {
    try {
      final image = await _cameraController!.takePicture();
      widget.onCaptureComplete(image);
    } catch (e) {
      print('Capture error: $e');
      widget.onCaptureComplete(null);
    }
  }
  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _capturePhoto,
              child: const Text('Capture DL Photo'),
            ),
          ),
        ),
      ],
    );
  }
} */ */

// version 5
/* import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

enum Challenge { initial, leftTurn, rightTurn, blink, center }

class LogIn extends StatefulWidget {
  final Function(int, [int?]) switchPage;
  final VoidCallback enterDemo;
  const LogIn({super.key, required this.switchPage, required this.enterDemo});
  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _retrieveLostData();
    }
  }

  Future<void> _retrieveLostData() async {
    final picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) return;
    if (response.file != null) {
      debugPrint('Recovered lost image: ${response.file?.path}');
    } else if (response.exception != null) {
      debugPrint('Lost data error: ${response.exception?.message}');
    }
  }

  Future<void> _postAuthCheck() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final firestore = FirebaseFirestore.instance;
    final query = await firestore.collection('user_ids').where('uid', isEqualTo: user.uid).get();
    if (query.docs.isEmpty) {
      // No DL associated, perform verification
      await _performDlVerification(user);
    } else {
      widget.switchPage(0);
    }
  }

  Future<void> _performDlVerification(User user, {bool isSignUp = false}) async {
    try {
      final dlInput = await _promptDlInput();
      if (dlInput == null) throw Exception('DL input cancelled');
      final String enteredDlNumber = dlInput['dlNumber']!;
      final String selectedState = dlInput['state']!;

      final dlPhotoFile = await showDialog<XFile?>(
        context: context,
        builder: (context) => DlCaptureScreen(onCaptureComplete: (file) => Navigator.pop(context, file)),
      );

      if (dlPhotoFile == null) throw Exception('DL photo capture failed');

      final dlData = await _extractLicenseNumber(dlPhotoFile.path, enteredDlNumber);
      final dynamic parsedDlNumber = dlData['dlNumber'];
      final String fullText = dlData['fullText'] ?? '';
      final bool isBlurry = dlData['isBlurry'] ?? false;

      if (parsedDlNumber == null || parsedDlNumber.toString().isEmpty) {
        String message = 'Could not find the entered DL number ($enteredDlNumber) in the photo.';
        if (isBlurry) message += '\nThe photo may be blurry or misaligned. Ensure good lighting and hold steady.';
        if (fullText.isNotEmpty) message += '\nRecognized text: $fullText';
        message += '\nWould you like to retry capturing the photo?';
        final retry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('DL Number Not Found'),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Retry')),
            ],
          ),
        );
        if (retry == true) return _performDlVerification(user, isSignUp: isSignUp);
        throw Exception('DL number verification failed');
      }

      if (selectedState == 'Texas' && (parsedDlNumber is! int || parsedDlNumber.toString().length < 7 || parsedDlNumber.toString().length > 8)) {
        throw Exception('Invalid Texas DL number format. Must be 7-8 digits.');
      }

      final croppedDlFace = await isolateCropDlFace(dlPhotoFile.path);
      if (croppedDlFace == null) throw Exception('No face detected on DL');
      await Future.delayed(const Duration(milliseconds: 500));

      final selfieBytes = await showDialog<Uint8List?>(
        context: context,
        builder: (context) => LivenessCaptureScreen(
          onCaptureComplete: (bytes) => Navigator.pop(context, bytes),
        ),
      );

      if (selfieBytes == null) throw Exception('Liveness check failed');

      final isMatch = await _compareFaces(croppedDlFace, selfieBytes);
      if (!isMatch) throw Exception('Faces do not match');

      // Store DL data
      String? email = user.email;
      String? phone = user.phoneNumber;
      final stored = await _storeDlData(user, enteredDlNumber, selectedState, email: email, phone: phone);
      if (stored) {
        widget.switchPage(0);
      }
    } catch (e) {
      debugPrint('Verification failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
      if (isSignUp) {
        // If sign-up, delete the new user on failure
        await user.delete();
        await FirebaseAuth.instance.signOut();
      }
    }
  }

  Future<void> _loginWithEmailOrPhone() async {
    final controller = TextEditingController();
    final input = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email or Phone'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter email or phone number'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Next')),
        ],
      ),
    );
    if (input == null || input.isEmpty) return;

    if (input.contains('@')) {
      // Email login
      final passController = TextEditingController();
      final password = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: passController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, passController.text.trim()), child: const Text('Log In')),
          ],
        ),
      );
      if (password == null || password.isEmpty) return;

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: input, password: password);
        await _postAuthCheck();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } else {
      // Phone auth
      final result = await _authWithPhone(initialPhone: input);
      if (result != null) {
        await _postAuthCheck();
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    final user = await _authWithGoogle();
    if (user != null) {
      await _postAuthCheck();
    }
  }

  Future<void> _loginWithApple() async {
    final user = await _authWithApple();
    if (user != null) {
      await _postAuthCheck();
    }
  }

  void _showIdVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ID Verification Required'),
          content: const Text('To create an account, we need to verify your ID. This includes taking a photo of your DL and a selfie for matching.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performVerificationAndSignUp();
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performVerificationAndSignUp() async {
    try {
      final dlInput = await _promptDlInput();
      if (dlInput == null) throw Exception('DL input cancelled');
      final String enteredDlNumber = dlInput['dlNumber']!;
      final String selectedState = dlInput['state']!;

      final dlPhotoFile = await showDialog<XFile?>(
        context: context,
        builder: (context) => DlCaptureScreen(onCaptureComplete: (file) => Navigator.pop(context, file)),
      );

      if (dlPhotoFile == null) throw Exception('DL photo capture failed');

      final dlData = await _extractLicenseNumber(dlPhotoFile.path, enteredDlNumber);
      final dynamic parsedDlNumber = dlData['dlNumber'];
      final String fullText = dlData['fullText'] ?? '';
      final bool isBlurry = dlData['isBlurry'] ?? false;

      if (parsedDlNumber == null || parsedDlNumber.toString().isEmpty) {
        String message = 'Could not find the entered DL number ($enteredDlNumber) in the photo.';
        if (isBlurry) message += '\nThe photo may be blurry or misaligned. Ensure good lighting and hold steady.';
        if (fullText.isNotEmpty) message += '\nRecognized text: $fullText';
        message += '\nWould you like to retry capturing the photo?';
        final retry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('DL Number Not Found'),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Retry')),
            ],
          ),
        );
        if (retry == true) return _performVerificationAndSignUp();
        throw Exception('DL number verification failed');
      }

      if (selectedState == 'Texas' && (parsedDlNumber is! int || parsedDlNumber.toString().length < 7 || parsedDlNumber.toString().length > 8)) {
        throw Exception('Invalid Texas DL number format. Must be 7-8 digits.');
      }

      final croppedDlFace = await isolateCropDlFace(dlPhotoFile.path);
      if (croppedDlFace == null) throw Exception('No face detected on DL');
      await Future.delayed(const Duration(milliseconds: 500));

      final selfieBytes = await showDialog<Uint8List?>(
        context: context,
        builder: (context) => LivenessCaptureScreen(
          onCaptureComplete: (bytes) => Navigator.pop(context, bytes),
        ),
      );

      if (selfieBytes == null) throw Exception('Liveness check failed');

      final isMatch = await _compareFaces(croppedDlFace, selfieBytes);
      if (!isMatch) throw Exception('Faces do not match');

      // Now choose sign-up method
      final method = await _showSignUpMethodDialog();
      if (method == null) throw Exception('Sign up cancelled');

      User? user;
      String? email, phone;

      switch (method) {
        case 'email':
          final creds = await _showCredentialsDialog();
          if (creds == null) throw Exception('Credentials cancelled');
          email = creds['email']!;
          final password = creds['password']!;
          final verified = await _verifyEmail(email, password);
          if (!verified) throw Exception('Email verification failed');
          user = FirebaseAuth.instance.currentUser;
          break;
        case 'phone':
          final result = await _authWithPhone();
          if (result == null) throw Exception('Phone sign up failed');
          user = result['user'];
          phone = result['phone'];
          break;
        case 'google':
          user = await _authWithGoogle();
          if (user == null) throw Exception('Google sign up failed');
          email = user.email;
          break;
        case 'apple':
          user = await _authWithApple();
          if (user == null) throw Exception('Apple sign up failed');
          email = user.email;
          break;
      }

      if (user == null) throw Exception('No user after sign up');

      // Store DL if everything succeeded
      final stored = await _storeDlData(user, enteredDlNumber, selectedState, email: email, phone: phone);
      if (stored) {
        widget.switchPage(0);
      } else {
        // Delete if not stored (e.g., duplicate)
        await user.delete();
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      debugPrint('Sign up failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
    }
  }

  Future<Map<String, String>?> _promptDlInput() async {
    final dlController = TextEditingController();
    String? selectedState;
    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Driver\'s License Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'State'),
              items: ['Texas', 'Other'].map((state) => DropdownMenuItem(value: state, child: Text(state))).toList(),
              onChanged: (value) => selectedState = value,
              validator: (value) => value == null ? 'Please select a state' : null,
            ),
            TextField(
              controller: dlController,
              decoration: const InputDecoration(labelText: 'DL Number'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (selectedState != null && dlController.text.trim().isNotEmpty) {
                Navigator.pop(context, {'state': selectedState!, 'dlNumber': dlController.text.trim()});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a state and DL number')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _showCredentialsDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Account Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                ),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                ),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All fields are required')),
                  );
                  return;
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid email')),
                  );
                  return;
                }
                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters')),
                  );
                  return;
                }
                if (password != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                Navigator.pop(context, {
                  'email': email,
                  'password': password,
                });
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _verifyEmail(String email, String password) async {
    try {
      // Create a temporary user to send verification email
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create temporary user');
      }
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent. Please check your inbox and verify your email.')),
      );

      // Poll for email verification status
      int attempts = 0;
      const maxAttempts = 60; // 5 minutes (60 * 5 seconds)
      while (attempts < maxAttempts) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        if (updatedUser != null && updatedUser.emailVerified) {
          return true;
        }
        await Future.delayed(const Duration(seconds: 5));
        attempts++;
      }

      // If not verified within time limit, delete the temporary user
      await user.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verification timed out. Please try again.')),
      );
      return false;
    } catch (e) {
      debugPrint('Email verification error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification email: $e')),
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> _extractLicenseNumber(String path, String enteredDlNumber) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      final cleanedText = recognizedText.text.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      final normalizedEnteredDlNumber = enteredDlNumber.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      debugPrint('Recognized text: $cleanedText');

      String dlNumberStr = '';
      if (cleanedText.contains(normalizedEnteredDlNumber)) dlNumberStr = enteredDlNumber;

      int? dlNumber;
      if (dlNumberStr.isNotEmpty) {
        try {
          dlNumber = int.parse(dlNumberStr);
        } catch (e) {
          debugPrint('Failed to parse DL number as int: $e');
          dlNumber = null;
        }
      }

      bool isBlurry = recognizedText.blocks.isEmpty || recognizedText.text.isEmpty;

      return {
        'dlNumber': dlNumber ?? dlNumberStr,
        'fullText': recognizedText.text,
        'isBlurry': isBlurry,
      };
    } catch (e) {
      debugPrint('Text recognition error: $e');
      return {
        'dlNumber': null,
        'fullText': '',
        'isBlurry': true,
      };
    }
  }

  Future<Uint8List?> isolateCropDlFace(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final faceDetector = FaceDetector(options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast));
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();
      if (faces.isEmpty) {
        debugPrint('No faces detected');
        return null;
      }
      final face = faces.first;
      final rect = face.boundingBox;
      final docsDir = await getApplicationDocumentsDirectory();
      final croppedImagePath = '${docsDir.path}/cropped_face.png';
      final cropData = {
        'path': path,
        'left': rect.left.toInt(),
        'top': rect.top.toInt(),
        'width': rect.width.toInt(),
        'height': rect.height.toInt(),
        'outputPath': croppedImagePath,
      };
      final croppedBytes = await compute(_cropDlFaceIsolate, cropData);
      if (croppedBytes != null) {
        try {
          final tempDir = await getTemporaryDirectory();
          final tempPath = '${tempDir.path}/temp_cropped.png';
          await File(tempPath).writeAsBytes(croppedBytes);
          await Gal.putImage(tempPath);
          debugPrint('Cropped face saved to gallery');
        } catch (e) {
          debugPrint('Gallery save error: $e');
        }
      }
      return croppedBytes;
    } catch (e) {
      debugPrint('Isolate error: $e');
      return null;
    }
  }

  Future<bool> _compareFaces(Uint8List dlFaceBytes, Uint8List selfieBytes) async {
    Interpreter? interpreter;
    try {
      final modelPath = 'assets/models/mobilefacenet_liveness.tflite';
      try {
        await DefaultAssetBundle.of(context).load(modelPath);
        debugPrint('Model file exists: $modelPath');
      } catch (e) {
        debugPrint('Model file not found: $modelPath, error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Model file not found: $modelPath')));
        return false;
      }
      interpreter = await Interpreter.fromAsset(modelPath);
      interpreter.allocateTensors();
      debugPrint('Loaded mobilefacenet_liveness.tflite successfully');
      debugPrint('Input shape: ${interpreter.getInputTensor(0).shape}');
      final outputShape = interpreter.getOutputTensor(0).shape;
      final dlInput = preprocess(dlFaceBytes);
      final dlOutput = List.generate(1, (_) => List.generate(outputShape[1], (_) => 0.0));
      try {
        interpreter.run(dlInput, dlOutput);
        debugPrint('Inference successful for DL face, output length: ${dlOutput.expand((row) => row).length}');
      } catch (e) {
        debugPrint('TFLite inference error for DL face: $e');
        interpreter.close();
        return false;
      }
      final dlEmbedding = dlOutput.expand((row) => row).toList();
      final selfieInput = preprocess(selfieBytes);
      final selfieOutput = List.generate(1, (_) => List.generate(outputShape[1], (_) => 0.0));
      try {
        interpreter.run(selfieInput, selfieOutput);
        debugPrint('Inference successful for selfie, output length: ${selfieOutput.expand((row) => row).length}');
      } catch (e) {
        debugPrint('TFLite inference error for selfie: $e');
        interpreter.close();
        return false;
      }
      final selfieEmbedding = selfieOutput.expand((row) => row).toList();
      if (dlEmbedding.length != selfieEmbedding.length) throw Exception('Embedding length mismatch');
      double similarity = cosineSimilarity(dlEmbedding, selfieEmbedding);
      debugPrint('Face similarity score: $similarity');
      interpreter.close();
      return similarity > 0.5;
    } catch (e) {
      debugPrint('Face comparison error: $e');
      interpreter?.close();
      return false;
    }
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  void _showDemoPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to Integridate!', textAlign: TextAlign.center),
          content: const Text(
            'This is an app demo complete with fake accounts,\n\n'
            'so you can see what makes Integridate different\n'
            'from all the other dating apps\n\n'
            'without having to create an account.\n\n'
            'Would you like to enter the demo?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.enterDemo();
              },
              child: const Text('Yes'),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('No')),
          ],
        );
      },
    );
  }

  Future<String?> _showSignUpMethodDialog() async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Sign Up Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'email'),
                child: const Text('Email and Password'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'phone'),
                child: const Text('Phone Number (OTP)'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'google'),
                child: const Text('Google'),
              ),
              if (Platform.isIOS)
                TextButton(
                  onPressed: () => Navigator.pop(context, 'apple'),
                  child: const Text('Apple'),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _authWithPhone({String? initialPhone}) async {
    final phoneController = TextEditingController(text: initialPhone ?? '');
    final phone = initialPhone ?? await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Phone Number'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '+1xxxxxxxxxx'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, phoneController.text.trim()), child: const Text('Send OTP')),
        ],
      ),
    );
    if (phone == null || phone.isEmpty) return null;

    final completer = Completer<Map<String, dynamic>>();
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        completer.complete({'user': userCredential.user, 'phone': phone});
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
        completer.complete(null);
      },
      codeSent: (String verificationId, int? resendToken) async {
        final codeController = TextEditingController();
        final code = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enter OTP'),
            content: TextField(controller: codeController, keyboardType: TextInputType.number),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, codeController.text.trim()), child: const Text('Verify')),
            ],
          ),
        );
        if (code == null) {
          completer.complete(null);
          return;
        }
        final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);
        try {
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete({'user': userCredential.user, 'phone': phone});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP: $e')));
          completer.complete(null);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    return await completer.future;
  }

  Future<User?> _authWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google auth failed: $e')));
      return null;
    }
  }

  Future<User?> _authWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      return userCredential.user;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Apple auth failed: $e')));
      return null;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> _storeDlData(User user, String enteredDlNumber, String selectedState, {String? email, String? phone}) async {
    final hash = sha256.convert(utf8.encode('salt$enteredDlNumber')).toString();
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('user_ids').doc(hash).get();
    if (doc.exists) {
      final creationTime = user.metadata.creationTime ?? DateTime.now();
      final lastSignInTime = user.metadata.lastSignInTime ?? DateTime.now();
      final isNew = (lastSignInTime.millisecondsSinceEpoch - creationTime.millisecondsSinceEpoch) < 60000;  // Within 1 min
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account already exists for this ID')));
      if (isNew) {
        await user.delete();
      }
      await FirebaseAuth.instance.signOut();
      return false;
    }
    final data = {
      'created_at': Timestamp.now(),
      'state': selectedState,
      'dlNumber': enteredDlNumber,
      'uid': user.uid,
    };
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    await firestore.collection('user_ids').doc(hash).set(data);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Integridate',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: _loginWithEmailOrPhone,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Email or Phone', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loginWithGoogle,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Sign in with Google', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            if (Platform.isIOS)
              TextButton(
                onPressed: _loginWithApple,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: const Text('Sign in with Apple', style: TextStyle(color: Colors.white)),
              ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: _showIdVerificationDialog,
              style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.transparent),
              child: const Text('Create Account'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _showDemoPopup,
              style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.transparent),
              child: const Text('try demo'),
            ),
          ],
        ),
      ),
    );
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

Uint8List? _cropDlFaceIsolate(Map<String, dynamic> cropData) {
  try {
    final path = cropData['path'] as String;
    final left = cropData['left'] as int;
    final top = cropData['top'] as int;
    final width = cropData['width'] as int;
    final height = cropData['height'] as int;
    final outputPath = cropData['outputPath'] as String;
    final dlImageBytes = File(path).readAsBytesSync();
    final image = img.decodeImage(dlImageBytes);
    if (image == null) {
      debugPrint('Failed to decode image');
      return null;
    }
    final imgWidth = image.width;
    final imgHeight = image.height;
    debugPrint('Image dimensions: ${imgWidth}x${imgHeight}');
    final cropped = img.copyCrop(
      image,
      x: left.clamp(0, imgWidth),
      y: top.clamp(0, imgHeight),
      width: width.clamp(0, imgWidth - left),
      height: height.clamp(0, imgHeight - top),
    );
    final croppedBytes = img.encodePng(cropped);
    final outputDir = File(outputPath).parent;
    if (!outputDir.existsSync()) outputDir.createSync(recursive: true);
    File(outputPath).writeAsBytesSync(croppedBytes);
    debugPrint('Cropped face saved for debugging at: $outputPath');
    return croppedBytes;
  } catch (e) {
    debugPrint('Face cropping error in isolate: $e');
    return null;
  }
}

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
      final modelPath = 'assets/models/mobilefacenet_liveness.tflite';
      _interpreter = await Interpreter.fromAsset(modelPath);
      _interpreter?.allocateTensors();
      debugPrint('Input shape: ${_interpreter?.getInputTensor(0).shape}');
      final modelData = await rootBundle.load(modelPath);
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
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

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
                child: const Text('Ready'),
              ),
            ),
          ),
      ],
    );
  }
}

class DlCaptureScreen extends StatefulWidget {
  final Function(XFile?) onCaptureComplete;
  const DlCaptureScreen({super.key, required this.onCaptureComplete});
  @override
  State<DlCaptureScreen> createState() => _DlCaptureScreenState();
}

class _DlCaptureScreenState extends State<DlCaptureScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _cleanupResources();
    } else if (state == AppLifecycleState.resumed && _cameraController == null) {
      _initializeCamera();
    }
  }

  Future<bool> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      debugPrint('Camera permission denied');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required for DL capture')),
      );
      return false;
    }
    return true;
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing) return;
    setState(() => _isInitializing = true);
    try {
      if (!await _checkCameraPermission()) {
        widget.onCaptureComplete(null);
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        widget.onCaptureComplete(null);
        return;
      }
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController!.initialize().catchError((e) {
        debugPrint('Camera initialization error: $e');
        throw e;
      });
      await _cameraController!.setFocusMode(FocusMode.auto).catchError((e) {
        debugPrint('Error setting focus mode: $e');
      });
      await _cameraController!.setExposureMode(ExposureMode.auto).catchError((e) {
        debugPrint('Error setting exposure mode: $e');
      });
      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      widget.onCaptureComplete(null);
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _cleanupResources() async {
    try {
      await _cameraController?.dispose().catchError((e) {
        debugPrint('Camera dispose error: $e');
      });
    } catch (e) {
      debugPrint('Cleanup error: $e');
    } finally {
      _cameraController = null;
    }
  }

  Future<void> _capturePhoto() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        debugPrint('Camera not initialized for capture');
        widget.onCaptureComplete(null);
        return;
      }
      await _cameraController!.setFocusMode(FocusMode.auto);
      await _cameraController!.setExposureMode(ExposureMode.auto);
      final image = await _cameraController!.takePicture();
      widget.onCaptureComplete(image);
    } catch (e) {
      debugPrint('Capture error: $e');
      widget.onCaptureComplete(null);
    } finally {
      await _cameraController?.setFocusMode(FocusMode.auto).catchError((e) {
        debugPrint('Error resetting focus mode: $e');
      });
      await _cameraController?.setExposureMode(ExposureMode.auto).catchError((e) {
        debugPrint('Error resetting exposure mode: $e');
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing || _cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Position your driver\'s license clearly in the frame.\nEnsure good lighting and hold the camera steady.',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
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
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _capturePhoto,
              child: const Text('Capture DL Photo'),
            ),
          ),
        ),
      ],
    );
  }
} */


// First phone only version


/* import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// Custom TextInputFormatter for phone number formatting
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digitsLength = digitsOnly.length;

    String newText = '';
    if (digitsLength > 0) {
      newText += '(${digitsOnly.substring(0, digitsLength >= 3 ? 3 : digitsLength)}';
      if (digitsLength > 3) {
        newText += ') ${digitsOnly.substring(3, digitsLength >= 6 ? 6 : digitsLength)}';
        if (digitsLength > 6) {
          newText += '-${digitsOnly.substring(6, digitsLength >= 10 ? 10 : digitsLength)}';
        }
      }
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class LogIn extends StatefulWidget {
  final Function(int, [int?]) switchPage;
  final VoidCallback enterDemo;
  const LogIn({super.key, required this.switchPage, required this.enterDemo});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _postAuthCheck() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    widget.switchPage(0);
  }

  Future<void> _loginWithPhone() async {
    final result = await _authWithPhone();
    if (result == null) return; // Handle cancellation
    final user = result['user'] as User;
    final phone = result['phone'] as String;

    // Check if user is new (creation and last sign-in times are close)
    final creationTime = user.metadata.creationTime ?? DateTime.now();
    final lastSignInTime = user.metadata.lastSignInTime ?? DateTime.now();
    final isNew = (lastSignInTime.millisecondsSinceEpoch - creationTime.millisecondsSinceEpoch) < 60000;

    if (isNew) {
      // Store data for new users only
      await _storeUserData(user, phone);
    }

    await _postAuthCheck();
  }

  Future<Map<String, dynamic>?> _authWithPhone() async {
    final phoneController = TextEditingController();
    
    // Not sure why grok added this but I also removed the init of initialPhone from the function declaration and it still works fine
    // Format initial phone number if provided
    // if (initialPhone != null && RegExp(r'^\d{10}$').hasMatch(initialPhone)) {
    //   phoneController.text =
    //       '(${initialPhone.substring(0, 3)}) ${initialPhone.substring(3, 6)}-${initialPhone.substring(6, 10)}';
    // }

    final phone = await showDialog<String>(  // Get phone number entry from user
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Phone Number', textAlign: TextAlign.center,),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Allow only digits
            PhoneNumberFormatter(), // Apply phone number formatting
          ],
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: '(000) 000-0000'),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final input = phoneController.text.replaceAll(RegExp(r'\D'), '');
              // Validate US phone number: 10 digits
              if (RegExp(r'^\d{10}$').hasMatch(input)) {
                Navigator.pop(context, input);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid 10-digit US phone number')),
                );
              }
            },
            child: const Text('Get OTP'),
          ),
        ],
      ),
    );
    if (phone == null || phone.isEmpty) return null;

    // Auto-prepend +1 to convert to E.164 format
    final e164Phone = '+1$phone';

    final completer = Completer<Map<String, dynamic>?>(); // Allow nullable map. This captures the user data so it can be stored in the user_id firestore collection for retrieval later 

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: e164Phone,

      verificationCompleted: (PhoneAuthCredential credential) async {  // This is for auto phone number verification via auto retrieval with google and android which does not require a OTP 
        try {
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete({'user': userCredential.user, 'phone': e164Phone});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auto-verification failed: $e')));
          completer.complete(null);
        }
      },

      verificationFailed: (FirebaseAuthException e) {  // Handles all verification errors
        String errorMessage;
        switch (e.code) {
          case 'invalid-phone-number':
            errorMessage = 'Invalid phone number format. Please use a 10-digit US number.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please try again later.';
            break;
          case 'provider-not-enabled':
            errorMessage = 'Phone authentication is not enabled in Firebase Console.';
            break;
          default:
            errorMessage = 'Phone verification failed: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        completer.complete(null);
      },

      codeSent: (String verificationId, int? resendToken) async {  // Auth case that requires OTP. This code runs when the code is successfully sent. Firebase passes a verification ID used to make sure the credential sent matches the OTP in the case that multiple users are trying to verify simultaneously
        final codeController = TextEditingController();
        final code = await showDialog<String>(  // Gets the OTP entered by the user
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enter OTP'),
            content: TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter 6-digit code'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),  // This closes the OTP entry dialogue
              TextButton(
                onPressed: () => Navigator.pop(context, codeController.text.trim()),  // Trims code of whitespace to avoid format errors
                child: const Text('Verify'),
              ),
            ],
          ),
        );

        if (code == null) {  // If the user does not enter the OTP into the dialogue: 
          completer.complete(null); // Handle OTP cancellation by returning a null completer 
          return;  // This check must be before the credential is created to avoid a null code error
        }

        final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);  // Creates a credential to be sent to firebase, and does so using the unique verification ID created by firebase (upon code_sent callback) and the entered code  

        try {
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete({'user': userCredential.user, 'phone': e164Phone});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP: $e')));
          completer.complete(null);
        }
      },

      codeAutoRetrievalTimeout: (String verificationId) {},  // Triggers when auto verification via auto retrieval times out
    );

    return await completer.future;
  }

  Future<void> _storeUserData(User user, String phone) async {
    final firestore = FirebaseFirestore.instance;
    final data = {
      'created_at': Timestamp.now(),
      'uid': user.uid,
      'phone': phone,
      // if (user.email != null) 'email': user.email,
    };
    await firestore.collection('user_ids').doc(phone).set(data);
  }

  void _showDemoPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to Integridate!', textAlign: TextAlign.center),
          content: const Text(
            'This is an app demo complete with fake accounts, '
            'so you can see what makes Integridate different '
            'from all the other dating apps '
            'without having to create an account.\n\n'
            'Would you like to enter the demo?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.enterDemo();
              },
              child: const Text('Yes'),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('No')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Integridate',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: _loginWithPhone,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Sign in with Phone', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _showDemoPopup,
              style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.transparent),
              child: const Text('Try Demo'),
            ),
          ],
        ),
      ),
    );
  }
} */