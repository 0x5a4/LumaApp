import 'package:flutter/foundation.dart';
import 'package:luma/cache.dart';
import 'package:luma/net/net.dart';
import 'package:luma/net/protocol.dart';
import 'package:rxdart/rxdart.dart';

///Remove all devices from [list] contained in the given [filter]
Iterable<LumaDevice> filter(Iterable<LumaDevice> filter, Iterable<LumaDevice> list) {
  List<LumaDevice> out = List.of(list);
  out.removeWhere((element) => filter.contains(element));
  return out;
}

Iterable<LumaDevice> loadAll(Iterable<CachedDeviceState> input) {
  List<LumaDevice> out = <LumaDevice>[];
  for (CachedDeviceState state in input) {
    out.add(LumaDevice(state));
  }
  return out;
}

class LumaDevice extends LumaDeviceBase {
  // ignore: close_sinks
  final BehaviorSubject<CachedDeviceState> _state = BehaviorSubject<CachedDeviceState>();

  LumaDevice(CachedDeviceState state) : super(state.deviceid, state.address, state.name, state.port) {
    _state.add(state);
    Cache.onStateDBUpdate.where((event) {
      if (!event.deleted) {
        CachedDeviceState value = event.value;
        return value.correspondsTo(this);
      }
      return false;
    }).listen((event) {
      _state.add(event.value);
    });
  }

  Future<void> updateState() async {
    DeviceSocket.sendToDevice(this, LumaProtocol.getAllCommand);
    DeviceUpdate update = await DeviceSocket.onReceive.firstWhere((update) => update.targets(this) && update.value == LumaValue.state);
    CachedDeviceState target = state;
    update.apply(target);
    target.save();
  }

  Stream<CachedDeviceState> get stateStream => _state.stream;

  CachedDeviceState get state => _state.value;
}

///Luma Device without state, not saved to database
class StatelessLumaDevice extends LumaDeviceBase {
  StatelessLumaDevice(int deviceid, String address, String name, int port) : super(deviceid, address, name, port);

  Future<LumaDevice> requestState() async {
    CachedDeviceState state = CachedDeviceState.stateless(_deviceid, _name, _address, _port);
    //Send a Request to the device and wait for the response
    DeviceSocket.sendToDevice(this, LumaProtocol.getAllCommand);
    DeviceUpdate update = await DeviceSocket.onReceive.firstWhere((update) => update.targets(this) && update.value == LumaValue.state);
    //Apply and Save State
    update.apply(state);
    if (kDebugMode) print(state);
    Cache.saveState(state);
    return LumaDevice(state);
  }
}

abstract class LumaDeviceBase {
  ///Display name
  String _name;

  ///Device ID, should be unique in combination with [address]
  int _deviceid;

  ///The IP Address of the Device
  String _address;

  ///UDP Port
  int _port;

  LumaDeviceBase(this._deviceid, this._address, this._name, this._port);

  @override
  int get hashCode => _address.hashCode ^ _deviceid.hashCode;

  @override
  bool operator ==(Object other) {
    return other is LumaDeviceBase && other._deviceid == this._deviceid && other._address == this._address;
  }

  @override
  String toString() {
    return "$_name with id $_deviceid at $_address:$_port";
  }

  String get name => _name;

  int get deviceid => _deviceid;

  String get address => _address;

  int get port => _port;
}
