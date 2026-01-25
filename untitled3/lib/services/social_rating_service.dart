import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/models/user_model.dart';
import '../common/models/project_model.dart';
import '../models/project_rating_model.dart';

/// Comprehensive Social & Rating Service for construction management system
/// Handles user discovery, project-based ratings, and rating aggregation
class SocialRatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user's role from Firestore
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

  /// Get all users for social tab (newly created users by role)
  /// Returns users ordered by creation date (newest first)
  static Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.uid != currentUserId) // Exclude current user
          .toList();
    });
  }

  /// Get user by UID for profile screen
  static Future<UserModel?> getUserByUid(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get completed projects for a specific user
  static Future<List<ProjectModel>> getUserCompletedProjects(String userUid) async {
    try {
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('status', isEqualTo: 'completed')
          .get();

      final userProjects = <ProjectModel>[];
      
      for (final doc in projectsSnapshot.docs) {
        final project = ProjectModel.fromFirestore(doc);
        
        // Check if user is involved in this project
        if (_isUserInvolvedInProject(project, userUid)) {
          userProjects.add(project);
        }
      }

      return userProjects;
    } catch (e) {
      return [];
    }
  }

  /// Check if user is involved in a project
  static bool _isUserInvolvedInProject(ProjectModel project, String userUid) {
    return project.ownerUid == userUid ||
           project.managerUid == userUid ||
           project.purchaseManagerUid == userUid ||
           project.createdBy == userUid; // Engineer who created
  }

  /// Check if current user can rate another user
  /// Based on role-based rules: Owner → Engineer/Manager/Contractor, etc.
  static Future<bool> canCurrentUserRate(String targetUserUid) async {
    if (currentUserId == null || currentUserId == targetUserUid) return false;

    try {
      final currentUserRole = await getCurrentUserRole();
      if (currentUserRole == null) return false;

      final targetUser = await getUserByUid(targetUserUid);
      if (targetUser == null) return false;

      return _isRatingAllowed(currentUserRole, targetUser.role);
    } catch (e) {
      return false;
    }
  }

  /// Check role-based rating permissions
  static bool _isRatingAllowed(String raterRole, String targetRole) {
    final normalizedRaterRole = raterRole.toLowerCase();
    final normalizedTargetRole = targetRole.toLowerCase();

    switch (normalizedRaterRole) {
      case 'ownerclient':
      case 'owner':
        // Owner can rate Engineer, Manager, Contractor
        return ['projectengineer', 'engineer', 'fieldmanager', 'manager', 'contractor'].contains(normalizedTargetRole);
      
      case 'projectengineer':
      case 'engineer':
        // Engineer can rate Manager, Contractor
        return ['fieldmanager', 'manager', 'contractor'].contains(normalizedTargetRole);
      
      case 'fieldmanager':
      case 'manager':
        // Manager can rate Contractor
        return ['contractor'].contains(normalizedTargetRole);
      
      default:
        return false;
    }
  }

  /// Get projects where both users worked together and project is completed
  static Future<List<ProjectModel>> getSharedCompletedProjects(String targetUserUid) async {
    if (currentUserId == null) return [];

    try {
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('status', isEqualTo: 'completed')
          .get();

      final sharedProjects = <ProjectModel>[];
      
      for (final doc in projectsSnapshot.docs) {
        final project = ProjectModel.fromFirestore(doc);
        
        // Check if both users are involved in this project
        if (_isUserInvolvedInProject(project, currentUserId!) &&
            _isUserInvolvedInProject(project, targetUserUid)) {
          sharedProjects.add(project);
        }
      }

      return sharedProjects;
    } catch (e) {
      return [];
    }
  }

  /// Check if current user has already rated target user in a specific project
  static Future<bool> hasAlreadyRated(String targetUserUid, String projectId) async {
    if (currentUserId == null) return false;

    try {
      final ratingsSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ratings')
          .where('ratedUserUid', isEqualTo: targetUserUid)
          .where('ratedByUid', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return ratingsSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Submit a project-based rating
  static Future<bool> submitRating({
    required String targetUserUid,
    required String projectId,
    required int deadlineScore,
    required int defectScore,
    required int paymentScore,
    required String comment,
  }) async {
    if (currentUserId == null) return false;

    try {
      // Validate scores
      if (deadlineScore < 0 || deadlineScore > 10 ||
          defectScore < 0 || defectScore > 10 ||
          paymentScore < 0 || paymentScore > 10) {
        return false;
      }

      // Check if already rated
      final alreadyRated = await hasAlreadyRated(targetUserUid, projectId);
      if (alreadyRated) return false;

      // Check if can rate
      final canRate = await canCurrentUserRate(targetUserUid);
      if (!canRate) return false;

      // Verify project is completed and both users are involved
      final sharedProjects = await getSharedCompletedProjects(targetUserUid);
      final targetProject = sharedProjects.where((p) => p.id == projectId).firstOrNull;
      if (targetProject == null) return false;

      // Get user roles
      final currentUserRole = await getCurrentUserRole();
      final targetUser = await getUserByUid(targetUserUid);
      if (currentUserRole == null || targetUser == null) return false;

      // Calculate final rating
      final finalRating = ProjectRatingModel.calculateFinalRating(
        deadlineScore: deadlineScore,
        defectScore: defectScore,
        paymentScore: paymentScore,
      );

      // Create rating model
      final rating = ProjectRatingModel(
        id: '',
        ratedUserUid: targetUserUid,
        ratedUserRole: targetUser.role,
        ratedByUid: currentUserId!,
        ratedByRole: currentUserRole,
        deadlineScore: deadlineScore,
        defectScore: defectScore,
        paymentScore: paymentScore,
        finalRating: finalRating,
        comment: comment,
        projectId: projectId,
        createdAt: DateTime.now(),
      );

      // Save rating to project's ratings subcollection
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ratings')
          .add(rating.toFirestore());

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
      final allRatings = <ProjectRatingModel>[];
      
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
          allRatings.add(ProjectRatingModel.fromFirestore(ratingDoc));
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
        final totalRating = allRatings.fold<double>(0.0, (sum, rating) => sum + rating.finalRating);
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

  /// Get all ratings for a specific user
  static Stream<List<ProjectRatingModel>> getUserRatings(String userUid) {
    return _firestore
        .collectionGroup('ratings')
        .where('ratedUserUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProjectRatingModel.fromFirestore(doc)).toList();
    });
  }

  /// Get projects available for rating a specific user
  static Future<List<Map<String, dynamic>>> getProjectsAvailableForRating(String targetUserUid) async {
    if (currentUserId == null) return [];

    try {
      final sharedProjects = await getSharedCompletedProjects(targetUserUid);
      final availableProjects = <Map<String, dynamic>>[];

      for (final project in sharedProjects) {
        // Check if current user has already rated in this project
        final alreadyRated = await hasAlreadyRated(targetUserUid, project.id);
        
        if (!alreadyRated) {
          availableProjects.add({
            'projectId': project.id,
            'projectName': project.projectName,
            'status': project.status,
            'completedAt': project.ownerApprovedAt, // Use as completion date
          });
        }
      }

      return availableProjects;
    } catch (e) {
      return [];
    }
  }

  /// Get rating statistics for a user
  static Future<Map<String, dynamic>> getUserRatingStats(String userUid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userUid).get();
      if (!userDoc.exists) {
        return {
          'ratingAvg': 0.0,
          'ratingCount': 0,
          'breakdown': <String, double>{},
        };
      }

      final userData = userDoc.data()!;
      final ratingAvg = (userData['ratingAvg'] ?? 0.0).toDouble();
      final ratingCount = userData['ratingCount'] ?? 0;

      // Get detailed breakdown
      final ratingsSnapshot = await _firestore
          .collectionGroup('ratings')
          .where('ratedUserUid', isEqualTo: userUid)
          .get();

      final ratings = ratingsSnapshot.docs
          .map((doc) => ProjectRatingModel.fromFirestore(doc))
          .toList();

      // Calculate breakdown by category
      final breakdown = <String, double>{};
      if (ratings.isNotEmpty) {
        final avgDeadline = ratings.fold<double>(0.0, (sum, r) => sum + r.deadlineScore) / ratings.length;
        final avgDefect = ratings.fold<double>(0.0, (sum, r) => sum + r.defectScore) / ratings.length;
        final avgPayment = ratings.fold<double>(0.0, (sum, r) => sum + r.paymentScore) / ratings.length;

        breakdown['deadline'] = double.parse(avgDeadline.toStringAsFixed(1));
        breakdown['defect'] = double.parse(avgDefect.toStringAsFixed(1));
        breakdown['payment'] = double.parse(avgPayment.toStringAsFixed(1));
      }

      return {
        'ratingAvg': ratingAvg,
        'ratingCount': ratingCount,
        'breakdown': breakdown,
      };
    } catch (e) {
      return {
        'ratingAvg': 0.0,
        'ratingCount': 0,
        'breakdown': <String, double>{},
      };
    }
  }

  /// Search users by name or role
  static Stream<List<UserModel>> searchUsers(String query) {
    if (query.isEmpty) {
      return getAllUsers();
    }

    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => 
              user.uid != currentUserId &&
              (user.name.toLowerCase().contains(query.toLowerCase()) ||
               user.role.toLowerCase().contains(query.toLowerCase()) ||
               user.generatedId.toLowerCase().contains(query.toLowerCase())))
          .toList();
    });
  }

  /// Get users by specific role
  static Stream<List<UserModel>> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.uid != currentUserId)
          .toList();
    });
  }
}