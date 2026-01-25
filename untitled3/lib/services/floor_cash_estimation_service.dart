import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/floor_model.dart';
import '../common/models/project_model.dart';

/// Floor-based Cash Estimation Service
/// Provides real-time cash estimation based on completed floors
/// OWNER-ONLY functionality
class FloorCashEstimationService {
  static final FloorCashEstimationService _instance = FloorCashEstimationService._internal();
  factory FloorCashEstimationService() => _instance;
  FloorCashEstimationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update project configuration (total floors and estimated cost)
  /// Can only be called once or with confirmation
  Future<void> updateProjectConfiguration({
    required String projectId,
    required int totalFloors,
    required double totalEstimatedCost,
  }) async {
    if (totalFloors <= 0) {
      throw Exception('Total floors must be greater than 0');
    }
    if (totalEstimatedCost <= 0) {
      throw Exception('Total estimated cost must be greater than 0');
    }

    final projectRef = _firestore.collection('projects').doc(projectId);
    
    await projectRef.update({
      'totalFloors': totalFloors,
      'totalEstimatedCost': totalEstimatedCost,
      'configuredAt': Timestamp.now(),
    });

    // Initialize floor documents if they don't exist
    await _initializeFloors(projectId, totalFloors);
  }

  /// Initialize floor documents for a project
  Future<void> _initializeFloors(String projectId, int totalFloors) async {
    final floorsRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('floors');

    final existingFloors = await floorsRef.get();
    final existingFloorNumbers = existingFloors.docs
        .map((doc) => (doc.data()['floorNumber'] as int?) ?? 0)
        .toSet();

    final batch = _firestore.batch();
    
    for (int i = 1; i <= totalFloors; i++) {
      if (!existingFloorNumbers.contains(i)) {
        final floorRef = floorsRef.doc();
        batch.set(floorRef, {
          'projectId': projectId,
          'floorNumber': i,
          'status': 'pending',
          'createdAt': Timestamp.now(),
        });
      }
    }

    await batch.commit();
  }

  /// Get project configuration
  Future<Map<String, dynamic>?> getProjectConfiguration(String projectId) async {
    final projectDoc = await _firestore.collection('projects').doc(projectId).get();
    
    if (!projectDoc.exists) return null;
    
    final data = projectDoc.data()!;
    final totalFloors = data['totalFloors'] as int?;
    final totalEstimatedCost = (data['totalEstimatedCost'] as num?)?.toDouble();
    
    if (totalFloors == null || totalEstimatedCost == null) {
      return null;
    }

    return {
      'totalFloors': totalFloors,
      'totalEstimatedCost': totalEstimatedCost,
      'configuredAt': data['configuredAt'],
    };
  }

  /// Stream of cash estimation data
  Stream<Map<String, dynamic>> getCashEstimationStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .asyncMap((projectDoc) async {
      if (!projectDoc.exists) {
        return {
          'configured': false,
          'error': 'Project not found',
        };
      }

      final projectData = projectDoc.data()!;
      final totalFloors = projectData['totalFloors'] as int?;
      final totalEstimatedCost = (projectData['totalEstimatedCost'] as num?)?.toDouble();

      if (totalFloors == null || totalEstimatedCost == null) {
        return {
          'configured': false,
          'message': 'Project configuration pending',
        };
      }

      // Get completed floors count
      final floorsSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('floors')
          .where('status', isEqualTo: 'completed')
          .get();

      final completedFloors = floorsSnapshot.docs.length;
      final amountPerFloor = totalEstimatedCost / totalFloors;
      final utilizedAmount = completedFloors * amountPerFloor;
      final remainingAmount = totalEstimatedCost - utilizedAmount;

      return {
        'configured': true,
        'totalFloors': totalFloors,
        'totalEstimatedCost': totalEstimatedCost,
        'completedFloors': completedFloors,
        'amountPerFloor': amountPerFloor,
        'utilizedAmount': utilizedAmount,
        'remainingAmount': remainingAmount,
        'completionPercentage': (completedFloors / totalFloors) * 100,
      };
    });
  }

  /// Get all floors for a project
  Stream<List<FloorModel>> getFloorsStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('floors')
        .orderBy('floorNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FloorModel.fromFirestore(doc))
            .toList());
  }

  /// Update floor status (for testing/admin purposes)
  Future<void> updateFloorStatus({
    required String projectId,
    required String floorId,
    required String status,
  }) async {
    final floorRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('floors')
        .doc(floorId);

    final Map<String, dynamic> updateData = {
      'status': status,
    };

    if (status == 'completed') {
      updateData['completedAt'] = Timestamp.now();
    }

    await floorRef.update(updateData);
  }

  /// Check if project is configured
  Future<bool> isProjectConfigured(String projectId) async {
    final config = await getProjectConfiguration(projectId);
    return config != null;
  }
}
