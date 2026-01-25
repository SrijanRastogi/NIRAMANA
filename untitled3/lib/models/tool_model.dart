import 'package:cloud_firestore/cloud_firestore.dart';

/// Tool Model for Tool Library Management
class ToolModel {
  final String toolId;
  final String toolName;
  final String status; // AVAILABLE | IN_USE
  final DateTime createdAt;
  final String? description;

  ToolModel({
    required this.toolId,
    required this.toolName,
    required this.status,
    required this.createdAt,
    this.description,
  });

  /// Create ToolModel from Firestore document
  factory ToolModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ToolModel(
      toolId: doc.id,
      toolName: data['toolName'] ?? '',
      status: data['status'] ?? 'AVAILABLE',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'toolName': toolName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
    };
  }

  /// Create a copy with updated fields
  ToolModel copyWith({
    String? toolId,
    String? toolName,
    String? status,
    DateTime? createdAt,
    String? description,
  }) {
    return ToolModel(
      toolId: toolId ?? this.toolId,
      toolName: toolName ?? this.toolName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }
}
