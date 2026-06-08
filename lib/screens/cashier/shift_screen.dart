import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../data/seed.dart';
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'cashier_sheets.dart';

class ShiftScreen extends StatelessWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = context.palette;
    const cashStart = 1000000;
    final cashSales = state.orders.where((o) => o.status == 'done' && o.pay == 'cash').fold(0, (a, o) => a + o.total);
    final totalSales = state.orders.where((o) => o.status == 'done').fold(0, (a, o) => a + o.total);
    final done = state.orders.where((o) => o.status == 'done').length;

    return Column(children: [
      TopBar(
        title: 'Ca làm việc',
        subtitle: Text('Trần Thị Bình · Thu ngân', style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [Avatar('TB', onTap: () => openProfile(context))],
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            HeroCard(
              label: state.shiftOpen ? 'Ca chiều · đang mở' : 'Chưa mở ca',
              value: state.shiftOpen ? '13:00 → 21:00' : '--:--',
              footer: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.access_time_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(state.shiftOpen ? 'Đã làm 4h 12p' : 'Bấm mở ca để bắt đầu',
                    style: AppType.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: _stat(context, 'cash', p.greenBg, p.greenD, kShort(totalSales), 'Tổng doanh thu')),
                const SizedBox(width: 10),
                Expanded(child: _stat(context, 'receipt', p.blueBg, p.blue, '$done', 'Số đơn')),
              ]),
            ),
            const SectionHeader('Đối soát tiền mặt'),
            CardBox(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                KvRow('Tiền đầu ca', Text(vnd(cashStart), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink))),
                KvRow('Thu tiền mặt', Text('+${vnd(cashSales)}', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.greenD))),
                KvRow('Chi (nhập hàng...)', Text('−${vnd(0)}', style: AppType.body(size: 14, weight: FontWeight.w800, color: p.red))),
                KvRow(
                  'Tiền trong két',
                  Text(vnd(cashStart + cashSales), style: AppType.display(size: 16, color: p.terracotta)),
                  last: true,
                  size: 16,
                  padding: const EdgeInsets.only(top: 12),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                AppButton('Thu / chi tiền mặt', icon: 'cash', large: true, block: true, variant: BtnVariant.ghost,
                    onTap: () => context.shell.toast('Ghi nhận thu/chi tiền mặt', 'cash')),
                const SizedBox(height: 10),
                AppButton(
                  state.shiftOpen ? 'Đóng ca & đối soát' : 'Mở ca làm việc',
                  icon: state.shiftOpen ? 'logout' : 'clock',
                  large: true,
                  block: true,
                  variant: state.shiftOpen ? BtnVariant.dark : BtnVariant.pri,
                  onTap: () {
                    state.toggleShift();
                    context.shell.toast(state.shiftOpen ? 'Đã mở ca làm việc' : 'Đã đóng ca · đối soát hoàn tất',
                        state.shiftOpen ? 'clock' : 'check');
                  },
                ),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _stat(BuildContext context, String icon, Color bg, Color fg, String value, String label) {
    final p = context.palette;
    return CardBox(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
          child: Icon(_iconData(icon), size: 18, color: fg),
        ),
        const SizedBox(height: 9),
        Text(value, style: AppType.display(size: 22, height: 1, color: p.ink)),
        const SizedBox(height: 4),
        Text(label, style: AppType.body(size: 12, weight: FontWeight.w700, color: p.ink2)),
      ]),
    );
  }

  IconData _iconData(String n) => {
        'cash': Icons.payments_outlined,
        'receipt': Icons.receipt_long_outlined,
      }[n]!;
}
