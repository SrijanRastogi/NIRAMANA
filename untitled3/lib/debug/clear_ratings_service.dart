import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Debug Service - Clear Rating Data for Testing
/// 
/// ⚠️ WARNING: This is for testing only. Remove in production.
class ClearRatingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Clear all ratings for a specific project
  static Future<bool> clearProjectRatings(String projectId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      print('🧹 Clearing ratings for project: $projectId');

      // Clear simple ratings (Rate Team)
      final simpleRatings = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ratings')
          .where('ratedByUid', isEqualTo: currentUser.uid)
          .get();

      for (final doc in simpleRatings.docs) {
        await doc.reference.delete();
        print('✅ Deleted simple rating: ${doc.id}');
      }

      // Clear comprehensive ratings (Rate Engineer Performance)
      final comprehensiveRatings = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('comprehensive_ratings')
          .where('ratedByUid', isEqualTo: currentUser.uid)
          .get();

      for (final doc in comprehensiveRatings.docs) {
        await doc.reference.delete();
        print('✅ Deleted comprehensive rating: ${doc.id}');
      }

      print('🎉 Successfully cleared all ratings for project: $projectId');
      return true;
    } catch (e) {
      print('❌ Error clearing ratings: $e');
      return false;
    }
  }

  /// Clear rating impressions for current user
  static Future<bool> clearRatingImpressions() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      print('🧹 Clearing rating impressions for user: ${currentUser.uid}');

      final impressions = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('impressions')
          .where('type', isEqualTo: 'rating_received')
          .get();

      for (final doc in impressions.docs) {
        await doc.reference.delete();
        print('✅ Deleted impression: ${doc.id}');
      }

      print('🎉 Successfully cleared rating impressions');
      return true;
    } catch (e) {
      print('❌ Error clearing impressions: $e');
      return false;
    }
  }

  /// Clear all rating data (ratings + impressions)
  static Future<bool> clearAllRatingData(String projectId) async {
    try {
      final ratingsCleared = await clearProjectRatings(projectId);
      final impressionsCleared = await clearRatingImpressions();
      
      return ratingsCleared && impressionsCleared;
    } catch (e) {
      print('❌ Error clearing all rating data: $e');
      return false;
    }
  }
}