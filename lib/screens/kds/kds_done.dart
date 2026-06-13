import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/kds_controller.dart';
import '../../models/kds.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import 'kds_profile.dart';

/// "Đã hoàn thành" — today's SERVED tickets (GET /kds/tickets?status=SERVED),
/// mirroring the web KDS "Hoàn thành" filter. Read-only review list.
class KdsDoneScreen extends StatefulWidget {
  const KdsDoneScreen({super.key});
  @override
  State<KdsDoneScreen> createState() => _KdsDoneScreenState();
}

class _KdsDoneScreenState extends State<KdsDoneScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<KdsController>().loadServed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ctl = context.watch<KdsController>();
    return Column(children: [
      TopBar(
        title: 'Đã hoàn thành',
        subtitle: Text('Ca này · ${ctl.stats.completed} đơn',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [
          IconBtn('history', onTap: () => ctl.loadServed()),
          Avatar('QD', colors: const [Color(0xFF3F8F5B), Color(0xFF6FB07A)], onTap: () => openKdsProfile(context)),
        ],
      ),
      Expanded(child: _body(context, ctl)),
    ]);
  }

  Widget _body(BuildContext context, KdsController ctl) {
    final p = context.palette;
    if (ctl.servedLoading && ctl.served.isEmpty) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (ctl.servedError != null && ctl.served.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(ctl.servedError!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => ctl.loadServed()),
        ]),
      );
    }
    if (ctl.served.isEmpty) {
      return const EmptyState(emoji: '☕', title: 'Chưa có đơn hoàn thành', sub: 'Đơn pha xong trong ca sẽ hiện ở đây');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: ctl.served.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _DoneCard(ticket: ctl.served[i]),
    );
  }
}

class _DoneCard extends StatelessWidget {
  final KdsTicket ticket;
  const _DoneCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
          child: Row(children: [
            Flexible(
              child: Text(ticket.ticketCode,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppType.display(size: 16, weight: FontWeight.w700, color: p.ink)),
            ),
            const SizedBox(width: 8),
            AppBadge(ticket.isDineIn ? '🪑 Bàn ${ticket.tableLabel ?? '—'}' : '🥡 Mang đi',
                color: ticket.isDineIn ? BadgeColor.blue : BadgeColor.gray),
            const Spacer(),
            Text('✓ Xong', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.greenD)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final it in ticket.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${it.quantity}×', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        it.variantName != null && it.variantName!.isNotEmpty
                            ? '${it.productName} (${it.variantName})'
                            : it.productName,
                        style: AppType.body(size: 13.5, weight: FontWeight.w600, color: p.ink2),
                      ),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
