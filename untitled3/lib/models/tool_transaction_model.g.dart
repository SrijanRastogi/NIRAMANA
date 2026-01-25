// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ToolTransactionModelAdapter extends TypeAdapter<ToolTransactionModel> {
  @override
  final int typeId = 11;

  @override
  ToolTransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ToolTransactionModel(
      transactionId: fields[0] as String,
      toolId: fields[1] as String,
      workerName: fields[2] as String,
      mobileNumber: fields[3] as String,
      projectId: fields[4] as String,
      borrowedAt: fields[5] as DateTime,
      expectedReturnAt: fields[6] as DateTime,
      returnedAt: fields[7] as DateTime?,
      condition: fields[8] as String?,
      borrowQrImageUrl: fields[9] as String,
      returnQrImageUrl: fields[10] as String?,
      managerId: fields[11] as String,
      isSynced: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ToolTransactionModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.transactionId)
      ..writeByte(1)
      ..write(obj.toolId)
      ..writeByte(2)
      ..write(obj.workerName)
      ..writeByte(3)
      ..write(obj.mobileNumber)
      ..writeByte(4)
      ..write(obj.projectId)
      ..writeByte(5)
      ..write(obj.borrowedAt)
      ..writeByte(6)
      ..write(obj.expectedReturnAt)
      ..writeByte(7)
      ..write(obj.returnedAt)
      ..writeByte(8)
      ..write(obj.condition)
      ..writeByte(9)
      ..write(obj.borrowQrImageUrl)
      ..writeByte(10)
      ..write(obj.returnQrImageUrl)
      ..writeByte(11)
      ..write(obj.managerId)
      ..writeByte(12)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolTransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
