import 'package:flutter/material.dart';

import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import 'kds_profile.dart';

class KdsStatsScreen extends StatelessWidget {
  const KdsStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stats = [
      ['check', p.greenBg, p.greenD, '86', 'Ly đã pha', '+12%', true],
      ['clock', p.amberBg, p.amber, '2:48', 'TG pha TB', 'nhanh hơn 8%', true],
      ['fire', p.redBg, p.red, '3', 'Đơn trễ (>6p)', '', false],
      ['coffee', p.blueBg, p.blue, '14:00', 'Giờ cao điểm', '', false],
    ];
    const top = [
      ['Cà phê sữa đá', 28],
      ['Trà đào cam sả', 19],
      ['Bạc xỉu', 16],
      ['Matcha Latte', 12],
    ];

    return Column(children: [
      TopBar(
        title: 'Thống kê pha chế',
        subtitle: Text('Hôm nay', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [Avatar('QD', colors: const [Color(0xFF3F8F5B), Color(0xFF6FB07A)], onTap: () => openKdsProfile(context))],
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 138,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [for (final s in stats) _statCard(context, s)],
              ),
            ),
            const SectionHeader('Món pha nhiều nhất'),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(children: [
                for (var i = 0; i < top.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      SizedBox(width: 18, child: Text('${i + 1}', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.muted))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(top[i][0] as String, style: AppType.body(size: 13.5, weight: FontWeight.w700, color: p.ink))),
                      Container(
                        width: 90,
                        height: 6,
                        decoration: BoxDecoration(color: p.cream2, borderRadius: BorderRadius.circular(3)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (top[i][1] as int) / 28,
                          child: Container(decoration: BoxDecoration(color: p.terracotta, borderRadius: BorderRadius.circular(3))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(width: 24, child: Text('${top[i][1]}', textAlign: TextAlign.right, style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink))),
                    ]),
                  ),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _statCard(BuildContext context, List<dynamic> s) {
    final p = context.palette;
    final delta = s[5] as String;
    final up = s[6] as bool;
    return CardBox(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: s[1] as Color, borderRadius: BorderRadius.circular(11)),
          child: Icon(_ic(s[0] as String), size: 18, color: s[2] as Color),
        ),
        const SizedBox(height: 9),
        Text(s[3] as String, style: AppType.display(size: 22, height: 1, color: p.ink)),
        const SizedBox(height: 4),
        Text(s[4] as String, style: AppType.body(size: 12, weight: FontWeight.w700, color: p.ink2)),
        if (delta.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.trending_up_rounded, size: 12, color: up ? p.greenD : p.red),
            const SizedBox(width: 3),
            Text(delta, style: AppType.body(size: 11, weight: FontWeight.w800, color: up ? p.greenD : p.red)),
          ]),
        ],
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
