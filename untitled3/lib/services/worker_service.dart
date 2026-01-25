import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';

/// Worker Service - Manages daily wagers with face recognition
/// Project-scoped: projects/{projectId}/workers/{workerId}
class WorkerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get workers collection reference for a project
  static CollectionReference<Map<String, dynamic>> _workersCollection(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('workers');
  }

  /// Enroll a new worker with face embedding
  static Future<String> enrollWorker({
    required String projectId,
    required String name,
    String? nickname,
    required String role,
    required double dailyWage,
    required List<double> faceEmbedding,
    String? photoUrl,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final worker = WorkerModel(
      id: '', // Will be set by Firestore
      projectId: projectId,
      name: name,
      nickname: nickname,
      role: role,
      dailyWage: dailyWage,
      faceEmbedding: faceEmbedding,
      active: true,
      createdAt: DateTime.now(),
      enrolledBy: currentUserId,
      photoUrl: photoUrl,
    );

    final docRef = await _workersCollection(projectId).add(worker.toFirestore());
    return docRef.id;
  }

  /// Get all active workers for a project
  static Future<List<WorkerModel>> getActiveWorkers(String projectId) async {
    final snapshot = await _workersCollection(projectId)
        .where('active', isEqualTo: true)
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((doc) => WorkerModel.fromFirestore(doc))
        .toList();
  }

  /// Get all workers (including inactive) for a project
  static Future<List<WorkerModel>> getAllWorkers(String projectId) async {
    final snapshot = await _workersCollection(projectId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => WorkerModel.fromFirestore(doc))
        .toList();
  }

  /// Stream of active workers
  static Stream<List<WorkerModel>> getActiveWorkersStream(String projectId) {
    return _workersCollection(projectId)
        .where('active', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkerModel.fromFirestore(doc))
            .toList());
  }

  /// Get a specific worker
  static Future<WorkerModel?> getWorker(String projectId, String workerId) async {
    final doc = await _workersCollection(projectId).doc(workerId).get();
    
    if (doc.exists) {
      return WorkerModel.fromFirestore(doc);
    }
    return null;
  }

  /// Update worker information
  static Future<void> updateWorker({
    required String projectId,
    required String workerId,
    String? name,
    String? nickname,
    String? role,
    double? dailyWage,
    bool? active,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final Map<String, dynamic> updates = {
      'updatedAt': Timestamp.now(),
    };

    if (name != null) updates['name'] = name;
    if (nickname != null) updates['nickname'] = nickname;
    if (role != null) updates['role'] = role;
    if (dailyWage != null) updates['dailyWage'] = dailyWage;
    if (active != null) updates['active'] = active;

    await _workersCollection(projectId).doc(workerId).update(updates);
  }

  /// Update worker face embedding (re-enrollment)
  static Future<void> updateFaceEmbedding({
    required String projectId,
    required String workerId,
    required List<double> faceEmbedding,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _workersCollection(projectId).doc(workerId).update({
      'faceEmbedding': faceEmbedding,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Deactivate worker (soft delete)
  static Future<void> deactivateWorker(String projectId, String workerId) async {
    await updateWorker(
      projectId: projectId,
      workerId: workerId,
      active: false,
    );
  }

  /// Reactivate worker
  static Future<void> reactivateWorker(String projectId, String workerId) async {
    await updateWorker(
      projectId: projectId,
      workerId: workerId,
      active: true,
    );
  }

  /// Delete worker permanently
  static Future<void> deleteWorker(String projectId, String workerId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _workersCollection(projectId).doc(workerId).delete();
  }

  /// Get workers with face embeddings (for recognition)
  static Future<Map<String, List<double>>> getWorkerEmbeddings(String projectId) async {
    final workers = await getActiveWorkers(projectId);
    
    final Map<String, List<double>> embeddings = {};
    
    for (final worker in workers) {
      if (worker.hasFaceEmbedding) {
        embeddings[worker.id] = worker.faceEmbedding!;
      }
    }

    return embeddings;
  }

  /// Check if worker name already exists in project
  static Future<bool> isWorkerNameExists(String projectId, String name) async {
    final snapshot = await _workersCollection(projectId)
        .where('name', isEqualTo: name)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get worker statistics for a project
  static Future<Map<String, dynamic>> getWorkerStats(String projectId) async {
    final workers = await getAllWorkers(projectId);
    
    final activeCount = workers.where((w) => w.active).length;
    final inactiveCount = workers.where((w) => !w.active).length;
    final withFaceCount = workers.where((w) => w.hasFaceEmbedding).length;
    
    final totalWages = workers
        .where((w) => w.active)
        .fold<double>(0, (sum, w) => sum + w.dailyWage);

    return {
      'total': workers.length,
      'active': activeCount,
      'inactive': inactiveCount,
      'withFace': withFaceCount,
      'totalDailyWages': totalWages,
    };
  }

  /// Search workers by name
  static Future<List<WorkerModel>> searchWorkers(String projectId, String query) async {
    final workers = await getActiveWorkers(projectId);
    
    final lowerQuery = query.toLowerCase();
    return workers.where((worker) {
      return worker.name.toLowerCase().contains(lowerQuery) ||
             (worker.nickname?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
