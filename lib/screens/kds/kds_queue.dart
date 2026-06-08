import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../data/models.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../theme/app_icons.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'kds_profile.dart';

class KdsQueueScreen extends StatelessWidget {
  const KdsQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    final f = state.kdsFilter;

    // Filter items per ticket by station, keep tickets that still have items.
    final tickets = state.kds
        .map((t) => (
              ticket: t,
              items: f == 'all' ? t.items : t.items.where((i) => i.st == f).toList(),
            ))
        .where((e) => e.items.isNotEmpty)
        .toList();

    final pending = state.kds.length;
    final waiting = state.kds.isEmpty ? 0 : (state.kds.fold(0, (a, t) => a + t.ago) / state.kds.length).round();

    return Column(children: [
      TopBar(
        title: 'Pha chế · Bar',
        subtitle: Text('Chi nhánh Cầu Giấy · real-time',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [
          IconBtn('bell', dot: true, onTap: () => context.shell.toast('Có đơn mới cần pha', 'bell')),
          Avatar('QD', colors: const [Color(0xFF3F8F5B), Color(0xFF6FB07A)], onTap: () => openKdsProfile(context)),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(children: [
          Expanded(child: _statBox(context, '$pending', 'Đơn đang chờ', p.terracotta)),
          const SizedBox(width: 10),
          Expanded(child: _statBox(context, fmtAgo(waiting), 'Thời gian chờ TB', p.ink)),
          const SizedBox(width: 10),
          Expanded(child: _statBox(context, '${state.kdsDone.length}', 'Xong gần đây', p.greenD)),
        ]),
      ),
      ChipsRow(children: [
        for (final c in const [
          ['all', 'Tất cả', '✨'],
          ['bar', 'Quầy pha chế', '🧋'],
          ['kitchen', 'Bếp / bánh', '🥐'],
        ])
          PillChip(c[1], emoji: c[2], on: f == c[0], onTap: () => state.setKdsFilter(c[0])),
      ]),
      Expanded(
        child: tickets.isEmpty
            ? const EmptyState(emoji: '✅', title: 'Không còn đơn nào', sub: 'Tất cả đã pha xong. Nghỉ tay chút nhé!')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                itemCount: tickets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _TicketCard(ticket: tickets[i].ticket, visibleItems: tickets[i].items),
              ),
      ),
    ]);
  }

  Widget _statBox(BuildContext context, String value, String label, Color color) {
    final p = context.palette;
    return CardBox(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: AppType.display(size: 21, height: 1, color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppType.body(size: 11, weight: FontWeight.w700, color: p.ink2)),
      ]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final KdsTicket ticket;
  final List<KdsItem> visibleItems;
  const _TicketCard({required this.ticket, required this.visibleItems});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    // Rebuild only this card (timer text + accent colours) on each 1s tick,
    // instead of rebuilding the whole KDS screen.
    return ValueListenableBuilder<int>(
      valueListenable: state.kdsTick,
      builder: (context, _, _) => _card(context, state),
    );
  }

  Widget _card(BuildContext context, AppState state) {
    final p = context.palette;
    final accent = ticket.ago >= 360 ? p.red : (ticket.ago >= 180 ? p.amber : p.green);
    final timerColor = ticket.ago >= 360 ? p.red : (ticket.ago >= 180 ? p.amber : p.greenD);
    final allOk = visibleItems.every((i) => i.ok);

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
          // left accent bar via a Row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // header
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line2))),
                        child: Row(children: [
                          // Left group (type badge + code + NEW) scales down to
                          // fit so the row never overflows on narrow cards.
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                AppBadge(
                                  ticket.type == 'dinein' ? '🪑 Bàn ${ticket.table ?? '—'}' : '🥡 Mang đi',
                                  color: ticket.type == 'dinein' ? BadgeColor.blue : BadgeColor.gray,
                                ),
                                const SizedBox(width: 8),
                                Text(ticket.code, style: AppType.display(size: 17, weight: FontWeight.w700, color: p.ink)),
                                if (ticket.isNew) ...[
                                  const SizedBox(width: 6),
                                  const AppBadge('MỚI', color: BadgeColor.red, pulse: true),
                                ],
                              ]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(fmtAgo(ticket.ago), style: AppType.body(size: 13, weight: FontWeight.w800, color: timerColor)),
                          const SizedBox(width: 5),
                          Icon(AppIcons.get('clock'), size: 14, color: timerColor),
                        ]),
                      ),
                      // items
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                        child: Column(
                          children: [
                            for (var k = 0; k < visibleItems.length; k++)
                              _item(context, state, visibleItems[k], k > 0),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // footer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(children: [
              Expanded(
                child: AppButton('Tem', icon: 'print', variant: BtnVariant.ghost,
                    onTap: () => context.shell.toast('In tem món ${ticket.code}', 'print')),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: AppButton(
                  allOk ? 'Hoàn thành' : 'Xong tất cả',
                  icon: 'check',
                  variant: allOk ? BtnVariant.pri : BtnVariant.dark,
                  onTap: () {
                    state.bumpTicket(ticket.code);
                    context.shell.toast('Đơn ${ticket.code} đã hoàn thành', 'check');
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, AppState state, KdsItem item, bool border) {
    final p = context.palette;
    final gi = ticket.items.indexOf(item);
    return GestureDetector(
      onTap: () => state.toggleKdsItem(ticket.code, gi),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: border ? Border(top: BorderSide(color: p.line)) : null),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            height: 26,
            decoration: BoxDecoration(color: item.ok ? p.green : p.espresso, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text('${item.q}', style: AppType.body(size: 13, weight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(item.n,
                  style: AppType.body(size: 14.5, weight: FontWeight.w700, color: item.ok ? p.muted : p.ink).copyWith(
                      decoration: item.ok ? TextDecoration.lineThrough : null)),
              if (item.mod.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(item.mod, style: AppType.body(size: 12, weight: FontWeight.w500, color: p.ink2)),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AppBadge(item.st == 'bar' ? 'Bar' : 'Bếp', color: item.st == 'bar' ? BadgeColor.blue : BadgeColor.amber),
          ),
          const SizedBox(width: 8),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: item.ok ? p.green : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: item.ok ? p.green : p.line2, width: 2),
            ),
            child: item.ok ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }
}
