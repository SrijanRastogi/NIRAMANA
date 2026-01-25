import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive Rating Model for Engineer performance evaluation
/// Based on deadlines, defect history, and payment advice
/// Path: /projects/{projectId}/comprehensive_ratings/{ratingId}
class ComprehensiveRatingModel {
  final String id;
  final String projectId;
  final String engineerUid;
  final String ratedByUid;        // Owner UID
  final String ratedByName;       // Owner name
  
  // Rating Components (1-10 scale each)
  final int deadlineRating;       // Meeting project deadlines
  final int qualityRating;        // Work quality / defect history
  final int paymentRating;        // Payment advice and financial management
  final int communicationRating;  // Communication and updates
  final int professionalismRating; // Overall professionalism
  
  // Overall calculated rating (average of components)
  final double overallRating;
  
  // Detailed feedback
  final String deadlineFeedback;
  final String qualityFeedback;
  final String paymentFeedback;
  final String communicationFeedback;
  final String professionalismFeedback;
  final String overallComments;
  
  // Metadata
  final DateTime createdAt;
  final bool isActive;            // Can be deactivated if needed

  ComprehensiveRatingModel({
    required this.id,
    required this.projectId,
    required this.engineerUid,
    required this.ratedByUid,
    required this.ratedByName,
    required this.deadlineRating,
    required this.qualityRating,
    required this.paymentRating,
    required this.communicationRating,
    required this.professionalismRating,
    required this.overallRating,
    required this.deadlineFeedback,
    required this.qualityFeedback,
    required this.paymentFeedback,
    required this.communicationFeedback,
    required this.professionalismFeedback,
    required this.overallComments,
    required this.createdAt,
    this.isActive = true,
  });

  /// Create from Firestore document
  factory ComprehensiveRatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComprehensiveRatingModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      engineerUid: data['engineerUid'] ?? '',
      ratedByUid: data['ratedByUid'] ?? '',
      ratedByName: data['ratedByName'] ?? '',
      deadlineRating: data['deadlineRating'] ?? 5,
      qualityRating: data['qualityRating'] ?? 5,
      paymentRating: data['paymentRating'] ?? 5,
      communicationRating: data['communicationRating'] ?? 5,
      professionalismRating: data['professionalismRating'] ?? 5,
      overallRating: (data['overallRating'] ?? 5.0).toDouble(),
      deadlineFeedback: data['deadlineFeedback'] ?? '',
      qualityFeedback: data['qualityFeedback'] ?? '',
      paymentFeedback: data['paymentFeedback'] ?? '',
      communicationFeedback: data['communicationFeedback'] ?? '',
      professionalismFeedback: data['professionalismFeedback'] ?? '',
      overallComments: data['overallComments'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'engineerUid': engineerUid,
      'ratedByUid': ratedByUid,
      'ratedByName': ratedByName,
      'deadlineRating': deadlineRating,
      'qualityRating': qualityRating,
      'paymentRating': paymentRating,
      'communicationRating': communicationRating,
      'professionalismRating': professionalismRating,
      'overallRating': overallRating,
      'deadlineFeedback': deadlineFeedback,
      'qualityFeedback': qualityFeedback,
      'paymentFeedback': paymentFeedback,
      'communicationFeedback': communicationFeedback,
      'professionalismFeedback': professionalismFeedback,
      'overallComments': overallComments,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  /// Calculate overall rating from components
  static double calculateOverallRating({
    required int deadlineRating,
    required int qualityRating,
    required int paymentRating,
    required int communicationRating,
    required int professionalismRating,
  }) {
    final total = deadlineRating + qualityRating + paymentRating + 
                  communicationRating + professionalismRating;
    return total / 5.0;
  }

  /// Get rating category description
  String getRatingDescription() {
    if (overallRating >= 9.0) return 'Exceptional';
    if (overallRating >= 8.0) return 'Excellent';
    if (overallRating >= 7.0) return 'Very Good';
    if (overallRating >= 6.0) return 'Good';
    if (overallRating >= 5.0) return 'Average';
    if (overallRating >= 4.0) return 'Below Average';
    if (overallRating >= 3.0) return 'Poor';
    return 'Very Poor';
  }

  /// Get rating color for UI
  String getRatingColor() {
    if (overallRating >= 8.0) return '#10B981'; // Green
    if (overallRating >= 6.0) return '#F59E0B'; // Orange
    return '#EF4444'; // Red
  }

  /// Create a copy with updated fields
  ComprehensiveRatingModel copyWith({
    String? id,
    String? projectId,
    String? engineerUid,
    String? ratedByUid,
    String? ratedByName,
    int? deadlineRating,
    int? qualityRating,
    int? paymentRating,
    int? communicationRating,
    int? professionalismRating,
    double? overallRating,
    String? deadlineFeedback,
    String? qualityFeedback,
    String? paymentFeedback,
    String? communicationFeedback,
    String? professionalismFeedback,
    String? overallComments,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ComprehensiveRatingModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      engineerUid: engineerUid ?? this.engineerUid,
      ratedByUid: ratedByUid ?? this.ratedByUid,
      ratedByName: ratedByName ?? this.ratedByName,
      deadlineRating: deadlineRating ?? this.deadlineRating,
      qualityRating: qualityRating ?? this.qualityRating,
      paymentRating: paymentRating ?? this.paymentRating,
      communicationRating: communicationRating ?? this.communicationRating,
      professionalismRating: professionalismRating ?? this.professionalismRating,
      overallRating: overallRating ?? this.overallRating,
      deadlineFeedback: deadlineFeedback ?? this.deadlineFeedback,
      qualityFeedback: qualityFeedback ?? this.qualityFeedback,
      paymentFeedback: paymentFeedback ?? this.paymentFeedback,
      communicationFeedback: communicationFeedback ?? this.communicationFeedback,
      professionalismFeedback: professionalismFeedback ?? this.professionalismFeedback,
      overallComments: overallComments ?? this.overallComments,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'ComprehensiveRatingModel(id: $id, projectId: $projectId, engineerUid: $engineerUid, overallRating: $overallRating)';
  }
}