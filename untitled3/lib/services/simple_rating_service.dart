import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/simple_rating_model.dart';
import '../common/models/project_model.dart';

/// Simple Rating Service - Zomato-style rating system
/// Handles project-based ratings with automatic profile updates
class SimpleRatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Check if current user can rate another user in a specific project
  static Future<bool> canRateUser({
    required String projectId,
    required String targetUserUid,
  }) async {
    if (currentUserId == null || currentUserId == targetUserUid) return false;

    try {
      // 1. Check if project is completed
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) return false;

      final project = ProjectModel.fromFirestore(projectDoc);
      if (project.status.toLowerCase() != 'completed') return false;

      // 2. Check if both users are part of the project
      final currentUserInProject = _isUserInProject(project, currentUserId!);
      final targetUserInProject = _isUserInProject(project, targetUserUid);
      
      if (!currentUserInProject || !targetUserInProject) return false;

      // 3. Check if rating already exists
      final existingRating = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ratings')
          .where('ratedUserUid', isEqualTo: targetUserUid)
          .where('ratedByUid', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return existingRating.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is part of a project
  static bool _isUserInProject(ProjectModel project, String userUid) {
    return project.ownerUid == userUid ||
           project.managerUid == userUid ||
           project.createdBy == userUid ||
           project.purchaseManagerUid == userUid;
  }

  /// Get completed projects where both users worked together
  static Future<List<Map<String, dynamic>>> getSharedCompletedProjects(String targetUserUid) async {
    if (currentUserId == null) return [];

    try {
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('status', isEqualTo: 'completed')
          .get();

      final sharedProjects = <Map<String, dynamic>>[];

      for (final doc in projectsSnapshot.docs) {
        final project = ProjectModel.fromFirestore(doc);
        
        // Check if both users are in this project
        if (_isUserInProject(project, currentUserId!) && 
            _isUserInProject(project, targetUserUid)) {
          
          // Check if current user can rate in this project
          final canRate = await canRateUser(
            projectId: project.id,
            targetUserUid: targetUserUid,
          );

          if (canRate) {
            sharedProjects.add({
              'projectId': project.id,
              'projectName': project.projectName,
              'completedAt': project.ownerApprovedAt,
            });
          }
        }
      }

      return sharedProjects;
    } catch (e) {
      return [];
    }
  }

  /// Submit a rating
  static Future<bool> submitRating({
    required String projectId,
    required String targetUserUid,
    required int rating,
    required String comment,
  }) async {
    if (currentUserId == null) return false;
    if (rating < 1 || rating > 10) return false;

    try {
      // Validate eligibility
      final canRate = await canRateUser(
        projectId: projectId,
        targetUserUid: targetUserUid,
      );
      if (!canRate) return false;

      // Create rating
      final ratingModel = SimpleRatingModel(
        id: '',
        ratedUserUid: targetUserUid,
        ratedByUid: currentUserId!,
        projectId: projectId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      // Save to project's ratings subcollection
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ratings')
          .add(ratingModel.toFirestore());

      // Update user's aggregate rating
      await _updateUserAggregateRating(targetUserUid);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update user's aggregate rating (ratingAvg and ratingCount)
  static Future<void> _updateUserAggregateRating(String userUid) async {
    try {
      // Get all ratings for this user across all projects
      final allRatings = <SimpleRatingModel>[];
      
      // Query all projects to find ratings for this user
      final projectsSnapshot = await _firestore.collection('projects').get();
      
      for (final projectDoc in projectsSnapshot.docs) {
        final ratingsSnapshot = await _firestore
            .collection('projects')
            .doc(projectDoc.id)
            .collection('ratings')
            .where('ratedUserUid', isEqualTo: userUid)
            .get();
        
        for (final ratingDoc in ratingsSnapshot.docs) {
          allRatings.add(SimpleRatingModel.fromFirestore(ratingDoc));
        }
      }

      if (allRatings.isEmpty) {
        // No ratings, set to 0
        await _firestore.collection('users').doc(userUid).update({
          'ratingAvg': 0.0,
          'ratingCount': 0,
        });
      } else {
        // Calculate average
        final totalRating = allRatings.fold<int>(0, (total, rating) => total + rating.rating);
        final avgRating = totalRating / allRatings.length;
        
        await _firestore.collection('users').doc(userUid).update({
          'ratingAvg': double.parse(avgRating.toStringAsFixed(1)),
          'ratingCount': allRatings.length,
        });
      }
    } catch (e) {
      // Handle error silently to not break the rating flow
    }
  }

  /// Get user's rating summary
  static Future<Map<String, dynamic>> getUserRatingSummary(String userUid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userUid).get();
      if (!userDoc.exists) {
        return {'ratingAvg': 0.0, 'ratingCount': 0};
      }

      final data = userDoc.data()!;
      return {
        'ratingAvg': (data['ratingAvg'] ?? 0.0).toDouble(),
        'ratingCount': data['ratingCount'] ?? 0,
      };
    } catch (e) {
      return {'ratingAvg': 0.0, 'ratingCount': 0};
    }
  }
}