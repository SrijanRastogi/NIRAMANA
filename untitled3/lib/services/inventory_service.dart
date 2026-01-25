import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_transaction_model.dart';

/// Service for managing inventory operations
/// Handles CRUD operations, stock tracking, and transaction history
class InventoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user info for transactions
  static Future<Map<String, String>> _getCurrentUserInfo() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User profile not found');

      final userData = userDoc.data()!;
      return {
        'uid': user.uid,
        'name': userData['name'] ?? 'Unknown User',
        'role': userData['role'] ?? 'unknown',
      };
    } catch (e) {
      return {
        'uid': user.uid,
        'name': 'Unknown User',
        'role': 'unknown',
      };
    }
  }

  /// Get all inventory items for a project
  static Stream<List<InventoryItemModel>> getProjectInventoryItems(String projectId) {
    return _firestore
        .collection('inventory_items')
        .where('projectId', isEqualTo: projectId)
        .orderBy('itemName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItemModel.fromFirestore(doc))
            .toList());
  }

  /// Get inventory items by category
  static Stream<List<InventoryItemModel>> getInventoryItemsByCategory(
      String projectId, String category) {
    return _firestore
        .collection('inventory_items')
        .where('projectId', isEqualTo: projectId)
        .where('category', isEqualTo: category)
        .orderBy('itemName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItemModel.fromFirestore(doc))
            .toList());
  }

  /// Get low stock items for a project
  static Stream<List<InventoryItemModel>> getLowStockItems(String projectId) {
    return _firestore
        .collection('inventory_items')
        .where('projectId', isEqualTo: projectId)
        .where('status', isEqualTo: 'LOW_STOCK')
        .orderBy('quantity')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItemModel.fromFirestore(doc))
            .toList());
  }

  /// Get out of stock items for a project
  static Stream<List<InventoryItemModel>> getOutOfStockItems(String projectId) {
    return _firestore
        .collection('inventory_items')
        .where('projectId', isEqualTo: projectId)
        .where('status', isEqualTo: 'OUT_OF_STOCK')
        .orderBy('itemName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItemModel.fromFirestore(doc))
            .toList());
  }

  /// Get inventory statistics for a project
  static Stream<Map<String, int>> getInventoryStats(String projectId) {
    return _firestore
        .collection('inventory_items')
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) {
      int totalItems = snapshot.docs.length;
      int lowStockItems = 0;
      int outOfStockItems = 0;
      int inStockItems = 0;

      for (var doc in snapshot.docs) {
        final item = InventoryItemModel.fromFirestore(doc);
        switch (item.status) {
          case 'LOW_STOCK':
            lowStockItems++;
            break;
          case 'OUT_OF_STOCK':
            outOfStockItems++;
            break;
          case 'IN_STOCK':
            inStockItems++;
            break;
        }
      }

      return {
        'totalItems': totalItems,
        'inStockItems': inStockItems,
        'lowStockItems': lowStockItems,
        'outOfStockItems': outOfStockItems,
      };
    });
  }

  /// Get recent transactions for a project
  static Stream<List<InventoryTransactionModel>> getRecentTransactions(
      String projectId, {int limit = 10}) {
    return _firestore
        .collection('inventory_transactions')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryTransactionModel.fromFirestore(doc))
            .toList());
  }

  /// Get transaction history for a specific item
  static Stream<List<InventoryTransactionModel>> getItemTransactionHistory(
      String itemId) {
    return _firestore
        .collection('inventory_transactions')
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryTransactionModel.fromFirestore(doc))
            .toList());
  }

  /// Add new inventory item
  static Future<Map<String, dynamic>> addInventoryItem({
    required String projectId,
    required String itemName,
    required String category,
    required double quantity,
    required String unit,
    double minStockLevel = 10.0,
    double? unitPrice,
    String? supplier,
    String? location,
    String? description,
  }) async {
    try {
      final userInfo = await _getCurrentUserInfo();
      final now = DateTime.now();

      // Create inventory item
      final itemRef = _firestore.collection('inventory_items').doc();
      final item = InventoryItemModel(
        id: itemRef.id,
        projectId: projectId,
        itemName: itemName,
        category: category,
        quantity: quantity,
        unit: unit,
        status: _getStockStatus(quantity, minStockLevel),
        minStockLevel: minStockLevel,
        unitPrice: unitPrice,
        supplier: supplier,
        location: location,
        createdAt: now,
        updatedAt: now,
        createdBy: userInfo['uid']!,
        description: description,
      );

      // Create initial transaction
      final transactionRef = _firestore.collection('inventory_transactions').doc();
      final transaction = InventoryTransactionModel(
        id: transactionRef.id,
        itemId: itemRef.id,
        projectId: projectId,
        type: 'IN',
        quantity: quantity,
        previousQuantity: 0.0,
        newQuantity: quantity,
        reason: 'INITIAL_STOCK',
        notes: 'Initial inventory item creation',
        createdAt: now,
        createdBy: userInfo['uid']!,
        createdByName: userInfo['name']!,
        createdByRole: userInfo['role']!,
        referenceType: 'MANUAL',
        unitPrice: unitPrice,
        supplier: supplier,
      );

      // Use batch write for atomic operation
      final batch = _firestore.batch();
      batch.set(itemRef, item.toFirestore());
      batch.set(transactionRef, transaction.toFirestore());
      await batch.commit();

      return {'success': true, 'itemId': itemRef.id};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update inventory item quantity (stock in/out)
  static Future<Map<String, dynamic>> updateInventoryQuantity({
    required String itemId,
    required String projectId,
    required double quantityChange, // Positive for IN, negative for OUT
    required String reason,
    String? notes,
    String? referenceId,
    String? referenceType,
    double? unitPrice,
    String? supplier,
    String? receiptNumber,
  }) async {
    try {
      final userInfo = await _getCurrentUserInfo();
      final now = DateTime.now();

      // Get current item
      final itemDoc = await _firestore.collection('inventory_items').doc(itemId).get();
      if (!itemDoc.exists) {
        return {'success': false, 'error': 'Inventory item not found'};
      }

      final currentItem = InventoryItemModel.fromFirestore(itemDoc);
      final previousQuantity = currentItem.quantity;
      final newQuantity = previousQuantity + quantityChange;

      if (newQuantity < 0) {
        return {'success': false, 'error': 'Insufficient stock. Available: ${previousQuantity.toStringAsFixed(2)} ${currentItem.unit}'};
      }

      // Determine transaction type
      String transactionType;
      if (quantityChange > 0) {
        transactionType = 'IN';
      } else if (quantityChange < 0) {
        transactionType = 'OUT';
      } else {
        transactionType = 'ADJUSTMENT';
      }

      // Update item
      final updatedItem = currentItem.copyWith(
        quantity: newQuantity,
        status: _getStockStatus(newQuantity, currentItem.minStockLevel),
        updatedAt: now,
      );

      // Create transaction record
      final transactionRef = _firestore.collection('inventory_transactions').doc();
      final transaction = InventoryTransactionModel(
        id: transactionRef.id,
        itemId: itemId,
        projectId: projectId,
        type: transactionType,
        quantity: quantityChange.abs(),
        previousQuantity: previousQuantity,
        newQuantity: newQuantity,
        reason: reason,
        notes: notes,
        createdAt: now,
        createdBy: userInfo['uid']!,
        createdByName: userInfo['name']!,
        createdByRole: userInfo['role']!,
        referenceId: referenceId,
        referenceType: referenceType,
        unitPrice: unitPrice,
        supplier: supplier,
        receiptNumber: receiptNumber,
      );

      // Use batch write for atomic operation
      final batch = _firestore.batch();
      batch.update(_firestore.collection('inventory_items').doc(itemId), updatedItem.toFirestore());
      batch.set(transactionRef, transaction.toFirestore());
      await batch.commit();

      return {
        'success': true,
        'previousQuantity': previousQuantity,
        'newQuantity': newQuantity,
        'transactionId': transactionRef.id,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete inventory item
  static Future<Map<String, dynamic>> deleteInventoryItem(String itemId) async {
    try {
      // Check if item has any transactions
      final transactions = await _firestore
          .collection('inventory_transactions')
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      if (transactions.docs.isNotEmpty) {
        return {'success': false, 'error': 'Cannot delete item with transaction history'};
      }

      await _firestore.collection('inventory_items').doc(itemId).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get inventory categories for a project
  static Future<List<String>> getProjectCategories(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection('inventory_items')
          .where('projectId', isEqualTo: projectId)
          .get();

      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final item = InventoryItemModel.fromFirestore(doc);
        categories.add(item.category);
      }

      final sortedCategories = categories.toList()..sort();
      return sortedCategories;
    } catch (e) {
      return [];
    }
  }

  /// Get predefined categories
  static List<String> getPredefinedCategories() {
    return [
      'CEMENT',
      'STEEL',
      'BRICKS',
      'SAND',
      'GRAVEL',
      'TOOLS',
      'ELECTRICAL',
      'PLUMBING',
      'PAINT',
      'WOOD',
      'TILES',
      'FIXTURES',
      'HARDWARE',
      'SAFETY',
      'OTHER',
    ];
  }

  /// Get predefined units
  static List<String> getPredefinedUnits() {
    return [
      'KG',
      'BAGS',
      'PIECES',
      'METERS',
      'LITERS',
      'TONS',
      'CUBIC_METERS',
      'SQUARE_METERS',
      'BOXES',
      'ROLLS',
      'SHEETS',
      'BUNDLES',
      'SETS',
      'UNITS',
    ];
  }

  /// Get predefined reasons for transactions
  static List<String> getTransactionReasons() {
    return [
      'PURCHASE',
      'DELIVERY',
      'USAGE',
      'DAMAGE',
      'THEFT',
      'RETURN',
      'TRANSFER',
      'ADJUSTMENT',
      'WASTAGE',
      'QUALITY_ISSUE',
    ];
  }

  /// Determine stock status based on quantity and minimum level
  static String _getStockStatus(double quantity, double minStockLevel) {
    if (quantity <= 0) {
      return 'OUT_OF_STOCK';
    } else if (quantity <= minStockLevel) {
      return 'LOW_STOCK';
    } else {
      return 'IN_STOCK';
    }
  }

  /// Search inventory items by name
  static Stream<List<InventoryItemModel>> searchInventoryItems(
      String projectId, String searchQuery) {
    return _firestore
        .collection('inventory_items')
        .where('projectId', isEqualTo: projectId)
        .orderBy('itemName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItemModel.fromFirestore(doc))
            .where((item) => item.itemName.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList());
  }

  /// Get inventory value summary for a project
  static Future<Map<String, double>> getInventoryValueSummary(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection('inventory_items')
          .where('projectId', isEqualTo: projectId)
          .get();

      double totalValue = 0.0;
      double inStockValue = 0.0;
      double lowStockValue = 0.0;

      for (var doc in snapshot.docs) {
        final item = InventoryItemModel.fromFirestore(doc);
        final itemValue = item.totalValue;
        totalValue += itemValue;

        switch (item.status) {
          case 'IN_STOCK':
            inStockValue += itemValue;
            break;
          case 'LOW_STOCK':
            lowStockValue += itemValue;
            break;
        }
      }

      return {
        'totalValue': totalValue,
        'inStockValue': inStockValue,
        'lowStockValue': lowStockValue,
      };
    } catch (e) {
      return {
        'totalValue': 0.0,
        'inStockValue': 0.0,
        'lowStockValue': 0.0,
      };
    }
  }
}