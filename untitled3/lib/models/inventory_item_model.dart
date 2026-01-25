import 'package:cloud_firestore/cloud_firestore.dart';

/// Inventory Item Model for tracking construction materials and supplies
class InventoryItemModel {
  final String id;
  final String projectId;
  final String itemName;
  final String category; // CEMENT, STEEL, BRICKS, TOOLS, ELECTRICAL, PLUMBING, etc.
  final double quantity;
  final String unit; // KG, BAGS, PIECES, METERS, LITERS, etc.
  final String status; // IN_STOCK, LOW_STOCK, OUT_OF_STOCK
  final double minStockLevel; // Threshold for low stock alerts
  final double? unitPrice; // Price per unit (optional)
  final String? supplier; // Supplier name (optional)
  final String? location; // Storage location (optional)
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // Manager UID who added the item
  final bool isSynced;
  final String? description; // Additional notes about the item

  InventoryItemModel({
    required this.id,
    required this.projectId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.status,
    this.minStockLevel = 10.0,
    this.unitPrice,
    this.supplier,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isSynced = true,
    this.description,
  });

  factory InventoryItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItemModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      itemName: data['itemName'] ?? '',
      category: data['category'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? '',
      status: data['status'] ?? 'IN_STOCK',
      minStockLevel: (data['minStockLevel'] ?? 10.0).toDouble(),
      unitPrice: data['unitPrice']?.toDouble(),
      supplier: data['supplier'],
      location: data['location'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      isSynced: true,
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'itemName': itemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'status': status,
      'minStockLevel': minStockLevel,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'description': description,
    };
  }

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryItemModel(
      id: map['id'] ?? '',
      projectId: map['projectId'] ?? '',
      itemName: map['itemName'] ?? '',
      category: map['category'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      status: map['status'] ?? 'IN_STOCK',
      minStockLevel: (map['minStockLevel'] ?? 10.0).toDouble(),
      unitPrice: map['unitPrice']?.toDouble(),
      supplier: map['supplier'],
      location: map['location'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      createdBy: map['createdBy'] ?? '',
      isSynced: map['isSynced'] ?? false,
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'itemName': itemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'status': status,
      'minStockLevel': minStockLevel,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'isSynced': isSynced,
      'description': description,
    };
  }

  InventoryItemModel copyWith({
    String? id,
    String? projectId,
    String? itemName,
    String? category,
    double? quantity,
    String? unit,
    String? status,
    double? minStockLevel,
    double? unitPrice,
    String? supplier,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isSynced,
    String? description,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      unitPrice: unitPrice ?? this.unitPrice,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isSynced: isSynced ?? this.isSynced,
      description: description ?? this.description,
    );
  }

  /// Get status color for UI display
  String get statusColor {
    switch (status) {
      case 'IN_STOCK':
        return '#10B981'; // Green
      case 'LOW_STOCK':
        return '#F59E0B'; // Orange
      case 'OUT_OF_STOCK':
        return '#EF4444'; // Red
      default:
        return '#6B7280'; // Gray
    }
  }

  /// Get category icon for UI display
  String get categoryIcon {
    switch (category.toUpperCase()) {
      case 'CEMENT':
        return '🏗️';
      case 'STEEL':
        return '🔩';
      case 'BRICKS':
        return '🧱';
      case 'TOOLS':
        return '🔨';
      case 'ELECTRICAL':
        return '⚡';
      case 'PLUMBING':
        return '🚰';
      case 'PAINT':
        return '🎨';
      case 'WOOD':
        return '🪵';
      default:
        return '📦';
    }
  }

  /// Check if item is low on stock
  bool get isLowStock => quantity <= minStockLevel && quantity > 0;

  /// Check if item is out of stock
  bool get isOutOfStock => quantity <= 0;

  /// Get total value of inventory item
  double get totalValue => unitPrice != null ? quantity * unitPrice! : 0.0;
}