import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../theme/app_icons.dart';
import '../../widgets/common.dart';

/// `.stat` admin KPI card with icon, value, label and optional delta.
class StatCard extends StatelessWidget {
  final String icon;
  final Color bg;
  final Color fg;
  final String value;
  final String label;
  final String? delta;
  final bool up;
  const StatCard({
    super.key,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.value,
    required this.label,
    this.delta,
    this.up = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CardBox(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
          child: Icon(AppIcons.get(icon), size: 18, color: fg),
        ),
        const SizedBox(height: 9),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, maxLines: 1, style: AppType.display(size: 22, height: 1, color: p.ink)),
        ),
        const SizedBox(height: 4),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppType.body(size: 12, weight: FontWeight.w700, color: p.ink2)),
        if (delta != null) ...[
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.trending_up_rounded, size: 12, color: up ? p.greenD : p.red),
              const SizedBox(width: 3),
              Text(delta!, maxLines: 1, style: AppType.body(size: 11, weight: FontWeight.w800, color: up ? p.greenD : p.red)),
            ]),
          ),
        ],
      ]),
    );
  }
}

/// `.chart` 7-day bar chart. Peak bar uses the espresso gradient.
class BarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  const BarChart({super.key, required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mx = values.reduce(math.max);
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (values[i] == mx)
                      Text('${values[i]}tr', style: AppType.body(size: 9.5, weight: FontWeight.w800, color: p.terracotta)),
                    const SizedBox(height: 7),
                    FractionallySizedBox(
                      widthFactor: 0.72,
                      child: Container(
                        height: (values[i] / mx) * 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: values[i] == mx ? [p.espresso2, p.espresso] : [p.caramel, p.terracotta],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(7), bottom: Radius.circular(4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(labels[i], style: AppType.body(size: 10.5, weight: FontWeight.w700, color: p.muted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.topbar` with a back button — port of `backbar(title, sub)`.
class BackBar extends StatelessWidget {
  final String title;
  final String sub;
  const BackBar({super.key, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TopBar(
      leading: IconBtn('back', onTap: () => context.read<AppState>().openAdminSub(null)),
      title: title,
      subtitle: Text(sub, style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
    );
  }
}

/// Conic-gradient donut for the payment-mix report.
class Donut extends StatelessWidget {
  final List<List<dynamic>> segments; // [label, percent, colorInt]
  final String center;
  final String centerSub;
  const Donut({super.key, required this.segments, required this.center, required this.centerSub});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 108,
      height: 108,
      child: CustomPaint(
        painter: _DonutPainter(segments, p.paper),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(center, style: AppType.display(size: 18, color: p.ink)),
            Text(centerSub, style: AppType.body(size: 10, weight: FontWeight.w700, color: p.ink2)),
          ]),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<List<dynamic>> segments;
  final Color hole;
  _DonutPainter(this.segments, this.hole);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = (s[1] as int) / 100 * 2 * math.pi;
      final paint = Paint()..color = Color(s[2] as int)..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, true, paint);
      start += sweep;
    }
    canvas.drawCircle(center, radius - 21, Paint()..color = hole);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => false;
}
