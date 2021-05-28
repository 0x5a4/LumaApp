import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:luma/devices.dart';
import 'package:luma/net/net.dart';
import 'package:luma/net/protocol.dart';
import 'package:rxdart/rxdart.dart';

part 'cache.g.dart';

///Manages all cached data
class Cache {
  static const deviceDBName = "stateCache";
  static late Box<CachedDeviceState> _deviceStateCache;

  // ignore: close_sinks
  static BehaviorSubject<Iterable<CachedDeviceState>> _onStateListUpdate = BehaviorSubject();
  static late Stream<BoxEvent> _onStateDBUpdate;

  ///Initializes the database
  static Future<void> init() async {
    ///Load state cache
    _deviceStateCache = await Hive.openBox(
      deviceDBName,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
    );

    _onStateDBUpdate = _deviceStateCache.watch();

    _onStateDBUpdate.listen((event) => _onStateListUpdate.add(_deviceStateCache.values));
    _onStateListUpdate.add(_deviceStateCache.values);
  }

  static bool containsKey(int hash) => _deviceStateCache.containsKey(hash);

  static void saveState(CachedDeviceState device) => _deviceStateCache.put(device.hashCode, device);

  static Future<void> clearStateCache() async => await _deviceStateCache.clear();

  static CachedDeviceState? getState(int hash, {CachedDeviceState? defaultValue}) => _deviceStateCache.get(hash, defaultValue: defaultValue);

  ///Returns a Stream emiting the whole list of states whenever they change
  static Stream<Iterable<CachedDeviceState>> get onStateListUpdate => _onStateListUpdate.stream;

  ///Returns a Stream emitting explicit updates the database
  static Stream<BoxEvent> get onStateDBUpdate => _onStateDBUpdate;

  ///Returns every state stored in the Database
  static Iterable<CachedDeviceState> get stateList => _deviceStateCache.values;
}

///Represents a devices state cached in the database
@HiveType(typeId: 0)
class CachedDeviceState with HiveObjectMixin {
  @HiveField(0)
  String _name;
  @HiveField(1)
  String _address;
  @HiveField(2)
  int _port;
  @HiveField(3)
  int _deviceid;
  @HiveField(4)
  List<LumaColor> colors = <LumaColor>[];
  @HiveField(5)
  bool isPowered = false;
  @HiveField(6)
  int mode = 0;
  @HiveField(7)
  int speed = 0;
  @HiveField(8)
  int ledNum = 0;

  InternetAddress _addressObj;

  CachedDeviceState(
    this._deviceid,
    this._name,
    this._address,
    this._port,
    this.colors,
    this.isPowered,
    this.mode,
    this.speed,
    this.ledNum,
  ) : this._addressObj = InternetAddress(_address);

  CachedDeviceState.stateless(this._deviceid, this._name, this._address, this._port) : this._addressObj = InternetAddress(_address);

  bool equalsExact(CachedDeviceState other) {
    return other.deviceid == this.deviceid &&
        other.name == this.name &&
        other.port == this.port &&
        other.address == this.address &&
        listEquals(other.colors, this.colors) &&
        other.isPowered == this.isPowered &&
        other.speed == this.speed &&
        other.ledNum == this.ledNum;
  }

  bool correspondsTo(LumaDevice device) {
    return device.hashCode == this.hashCode;
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is CachedDeviceState && other.hashCode == this.hashCode;

  @override
  int get hashCode => _address.hashCode ^ _deviceid.hashCode;

  @override
  String toString() {
    return 'CachedDevice{name: $name, address: $address, port: $port, colors: $colors, isPowered: $isPowered, mode: $mode, speed: $speed, ledNum: $ledNum, deviceid: $deviceid}';
  }

  String get name => _name;

  String get address => _address;

  int get deviceid => _deviceid;

  int get port => _port;

  InternetAddress get addressObj => _addressObj;

  set address(String address) {
    this._address = address;
    this._addressObj = InternetAddress(address);
  }

  ///Update Methods

  void updateColors(List<LumaColor> colors) {
    if (_updateHost(LumaValue.led, LumaColorList.fromList(colors)) != 0) {
      this.colors = colors;
      this.save();
    }
  }

  void updatePower(bool power) {
    if (_updateHost(LumaValue.power, LumaPowerValue.fromBool(power)) != 0) {
      this.isPowered = power;
      this.save();
    }
  }

  void updateMode(int mode) {
    if (_updateHost(LumaValue.mode, LumaAnimationMode.fromid(mode)) != 0) {
      this.mode = mode;
      this.save();
    }
  }

  void updateSpeed(int speed) {
    if (_updateHost(LumaValue.speed, LumaSpeed(speed)) != 0) {
      this.speed = speed;
      this.save();
    }
  }

  int _updateHost(LumaValue value, LumaData? data) {
    if (data == null) return 0;
    return DeviceSocket.send(
      _addressObj,
      port,
      LumaProtocol.constructMsg(
        LumaProtocol.setCommand,
        value,
        data: data,
      ),
    );
  }
}
