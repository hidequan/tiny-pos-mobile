import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/kds_controller.dart';
import '../../models/kds.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'kds_profile.dart';

/// KDS / Bar queue — real tickets from /kds/tickets (polled).
class KdsQueueScreen extends StatefulWidget {
  const KdsQueueScreen({super.key});
  @override
  State<KdsQueueScreen> createState() => _KdsQueueScreenState();
}

class _KdsQueueScreenState extends State<KdsQueueScreen> {
  KdsController? _ctl;
  String _filter = 'all'; // all | waiting | preparing
  String _search = '';

  static const _prepStatuses = ['PREPARING', 'PARTIAL_READY', 'READY'];

  List<KdsTicket> _filtered(List<KdsTicket> all) {
    var list = switch (_filter) {
      'waiting' => all.where((t) => t.status == 'WAITING').toList(),
      'preparing' => all.where((t) => _prepStatuses.contains(t.status)).toList(),
      _ => all,
    };
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((t) =>
              t.ticketCode.toLowerCase().contains(q) ||
              (t.tableLabel ?? '').toLowerCase().contains(q) ||
              t.items.any((i) => i.productName.toLowerCase().contains(q)))
          .toList();
    }
    return list;
  }

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
      SearchField(hint: 'Tìm mã đơn / bàn / món...', value: _search, onChanged: (v) => setState(() => _search = v)),
      ChipsRow(children: [
        PillChip('Tất cả', emoji: '📋', on: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
        PillChip('Chờ pha', on: _filter == 'waiting', onTap: () => setState(() => _filter = 'waiting')),
        PillChip('Đang pha', on: _filter == 'preparing', onTap: () => setState(() => _filter = 'preparing')),
      ]),
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
    final tickets = _filtered(ctl.tickets);
    if (tickets.isEmpty) {
      final hasAny = ctl.tickets.isNotEmpty;
      final (emoji, title, sub) = _search.trim().isNotEmpty || (hasAny && _filter != 'all')
          ? ('🔍', 'Không có đơn khớp', 'Thử bỏ lọc hoặc đổi từ khóa')
          : ('✅', 'Không còn đơn nào', 'Tất cả đã pha xong. Nghỉ tay chút nhé!');
      return EmptyState(emoji: emoji, title: title, sub: sub);
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
    final mins = ticket.agoSeconds(now) ~/ 60;
    final overdue = mins >= 10 && ticket.status != 'READY';
    // Card accent follows the STATUS (mirrors the web TICKET_BORDER) so it
    // changes the moment the bar presses "Bắt đầu làm" / "Hoàn thành".
    final accent = _accent(p, ticket.status);
    final timerColor = overdue ? p.red : p.muted;

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
                      Text('$mins phút${overdue ? ' ⚠' : ''}',
                          style: AppType.body(size: 13, weight: FontWeight.w800, color: timerColor)),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: Align(alignment: Alignment.centerLeft, child: _statusBadge(ticket.status)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                    child: Column(children: [
                      for (var k = 0; k < ticket.items.length; k++) _item(context, ticket.items[k], k > 0),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: ticket.status == 'WAITING'
                ? AppButton(
                    'Bắt đầu làm',
                    icon: 'fire',
                    block: true,
                    variant: BtnVariant.dark,
                    onTap: () {
                      ctl.startTicket(ticket.id);
                      context.shell.toast('Bắt đầu pha đơn ${ticket.ticketCode}', 'fire');
                    },
                  )
                : AppButton(
                    'Hoàn thành',
                    icon: 'check',
                    block: true,
                    variant: BtnVariant.pri,
                    onTap: () {
                      ctl.bumpTicket(ticket.id);
                      context.shell.toast('Đơn ${ticket.ticketCode} đã hoàn thành', 'check');
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _accent(Palette p, String status) => switch (status) {
        'WAITING' => p.amber,
        'PREPARING' || 'PARTIAL_READY' => const Color(0xFF3E7C74), // teal
        'READY' => p.greenD,
        'SERVED' || 'COMPLETED' => p.muted,
        _ => p.line2,
      };

  Widget _statusBadge(String status) {
    final (txt, col) = switch (status) {
      'WAITING' => ('● Chờ pha', BadgeColor.amber),
      'PREPARING' || 'PARTIAL_READY' => ('● Đang pha', BadgeColor.blue),
      'READY' => ('● Sẵn sàng', BadgeColor.green),
      'SERVED' || 'COMPLETED' => ('✓ Hoàn thành', BadgeColor.gray),
      _ => ('● Chờ pha', BadgeColor.amber),
    };
    return AppBadge(txt, color: col);
  }

  Widget _item(BuildContext context, KdsTicketItem item, bool border) {
    final p = context.palette;
    final done = item.done;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(border: border ? Border(top: BorderSide(color: p.line)) : null),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${item.quantity}×',
            style: AppType.body(size: 14, weight: FontWeight.w800, color: done ? p.muted : p.ink2)),
        const SizedBox(width: 9),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(
              item.variantName != null && item.variantName!.isNotEmpty ? '${item.productName} (${item.variantName})' : item.productName,
              style: AppType.body(size: 14.5, weight: FontWeight.w700, color: done ? p.muted : p.ink)
                  .copyWith(decoration: done ? TextDecoration.lineThrough : null),
            ),
            if (item.mods.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(item.mods, style: AppType.body(size: 12, weight: FontWeight.w500, color: p.ink2)),
            ],
          ]),
        ),
      ]),
    );
  }
}
