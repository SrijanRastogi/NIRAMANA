import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/tool_model.dart';
import '../models/tool_transaction_model.dart';

class ToolService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get tool by ID
  static Future<ToolModel?> getToolById(String toolId) async {
    try {
      final doc = await _firestore.collection('tools').doc(toolId).get();
      if (doc.exists) {
        return ToolModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching tool: $e');
      return null;
    }
  }

  /// Check if tool is available for borrowing
  static Future<bool> isToolAvailable(String toolId) async {
    try {
      final tool = await getToolById(toolId);
      return tool != null && tool.status == 'AVAILABLE';
    } catch (e) {
      print('Error checking tool availability: $e');
      return false;
    }
  }

  /// Get active transaction for a tool (where returnedAt is null)
  static Future<ToolTransactionModel?> getActiveTransaction(String toolId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tool_transactions')
          .where('toolId', isEqualTo: toolId)
          .where('returnedAt', isNull: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return ToolTransactionModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error fetching active transaction: $e');
      return null;
    }
  }

  /// Borrow a tool
  static Future<Map<String, dynamic>> borrowTool({
    required String toolId,
    required String workerName,
    required String mobileNumber,
    required String projectId,
    required DateTime expectedReturnAt,
    required String borrowQrImageUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Check if tool is available
      final isAvailable = await isToolAvailable(toolId);
      if (!isAvailable) {
        return {'success': false, 'error': 'Tool is not available for borrowing'};
      }

      // Create transaction
      final transactionRef = _firestore.collection('tool_transactions').doc();
      final transaction = ToolTransactionModel(
        transactionId: transactionRef.id,
        toolId: toolId,
        workerName: workerName,
        mobileNumber: mobileNumber,
        projectId: projectId,
        borrowedAt: DateTime.now(),
        expectedReturnAt: expectedReturnAt,
        borrowQrImageUrl: borrowQrImageUrl,
        managerId: currentUser.uid,
        isSynced: true,
      );

      // Use Firestore batch for atomic operation
      final batch = _firestore.batch();

      // Update tool status
      batch.update(
        _firestore.collection('tools').doc(toolId),
        {'status': 'IN_USE'},
      );

      // Create transaction record
      batch.set(transactionRef, transaction.toFirestore());

      await batch.commit();

      return {'success': true, 'transactionId': transactionRef.id};
    } catch (e) {
      print('Error borrowing tool: $e');
      return {'success': false, 'error': 'Failed to borrow tool: $e'};
    }
  }

  /// Borrow tool offline (save to Hive)
  static Future<Map<String, dynamic>> borrowToolOffline({
    required String toolId,
    required String workerName,
    required String mobileNumber,
    required String projectId,
    required DateTime expectedReturnAt,
    required String borrowQrImageUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final box = await Hive.openBox('offline_tool_transactions');
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

      final transaction = ToolTransactionModel(
        transactionId: transactionId,
        toolId: toolId,
        workerName: workerName,
        mobileNumber: mobileNumber,
        projectId: projectId,
        borrowedAt: DateTime.now(),
        expectedReturnAt: expectedReturnAt,
        borrowQrImageUrl: borrowQrImageUrl,
        managerId: currentUser.uid,
        isSynced: false,
      );

      await box.put(transactionId, transaction.toMap());

      return {'success': true, 'transactionId': transactionId};
    } catch (e) {
      print('Error saving offline tool transaction: $e');
      return {'success': false, 'error': 'Failed to save offline: $e'};
    }
  }

  /// Return a tool
  static Future<Map<String, dynamic>> returnTool({
    required String toolId,
    required String condition,
    required String returnQrImageUrl,
  }) async {
    try {
      // Get active transaction
      final activeTransaction = await getActiveTransaction(toolId);
      if (activeTransaction == null) {
        return {'success': false, 'error': 'No active transaction found for this tool'};
      }

      // Use Firestore batch for atomic operation
      final batch = _firestore.batch();

      // Update tool status
      batch.update(
        _firestore.collection('tools').doc(toolId),
        {'status': 'AVAILABLE'},
      );

      // Update transaction
      batch.update(
        _firestore.collection('tool_transactions').doc(activeTransaction.transactionId),
        {
          'returnedAt': Timestamp.now(),
          'condition': condition,
          'returnQrImageUrl': returnQrImageUrl,
        },
      );

      await batch.commit();

      return {'success': true, 'transactionId': activeTransaction.transactionId};
    } catch (e) {
      print('Error returning tool: $e');
      return {'success': false, 'error': 'Failed to return tool: $e'};
    }
  }

  /// Return tool offline (save to Hive)
  static Future<Map<String, dynamic>> returnToolOffline({
    required String toolId,
    required String condition,
    required String returnQrImageUrl,
  }) async {
    try {
      final box = await Hive.openBox('offline_tool_returns');
      final returnId = DateTime.now().millisecondsSinceEpoch.toString();

      final returnData = {
        'returnId': returnId,
        'toolId': toolId,
        'condition': condition,
        'returnQrImageUrl': returnQrImageUrl,
        'returnedAt': DateTime.now().toIso8601String(),
        'isSynced': false,
      };

      await box.put(returnId, returnData);

      return {'success': true, 'returnId': returnId};
    } catch (e) {
      print('Error saving offline tool return: $e');
      return {'success': false, 'error': 'Failed to save offline: $e'};
    }
  }

  /// Sync offline transactions to Firestore
  static Future<void> syncOfflineTransactions() async {
    try {
      // Sync borrow transactions
      final borrowBox = await Hive.openBox('offline_tool_transactions');
      for (var key in borrowBox.keys) {
        final data = borrowBox.get(key) as Map<String, dynamic>;
        final transaction = ToolTransactionModel.fromMap(data);

        if (!transaction.isSynced) {
          final result = await borrowTool(
            toolId: transaction.toolId,
            workerName: transaction.workerName,
            mobileNumber: transaction.mobileNumber,
            projectId: transaction.projectId,
            expectedReturnAt: transaction.expectedReturnAt,
            borrowQrImageUrl: transaction.borrowQrImageUrl,
          );

          if (result['success'] == true) {
            await borrowBox.delete(key);
          }
        }
      }

      // Sync return transactions
      final returnBox = await Hive.openBox('offline_tool_returns');
      for (var key in returnBox.keys) {
        final data = returnBox.get(key) as Map<String, dynamic>;
        final isSynced = data['isSynced'] as bool? ?? false;

        if (!isSynced) {
          final result = await returnTool(
            toolId: data['toolId'] as String,
            condition: data['condition'] as String,
            returnQrImageUrl: data['returnQrImageUrl'] as String,
          );

          if (result['success'] == true) {
            await returnBox.delete(key);
          }
        }
      }
    } catch (e) {
      print('Error syncing offline transactions: $e');
    }
  }

  /// Get all transactions for a project
  static Stream<List<ToolTransactionModel>> getProjectTransactions(String projectId) {
    return _firestore
        .collection('tool_transactions')
        .where('projectId', isEqualTo: projectId)
        .orderBy('borrowedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ToolTransactionModel.fromFirestore(doc))
            .toList());
  }

  /// Get damaged tools (for engineer review)
  static Stream<List<ToolTransactionModel>> getDamagedTools() {
    return _firestore
        .collection('tool_transactions')
        .where('condition', isEqualTo: 'DAMAGED')
        .where('returnedAt', isNull: false)
        .orderBy('returnedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ToolTransactionModel.fromFirestore(doc))
            .toList());
  }
}
