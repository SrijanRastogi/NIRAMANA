import 'package:cloud_firestore/cloud_firestore.dart';

/// Impression Model for notifications about ratings and feedback
/// Path: /users/{userId}/impressions/{impressionId}
class ImpressionModel {
  final String id;
  final String type;           // "rating_received", "feedback_received", etc.
  final String projectId;
  final String fromRole;       // "owner", "manager", "engineer"
  final String fromUserUid;    // UID of the person who gave the rating
  final String fromUserName;   // Name of the person who gave the rating
  final String message;        // Display message
  final int? rating;           // Rating value (if applicable)
  final String? comment;       // Comment (if applicable)
  final bool read;             // Whether the impression has been read
  final DateTime createdAt;

  ImpressionModel({
    required this.id,
    required this.type,
    required this.projectId,
    required this.fromRole,
    required this.fromUserUid,
    required this.fromUserName,
    required this.message,
    this.rating,
    this.comment,
    required this.read,
    required this.createdAt,
  });

  /// Create from Firestore document
  factory ImpressionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ImpressionModel(
      id: doc.id,
      type: data['type'] ?? '',
      projectId: data['projectId'] ?? '',
      fromRole: data['fromRole'] ?? '',
      fromUserUid: data['fromUserUid'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      message: data['message'] ?? '',
      rating: data['rating'],
      comment: data['comment'],
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'projectId': projectId,
      'fromRole': fromRole,
      'fromUserUid': fromUserUid,
      'fromUserName': fromUserName,
      'message': message,
      if (rating != null) 'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      'read': read,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  ImpressionModel copyWith({
    String? id,
    String? type,
    String? projectId,
    String? fromRole,
    String? fromUserUid,
    String? fromUserName,
    String? message,
    int? rating,
    String? comment,
    bool? read,
    DateTime? createdAt,
  }) {
    return ImpressionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      projectId: projectId ?? this.projectId,
      fromRole: fromRole ?? this.fromRole,
      fromUserUid: fromUserUid ?? this.fromUserUid,
      fromUserName: fromUserName ?? this.fromUserName,
      message: message ?? this.message,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ImpressionModel(id: $id, type: $type, fromRole: $fromRole, message: $message, read: $read)';
  }
}