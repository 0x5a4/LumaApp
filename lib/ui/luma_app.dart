import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:luma/cache.dart';
import 'package:luma/devices.dart';
import 'package:luma/net/net.dart';
import 'package:luma/net/protocol.dart';
import 'package:luma/ui/lumawidgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:luma/main.dart';

final BehaviorSubject<LumaDevice?> selectedDeviceStream = BehaviorSubject.seeded(null);

LumaDevice? get selectedDevice => selectedDeviceStream.hasValue ? selectedDeviceStream.value : null;

class LumaApp extends StatefulWidget {
  const LumaApp();

  @override
  _LumaAppState createState() => _LumaAppState();
}

class _LumaAppState extends State<LumaApp> {
  LumaDevice? selectedDevice;
  bool isLoaded = false;

  _LumaAppState() {
    Future.wait([
      initializeApp(),
      Future.delayed(Duration(
        seconds: startupDelay,
      ))
    ]).then((value) => setState(() => isLoaded = true));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoaded) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).backgroundColor,
        drawerScrimColor: Color(0x00000000),
        drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.2,
        body: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).viewPadding.top + titleBarHeight,
              child: ColoredBox(
                color: Theme.of(context).focusColor,
                child: StreamBuilder<LumaDevice?>(
                    stream: selectedDeviceStream,
                    builder: (context, snapshot) {
                      LumaDevice? device = snapshot.data;
                      String caption = "None";
                      if (device != null) {
                        caption = device.name;
                      }

                      return SafeArea(
                        child: Center(
                          child: Text(caption, style: Theme.of(context).textTheme.headline2),
                        ),
                      );
                    }),
              ),
            ),
            Expanded(
              child: DeviceView(selectedDeviceStream),
            ),
          ],
        ),

        ///Available Devices
        drawer: DeviceDrawer(
          exitButtonAlignment: Alignment.topRight,
          clipBorderRadius: BorderRadius.horizontal(
            right: Radius.circular(rectClipRadius),
          ),
          caption: Text(
            "Your Devices",
            style: Theme.of(context).textTheme.headline1,
          ),
          child: Flexible(
            child: StreamBuilder<Iterable<LumaDevice>>(
              stream: Cache.onStateListUpdate.map((stateList) {
                return stateList.map<LumaDevice>((state) => LumaDevice(state));
              }),
              builder: (context, snapshot) => asListView<LumaDevice>(
                snapshot,
                onTap: (device) {
                  selectedDeviceStream.add(device);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),

        ///DiscoveryDrawer
        endDrawer: DeviceDrawer(
          exitButtonAlignment: Alignment.topLeft,
          clipBorderRadius: BorderRadius.horizontal(
            left: Radius.circular(rectClipRadius),
          ),
          caption: Text(
            "Available",
            style: Theme.of(context).textTheme.headline1,
          ),
          child: Flexible(
            child: RefreshIndicator(
              onRefresh: () async {
                await DeviceDiscoverer.discover();
                if (mounted) setState(() {});
              },
              backgroundColor: Theme.of(context).backgroundColor,
              child: StreamBuilder<Iterable<StatelessLumaDevice>>(
                stream: DeviceDiscoverer.onDiscover,
                builder: (context, snapshot) => asListView<StatelessLumaDevice>(
                  snapshot,
                  onTap: (device) {
                    runZonedGuarded(
                      () => device.requestState(),
                      (e, stackTrace) {
                        print(e);
                        print(stackTrace);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Center(
      child: Image.asset("assets/img/startup.gif"),
    );
  }

  ListView asListView<T extends LumaDeviceBase>(AsyncSnapshot<Iterable<T>> snapshot, {void Function(T device)? onTap}) {
    List<Widget> result = createDeviceTileList<T>([]);
    if (snapshot.hasError) {
      print(snapshot.error);
      print(snapshot.stackTrace);
    }

    Iterable<T>? data = snapshot.data;
    if (data != null) {
      result = createDeviceTileList<T>(data.toList(), onTap: onTap);
    }

    return ListView(
      padding: EdgeInsets.zero,
      physics: BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: result,
    );
  }

  List<Widget> createDeviceTileList<T extends LumaDeviceBase>(List<T> list, {void Function(T device)? onTap}) {
    List<Widget> result = <Widget>[];
    Padding seperator = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 5,
        width: double.infinity,
        child: ColoredBox(
          color: Color(0xFF2B3038),
        ),
      ),
    );
    result.add(seperator);
    for (T device in list) {
      result.add(DeviceListTile<T>(device, onTap: onTap));
      result.add(seperator);
    }
    return result;
  }

  Future<void> initializeApp() async {
    //Hive
    await Hive.initFlutter("luma");
    Hive.registerAdapter(CachedDeviceStateAdapter());
    Hive.registerAdapter(LumaColorAdapter());

    //Run protected to catch async errors
    await Cache.init();
    await DeviceSocket.init();
    await DeviceDiscoverer.start();

    //Flags
    if (const bool.fromEnvironment("LUMA_WIPEDB")) {
      print("Wiping database...");
      await Cache.clearStateCache();
    }

    if (const bool.fromEnvironment("LUMA_TEST")) {
      print("Adding test entries...");
      Cache.saveState(CachedDeviceState(0, "test1", "192.168.0.55", 65000, [], true, 0, 4, 300));
      Cache.saveState(CachedDeviceState(1, "test2", "192.168.0.55", 65000, [], false, 0, 10, 30));
      Cache.saveState(CachedDeviceState(2, "test3", "192.168.0.55", 65000, [], false, 1, 8, 100));
      Cache.saveState(CachedDeviceState(3, "test4", "192.168.0.55", 65000, [], true, 2, 9, 150));
      Cache.saveState(CachedDeviceState(4, "test5", "192.168.0.55", 65000, [], true, 3, 3, 70));
      Cache.saveState(CachedDeviceState(5, "test6", "192.168.0.55", 65000, [], false, 0, 1, 60));
    }
  }
}
