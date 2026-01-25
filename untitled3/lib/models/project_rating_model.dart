import 'package:cloud_firestore/cloud_firestore.dart';

/// Project-based Rating Model for construction management system
/// Stores ratings given by users to other users within specific projects
/// Path: /projects/{projectId}/ratings/{ratingId}
class ProjectRatingModel {
  final String id;
  final String ratedUserUid;
  final String ratedUserRole;
  final String ratedByUid;
  final String ratedByRole;
  final int deadlineScore;    // 0-10
  final int defectScore;      // 0-10
  final int paymentScore;     // 0-10
  final double finalRating;   // Weighted result
  final String comment;
  final String projectId;
  final DateTime createdAt;

  ProjectRatingModel({
    required this.id,
    required this.ratedUserUid,
    required this.ratedUserRole,
    required this.ratedByUid,
    required this.ratedByRole,
    required this.deadlineScore,
    required this.defectScore,
    required this.paymentScore,
    required this.finalRating,
    required this.comment,
    required this.projectId,
    required this.createdAt,
  });

  /// Calculate final rating using weighted formula
  /// finalRating = (deadlineScore * 0.4) + (defectScore * 0.4) + (paymentScore * 0.2)
  static double calculateFinalRating({
    required int deadlineScore,
    required int defectScore,
    required int paymentScore,
  }) {
    final result = (deadlineScore * 0.4) + (defectScore * 0.4) + (paymentScore * 0.2);
    return double.parse(result.toStringAsFixed(1));
  }

  /// Create ProjectRatingModel from Firestore document
  factory ProjectRatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectRatingModel(
      id: doc.id,
      ratedUserUid: data['ratedUserUid'] ?? '',
      ratedUserRole: data['ratedUserRole'] ?? '',
      ratedByUid: data['ratedByUid'] ?? '',
      ratedByRole: data['ratedByRole'] ?? '',
      deadlineScore: data['deadlineScore'] ?? 0,
      defectScore: data['defectScore'] ?? 0,
      paymentScore: data['paymentScore'] ?? 0,
      finalRating: (data['finalRating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      projectId: data['projectId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert ProjectRatingModel to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'ratedUserUid': ratedUserUid,
      'ratedUserRole': ratedUserRole,
      'ratedByUid': ratedByUid,
      'ratedByRole': ratedByRole,
      'deadlineScore': deadlineScore,
      'defectScore': defectScore,
      'paymentScore': paymentScore,
      'finalRating': finalRating,
      'comment': comment,
      'projectId': projectId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  ProjectRatingModel copyWith({
    String? id,
    String? ratedUserUid,
    String? ratedUserRole,
    String? ratedByUid,
    String? ratedByRole,
    int? deadlineScore,
    int? defectScore,
    int? paymentScore,
    double? finalRating,
    String? comment,
    String? projectId,
    DateTime? createdAt,
  }) {
    return ProjectRatingModel(
      id: id ?? this.id,
      ratedUserUid: ratedUserUid ?? this.ratedUserUid,
      ratedUserRole: ratedUserRole ?? this.ratedUserRole,
      ratedByUid: ratedByUid ?? this.ratedByUid,
      ratedByRole: ratedByRole ?? this.ratedByRole,
      deadlineScore: deadlineScore ?? this.deadlineScore,
      defectScore: defectScore ?? this.defectScore,
      paymentScore: paymentScore ?? this.paymentScore,
      finalRating: finalRating ?? this.finalRating,
      comment: comment ?? this.comment,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ProjectRatingModel(id: $id, ratedUserUid: $ratedUserUid, ratedByUid: $ratedByUid, finalRating: $finalRating, projectId: $projectId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectRatingModel &&
        other.id == id &&
        other.ratedUserUid == ratedUserUid &&
        other.ratedByUid == ratedByUid &&
        other.projectId == projectId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ratedUserUid.hashCode ^
        ratedByUid.hashCode ^
        projectId.hashCode;
  }
}