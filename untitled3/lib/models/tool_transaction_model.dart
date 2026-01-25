import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'tool_transaction_model.g.dart';

/// Tool Transaction Model for tracking tool borrowing and returns
@HiveType(typeId: 11)
class ToolTransactionModel extends HiveObject {
  @HiveField(0)
  final String transactionId;

  @HiveField(1)
  final String toolId;

  @HiveField(2)
  final String workerName;

  @HiveField(3)
  final String mobileNumber;

  @HiveField(4)
  final String projectId;

  @HiveField(5)
  final DateTime borrowedAt;

  @HiveField(6)
  final DateTime expectedReturnAt;

  @HiveField(7)
  final DateTime? returnedAt;

  @HiveField(8)
  final String? condition; // GOOD | DAMAGED

  @HiveField(9)
  final String borrowQrImageUrl;

  @HiveField(10)
  final String? returnQrImageUrl;

  @HiveField(11)
  final String managerId;

  @HiveField(12)
  final bool isSynced;

  ToolTransactionModel({
    required this.transactionId,
    required this.toolId,
    required this.workerName,
    required this.mobileNumber,
    required this.projectId,
    required this.borrowedAt,
    required this.expectedReturnAt,
    this.returnedAt,
    this.condition,
    required this.borrowQrImageUrl,
    this.returnQrImageUrl,
    required this.managerId,
    this.isSynced = false,
  });

  /// Create ToolTransactionModel from Firestore document
  factory ToolTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ToolTransactionModel(
      transactionId: doc.id,
      toolId: data['toolId'] ?? '',
      workerName: data['workerName'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      projectId: data['projectId'] ?? '',
      borrowedAt: (data['borrowedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedReturnAt: (data['expectedReturnAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      returnedAt: (data['returnedAt'] as Timestamp?)?.toDate(),
      condition: data['condition'],
      borrowQrImageUrl: data['borrowQrImageUrl'] ?? '',
      returnQrImageUrl: data['returnQrImageUrl'],
      managerId: data['managerId'] ?? '',
      isSynced: true,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'toolId': toolId,
      'workerName': workerName,
      'mobileNumber': mobileNumber,
      'projectId': projectId,
      'borrowedAt': Timestamp.fromDate(borrowedAt),
      'expectedReturnAt': Timestamp.fromDate(expectedReturnAt),
      'returnedAt': returnedAt != null ? Timestamp.fromDate(returnedAt!) : null,
      'condition': condition,
      'borrowQrImageUrl': borrowQrImageUrl,
      'returnQrImageUrl': returnQrImageUrl,
      'managerId': managerId,
    };
  }

  /// Convert to Hive map for offline storage
  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'toolId': toolId,
      'workerName': workerName,
      'mobileNumber': mobileNumber,
      'projectId': projectId,
      'borrowedAt': borrowedAt.toIso8601String(),
      'expectedReturnAt': expectedReturnAt.toIso8601String(),
      'returnedAt': returnedAt?.toIso8601String(),
      'condition': condition,
      'borrowQrImageUrl': borrowQrImageUrl,
      'returnQrImageUrl': returnQrImageUrl,
      'managerId': managerId,
      'isSynced': isSynced,
    };
  }

  /// Create from Hive map
  factory ToolTransactionModel.fromMap(Map<String, dynamic> map) {
    return ToolTransactionModel(
      transactionId: map['transactionId'] ?? '',
      toolId: map['toolId'] ?? '',
      workerName: map['workerName'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      projectId: map['projectId'] ?? '',
      borrowedAt: DateTime.parse(map['borrowedAt'] ?? DateTime.now().toIso8601String()),
      expectedReturnAt: DateTime.parse(map['expectedReturnAt'] ?? DateTime.now().toIso8601String()),
      returnedAt: map['returnedAt'] != null ? DateTime.parse(map['returnedAt']) : null,
      condition: map['condition'],
      borrowQrImageUrl: map['borrowQrImageUrl'] ?? '',
      returnQrImageUrl: map['returnQrImageUrl'],
      managerId: map['managerId'] ?? '',
      isSynced: map['isSynced'] ?? false,
    );
  }

  /// Create a copy with updated fields
  ToolTransactionModel copyWith({
    String? transactionId,
    String? toolId,
    String? workerName,
    String? mobileNumber,
    String? projectId,
    DateTime? borrowedAt,
    DateTime? expectedReturnAt,
    DateTime? returnedAt,
    String? condition,
    String? borrowQrImageUrl,
    String? returnQrImageUrl,
    String? managerId,
    bool? isSynced,
  }) {
    return ToolTransactionModel(
      transactionId: transactionId ?? this.transactionId,
      toolId: toolId ?? this.toolId,
      workerName: workerName ?? this.workerName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      projectId: projectId ?? this.projectId,
      borrowedAt: borrowedAt ?? this.borrowedAt,
      expectedReturnAt: expectedReturnAt ?? this.expectedReturnAt,
      returnedAt: returnedAt ?? this.returnedAt,
      condition: condition ?? this.condition,
      borrowQrImageUrl: borrowQrImageUrl ?? this.borrowQrImageUrl,
      returnQrImageUrl: returnQrImageUrl ?? this.returnQrImageUrl,
      managerId: managerId ?? this.managerId,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
