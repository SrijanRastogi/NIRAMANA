import 'package:cloud_firestore/cloud_firestore.dart';

/// Worker Model for Daily Wagers with Face Recognition
/// Stores worker information and face embeddings (NOT raw images)
class WorkerModel {
  final String id;
  final String projectId;
  final String name;
  final String? nickname;
  final String role; // Mason, Helper, Carpenter, etc.
  final double dailyWage;
  final List<double>? faceEmbedding; // 128-dimensional face embedding
  final bool active;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? enrolledBy; // Manager UID who enrolled the worker
  final String? photoUrl; // Optional profile photo (for display only, NOT for recognition)

  WorkerModel({
    required this.id,
    required this.projectId,
    required this.name,
    this.nickname,
    required this.role,
    required this.dailyWage,
    this.faceEmbedding,
    required this.active,
    required this.createdAt,
    this.updatedAt,
    this.enrolledBy,
    this.photoUrl,
  });

  factory WorkerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkerModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      name: data['name'] ?? '',
      nickname: data['nickname'],
      role: data['role'] ?? '',
      dailyWage: (data['dailyWage'] as num?)?.toDouble() ?? 0.0,
      faceEmbedding: (data['faceEmbedding'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      active: data['active'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      enrolledBy: data['enrolledBy'],
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'name': name,
      'nickname': nickname,
      'role': role,
      'dailyWage': dailyWage,
      'faceEmbedding': faceEmbedding,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'enrolledBy': enrolledBy,
      'photoUrl': photoUrl,
    };
  }

  WorkerModel copyWith({
    String? id,
    String? projectId,
    String? name,
    String? nickname,
    String? role,
    double? dailyWage,
    List<double>? faceEmbedding,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? enrolledBy,
    String? photoUrl,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      role: role ?? this.role,
      dailyWage: dailyWage ?? this.dailyWage,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enrolledBy: enrolledBy ?? this.enrolledBy,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  bool get hasFaceEmbedding => faceEmbedding != null && faceEmbedding!.isNotEmpty;

  String get displayName => nickname?.isNotEmpty == true ? nickname! : name;
}

/// Face Recognition Result
class FaceRecognitionResult {
  final String workerId;
  final String workerName;
  final double confidence; // 0.0 to 1.0
  final bool isMatch; // true if confidence > threshold

  FaceRecognitionResult({
    required this.workerId,
    required this.workerName,
    required this.confidence,
    required this.isMatch,
  });
}

/// Face Attendance Record (extends WorkerAttendance)
class FaceAttendanceRecord {
  final String workerId;
  final String workerName;
  final String role;
  final double dailyWage;
  final bool present;
  final String verificationMethod; // 'FACE', 'MANUAL', 'GPS'
  final double? faceConfidence; // Only for FACE verification
  final DateTime? markedAt;
  final Map<String, dynamic>? geoLocation;

  FaceAttendanceRecord({
    required this.workerId,
    required this.workerName,
    required this.role,
    required this.dailyWage,
    required this.present,
    required this.verificationMethod,
    this.faceConfidence,
    this.markedAt,
    this.geoLocation,
  });

  Map<String, dynamic> toJson() {
    return {
      'workerId': workerId,
      'workerName': workerName,
      'role': role,
      'dailyWage': dailyWage,
      'present': present,
      'verificationMethod': verificationMethod,
      'faceConfidence': faceConfidence,
      'markedAt': markedAt != null ? Timestamp.fromDate(markedAt!) : null,
      'geoLocation': geoLocation,
    };
  }

  factory FaceAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return FaceAttendanceRecord(
      workerId: json['workerId'] ?? '',
      workerName: json['workerName'] ?? '',
      role: json['role'] ?? '',
      dailyWage: (json['dailyWage'] as num?)?.toDouble() ?? 0.0,
      present: json['present'] ?? false,
      verificationMethod: json['verificationMethod'] ?? 'MANUAL',
      faceConfidence: (json['faceConfidence'] as num?)?.toDouble(),
      markedAt: (json['markedAt'] as Timestamp?)?.toDate(),
      geoLocation: json['geoLocation'] as Map<String, dynamic>?,
    );
  }
}
