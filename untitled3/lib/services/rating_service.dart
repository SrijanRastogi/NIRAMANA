import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rating_model.dart';

/// Rating Service for managing user ratings within projects
/// Handles rating creation, validation, and aggregate calculations
class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user's role
  static Future<String?> getCurrentUserRole() async {
    if (currentUserId == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId!).get();
      if (!userDoc.exists) return null;
      
      final data = userDoc.data();
      return data?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Check if current user can rate others
  /// Only Owners and Engineers can rate, Managers cannot
  static Future<bool> canCurrentUserRate() async {
    final role = await getCurrentUserRole();
    if (role == null) return false;
    
    final normalizedRole = role.toLowerCase();
    return normalizedRole == 'ownerclient' || 
           normalizedRole == 'projectengineer' ||
           normalizedRole == 'owner' ||
           normalizedRole == 'engineer';
  }

  /// Check if user has already rated another user in a specific project
  static Future<bool> hasUserRatedInProject({
    required String ratedUserUid,
    required String projectId,
  }) async {
    if (currentUserId == null) return false;

    try {
      final querySnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ratings')
          .where('ratedUserUid', isEqualTo: ratedUserUid)
          .where('ratedByUid', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Submit a rating for a user in a project
  static Future<bool> submitRating({
    required String ratedUserUid,
    required String projectId,
    required int rating,
  }) async {
    if (currentUserId == null) return false;
    if (rating < 1 || rating > 10) return false;
    if (ratedUserUid == currentUserId) return false; // Cannot rate self

    try {
      // Check if user can rate
      final canRate = await canCurrentUserRate();
      if (!canRate) return false;

      // Check for duplicate rating
      final hasRated = await hasUserRatedInProject(
        ratedUserUid: ratedUserUid,
        projectId: projectId,
      );
      if (hasRated) return false;

      // Get current user's role
      final currentRole = await getCurrentUserRole();
      if (currentRole == null) return false;

      // Create rating document
      final ratingData = RatingModel(
        id: '',
        ratedUserUid: ratedUserUid,
        ratedByUid: currentUserId!,
        ratedByRole: currentRole,
        rating: rating,
        projectId: projectId,
        createdAt: DateTime.now(),
      );

      // Save rating to project's ratings subcollection
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ratings')
          .add(ratingData.toFirestore());

      // Update user's aggregate rating
      await _updateUserAggregateRating(ratedUserUid);

      return true;
    } catch (e) {
      return false;
    }
  }
  /// Update user's aggregate rating (average and count)
  static Future<void> _updateUserAggregateRating(String userUid) async {
    try {
      // Get all ratings for this user across all projects
      final allRatings = <RatingModel>[];
      
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
          allRatings.add(RatingModel.fromFirestore(ratingDoc));
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

  /// Get ratings for a specific user
  static Stream<List<RatingModel>> getUserRatings(String userUid) {
    return _firestore
        .collectionGroup('ratings')
        .where('ratedUserUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RatingModel.fromFirestore(doc)).toList();
    });
  }

  /// Get user's projects where they can be rated
  static Future<List<String>> getUserRatableProjects(String userUid) async {
    try {
      // Get projects where user is involved (as owner, manager, or engineer)
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('participants', arrayContains: userUid)
          .get();

      return projectsSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get projects where current user can rate the target user
  static Future<List<Map<String, dynamic>>> getProjectsForRating(String targetUserUid) async {
    if (currentUserId == null) return [];

    try {
      // Get all projects where both users are involved
      final projectsSnapshot = await _firestore.collection('projects').get();
      final ratableProjects = <Map<String, dynamic>>[];

      for (final projectDoc in projectsSnapshot.docs) {
        final projectData = projectDoc.data();
        final projectId = projectDoc.id;
        
        // Check if both users are involved in this project
        final participants = List<String>.from(projectData['participants'] ?? []);
        final managerId = projectData['managerId'] as String?;
        final engineerId = projectData['engineerId'] as String?;
        final ownerId = projectData['ownerId'] as String?;
        
        final allInvolved = [
          ...participants,
          if (managerId != null) managerId,
          if (engineerId != null) engineerId,
          if (ownerId != null) ownerId,
        ];

        if (allInvolved.contains(currentUserId) && allInvolved.contains(targetUserUid)) {
          // Check if current user has already rated in this project
          final hasRated = await hasUserRatedInProject(
            ratedUserUid: targetUserUid,
            projectId: projectId,
          );

          if (!hasRated) {
            ratableProjects.add({
              'projectId': projectId,
              'projectName': projectData['projectName'] ?? 'Unknown Project',
              'status': projectData['status'] ?? 'unknown',
            });
          }
        }
      }

      return ratableProjects;
    } catch (e) {
      return [];
    }
  }
}