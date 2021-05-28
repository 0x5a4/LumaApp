// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedDeviceStateAdapter extends TypeAdapter<CachedDeviceState> {
  @override
  final int typeId = 0;

  @override
  CachedDeviceState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedDeviceState(
      fields[3] as int,
      fields[0] as String,
      fields[1] as String,
      fields[2] as int,
      (fields[4] as List).cast<LumaColor>(),
      fields[5] as bool,
      fields[6] as int,
      fields[7] as int,
      fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CachedDeviceState obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj._name)
      ..writeByte(1)
      ..write(obj._address)
      ..writeByte(2)
      ..write(obj._port)
      ..writeByte(3)
      ..write(obj._deviceid)
      ..writeByte(4)
      ..write(obj.colors)
      ..writeByte(5)
      ..write(obj.isPowered)
      ..writeByte(6)
      ..write(obj.mode)
      ..writeByte(7)
      ..write(obj.speed)
      ..writeByte(8)
      ..write(obj.ledNum);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedDeviceStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
