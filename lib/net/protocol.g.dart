// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LumaColorAdapter extends TypeAdapter<LumaColor> {
  @override
  final int typeId = 1;

  @override
  LumaColor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LumaColor(
      fields[0] as int,
      fields[1] as int,
      fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LumaColor obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.hue)
      ..writeByte(1)
      ..write(obj.saturation)
      ..writeByte(2)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LumaColorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
