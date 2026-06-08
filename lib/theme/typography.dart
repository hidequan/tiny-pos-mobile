import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font helpers. Body = Hanken Grotesk (`--ff`), Display = Fraunces (`--fd`).
class AppType {
  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double letterSpacing = -0.14,
  }) =>
      GoogleFonts.hankenGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Fraunces — used for titles, hero numbers, big totals.
  static TextStyle display({
    double size = 21,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double letterSpacing = -0.4,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextTheme textTheme() => GoogleFonts.hankenGroteskTextTheme();
}
