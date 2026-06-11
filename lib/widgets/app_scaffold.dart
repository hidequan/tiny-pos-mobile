import 'package:flutter/material.dart';

/// The centered fixed-width (≤480px) phone frame used by full-screen pages that
/// live OUTSIDE the role shell (login, splash), matching PhoneFrame's layout.
class AppFrame extends StatelessWidget {
  final Widget child;
  const AppFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9E0D2),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ClipRect(child: SizedBox.expand(child: child)),
        ),
      ),
    );
  }
}
