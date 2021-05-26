import 'dart:typed_data';
import 'package:color/color.dart';
import 'package:hive/hive.dart';

import 'package:luma/cache.dart';
import 'package:luma/net/net.dart';

part 'protocol.g.dart';

typedef ApplyLumaValue(CachedDeviceState target, Uint8List value);

class LumaProtocol {
  static const int setCommand = 0;
  static const int getCommand = 1;
  static const int notifyCommand = 2;

  static final Uint8List getAllCommand = constructMsg(getCommand, LumaValue.state);

  ///Construct a Message, compatible with the Luma Protocol according to the Parameters
  static Uint8List constructMsg(int command, LumaValue value, {LumaData? data}) {
    BytesBuilder builder = BytesBuilder();

    //Construct Header
    int headerByte = command << 6;
    int valueByte = value.id & 0x3F;
    headerByte |= valueByte;
    builder.addByte(headerByte);

    //Append Data if necessary
    if (data != null) {
      builder.add(data.asBytes.toList());
    }

    return builder.toBytes();
  }

  ///Inspects the given Message and creates a [DeviceUpdate] with the given [destination]
  ///Might return null if the command id or the value id are unknown
  static DeviceUpdate? interpret(String destinationAddress, Uint8List msg) {
    int msglength = msg.length;
    if (msglength < 1) {
      print("Message had length 0. Skipping...");
      return null;
    }

    //Deconstruct Header
    int header = msg[0];
    int commandID = (header & 0xC0) >> 6;
    int valueID = header & 0x3F;
    //Can we even handle the Command?
    if (commandID == notifyCommand) {
      int deviceID = msg[1];
      LumaValue value = LumaValue.fromid(valueID);

      if (value == LumaValue.invalid) {
        print("Unknown Value with id $valueID");
        return null;
      }

      //Remove the header and deviceid from the message so we only have the data
      return DeviceUpdate(destinationAddress, deviceID, commandID, value, msg.sublist(2));
    } else {
      print("Cannot interpret Command with id $commandID");
      return null;
    }
  }
}

///Representation for a List of LumaColors
///The primarly serves the purpose of being compatible with [LumaData]
class LumaColorList implements LumaData {
  List<LumaColor> _list = <LumaColor>[];

  LumaColorList();

  LumaColorList.fromList(List<LumaColor> list) : _list = list;

  void add(LumaColor color) => _list.add(color);

  int get length => _list.length;

  @override
  Uint8List get asBytes {
    BytesBuilder builder = BytesBuilder();
    for (LumaColor color in _list) {
      Uint8List bytes = color.asBytes;
      builder.add(bytes);
    }
    return builder.toBytes();
  }
}

@HiveType(typeId: 1)
///A HSV Color Representation that correctly encodes and decodes to the format required by the Luma Protocol
class LumaColor implements LumaData {
  @HiveField(0)
  late int hue;
  @HiveField(1)
  late int saturation;
  @HiveField(2)
  late int value;

  LumaColor(this.hue, this.saturation, this.value) {
    assert(hue >= 0 && hue <= 360, "Hue must be in range 0 to 360, was $hue");
    assert(saturation >= 0 && saturation <= 100, "Saturation must be in range 0 to 100, was $saturation");
    assert(value >= 0 && value <= 100, "Value must be in range 0 to 100, was $value");
  }

  LumaColor.fromRGB(int r, int g, int b) {
    HsvColor hsv = RgbColor(r, g, b).toHsvColor();
    this.hue = hsv.h.round();
    this.saturation = hsv.s.round();
    this.value = hsv.v.round();
  }

  factory LumaColor.fromBytes(Uint8List bytes) {
    if (bytes.length < 3) throw "Cannot extract HSV From less than 3 bytes. Got only ${bytes.length}";
    int firstByte = bytes[0];
    int secondByte = bytes[1];
    int thirdByte = bytes[2];
    int hue = firstByte << 1;
    hue |= secondByte & 0x80;
    int saturation = secondByte & 0x7F;
    int value = (thirdByte & 0xFE) >> 1;
    return LumaColor(hue, saturation, value);
  }

  @override
  bool operator ==(Object other) {
    return other is LumaColor && other.hashCode == this.hashCode;
  }

  @override
  int get hashCode => hue.hashCode ^ saturation.hashCode ^ value.hashCode;

  @override
  Uint8List get asBytes {
    Uint8List bytes = Uint8List(3);
    bytes[0] = hue >> 1;
    bytes[1] = (hue & 1) | saturation;
    bytes[2] = value << 1;
    return bytes;
  }

