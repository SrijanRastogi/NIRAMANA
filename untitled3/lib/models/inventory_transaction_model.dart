import 'package:cloud_firestore/cloud_firestore.dart';

/// Inventory Transaction Model for tracking stock movements
class InventoryTransactionModel {
  final String id;
  final String itemId;
  final String projectId;
  final String type; // IN, OUT, ADJUSTMENT
  final double quantity;
  final double previousQuantity;
  final double newQuantity;
  final String reason; // PURCHASE, USAGE, DAMAGE, THEFT, RETURN, ADJUSTMENT, etc.
  final String? notes; // Additional details
  final DateTime createdAt;
  final String createdBy; // UID of user who made the transaction
  final String createdByName; // Name of user for display
  final String createdByRole; // Role of user (manager, engineer, etc.)
  final bool isSynced;
  final String? referenceId; // Reference to related document (MR, PO, etc.)
  final String? referenceType; // MATERIAL_REQUEST, PURCHASE_ORDER, MANUAL, etc.
  final double? unitPrice; // Price per unit at time of transaction
  final String? supplier; // Supplier for IN transactions
  final String? receiptNumber; // Receipt/invoice number

  InventoryTransactionModel({
    required this.id,
    required this.itemId,
    required this.projectId,
    required this.type,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    required this.reason,
    this.notes,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    required this.createdByRole,
    this.isSynced = true,
    this.referenceId,
    this.referenceType,
    this.unitPrice,
    this.supplier,
    this.receiptNumber,
  });

  factory InventoryTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryTransactionModel(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      projectId: data['projectId'] ?? '',
      type: data['type'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      previousQuantity: (data['previousQuantity'] ?? 0.0).toDouble(),
      newQuantity: (data['newQuantity'] ?? 0.0).toDouble(),
      reason: data['reason'] ?? '',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdByRole: data['createdByRole'] ?? '',
      isSynced: true,
      referenceId: data['referenceId'],
      referenceType: data['referenceType'],
      unitPrice: data['unitPrice']?.toDouble(),
      supplier: data['supplier'],
      receiptNumber: data['receiptNumber'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'projectId': projectId,
      'type': type,
      'quantity': quantity,
      'previousQuantity': previousQuantity,
      'newQuantity': newQuantity,
      'reason': reason,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'receiptNumber': receiptNumber,
    };
  }

  factory InventoryTransactionModel.fromMap(Map<String, dynamic> map) {
    return InventoryTransactionModel(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      projectId: map['projectId'] ?? '',
      type: map['type'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      previousQuantity: (map['previousQuantity'] ?? 0.0).toDouble(),
      newQuantity: (map['newQuantity'] ?? 0.0).toDouble(),
      reason: map['reason'] ?? '',
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdByRole: map['createdByRole'] ?? '',
      isSynced: map['isSynced'] ?? false,
      referenceId: map['referenceId'],
      referenceType: map['referenceType'],
      unitPrice: map['unitPrice']?.toDouble(),
      supplier: map['supplier'],
      receiptNumber: map['receiptNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'projectId': projectId,
      'type': type,
      'quantity': quantity,
      'previousQuantity': previousQuantity,
      'newQuantity': newQuantity,
      'reason': reason,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      'isSynced': isSynced,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'receiptNumber': receiptNumber,
    };
  }

  InventoryTransactionModel copyWith({
    String? id,
    String? itemId,
    String? projectId,
    String? type,
    double? quantity,
    double? previousQuantity,
    double? newQuantity,
    String? reason,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
    String? createdByRole,
    bool? isSynced,
    String? referenceId,
    String? referenceType,
    double? unitPrice,
    String? supplier,
    String? receiptNumber,
  }) {
    return InventoryTransactionModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      previousQuantity: previousQuantity ?? this.previousQuantity,
      newQuantity: newQuantity ?? this.newQuantity,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByRole: createdByRole ?? this.createdByRole,
      isSynced: isSynced ?? this.isSynced,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      unitPrice: unitPrice ?? this.unitPrice,
      supplier: supplier ?? this.supplier,
      receiptNumber: receiptNumber ?? this.receiptNumber,
    );
  }

  /// Get transaction type color for UI display
  String get typeColor {
    switch (type) {
      case 'IN':
        return '#10B981'; // Green
      case 'OUT':
        return '#EF4444'; // Red
      case 'ADJUSTMENT':
        return '#F59E0B'; // Orange
      default:
        return '#6B7280'; // Gray
    }
  }

  /// Get transaction type icon for UI display
  String get typeIcon {
    switch (type) {
      case 'IN':
        return '📥';
      case 'OUT':
        return '📤';
      case 'ADJUSTMENT':
        return '⚖️';
      default:
        return '📋';
    }
  }

  /// Get reason display text
  String get reasonDisplay {
    switch (reason.toUpperCase()) {
      case 'PURCHASE':
        return 'Material Purchase';
      case 'USAGE':
        return 'Used in Construction';
      case 'DAMAGE':
        return 'Damaged/Broken';
      case 'THEFT':
        return 'Theft/Missing';
      case 'RETURN':
        return 'Returned to Supplier';
      case 'ADJUSTMENT':
        return 'Stock Adjustment';
      case 'DELIVERY':
        return 'Material Delivery';
      case 'TRANSFER':
        return 'Transfer to Site';
      default:
        return reason;
    }
  }

  /// Get transaction value
  double get transactionValue => unitPrice != null ? quantity * unitPrice! : 0.0;

  /// Check if transaction increases stock
  bool get isStockIncrease => type == 'IN' || (type == 'ADJUSTMENT' && quantity > 0);

  /// Check if transaction decreases stock
  bool get isStockDecrease => type == 'OUT' || (type == 'ADJUSTMENT' && quantity < 0);
}