import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/worker_model.dart';
import '../services/worker_service.dart';
import '../services/face_recognition_service.dart';

/// Face Attendance Service
/// Handles face-based attendance marking with GPS validation
class FaceAttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FaceRecognitionService _faceService = FaceRecognitionService();

  static String? get currentUserId => _auth.currentUser?.uid;

  /// GPS validation settings
  static const double GPS_FENCE_RADIUS = 100.0; // meters
  static const int TIME_WINDOW_START = 6; // 6 AM
  static const int TIME_WINDOW_END = 20; // 8 PM

  /// Get attendance collection reference
  static CollectionReference<Map<String, dynamic>> _attendanceCollection(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('attendance');
  }

  /// Validate GPS location
  static Future<Map<String, dynamic>> validateGPS({
    required double projectLat,
    required double projectLng,
  }) async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'valid': false,
            'reason': 'Location permission denied',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'valid': false,
          'reason': 'Location permission permanently denied',
        };
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate distance
      final distance = Geolocator.distanceBetween(
        projectLat,
        projectLng,
        position.latitude,
        position.longitude,
      );

      if (distance > GPS_FENCE_RADIUS) {
        return {
          'valid': false,
          'reason': 'You are ${distance.toStringAsFixed(0)}m away from the project site. Please be within ${GPS_FENCE_RADIUS.toStringAsFixed(0)}m.',
          'distance': distance,
        };
      }

      return {
        'valid': true,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.toIso8601String(),
        },
        'distance': distance,
      };

    } catch (e) {
      return {
        'valid': false,
        'reason': 'GPS error: $e',
      };
    }
  }

  /// Validate time window
  static bool validateTimeWindow() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= TIME_WINDOW_START && hour < TIME_WINDOW_END;
  }

  /// Process face scan and mark attendance
  static Future<Map<String, dynamic>> processFaceScan({
    required String projectId,
    required File imageFile,
    required double projectLat,
    required double projectLng,
  }) async {
    if (currentUserId == null) {
      return {
        'success': false,
        'error': 'User not authenticated',
      };
    }

    try {
      // 1. Validate GPS
      final gpsValidation = await validateGPS(
        projectLat: projectLat,
        projectLng: projectLng,
      );

      if (gpsValidation['valid'] != true) {
        return {
          'success': false,
          'error': gpsValidation['reason'],
        };
      }

      // 2. Validate time window
      if (!validateTimeWindow()) {
        return {
          'success': false,
          'error': 'Attendance can only be marked between ${TIME_WINDOW_START}:00 and ${TIME_WINDOW_END}:00',
        };
      }

      // 3. Extract face embedding from image
      final embedding = await _faceService.extractFaceEmbedding(imageFile);
      
      if (embedding == null) {
        return {
          'success': false,
          'error': 'No face detected in image. Please ensure face is clearly visible.',
        };
      }

      // 4. Get known worker embeddings
      final knownEmbeddings = await WorkerService.getWorkerEmbeddings(projectId);

      if (knownEmbeddings.isEmpty) {
        return {
          'success': false,
          'error': 'No enrolled workers found. Please enroll workers first.',
        };
      }

      // 5. Match face
      final match = _faceService.matchFace(embedding, knownEmbeddings);

      if (match == null) {
        return {
          'success': false,
          'error': 'Face not recognized. Worker may not be enrolled.',
          'unrecognized': true,
        };
      }

      // 6. Get worker details
      final worker = await WorkerService.getWorker(projectId, match['workerId']);
      
      if (worker == null) {
        return {
          'success': false,
          'error': 'Worker not found',
        };
      }

      // 7. Check if already marked today
      final today = _getTodayKey();
      final existingAttendance = await getAttendanceForDate(projectId, today);

      if (existingAttendance != null) {
        final alreadyMarked = existingAttendance['records']
            .any((r) => r['workerId'] == worker.id && r['present'] == true);

        if (alreadyMarked) {
          return {
            'success': false,
            'error': '${worker.displayName} is already marked present today',
            'alreadyMarked': true,
          };
        }
      }

      // 8. Mark attendance
      await markAttendance(
        projectId: projectId,
        workerId: worker.id,
        workerName: worker.displayName,
        role: worker.role,
        dailyWage: worker.dailyWage,
        verificationMethod: 'FACE',
        faceConfidence: match['confidence'],
        geoLocation: gpsValidation['location'],
      );

      return {
        'success': true,
        'worker': {
          'id': worker.id,
          'name': worker.displayName,
          'role': worker.role,
          'wage': worker.dailyWage,
        },
        'confidence': match['confidence'],
        'distance': gpsValidation['distance'],
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'Error processing face scan: $e',
      };
    }
  }

  /// Mark attendance for a worker
  static Future<void> markAttendance({
    required String projectId,
    required String workerId,
    required String workerName,
    required String role,
    required double dailyWage,
    required String verificationMethod,
    double? faceConfidence,
    Map<String, dynamic>? geoLocation,
  }) async {
    final today = _getTodayKey();
    
    final attendanceRecord = FaceAttendanceRecord(
      workerId: workerId,
      workerName: workerName,
      role: role,
      dailyWage: dailyWage,
      present: true,
      verificationMethod: verificationMethod,
      faceConfidence: faceConfidence,
      markedAt: DateTime.now(),
      geoLocation: geoLocation,
    );

    // Check if attendance document exists for today
    final query = await _attendanceCollection(projectId)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // Update existing document
      final docId = query.docs.first.id;
      await _attendanceCollection(projectId).doc(docId).update({
        'records': FieldValue.arrayUnion([attendanceRecord.toJson()]),
        'updatedAt': Timestamp.now(),
        'updatedBy': currentUserId,
      });
    } else {
      // Create new document
      await _attendanceCollection(projectId).add({
        'projectId': projectId,
        'date': today,
        'records': [attendanceRecord.toJson()],
        'createdAt': Timestamp.now(),
        'createdBy': currentUserId,
      });
    }
  }

  /// Get attendance for a specific date
  static Future<Map<String, dynamic>?> getAttendanceForDate(
    String projectId,
    String date,
  ) async {
    final query = await _attendanceCollection(projectId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();
      return {
        'id': doc.id,
        'date': data['date'],
        'records': (data['records'] as List<dynamic>)
            .map((r) => FaceAttendanceRecord.fromJson(r as Map<String, dynamic>))
            .toList(),
        'createdAt': (data['createdAt'] as Timestamp).toDate(),
      };
    }

    return null;
  }

  /// Get today's attendance
  static Future<Map<String, dynamic>?> getTodayAttendance(String projectId) async {
    return getAttendanceForDate(projectId, _getTodayKey());
  }

  /// Stream of today's attendance
  static Stream<Map<String, dynamic>?> getTodayAttendanceStream(String projectId) {
    final today = _getTodayKey();
    
    return _attendanceCollection(projectId)
        .where('date', isEqualTo: today)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          
          final doc = snapshot.docs.first;
          final data = doc.data();
          
          return {
            'id': doc.id,
            'date': data['date'],
            'records': (data['records'] as List<dynamic>)
                .map((r) => FaceAttendanceRecord.fromJson(r as Map<String, dynamic>))
                .toList(),
            'createdAt': (data['createdAt'] as Timestamp).toDate(),
          };
        });
  }

  /// Calculate daily wages for a date
  static Future<Map<String, dynamic>> calculateDailyWages(
    String projectId,
    String date,
  ) async {
    final attendance = await getAttendanceForDate(projectId, date);
    
    if (attendance == null) {
      return {
        'totalWorkers': 0,
        'presentWorkers': 0,
        'totalWages': 0.0,
        'byVerificationMethod': {},
      };
    }

    final records = attendance['records'] as List<FaceAttendanceRecord>;
    final presentRecords = records.where((r) => r.present).toList();

    final totalWages = presentRecords.fold<double>(
      0,
      (sum, record) => sum + record.dailyWage,
    );

    // Group by verification method
    final byMethod = <String, Map<String, dynamic>>{};
    for (final record in presentRecords) {
      final method = record.verificationMethod;
      if (!byMethod.containsKey(method)) {
        byMethod[method] = {
          'count': 0,
          'wages': 0.0,
        };
      }
      byMethod[method]!['count'] = (byMethod[method]!['count'] as int) + 1;
      byMethod[method]!['wages'] = (byMethod[method]!['wages'] as double) + record.dailyWage;
    }

    return {
      'totalWorkers': records.length,
      'presentWorkers': presentRecords.length,
      'totalWages': totalWages,
      'byVerificationMethod': byMethod,
    };
  }

  /// Get attendance summary for date range
  static Future<List<Map<String, dynamic>>> getAttendanceSummary({
    required String projectId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final summary = <Map<String, dynamic>>[];
    
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final dateKey = _formatDate(currentDate);
      final wages = await calculateDailyWages(projectId, dateKey);
      
      summary.add({
        'date': dateKey,
        ...wages,
      });
      
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return summary;
  }

  /// Helper: Get today's date key
  static String _getTodayKey() {
    final now = DateTime.now();
    return _formatDate(now);
  }

  /// Helper: Format date as YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
