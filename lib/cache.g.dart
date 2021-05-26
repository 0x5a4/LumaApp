// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedDeviceAdapter extends TypeAdapter<CachedDeviceState> {
  @override
  final int typeId = 0;

  @override
  CachedDeviceState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedDeviceState(
      fields[8] as int,
      fields[0] as String,
      fields[1] as String,
      fields[2] as int,
      (fields[3] as List?)?.cast<LumaColor>(),
      fields[4] as bool?,
      fields[5] as int?,
      fields[6] as int?,
      fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedDeviceState obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.port)
      ..writeByte(3)
      ..write(obj.colors)
      ..writeByte(4)
      ..write(obj.isPowered)
      ..writeByte(5)
      ..write(obj.mode)
      ..writeByte(6)
      ..write(obj.speed)
      ..writeByte(7)
      ..write(obj.ledNum)
      ..writeByte(8)
      ..write(obj.deviceid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedDeviceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
