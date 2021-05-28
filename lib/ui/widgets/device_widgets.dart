import 'package:flutter/material.dart';

import 'package:luma/devices.dart';
import 'package:luma/main.dart';

class DeviceDrawer extends StatelessWidget {
  final Widget child;
  final Alignment exitButtonAlignment;
  final Text caption;
  final BorderRadius clipBorderRadius;

  const DeviceDrawer({
    required this.child,
    required this.caption,
    required this.clipBorderRadius,
    required this.exitButtonAlignment,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      height: computeHeight(MediaQuery.of(context)),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black.withOpacity(0.4),
          width: 1.5
        ),
        borderRadius: clipBorderRadius,
      ),
      child: ClipRRect(
        borderRadius: clipBorderRadius,
        child: ColoredBox(
          color: Theme.of(context).focusColor,
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 45,
                  ),
                  caption,
                  SizedBox(
                    height: 20,
                  ),
                  child
                ],
              ),
              Align(
                alignment: exitButtonAlignment,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: GestureDetector(
                    child: Image.asset(
                      "assets/img/cross.png",
                      width: 30,
                      height: 30,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  double computeHeight(MediaQueryData query) {
    double screenHeight = query.size.height;
    double actual = screenHeight - query.viewPadding.top * 2;
    return actual - 20;
  }
}

class DeviceListTile<T extends LumaDeviceBase> extends StatelessWidget {
  final T device;
  final void Function(T device)? onTap;

  const DeviceListTile(this.device, {this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 5),
        onTap: () => onTap?.call(device),
        title: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      "assets/img/ledicon.png",
                      height: 50,
                      width: 50,
                    ),
                    SizedBox(
                      width: 7,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${device.address}:${device.port}",
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
