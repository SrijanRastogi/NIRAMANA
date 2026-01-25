import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comprehensive_rating_model.dart';
import '../common/models/project_model.dart';
import '../common/models/user_model.dart';
import '../services/impression_service.dart';

/// Comprehensive Rating Service - Handles detailed Engineer performance ratings
class ComprehensiveRatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Check if current user can rate the engineer for this project
  static Future<bool> canRateEngineer({
    required String projectId,
    required String engineerUid,
  }) async {
    if (currentUserId == null || currentUserId == engineerUid) return false;

    try {
      // Check if current user is the owner of the project
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) return false;

      final project = ProjectModel.fromFirestore(projectDoc);
      if (project.ownerUid != currentUserId) return false;

      // Check if rating already exists
      final existingRating = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('comprehensive_ratings')
          .where('engineerUid', isEqualTo: engineerUid)
          .where('ratedByUid', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return existingRating.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get project engineer information
  static Future<UserModel?> getProjectEngineer(String projectId) async {
    try {
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) return null;

      final project = ProjectModel.fromFirestore(projectDoc);
      if (project.createdBy.isEmpty) return null;

      final engineerDoc = await _firestore
          .collection('users')
          .doc(project.createdBy)
          .get();

      if (engineerDoc.exists) {
        return UserModel.fromFirestore(engineerDoc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Submit comprehensive rating
  static Future<bool> submitComprehensiveRating({
    required String projectId,
    required String engineerUid,
    required int deadlineRating,
    required int qualityRating,
    required int paymentRating,
    required int communicationRating,
    required int professionalismRating,
    required String deadlineFeedback,
    required String qualityFeedback,
    required String paymentFeedback,
    required String communicationFeedback,
    required String professionalismFeedback,
    required String overallComments,
  }) async {
    if (currentUserId == null) return false;

    try {
      // Validate eligibility
      final canRate = await canRateEngineer(
        projectId: projectId,
        engineerUid: engineerUid,
      );
      if (!canRate) return false;

      // Get owner name
      final ownerDoc = await _firestore.collection('users').doc(currentUserId!).get();
      final ownerName = ownerDoc.exists 
          ? (ownerDoc.data() as Map<String, dynamic>)['name'] ?? 'Project Owner'
          : 'Project Owner';

      // Calculate overall rating
      final overallRating = ComprehensiveRatingModel.calculateOverallRating(
        deadlineRating: deadlineRating,
        qualityRating: qualityRating,
        paymentRating: paymentRating,
        communicationRating: communicationRating,
        professionalismRating: professionalismRating,
      );

      // Create comprehensive rating
      final rating = ComprehensiveRatingModel(
        id: '',
        projectId: projectId,
        engineerUid: engineerUid,
        ratedByUid: currentUserId!,
        ratedByName: ownerName,
        deadlineRating: deadlineRating,
        qualityRating: qualityRating,
        paymentRating: paymentRating,
        communicationRating: communicationRating,
        professionalismRating: professionalismRating,
        overallRating: overallRating,
        deadlineFeedback: deadlineFeedback,
        qualityFeedback: qualityFeedback,
        paymentFeedback: paymentFeedback,
        communicationFeedback: communicationFeedback,
        professionalismFeedback: professionalismFeedback,
        overallComments: overallComments,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('comprehensive_ratings')
          .add(rating.toFirestore());

      // Create comprehensive rating impression notification
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      final projectName = projectDoc.exists 
          ? ProjectModel.fromFirestore(projectDoc).projectName
          : 'Project';

      await ImpressionService.createComprehensiveRatingImpression(
        targetUserUid: engineerUid,
        projectId: projectId,
        projectName: projectName,
        overallRating: overallRating,
        deadlineRating: deadlineRating,
        qualityRating: qualityRating,
        paymentRating: paymentRating,
        communicationRating: communicationRating,
        professionalismRating: professionalismRating,
        overallComments: overallComments,
        fromRole: 'Owner',
        fromUserName: ownerName,
      );

      // Update engineer's aggregate rating in user profile
      await _updateEngineerAggregateRating(engineerUid);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update engineer's aggregate rating across all projects
  static Future<void> _updateEngineerAggregateRating(String engineerUid) async {
    try {
      // Get all comprehensive ratings for this engineer
      final allRatings = <ComprehensiveRatingModel>[];
      
      // Query all projects to find ratings for this engineer
      final projectsSnapshot = await _firestore.collection('projects').get();
      
      for (final projectDoc in projectsSnapshot.docs) {
        final ratingsSnapshot = await _firestore
            .collection('projects')
            .doc(projectDoc.id)
            .collection('comprehensive_ratings')
            .where('engineerUid', isEqualTo: engineerUid)
            .where('isActive', isEqualTo: true)
            .get();
        
        for (final ratingDoc in ratingsSnapshot.docs) {
          allRatings.add(ComprehensiveRatingModel.fromFirestore(ratingDoc));
        }
      }

      if (allRatings.isEmpty) {
        // No ratings, set to 0
        await _firestore.collection('users').doc(engineerUid).update({
          'comprehensiveRatingAvg': 0.0,
          'comprehensiveRatingCount': 0,
        });
      } else {
        // Calculate average
        final totalRating = allRatings.fold<double>(0.0, (total, rating) => total + rating.overallRating);
        final avgRating = totalRating / allRatings.length;
        
        await _firestore.collection('users').doc(engineerUid).update({
          'comprehensiveRatingAvg': double.parse(avgRating.toStringAsFixed(2)),
          'comprehensiveRatingCount': allRatings.length,
        });
      }
    } catch (e) {
      // Handle error silently to not break the rating flow
    }
  }

  /// Get comprehensive ratings for an engineer
  static Future<List<ComprehensiveRatingModel>> getEngineerRatings(String engineerUid) async {
    try {
      final allRatings = <ComprehensiveRatingModel>[];
      
      // Query all projects to find ratings for this engineer
      final projectsSnapshot = await _firestore.collection('projects').get();
      
      for (final projectDoc in projectsSnapshot.docs) {
        final ratingsSnapshot = await _firestore
            .collection('projects')
            .doc(projectDoc.id)
            .collection('comprehensive_ratings')
            .where('engineerUid', isEqualTo: engineerUid)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
        
        for (final ratingDoc in ratingsSnapshot.docs) {
          allRatings.add(ComprehensiveRatingModel.fromFirestore(ratingDoc));
        }
      }

      // Sort by creation date (most recent first)
      allRatings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allRatings;
    } catch (e) {
      return [];
    }
  }

  /// Get comprehensive rating for a specific project
  static Future<ComprehensiveRatingModel?> getProjectRating({
    required String projectId,
    required String engineerUid,
  }) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('comprehensive_ratings')
          .where('engineerUid', isEqualTo: engineerUid)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        return ComprehensiveRatingModel.fromFirestore(ratingsSnapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get engineer's rating summary
  static Future<Map<String, dynamic>> getEngineerRatingSummary(String engineerUid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(engineerUid).get();
      if (!userDoc.exists) {
        return {'comprehensiveRatingAvg': 0.0, 'comprehensiveRatingCount': 0};
      }

      final data = userDoc.data()!;
      return {
        'comprehensiveRatingAvg': (data['comprehensiveRatingAvg'] ?? 0.0).toDouble(),
        'comprehensiveRatingCount': data['comprehensiveRatingCount'] ?? 0,
      };
    } catch (e) {
      return {'comprehensiveRatingAvg': 0.0, 'comprehensiveRatingCount': 0};
    }
  }
}