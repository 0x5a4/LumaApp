import 'package:flutter/material.dart';
import 'package:luma/ui/luma_app.dart';

const double rectClipRadius = 20.0;
const int titleBarHeight = 60;
const int startupDelay = 2;

void main() async {
  runApp(
    MaterialApp(
      home: LumaApp(),
      theme: ThemeData(
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Color(0xFF404449), fontSize: 14),
          subtitle1: TextStyle(color: Color(0xFF404449), fontSize: 12),
          headline1: TextStyle(color: Color(0xFFFED32C), fontSize: 35),
          headline2: TextStyle(color: Color(0xFFFED32C), fontSize: 30),
          headline3: TextStyle(color: Color(0xFFFED32C), fontSize: 16),
          caption: TextStyle(color: Color(0xFF2B3038), fontSize: 20),
        ),
        accentColor: Color(0xFF2B3038),
        backgroundColor: Color(0xFF2B3038),
        focusColor: Color(0xFF20242A),
        highlightColor: Color(0xFFFED32C),
        fontFamily: "Roboto",
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}
