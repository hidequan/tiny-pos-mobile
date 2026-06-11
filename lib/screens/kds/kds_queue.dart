import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/kds_controller.dart';
import '../../models/kds.dart';
import '../../services/receipt.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../theme/app_icons.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'kds_profile.dart';

String fmtAgo(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// KDS / Bar queue — real tickets from /kds/tickets (polled).
class KdsQueueScreen extends StatefulWidget {
  const KdsQueueScreen({super.key});
  @override
  State<KdsQueueScreen> createState() => _KdsQueueScreenState();
}

class _KdsQueueScreenState extends State<KdsQueueScreen> {
  KdsController? _ctl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ctl = context.read<KdsController>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctl = _ctl;
      if (ctl == null || !mounted) return;
      if (!ctl.loaded) ctl.load();
      ctl.startPolling();
    });
  }

  @override
  void dispose() {
    _ctl?.stopPolling(); // saved ref — context.read is unsafe in dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctl = context.watch<KdsController>();
    final p = context.palette;
    final now = DateTime.now();

    return Column(children: [
      TopBar(
        title: 'Pha chế · Bar',
        subtitle: Text('Hàng chờ real-time',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [
          IconBtn('bell', dot: ctl.stats.waiting > 0, onTap: () => ctl.load()),
          Avatar('QD', colors: const [Color(0xFF3F8F5B), Color(0xFF6FB07A)], onTap: () => openKdsProfile(context)),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(children: [
          Expanded(child: _statBox(context, '${ctl.stats.waiting}', 'Đơn đang chờ', p.terracotta)),
          const SizedBox(width: 10),
          Expanded(child: _statBox(context, '${ctl.stats.preparing}', 'Đang pha', p.ink)),
          const SizedBox(width: 10),
          Expanded(child: _statBox(context, '${ctl.stats.completed}', 'Đã xong', p.greenD)),
        ]),
      ),
      Expanded(child: _body(context, ctl, now)),
    ]);
  }

  Widget _body(BuildContext context, KdsController ctl, DateTime now) {
    final p = context.palette;
    if (ctl.loading && !ctl.loaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (ctl.error != null && !ctl.loaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📡', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(ctl.error!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => ctl.load()),
        ]),
      );
    }
    final tickets = ctl.tickets;
    if (tickets.isEmpty) {
      return const EmptyState(emoji: '✅', title: 'Không còn đơn nào', sub: 'Tất cả đã pha xong. Nghỉ tay chút nhé!');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      itemCount: tickets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _TicketCard(ticket: tickets[i], now: now),
    );
  }

  Widget _statBox(BuildContext context, String value, String label, Color color) {
    final p = context.palette;
    return CardBox(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: AppType.display(size: 21, height: 1, color: color)),
        const SizedBox(height: 4),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppType.body(size: 11, weight: FontWeight.w700, color: p.ink2)),
      ]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final KdsTicket ticket;
  final DateTime now;
  const _TicketCard({required this.ticket, required this.now});

  @override
  Widget build(BuildContext context) {
    final ctl = context.read<KdsController>();
    final p = context.palette;
    final ago = ticket.agoSeconds(now);
    final accent = ago >= 360 ? p.red : (ago >= 180 ? p.amber : p.green);
    final timerColor = ago >= 360 ? p.red : (ago >= 180 ? p.amber : p.greenD);
    final allDone = ticket.allDone;

    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
        boxShadow: const [BoxShadow(color: Color(0x0F3C1E0A), blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 5,
                decoration: BoxDecoration(color: accent, borderRadius: const BorderRadius.horizontal(left: Radius.circular(16))),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line2))),
                    child: Row(children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            AppBadge(
                              ticket.isDineIn ? '🪑 Bàn ${ticket.tableLabel ?? '—'}' : '🥡 Mang đi',
                              color: ticket.isDineIn ? BadgeColor.blue : BadgeColor.gray,
                            ),
                            const SizedBox(width: 8),
                            Text(ticket.ticketCode, style: AppType.display(size: 16, weight: FontWeight.w700, color: p.ink)),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(fmtAgo(ago), style: AppType.body(size: 13, weight: FontWeight.w800, color: timerColor)),
                      const SizedBox(width: 5),
                      Icon(AppIcons.get('clock'), size: 14, color: timerColor),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                    child: Column(children: [
                      for (var k = 0; k < ticket.items.length; k++) _item(context, ctl, ticket.items[k], k > 0),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(children: [
              Expanded(
                child: AppButton('Tem', icon: 'print', variant: BtnVariant.ghost,
                    onTap: () => _printLabels(context)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: AppButton(
                  allDone ? 'Hoàn thành' : 'Xong tất cả',
                  icon: 'check',
                  variant: allDone ? BtnVariant.pri : BtnVariant.dark,
                  onTap: () {
                    ctl.bumpTicket(ticket.id);
                    context.shell.toast('Đơn ${ticket.ticketCode} đã hoàn thành', 'check');
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _printLabels(BuildContext context) async {
    final items = [
      for (final it in ticket.items)
        LabelItem(productName: it.productName, variantName: it.variantName, mods: it.mods, quantity: it.quantity),
    ];
    try {
      await ReceiptService.printLabels(ticket.ticketCode, items);
    } catch (_) {
      if (context.mounted) context.shell.toast('Không mở được bản in tem', 'edit');
    }
  }

  Widget _item(BuildContext context, KdsController ctl, KdsTicketItem item, bool border) {
    final p = context.palette;
    final busy = ctl.itemBusy(item.id);
    return GestureDetector(
      onTap: item.done || busy ? null : () => ctl.markItemDone(item.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: border ? Border(top: BorderSide(color: p.line)) : null),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            height: 26,
            decoration: BoxDecoration(color: item.done ? p.green : p.espresso, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text('${item.quantity}', style: AppType.body(size: 13, weight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(
                item.variantName != null && item.variantName!.isNotEmpty ? '${item.productName} (${item.variantName})' : item.productName,
                style: AppType.body(size: 14.5, weight: FontWeight.w700, color: item.done ? p.muted : p.ink)
                    .copyWith(decoration: item.done ? TextDecoration.lineThrough : null),
              ),
              if (item.mods.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(item.mods, style: AppType.body(size: 12, weight: FontWeight.w500, color: p.ink2)),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          busy
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: p.muted))
              : Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: item.done ? p.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: item.done ? p.green : p.line2, width: 2),
                  ),
                  child: item.done ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
                ),
        ]),
      ),
    );
  }
}
