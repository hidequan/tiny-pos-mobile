import 'package:flutter/material.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../data/seed.dart';

/// `.opt` — a selectable option pill with optional surcharge label.
class OptionPill extends StatelessWidget {
  final String label;
  final int price;
  final bool on;
  final VoidCallback onTap;
  const OptionPill({super.key, required this.label, this.price = 0, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? (p.isDark ? const Color(0x1FC75B39) : const Color(0xFFFDF1EC)) : p.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? p.terracotta : p.line2, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppType.body(size: 13.5, weight: FontWeight.w700, color: on ? p.terracottaD : p.ink)),
            if (price > 0) ...[
              const SizedBox(width: 7),
              Text('+${kShort(price)}', style: AppType.body(size: 12, weight: FontWeight.w700, color: on ? p.terracotta : p.muted)),
            ],
          ],
        ),
      ),
    );
  }
}
