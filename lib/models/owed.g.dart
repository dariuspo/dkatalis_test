// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owed.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OwedAdapter extends TypeAdapter<Owed> {
  @override
  final int typeId = 2;

  @override
  Owed read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Owed(
      name: fields[1] as String,
      amount: fields[0] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Owed obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OwedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
