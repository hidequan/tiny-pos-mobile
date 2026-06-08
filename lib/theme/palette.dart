import 'package:flutter/material.dart';

/// Color tokens ported 1:1 from the approved `tinypos.html` mockup `:root`.
/// Light = default app theme. Dark = the KDS / Bar screen theme.
class Palette {
  final Color espresso;
  final Color espresso2;
  final Color coffee;
  final Color terracotta;
  final Color terracottaD;
  final Color caramel;
  final Color cream;
  final Color cream2;
  final Color paper;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color faint;
  final Color line;
  final Color line2;
  final Color green;
  final Color greenBg;
  final Color greenD;
  final Color amber;
  final Color amberBg;
  final Color red;
  final Color redBg;
  final Color blue;
  final Color blueBg;
  final bool isDark;

  const Palette({
    required this.espresso,
    required this.espresso2,
    required this.coffee,
    required this.terracotta,
    required this.terracottaD,
    required this.caramel,
    required this.cream,
    required this.cream2,
    required this.paper,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.faint,
    required this.line,
    required this.line2,
    required this.green,
    required this.greenBg,
    required this.greenD,
    required this.amber,
    required this.amberBg,
    required this.red,
    required this.redBg,
    required this.blue,
    required this.blueBg,
    required this.isDark,
  });

  static const Palette light = Palette(
    espresso: Color(0xFF241008),
    espresso2: Color(0xFF3A1F12),
    coffee: Color(0xFF6F4E37),
    terracotta: Color(0xFFC75B39),
    terracottaD: Color(0xFFB14A2C),
    caramel: Color(0xFFD98A4E),
    cream: Color(0xFFF7F1E8),
    cream2: Color(0xFFEFE5D6),
    paper: Color(0xFFFFFFFF),
    ink: Color(0xFF2A1810),
    ink2: Color(0xFF6B5749),
    muted: Color(0xFF9C8A79),
    faint: Color(0xFFBCAE9E),
    line: Color(0xFFEBE0D0),
    line2: Color(0xFFE0D2BF),
    green: Color(0xFF3F8F5B),
    greenBg: Color(0xFFE6F2EA),
    greenD: Color(0xFF2F7347),
    amber: Color(0xFFCF942F),
    amberBg: Color(0xFFFBF0D8),
    red: Color(0xFFCF462C),
    redBg: Color(0xFFFBE6E0),
    blue: Color(0xFF3F6FB0),
    blueBg: Color(0xFFE7EEF8),
    isDark: false,
  );

  /// KDS dark theme (`#phone[data-theme="dark"]`). Brand colors unchanged,
  /// only surface / ink / line / *-bg tokens are overridden.
  static const Palette dark = Palette(
    espresso: Color(0xFF241008),
    espresso2: Color(0xFF3A1F12),
    coffee: Color(0xFF6F4E37),
    terracotta: Color(0xFFC75B39),
    terracottaD: Color(0xFFB14A2C),
    caramel: Color(0xFFD98A4E),
    cream: Color(0xFF16110D),
    cream2: Color(0xFF1F1813),
    paper: Color(0xFF221A14),
    ink: Color(0xFFF4ECE2),
    ink2: Color(0xFFB7A895),
    muted: Color(0xFF8D7D6D),
    faint: Color(0xFF6F6256),
    line: Color(0xFF2B231C),
    line2: Color(0xFF352B22),
    green: Color(0xFF3F8F5B),
    greenBg: Color(0xFF1D2C22),
    greenD: Color(0xFF2F7347),
    amber: Color(0xFFCF942F),
    amberBg: Color(0xFF2E2615),
    red: Color(0xFFCF462C),
    redBg: Color(0xFF321D18),
    blue: Color(0xFF3F6FB0),
    blueBg: Color(0xFF1C2533),
    isDark: true,
  );
}

/// Inherited scope so any descendant can read the active [Palette] via
/// `context.palette`. Switched to [Palette.dark] when the KDS role is active.
class PaletteScope extends InheritedWidget {
  final Palette palette;
  const PaletteScope({super.key, required this.palette, required super.child});

  static Palette of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PaletteScope>();
    return scope?.palette ?? Palette.light;
  }

  @override
  bool updateShouldNotify(PaletteScope oldWidget) => palette.isDark != oldWidget.palette.isDark;
}

extension PaletteContext on BuildContext {
  Palette get palette => PaletteScope.of(this);
}
