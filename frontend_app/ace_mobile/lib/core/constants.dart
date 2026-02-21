import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class appSize {
  static const defaultPadding = 16.0;
  static const defaultRadius = 12.0;
  static const defaultAniDuration = Duration(milliseconds: 300);

  static const heading = 24.0;
  static const subHeading = 20.0;
  static const body = 16.0;
  static const small = 12.0;
}

class apiconstants {
  static const baseUrl = "https://api.example.com";
  static const timeout = Duration(seconds: 10);

  static const authurl = "/auth";
  static const aiurl = "/ai";
}

class appColors {
  static const primary = Color(0xFF2D7B60);
  static const background = Color(0xFFE8F4F0);
  static const secondary = Color(0xFF4B5563);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
}

class componentColors {
  static const colorA = Color(0xFFB91C1C);
  static const colorB = Color(0xFF5B3FA2);
}

class textColors {
  static const primary = Color(0xFF2D7B60);
  static const secondary = Color(0xFF4B5563);
  static const tertiary = Colors.white;
}

class Sizes {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class appTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,

    /// ⭐ DEFINE COLOR SCHEME
    colorScheme: ColorScheme.fromSeed(
      seedColor: appColors.primary,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: appColors.background,

    /// Typography
    textTheme: GoogleFonts.poppinsTextTheme(),
    fontFamily: GoogleFonts.poppins().fontFamily,
  );
}
