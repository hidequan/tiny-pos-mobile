import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'kds_profile.dart';

class KdsDoneScreen extends StatelessWidget {
  const KdsDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    return Column(children: [
      TopBar(
        title: 'Đã hoàn thành',
        subtitle: Text('Ca này · ${state.kdsDone.length} đơn',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [Avatar('QD', colors: const [Color(0xFF3F8F5B), Color(0xFF6FB07A)], onTap: () => openKdsProfile(context))],
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(top: 6, bottom: 20),
          children: [
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clip: true,
              padding: EdgeInsets.zero,
              child: RowList([
                for (final d in state.kdsDone)
                  ListRow(
                    leading: LeadIcon(icon: 'check', bg: p.greenBg, fg: p.greenD),
                    title: d.code,
                    subtitle: '${d.items} món · phục vụ trong ${d.min}',
                    trailing: const AppBadge('Xong', color: BadgeColor.green),
                  ),
              ]),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppButton('Hoàn tác đơn vừa xong',
                  icon: 'history', block: true, variant: BtnVariant.ghost,
                  onTap: () => context.shell.toast('Khôi phục đơn gần nhất', 'history')),
            ),
          ],
        ),
      ),
    ]);
  }
}
