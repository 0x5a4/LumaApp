import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';

import 'package:luma/cache.dart';
import 'package:luma/devices.dart';
import 'package:luma/net/protocol.dart';
import 'package:rxdart/rxdart.dart';

class DeviceSocket {
  // ignore: close_sinks
  static late Stream<DeviceUpdate> _onReceive;
  static late RawDatagramSocket _socket;
  static const socketPort = 65001;

  static Future<void> init({port = socketPort}) async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    //Map the RawSocket Events to a stream of non-nullable datagrams
    _onReceive = _socket
        .where((event) => event == RawSocketEvent.read)
        .map((event) => _socket.receive())
        .where((datagram) => datagram != null)
        .map<DeviceUpdate?>((datagram) => LumaProtocol.interpret(datagram!.address.address, datagram.data))
        .where((update) => update != null)
        .map((update) => update!)
        .asBroadcastStream();
    //Update Cache whenever a datagram is received that points to an existing state
    _onReceive.listen((update) async {
      // address xor id is the same value returned by the states own hashCode function.
      // But we dont have an object at hand, so we artificially create the hash ourselves
      CachedDeviceState? target = Cache.getState(update.destinationAddress.hashCode ^ update.destinationID.hashCode);
      if (target != null) {
        await runZonedGuarded(() async {
          update.apply(target);
          await target.save();
        }, (e, stackTrace) {
          print("Unable to update device state $e");
          print(stackTrace);
        });
      }
    });
  }

  ///Send the given data to the given device. Returns the Number of bytes send
  static int sendToDevice(LumaDeviceBase device, Uint8List data) => send(InternetAddress(device.address), device.port, data);

  static int send(InternetAddress address, int port, Uint8List data) => _socket.send(data, address, port);

  static Stream<DeviceUpdate> get onReceive => _onReceive;
}

class DeviceUpdate {
  final String destinationAddress;
  final int destinationID;
  final int commandID;
  final LumaValue value;
  final Uint8List data;

  DeviceUpdate(this.destinationAddress, this.destinationID, this.commandID, this.value, this.data);

  void apply(CachedDeviceState cachedDevice) {
    value.apply(cachedDevice, data);
  }

  bool targets(LumaDeviceBase device) => device.address == this.destinationAddress && device.deviceid == this.destinationID;
}

class DeviceDiscoverer {
  static const mdnsServiceName = "_luma._tcp";
  static final MDnsClient _client = MDnsClient();
  static final BehaviorSubject<List<StatelessLumaDevice>> _deviceCache = BehaviorSubject();
  static bool _isRunning = false;

  static Future<void> start() async {
    assert(!_isRunning, "Already Running");
    await _client.start();
    _isRunning = true;
    await discover();
  }

  static void stop() async {
    assert(_isRunning, "Cannot stop when not running");
    _client.stop();
    _isRunning = false;
  }

  static Future<List<StatelessLumaDevice>> discover() async {
    assert(_isRunning, "Not Running");
    List<StatelessLumaDevice> result = <StatelessLumaDevice>[];
    await for (PtrResourceRecord ptr in _client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(mdnsServiceName)).distinct()) {
      await for (SrvResourceRecord srv in _client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName)).distinct()) {
        await for (IPAddressResourceRecord ip in _client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target)).distinct()) {
          try {
            String info = srv.name.substring(0, srv.name.indexOf(".$mdnsServiceName"));
            String name = info.substring(0, info.lastIndexOf("."));
            String idString = info.substring(info.lastIndexOf(".") + 1);
            int port = srv.port;
            int id = int.parse(idString);
            StatelessLumaDevice device = StatelessLumaDevice(id, ip.address.address, name, port);
            if (!result.contains(device)) {
              if (kDebugMode) print(device);
              result.add(device);
            }
          } catch (e, stackTrace) {
            print(e);
            print(stackTrace);
          }
        }
      }
    }
    _deviceCache.add(result);
    return result;
  }

  static Stream<Iterable<StatelessLumaDevice>> get onDiscover {
    assert(_isRunning, "Not Running, cannot obtain stream");
    return _deviceCache.stream;
  }

  static Iterable<StatelessLumaDevice> get availableDevices => _deviceCache.value;

  static bool get isRunning => _isRunning;
}