  @override
  String toString() {
    return 'LumaColor{hue: $hue, saturation: $saturation, value: $value}';
  }
}

///Class representing a value accessed by the Luma protocol
///including their [id], [name] and how they apply to a [CachedDeviceState]
///
///Also holds a couple of constants defining each value possible
class LumaValue {
  ///Invalid Value
  static final LumaValue invalid = LumaValue._(-1, "invalid", (device, value) {});

  static final LumaValue led = LumaValue._(0, "led", (device, value) {
    List<LumaColor> result = <LumaColor>[];
    for (int i = 0; i < value.length; i += 3) {
      LumaColor color = LumaColor.fromBytes(value.sublist(i, i + 3));
      result.add(color);
    }
    device.colors = result;
  });

  static final LumaValue power = LumaValue._(1, "power", (target, value) {
    int byte = value[0];
    if (byte == 0) {
      target.isPowered = false;
    } else if (byte == 1) {
      target.isPowered = true;
    } else if (byte == 0xFF) {
      target.isPowered = !target.isPowered!;
    }
  });

  static final LumaValue mode = LumaValue._(2, "mode", (target, value) {
    target.mode = value[0];
  });

  static final LumaValue speed = LumaValue._(3, "speed", (target, value) {
    int speed = value[0];
    speed <<= 8;
    speed |= value[1];
    target.speed = speed;
  });

  static final LumaValue state = LumaValue._(39, "state", (target, value) {
    lednum.apply(target, value.sublist(0, 1));
    power.apply(target, value.sublist(1, 2));
    mode.apply(target, value.sublist(2, 3));
    speed.apply(target, value.sublist(3, 5));
    led.apply(target, value.sublist(5));
  });

  static final LumaValue lednum = LumaValue._immutable(40, "lednum", (device, value) {
    device.ledNum = value[0];
  });

  static final LumaValue globalIP = LumaValue._immutable(42, "globalIP", (device, value) {});

  static final LumaValue dummy = LumaValue._immutable(43, "dummy", (device, value) {
    print("Dummy cannot be applied. Skipping...");
  });

  //Parameters:
  static final List<LumaValue> _values = <LumaValue>[];
  final int id;
  final bool isImmutable;
  final String name;
  final ApplyLumaValue _apply;

  LumaValue._(this.id, this.name, this._apply) : this.isImmutable = false {
    _values.add(this);
  }

  LumaValue._immutable(this.id, this.name, this._apply) : this.isImmutable = true {
    _values.add(this);
  }

  ///Return the LumaValue with the given id. Might be null if that id doesnt exist
  factory LumaValue.fromid(int id) {
    for (LumaValue val in values) {
      if (val.id == id) {
        return val;
      }
    }
    return LumaValue.invalid;
  }

  ApplyLumaValue get apply => _apply;

  static Iterable<LumaValue> get values => _values;

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => id.hashCode;
}

///Represents speed and correctly translates to
///the format required by the Luma protocol
class LumaSpeed implements LumaData {
  final int speed;

  const LumaSpeed._(this.speed);

  @override
  Uint8List get asBytes {
    Uint8List bytes = Uint8List(2);
    bytes[0] = speed & 0xFF00;
    bytes[1] = speed & 0x00FF;
    return bytes;
  }
}

///Contains every possible animation mode
class LumaAnimationMode implements LumaData {
  static const LumaAnimationMode led = LumaAnimationMode._(0, "static");
  static const LumaAnimationMode rainbow = LumaAnimationMode._(1, "rainbow");
  static const LumaAnimationMode positive_cycle = LumaAnimationMode._(2, "positive_cycle");
  static const LumaAnimationMode negative_cycle = LumaAnimationMode._(3, "negative_cycle");

  final int id;
  final String name;

  const LumaAnimationMode._(this.id, this.name);

  @override
  Uint8List get asBytes {
    return Uint8List(1)..add(id);
  }
}

///Contains every possible power value
class LumaPowerValue implements LumaData {
  static const LumaPowerValue on = LumaPowerValue._(true);
  static const LumaPowerValue off = LumaPowerValue._(false);
  static const LumaPowerValue invert = LumaPowerValue._invert();

  final bool value;
  final bool isInverter;

  const LumaPowerValue._(this.value) : this.isInverter = false;

  const LumaPowerValue._invert()
      : this.isInverter = true,
        this.value = false;

  @override
  Uint8List get asBytes {
    if (isInverter) return Uint8List.fromList([0xFF]);
    return Uint8List.fromList([value ? 1 : 0]);
  }
}

abstract class LumaData {
  Uint8List get asBytes;
}
