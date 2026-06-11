import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/kds_controller.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import 'kds_profile.dart';

class KdsStatsScreen extends StatelessWidget {
  const KdsStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ctl = context.watch<KdsController>();
    if (!ctl.loaded && !ctl.loading && ctl.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ctl.load());
    }
    final s = ctl.stats;
    final cards = [
      ['fire', p.amberBg, p.amber, '${s.waiting}', 'Đơn đang chờ'],
      ['clock', const Color(0xFFEFE6F7), const Color(0xFF7A4FB0), '${s.preparing}', 'Đang pha'],
      ['check', p.greenBg, p.greenD, '${s.completed}', 'Đã xong'],
      ['coffee', p.blueBg, p.blue, '${ctl.tickets.length}', 'Vé trên màn'],
    ];

    return Column(children: [
      TopBar(
        title: 'Thống kê pha chế',
        subtitle: Text('Real-time', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [Avatar('QD', colors: const [Color(0xFF3F8F5B), Color(0xFF6FB07A)], onTap: () => openKdsProfile(context))],
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.only(bottom: 20), children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 118,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [for (final c in cards) _card(context, c)],
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _card(BuildContext context, List<dynamic> c) {
    final p = context.palette;
    return CardBox(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: c[1] as Color, borderRadius: BorderRadius.circular(11)),
          child: Icon(_ic(c[0] as String), size: 18, color: c[2] as Color),
        ),
        const SizedBox(height: 9),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(c[3] as String, maxLines: 1, style: AppType.display(size: 22, height: 1, color: p.ink)),
        ),
        const SizedBox(height: 4),
        Text(c[4] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppType.body(size: 12, weight: FontWeight.w700, color: p.ink2)),
      ]),
    );
  }

  IconData _ic(String n) => {
        'check': Icons.check_rounded,
        'clock': Icons.access_time_rounded,
        'fire': Icons.local_fire_department_outlined,
        'coffee': Icons.local_cafe_outlined,
      }[n]!;
}
