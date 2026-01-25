import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Face Recognition Service - ON-DEVICE ONLY
/// Uses Google ML Kit for face detection and MobileFaceNet for embeddings
/// NO cloud APIs, NO raw image storage
class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  // ML Kit Face Detector
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: false,
      enableTracking: false,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  // TFLite Interpreter for MobileFaceNet
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Face recognition threshold (cosine similarity)
  static const double RECOGNITION_THRESHOLD = 0.75; // Adjust based on testing
  static const int EMBEDDING_SIZE = 128;

  /// Initialize the face recognition model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if model file exists
      try {
        await rootBundle.load('assets/models/mobilefacenet.tflite');
      } catch (e) {
        print('⚠️ MobileFaceNet model not found. Face recognition will not work.');
        print('📥 Download model from: https://github.com/sirius-ai/MobileFaceNet_TF');
        print('📁 Place it in: assets/models/mobilefacenet.tflite');
        print('📝 See FACE_RECOGNITION_SETUP.md for instructions');
        throw Exception('Face recognition model not found. Please download and add mobilefacenet.tflite to assets/models/');
      }

      // Load MobileFaceNet model
      _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
      _isInitialized = true;
      print('✅ Face Recognition Service initialized');
    } catch (e) {
      print('❌ Failed to initialize Face Recognition Service: $e');
      throw Exception('Failed to load face recognition model: $e');
    }
  }

  /// Detect faces in an image
  Future<List<Face>> detectFaces(InputImage inputImage) async {
    try {
      final faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      print('❌ Face detection error: $e');
      return [];
    }
  }

  /// Extract face embedding from image
  /// Returns 128-dimensional embedding vector
  Future<List<double>?> extractFaceEmbedding(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 1. Detect face using ML Kit
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await detectFaces(inputImage);

      if (faces.isEmpty) {
        print('⚠️ No face detected in image');
        return null;
      }

      if (faces.length > 1) {
        print('⚠️ Multiple faces detected, using the largest one');
      }

      // Use the largest face
      final face = faces.reduce((a, b) => 
        (a.boundingBox.width * a.boundingBox.height) > 
        (b.boundingBox.width * b.boundingBox.height) ? a : b
      );

      // 2. Load and preprocess image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        print('❌ Failed to decode image');
        return null;
      }

      // 3. Crop face region
      final faceImage = _cropFace(image, face.boundingBox);
      
      // 4. Resize to model input size (112x112 for MobileFaceNet)
      final resizedImage = img.copyResize(faceImage, width: 112, height: 112);

      // 5. Normalize and prepare input
      final input = _preprocessImage(resizedImage);

      // 6. Run inference
      final output = List.filled(1 * EMBEDDING_SIZE, 0.0).reshape([1, EMBEDDING_SIZE]);
      _interpreter!.run(input, output);

      // 7. Extract and normalize embedding
      final embedding = List<double>.from(output[0]);
      final normalizedEmbedding = _normalizeEmbedding(embedding);

      print('✅ Face embedding extracted: ${normalizedEmbedding.length} dimensions');
      return normalizedEmbedding;

    } catch (e) {
      print('❌ Face embedding extraction error: $e');
      return null;
    }
  }

  /// Crop face region from image
  img.Image _cropFace(img.Image image, Rect boundingBox) {
    // Add padding around face (20%)
    final padding = 0.2;
    final width = boundingBox.width;
    final height = boundingBox.height;
    
    final x = max(0, (boundingBox.left - width * padding).toInt());
    final y = max(0, (boundingBox.top - height * padding).toInt());
    final w = min(image.width - x, (width * (1 + 2 * padding)).toInt());
    final h = min(image.height - y, (height * (1 + 2 * padding)).toInt());

    return img.copyCrop(image, x: x, y: y, width: w, height: h);
  }

  /// Preprocess image for MobileFaceNet
  /// Input: 112x112 RGB image
  /// Output: [1, 112, 112, 3] normalized tensor
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final input = List.generate(
      1,
      (_) => List.generate(
        112,
        (y) => List.generate(
          112,
          (x) {
            final pixel = image.getPixel(x, y);
            // Normalize to [-1, 1]
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );
    return input;
  }

  /// Normalize embedding using L2 normalization
  List<double> _normalizeEmbedding(List<double> embedding) {
    final norm = sqrt(embedding.fold<double>(0, (sum, val) => sum + val * val));
    return embedding.map((val) => val / norm).toList();
  }

  /// Compare two face embeddings using cosine similarity
  /// Returns similarity score (0.0 to 1.0)
  double compareFaces(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw Exception('Embedding dimensions do not match');
    }

    // Cosine similarity
    double dotProduct = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
    }

    // Since embeddings are already normalized, cosine similarity = dot product
    // Convert to 0-1 range: (similarity + 1) / 2
    return (dotProduct + 1) / 2;
  }

  /// Match a face embedding against a list of known embeddings
  /// Returns the best match with confidence score
  Map<String, dynamic>? matchFace(
    List<double> queryEmbedding,
    Map<String, List<double>> knownEmbeddings, {
    double threshold = RECOGNITION_THRESHOLD,
  }) {
    if (knownEmbeddings.isEmpty) {
      return null;
    }

    String? bestMatchId;
    double bestSimilarity = 0.0;

    for (final entry in knownEmbeddings.entries) {
      final similarity = compareFaces(queryEmbedding, entry.value);
      
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestMatchId = entry.key;
      }
    }

    if (bestSimilarity >= threshold && bestMatchId != null) {
      return {
        'workerId': bestMatchId,
        'confidence': bestSimilarity,
        'isMatch': true,
      };
    }

    return null;
  }

  /// Batch match multiple faces against known embeddings
  Future<List<Map<String, dynamic>>> batchMatchFaces(
    List<List<double>> queryEmbeddings,
    Map<String, List<double>> knownEmbeddings, {
    double threshold = RECOGNITION_THRESHOLD,
  }) async {
    final results = <Map<String, dynamic>>[];

    for (final queryEmbedding in queryEmbeddings) {
      final match = matchFace(queryEmbedding, knownEmbeddings, threshold: threshold);
      if (match != null) {
        results.add(match);
      }
    }

    return results;
  }

  /// Validate face quality before enrollment
  /// Returns true if face is suitable for enrollment
  Future<Map<String, dynamic>> validateFaceQuality(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await detectFaces(inputImage);

      if (faces.isEmpty) {
        return {
          'valid': false,
          'reason': 'No face detected. Please ensure your face is clearly visible.',
        };
      }

      if (faces.length > 1) {
        return {
          'valid': false,
          'reason': 'Multiple faces detected. Please ensure only one person is in the frame.',
        };
      }

      final face = faces.first;

      // Check face size (should be at least 15% of image)
      final boundingBox = face.boundingBox;
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image != null) {
        final faceArea = boundingBox.width * boundingBox.height;
        final imageArea = image.width * image.height;
        final faceRatio = faceArea / imageArea;

        if (faceRatio < 0.15) {
          return {
            'valid': false,
            'reason': 'Face is too small. Please move closer to the camera.',
          };
        }
      }

      // Check head pose (optional - can be strict or lenient)
      final headEulerAngleY = face.headEulerAngleY;
      final headEulerAngleZ = face.headEulerAngleZ;

      if (headEulerAngleY != null && headEulerAngleY!.abs() > 30) {
        return {
          'valid': false,
          'reason': 'Please face the camera directly (head turned too much).',
        };
      }

      if (headEulerAngleZ != null && headEulerAngleZ!.abs() > 20) {
        return {
          'valid': false,
          'reason': 'Please keep your head straight (tilted too much).',
        };
      }

      return {
        'valid': true,
        'face': face,
      };

    } catch (e) {
      return {
        'valid': false,
        'reason': 'Error validating face: $e',
      };
    }
  }

  /// Dispose resources
  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
    _isInitialized = false;
  }
}
