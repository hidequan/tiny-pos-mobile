import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/kds_controller.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import 'kds_profile.dart';

class KdsDoneScreen extends StatelessWidget {
  const KdsDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ctl = context.watch<KdsController>();
    if (!ctl.loaded && !ctl.loading && ctl.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ctl.load());
    }
    return Column(children: [
      TopBar(
        title: 'Đã hoàn thành',
        subtitle: Text('Ca này · ${ctl.stats.completed} đơn',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [Avatar('QD', colors: const [Color(0xFF3F8F5B), Color(0xFF6FB07A)], onTap: () => openKdsProfile(context))],
      ),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(color: p.greenBg, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, size: 42, color: p.greenD),
              ),
              const SizedBox(height: 16),
              Text('${ctl.stats.completed} đơn đã xong', style: AppType.display(size: 22, color: p.ink)),
              const SizedBox(height: 6),
              Text('trong ca làm việc hiện tại', style: AppType.body(size: 13, color: p.muted)),
              const SizedBox(height: 18),
              AppButton('Làm mới', icon: 'history', variant: BtnVariant.ghost, onTap: () => ctl.load()),
            ]),
          ),
        ),
      ),
    ]);
  }
}
