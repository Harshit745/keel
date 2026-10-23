// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'self_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SelfLogAdapter extends TypeAdapter<SelfLog> {
  @override
  final int typeId = 1;

  @override
  SelfLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SelfLog(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      sleepHours: fields[2] as double,
      energyLevel: fields[3] as int,
      moodRating: fields[4] as int,
      moneySpent: fields[5] as double,
      dailyBudget: fields[6] as double,
      exercised: fields[7] as bool,
      journalEntry: fields[8] as String,
      selfScore: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SelfLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.sleepHours)
      ..writeByte(3)
      ..write(obj.energyLevel)
      ..writeByte(4)
      ..write(obj.moodRating)
      ..writeByte(5)
      ..write(obj.moneySpent)
      ..writeByte(6)
      ..write(obj.dailyBudget)
      ..writeByte(7)
      ..write(obj.exercised)
      ..writeByte(8)
      ..write(obj.journalEntry)
      ..writeByte(9)
      ..write(obj.selfScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelfLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
