// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectModelAdapter extends TypeAdapter<ProjectModel> {
  @override
  final int typeId = 2;

  @override
  ProjectModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectModel(
      id: fields[0] as String,
      projectName: fields[1] as String,
      createdBy: fields[2] as String,
      ownerId: fields[3] as String,
      managerId: fields[4] as String,
      status: fields[5] as String,
      createdAt: fields[6] as DateTime,
      ownerApprovedAt: fields[7] as DateTime?,
      managerAcceptedAt: fields[8] as DateTime?,
      isSynced: fields[9] as bool,
      ownerUid: fields[10] as String?,
      managerUid: fields[11] as String?,
      ownerName: fields[12] as String?,
      managerName: fields[13] as String?,
      purchaseManagerUid: fields[14] as String?,
      purchaseManagerId: fields[15] as String?,
      purchaseManagerName: fields[16] as String?,
      totalFloors: fields[17] as int?,
      totalEstimatedCost: fields[18] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectName)
      ..writeByte(2)
      ..write(obj.createdBy)
      ..writeByte(3)
      ..write(obj.ownerId)
      ..writeByte(4)
      ..write(obj.managerId)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.ownerApprovedAt)
      ..writeByte(8)
      ..write(obj.managerAcceptedAt)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.ownerUid)
      ..writeByte(11)
      ..write(obj.managerUid)
      ..writeByte(12)
      ..write(obj.ownerName)
      ..writeByte(13)
      ..write(obj.managerName)
      ..writeByte(14)
      ..write(obj.purchaseManagerUid)
      ..writeByte(15)
      ..write(obj.purchaseManagerId)
      ..writeByte(16)
      ..write(obj.purchaseManagerName)
      ..writeByte(17)
      ..write(obj.totalFloors)
      ..writeByte(18)
      ..write(obj.totalEstimatedCost);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}