import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Project Migration Helper
/// Fixes existing projects that don't have ownerUid and managerUid fields
/// This is a one-time migration to ensure data consistency with Firestore rules
class ProjectMigrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Migrate a single project to add ownerUid and managerUid if missing
  /// Returns true if migration was needed and successful
  static Future<bool> migrateProjectIfNeeded(String projectId) async {
    try {
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      
      if (!projectDoc.exists) {
        print('❌ Project $projectId not found');
        return false;
      }

      final data = projectDoc.data() as Map<String, dynamic>;
      
      // Check if migration is needed
      final hasOwnerUid = data.containsKey('ownerUid') && data['ownerUid'] != null;
      final hasManagerUid = data.containsKey('managerUid') && data['managerUid'] != null;
      
      if (hasOwnerUid && hasManagerUid) {
        print('✅ Project $projectId already has ownerUid and managerUid');
        return false;
      }

      // Get owner and manager UIDs from the data
      final ownerId = data['ownerId'] as String?;
      final managerId = data['managerId'] as String?;
      
      if (ownerId == null || managerId == null) {
        print('❌ Project $projectId missing ownerId or managerId');
        return false;
      }

      // Prepare update payload
      final updatePayload = <String, dynamic>{};
      
      if (!hasOwnerUid) {
        updatePayload['ownerUid'] = ownerId;
        print('📝 Adding ownerUid: $ownerId');
      }
      
      if (!hasManagerUid) {
        updatePayload['managerUid'] = managerId;
        print('📝 Adding managerUid: $managerId');
      }

      // Apply migration
      await _firestore.collection('projects').doc(projectId).update(updatePayload);
      print('✅ Project $projectId migrated successfully');
      return true;
    } catch (e) {
      print('❌ Migration failed for project $projectId: $e');
      return false;
    }
  }

  /// Migrate all projects in the database
  /// This should only be run once by an admin
  /// Returns count of projects migrated
  static Future<int> migrateAllProjects() async {
    try {
      print('🔄 Starting project migration...');
      
      final projectsSnapshot = await _firestore.collection('projects').get();
      int migratedCount = 0;
      
      print('📊 Found ${projectsSnapshot.docs.length} projects to check');
      
      for (final projectDoc in projectsSnapshot.docs) {
        final migrated = await migrateProjectIfNeeded(projectDoc.id);
        if (migrated) {
          migratedCount++;
        }
      }
      
      print('✅ Migration complete: $migratedCount projects updated');
      return migratedCount;
    } catch (e) {
      print('❌ Migration failed: $e');
      return 0;
    }
  }

  /// Check project data consistency
  /// Returns a report of issues found
  static Future<Map<String, dynamic>> checkProjectConsistency(String projectId) async {
    try {
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      
      if (!projectDoc.exists) {
        return {
          'exists': false,
          'issues': ['Project not found'],
        };
      }

      final data = projectDoc.data() as Map<String, dynamic>;
      final issues = <String>[];
      
      // Check required fields
      if (data['ownerId'] == null || (data['ownerId'] as String).isEmpty) {
        issues.add('Missing or empty ownerId');
      }
      if (data['managerId'] == null || (data['managerId'] as String).isEmpty) {
        issues.add('Missing or empty managerId');
      }
      if (data['createdBy'] == null || (data['createdBy'] as String).isEmpty) {
        issues.add('Missing or empty createdBy (engineer UID)');
      }
      
      // Check ownerUid and managerUid
      if (data['ownerUid'] == null || (data['ownerUid'] as String).isEmpty) {
        issues.add('Missing or empty ownerUid');
      }
      if (data['managerUid'] == null || (data['managerUid'] as String).isEmpty) {
        issues.add('Missing or empty managerUid');
      }
      
      // Check if UIDs match
      if (data['ownerId'] != data['ownerUid']) {
        issues.add('ownerId (${data['ownerId']}) does not match ownerUid (${data['ownerUid']})');
      }
      if (data['managerId'] != data['managerUid']) {
        issues.add('managerId (${data['managerId']}) does not match managerUid (${data['managerUid']})');
      }
      
      return {
        'exists': true,
        'projectId': projectId,
        'ownerId': data['ownerId'],
        'ownerUid': data['ownerUid'],
        'managerId': data['managerId'],
        'managerUid': data['managerUid'],
        'createdBy': data['createdBy'],
        'status': data['status'],
        'issues': issues,
        'isConsistent': issues.isEmpty,
      };
    } catch (e) {
      return {
        'exists': false,
        'issues': ['Error checking consistency: $e'],
      };
    }
  }

  /// Validate that current user can approve a project
  /// This is a debug helper to understand permission issues
  static Future<Map<String, dynamic>> validateOwnerApprovalPermission(String projectId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'canApprove': false,
          'reason': 'User not authenticated',
        };
      }

      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) {
        return {
          'canApprove': false,
          'reason': 'Project not found',
        };
      }

      final data = projectDoc.data() as Map<String, dynamic>;
      final currentUid = currentUser.uid;
      
      // Check all possible owner fields
      final ownerId = data['ownerId'] as String?;
      final ownerUid = data['ownerUid'] as String?;
      final ownerPublicId = data['ownerPublicId'] as String?;
      
      final isOwnerByOwnerId = currentUid == ownerId;
      final isOwnerByOwnerUid = currentUid == ownerUid;
      final isOwnerByPublicId = currentUid == ownerPublicId;
      
      final canApprove = isOwnerByOwnerId || isOwnerByOwnerUid || isOwnerByPublicId;
      
      return {
        'canApprove': canApprove,
        'currentUid': currentUid,
        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerPublicId': ownerPublicId,
        'isOwnerByOwnerId': isOwnerByOwnerId,
        'isOwnerByOwnerUid': isOwnerByOwnerUid,
        'isOwnerByPublicId': isOwnerByPublicId,
        'reason': canApprove ? 'User is project owner' : 'User is not project owner',
      };
    } catch (e) {
      return {
        'canApprove': false,
        'reason': 'Error validating permission: $e',
      };
    }
  }
}
