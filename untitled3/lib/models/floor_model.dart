import 'package:cloud_firestore/cloud_firestore.dart';

/// Floor Model for tracking floor completion status
/// Used for real-time cash estimation based on completed floors
class FloorModel {
  final String id;
  final String projectId;
  final int floorNumber;
  final String status; // 'pending', 'in_progress', 'completed'
  final DateTime createdAt;
  final DateTime? completedAt;

  FloorModel({
    required this.id,
    required this.projectId,
    required this.floorNumber,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory FloorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FloorModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      floorNumber: data['floorNumber'] ?? 0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'floorNumber': floorNumber,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    };
  }

  bool get isCompleted => status == 'completed';
}
