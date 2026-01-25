import 'package:cloud_firestore/cloud_firestore.dart';

/// Rating Model for user ratings within projects
/// Stores individual ratings given by users to other users within specific projects
class RatingModel {
  final String id;
  final String ratedUserUid;
  final String ratedByUid;
  final String ratedByRole;
  final int rating;
  final String projectId;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.ratedUserUid,
    required this.ratedByUid,
    required this.ratedByRole,
    required this.rating,
    required this.projectId,
    required this.createdAt,
  });

  /// Create RatingModel from Firestore document
  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RatingModel(
      id: doc.id,
      ratedUserUid: data['ratedUserUid'] ?? '',
      ratedByUid: data['ratedByUid'] ?? '',
      ratedByRole: data['ratedByRole'] ?? '',
      rating: data['rating'] ?? 0,
      projectId: data['projectId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert RatingModel to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'ratedUserUid': ratedUserUid,
      'ratedByUid': ratedByUid,
      'ratedByRole': ratedByRole,
      'rating': rating,
      'projectId': projectId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  RatingModel copyWith({
    String? id,
    String? ratedUserUid,
    String? ratedByUid,
    String? ratedByRole,
    int? rating,
    String? projectId,
    DateTime? createdAt,
  }) {
    return RatingModel(
      id: id ?? this.id,
      ratedUserUid: ratedUserUid ?? this.ratedUserUid,
      ratedByUid: ratedByUid ?? this.ratedByUid,
      ratedByRole: ratedByRole ?? this.ratedByRole,
      rating: rating ?? this.rating,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'RatingModel(id: $id, ratedUserUid: $ratedUserUid, ratedByUid: $ratedByUid, rating: $rating, projectId: $projectId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RatingModel &&
        other.id == id &&
        other.ratedUserUid == ratedUserUid &&
        other.ratedByUid == ratedByUid &&
        other.rating == rating &&
        other.projectId == projectId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ratedUserUid.hashCode ^
        ratedByUid.hashCode ^
        rating.hashCode ^
        projectId.hashCode;
  }
}