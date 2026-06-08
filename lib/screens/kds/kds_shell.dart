import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import 'kds_queue.dart';
import 'kds_done.dart';
import 'kds_stats.dart';

class KdsShell extends StatelessWidget {
  const KdsShell({super.key});
  @override
  Widget build(BuildContext context) {
    final tab = context.watch<AppState>().kdsTab;
    switch (tab) {
      case 'done':
        return const KdsDoneScreen();
      case 'stats':
        return const KdsStatsScreen();
      case 'queue':
      default:
        return const KdsQueueScreen();
    }
  }
}
