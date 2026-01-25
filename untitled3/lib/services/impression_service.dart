import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/impression_model.dart';

/// Impression Service - Handles impression notifications for ratings and feedback
class ImpressionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Create a comprehensive rating impression for a user
  static Future<bool> createComprehensiveRatingImpression({
    required String targetUserUid,
    required String projectId,
    required String projectName,
    required double overallRating,
    required int deadlineRating,
    required int qualityRating,
    required int paymentRating,
    required int communicationRating,
    required int professionalismRating,
    required String overallComments,
    required String fromRole,
    required String fromUserName,
  }) async {
    if (currentUserId == null) return false;

    try {
      // Create detailed message about the comprehensive rating
      final ratingDescription = _getRatingDescription(overallRating);
      final detailedMessage = '$fromUserName completed a comprehensive performance evaluation for $projectName. '
          'Overall Rating: ${overallRating.toStringAsFixed(1)}/10 ($ratingDescription)';
      
      // Create detailed comment with breakdown
      final detailedComment = '''
Performance Breakdown:
• Deadline Management: $deadlineRating/10
• Work Quality: $qualityRating/10  
• Payment Advice: $paymentRating/10
• Communication: $communicationRating/10
• Professionalism: $professionalismRating/10

${overallComments.isNotEmpty ? 'Comments: $overallComments' : ''}
      '''.trim();

      final impression = ImpressionModel(
        id: '',
        type: 'comprehensive_rating_received',
        projectId: projectId,
        fromRole: fromRole.toLowerCase(),
        fromUserUid: currentUserId!,
        fromUserName: fromUserName,
        message: detailedMessage,
        rating: overallRating.round(),
        comment: detailedComment,
        read: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(targetUserUid)
          .collection('impressions')
          .add(impression.toFirestore());

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get rating description helper method
  static String _getRatingDescription(double rating) {
    if (rating >= 9.0) return 'Exceptional';
    if (rating >= 8.0) return 'Excellent';
    if (rating >= 7.0) return 'Very Good';
    if (rating >= 6.0) return 'Good';
    if (rating >= 5.0) return 'Average';
    if (rating >= 4.0) return 'Below Average';
    if (rating >= 3.0) return 'Poor';
    return 'Very Poor';
  }
  static Future<bool> createRatingImpression({
    required String targetUserUid,
    required String projectId,
    required String projectName,
    required int rating,
    required String comment,
    required String fromRole,
    required String fromUserName,
  }) async {
    if (currentUserId == null) return false;

    try {
      final impression = ImpressionModel(
        id: '',
        type: 'rating_received',
        projectId: projectId,
        fromRole: fromRole.toLowerCase(),
        fromUserUid: currentUserId!,
        fromUserName: fromUserName,
        message: '$fromUserName rated you $rating/10 on $projectName',
        rating: rating,
        comment: comment.isNotEmpty ? comment : null,
        read: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(targetUserUid)
          .collection('impressions')
          .add(impression.toFirestore());

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get impressions for current user
  static Stream<List<ImpressionModel>> getUserImpressions() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('impressions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ImpressionModel.fromFirestore(doc))
            .toList());
  }

  /// Get unread impressions count for current user
  static Stream<int> getUnreadImpressionsCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('impressions')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark impression as read
  static Future<bool> markImpressionAsRead(String impressionId) async {
    if (currentUserId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('impressions')
          .doc(impressionId)
          .update({'read': true});

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark all impressions as read
  static Future<bool> markAllImpressionsAsRead() async {
    if (currentUserId == null) return false;

    try {
      final batch = _firestore.batch();
      final impressions = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('impressions')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in impressions.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete impression
  static Future<bool> deleteImpression(String impressionId) async {
    if (currentUserId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('impressions')
          .doc(impressionId)
          .delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get impressions for a specific project
  static Stream<List<ImpressionModel>> getProjectImpressions(String projectId) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('impressions')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ImpressionModel.fromFirestore(doc))
            .toList());
  }
}