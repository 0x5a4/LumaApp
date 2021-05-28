import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:luma/cache.dart';
import 'package:luma/devices.dart';
import 'package:luma/main.dart';
import 'package:luma/net/protocol.dart';

class DeviceView extends StatelessWidget {
  final Stream<LumaDevice?> deviceStream;

  const DeviceView(this.deviceStream, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LumaDevice?>(
      stream: deviceStream,
      builder: (context, snapshot) {
        LumaDevice? device = snapshot.data;
        if (device == null) {
          return Center(
            child: Text(
              "Nothing",
              style: Theme.of(context).textTheme.headline2,
            ),
          );
        }

        return Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: PowerButton(device.stateStream),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: LumaColorPicker(),
            )
          ],
        );
      },
    );
  }
}

class LumaColorPicker extends StatelessWidget {
  const LumaColorPicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ColorPicker(
      onColorChanged: (value) {
        LumaColor color = LumaColor.fromColor(value);
      },
      pickersEnabled: {
        ColorPickerType.wheel: true,
        ColorPickerType.accent: false,
        ColorPickerType.primary: false,
        ColorPickerType.both: false,
        ColorPickerType.bw: false,
        ColorPickerType.custom: false,
      },
      enableShadesSelection: false,
    );
  }
}

class PowerButton extends StatelessWidget {
  final Stream<CachedDeviceState> stateStream;

  const PowerButton(this.stateStream, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.all(Radius.circular(rectClipRadius));
    return StreamBuilder<CachedDeviceState>(
      stream: stateStream,
      builder: (context, snapshot) {
        String text = "Error";
        Color boxColor = Color(0x0);
        Color textColor = Theme.of(context).highlightColor;

        if (snapshot.hasError) {
          print(snapshot.error);
          print(snapshot.stackTrace);
        }

        CachedDeviceState? state = snapshot.data;

        if (state != null) {
          bool isPowered = state.isPowered;
          text = isPowered ? "On" : "Off";
          textColor = isPowered ? Theme.of(context).accentColor : textColor;
          boxColor = isPowered ? Theme.of(context).highlightColor : boxColor;
        }

        return GestureDetector(
          onTap: () {
            if (state != null) {
              state.updatePower(!state.isPowered);
            }
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: titleBarHeight.toDouble(),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).highlightColor,
                width: 3,
              ),
              color: boxColor,
              borderRadius: borderRadius,
            ),
            child: Center(
              child: Text(
                text,
                style: Theme.of(context).textTheme.caption?.copyWith(color: textColor),
              ),
            ),
          ),
        );
      },
    );
  }
}

//TODO: Color Wheel, Speed Slider
