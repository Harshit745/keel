// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BuildLogAdapter extends TypeAdapter<BuildLog> {
  @override
  final int typeId = 0;

  @override
  BuildLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BuildLog(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      tasksShipped: fields[2] as int,
      talkedToUser: fields[3] as bool,
      movedNeedle: fields[4] as bool,
      revenueAdded: fields[5] as double,
      ideasCaptured: (fields[6] as List).cast<String>(),
      winOfDay: fields[7] as String,
      buildScore: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BuildLog obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.tasksShipped)
      ..writeByte(3)
      ..write(obj.talkedToUser)
      ..writeByte(4)
      ..write(obj.movedNeedle)
      ..writeByte(5)
      ..write(obj.revenueAdded)
      ..writeByte(6)
      ..write(obj.ideasCaptured)
      ..writeByte(7)
      ..write(obj.winOfDay)
      ..writeByte(8)
      ..write(obj.buildScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
