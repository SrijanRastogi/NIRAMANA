    import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple Rating Model - Zomato-style rating system
/// Path: /projects/{projectId}/ratings/{ratingId}
class SimpleRatingModel {
  final String id;
  final String ratedUserUid;
  final String ratedByUid;
  final String projectId;
  final int rating;           // 1-10
  final String comment;       // Optional
  final DateTime createdAt;

  SimpleRatingModel({
    required this.id,
    required this.ratedUserUid,
    required this.ratedByUid,
    required this.projectId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  /// Create from Firestore document
  factory SimpleRatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SimpleRatingModel(
      id: doc.id,
      ratedUserUid: data['ratedUserUid'] ?? '',
      ratedByUid: data['ratedByUid'] ?? '',
      projectId: data['projectId'] ?? '',
      rating: data['rating'] ?? 5,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'ratedUserUid': ratedUserUid,
      'ratedByUid': ratedByUid,
      'projectId': projectId,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  String toString() {
    return 'SimpleRatingModel(ratedUserUid: $ratedUserUid, ratedByUid: $ratedByUid, rating: $rating)';
  }
}