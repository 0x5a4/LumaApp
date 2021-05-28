import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma/cache.dart';
import 'package:luma/net/net.dart';
import 'package:luma/net/protocol.dart';

void main() {
  group("LumaProtocol.constructMsg behaves as expected:", () {
    test("Get-Command Construction", () {
      expect(LumaProtocol.constructMsg(LumaProtocol.getCommand, LumaValue.led), Uint8List.fromList([0x40]));
      expect(LumaProtocol.constructMsg(LumaProtocol.getCommand, LumaValue.dummy), Uint8List.fromList([0x6B]));
    });

    test("Set-Command Construction", () {
      expect(LumaProtocol.constructMsg(LumaProtocol.setCommand, LumaValue.power, data: LumaPowerValue.on), Uint8List.fromList([0x01, 0x01]));
      expect(
        LumaProtocol.constructMsg(
          LumaProtocol.setCommand,
          LumaValue.led,
          data: LumaColorList.fromList([LumaColor(106, 78, 92), LumaColor(136, 70, 66)]),
        ),
        Uint8List.fromList([0x00, 0x35, 0x4E, 0xB8, 0x44, 0x46, 0x84]),
      );
    });
  });

  test("Color converts to rgb", () {
    expect(LumaColor.fromRGB(93, 148, 121), LumaColor(151, 37, 58));
  });

  test("Color assembles to the correct chain of bits", () {
    expect(LumaColor(106, 78, 92).asBytes, Uint8List.fromList([0x35, 0x4E, 0xB8]));
  });

  test("LumaProtocol.extractColorFromBytes works", () {
    expect(LumaColor.fromBytes(Uint8List.fromList([0x35, 0x4E, 0xB8])), LumaColor(106, 78, 92));
  });
  
  test("LumaColor loads from Color", () {
    expect(LumaColor.fromColor(Color(0xFF379e72)), LumaColor(154, 65, 62));
  });

  test("LumaColor converts to Color", () {
    expect(LumaColor(154, 65, 62).toColor(), Color(0xFF379e72));
  });

  test("Device Update", () {
    DeviceUpdate update = DeviceUpdate(
      "192.168.0.55",
      0,
      LumaProtocol.notifyCommand,
      LumaValue.state,
      Uint8List.fromList([150, 0, 0, 0, 4]..addAll(LumaColor(106, 78, 92).asBytes)),
    );
    CachedDeviceState cachedDevice = CachedDeviceState.stateless(0, "hell", "192.168.0.55", 666);
    update.apply(cachedDevice);
    expect(cachedDevice.equalsExact(CachedDeviceState(0, "hell", "192.168.0.55", 666, [LumaColor(106, 78, 92)], false, 0, 4, 150)), isTrue);
  });
}
