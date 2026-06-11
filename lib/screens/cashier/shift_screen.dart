import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/session.dart';
import '../../state/shift_controller.dart';
import '../../models/shift.dart';
import '../../data/seed.dart' show vnd, kShort;
import '../../theme/palette.dart';
import '../../theme/typography.dart';
import '../../widgets/common.dart';
import '../../widgets/shell.dart';
import 'cashier_sheets.dart';

const _denoms = [500000, 200000, 100000, 50000, 20000, 10000, 5000, 2000, 1000];

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});
  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  @override
  void initState() {
    super.initState();
    final c = context.read<ShiftController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!c.loaded) c.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ShiftController>();
    final p = context.palette;
    final user = context.read<SessionState>().user;
    final initials = user?.initials ?? 'TB';

    return Column(children: [
      TopBar(
        title: 'Ca làm việc',
        subtitle: Text('${user?.fullName ?? 'Thu ngân'} · Thu ngân',
            style: AppType.body(size: 12.5, weight: FontWeight.w600, color: p.ink2)),
        actions: [
          IconBtn('history', onTap: () => c.load()),
          Avatar(initials, onTap: () => openProfile(context)),
        ],
      ),
      Expanded(child: _body(context, c)),
    ]);
  }

  Widget _body(BuildContext context, ShiftController c) {
    final p = context.palette;
    if (c.loading && !c.loaded) {
      return Center(child: CircularProgressIndicator(color: p.terracotta));
    }
    if (c.error != null && !c.loaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🕗', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(c.error!, style: AppType.body(size: 13, color: p.muted)),
          const SizedBox(height: 16),
          AppButton('Thử lại', icon: 'history', onTap: () => c.load()),
        ]),
      );
    }
    final s = c.shift;
    if (s == null || !s.isOpen) return _closed(context, c);
    return _open(context, c, s);
  }

  // ---- no open shift ----
  Widget _closed(BuildContext context, ShiftController c) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        HeroCard(
          label: 'Chưa mở ca',
          value: '--:--',
          footer: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.access_time_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text('Mở ca để bắt đầu nhận đơn',
                style: AppType.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppButton('Mở ca làm việc', icon: 'clock', large: true, block: true,
              onTap: () => _openShiftSheet(context, c)),
        ),
      ],
    );
  }

  // ---- open shift ----
  Widget _open(BuildContext context, ShiftController c, Shift s) {
    final p = context.palette;
    final sm = s.summary;
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        HeroCard(
          label: '${s.shiftTypeLabel} · đang mở',
          value: s.shiftCode,
          footer: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.access_time_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(s.openedAt != null ? 'Mở lúc ${_hm(s.openedAt!)}' : 'Đang mở',
                style: AppType.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: _stat(context, Icons.payments_outlined, p.greenBg, p.greenD, kShort(sm.cashSales), 'Bán tiền mặt')),
            const SizedBox(width: 10),
            Expanded(child: _stat(context, Icons.account_balance_wallet_outlined, const Color(0xFFFCE8DF), p.terracotta, kShort(sm.expectedCash), 'Tiền trong két')),
          ]),
        ),
        if (sm.sentToBarUnpaidCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: CardBox(
              color: p.amberBg,
              borderColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                const Text('⚠️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${sm.sentToBarUnpaidCount} đơn gửi bar chưa thu tiền',
                      style: AppType.body(size: 13, weight: FontWeight.w700, color: p.amber)),
                ),
              ]),
            ),
          ),
        const SectionHeader('Đối soát tiền mặt'),
        CardBox(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _kv(context, 'Tiền đầu ca', vnd(sm.openingCash), p.ink),
            _kv(context, 'Bán thu tiền mặt', '+${vnd(sm.cashSales)}', p.greenD),
            if (sm.cashIn != 0) _kv(context, 'Thu thêm', '+${vnd(sm.cashIn)}', p.greenD),
            if (sm.cashOut != 0) _kv(context, 'Chi ra', vnd(sm.cashOut), p.red),
            if (sm.cashRefund != 0) _kv(context, 'Hoàn tiền', vnd(-sm.cashRefund.abs()), p.red),
            KvRow('Dự kiến trong két',
                Text(vnd(sm.expectedCash), style: AppType.display(size: 16, color: p.terracotta)),
                last: true, size: 16, padding: const EdgeInsets.only(top: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: AppButton('Thu thêm', icon: 'plus', large: true, variant: BtnVariant.ghost,
                    onTap: () => _cashSheet(context, c, true)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton('Chi ra', icon: 'cash', large: true, variant: BtnVariant.ghost,
                    onTap: () => _cashSheet(context, c, false)),
              ),
            ]),
            const SizedBox(height: 10),
            AppButton('Đóng ca & đối soát', icon: 'logout', large: true, block: true,
                variant: BtnVariant.dark, onTap: () => _closeSheet(context, c, s)),
          ]),
        ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v, Color color) => KvRow(k,
      Text(v, style: AppType.body(size: 14, weight: FontWeight.w800, color: color)));

  String _hm(DateTime d) {
    final x = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(x.hour)}:${two(x.minute)}';
  }

  Widget _stat(BuildContext context, IconData icon, Color bg, Color fg, String value, String label) {
    final p = context.palette;
    return CardBox(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: fg)),
        const SizedBox(height: 9),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(value, style: AppType.display(size: 22, height: 1, color: p.ink))),
        const SizedBox(height: 4),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppType.body(size: 12, weight: FontWeight.w700, color: p.ink2)),
      ]),
    );
  }

  // ---- open-shift sheet ----
  void _openShiftSheet(BuildContext context, ShiftController c) {
    final cash = TextEditingController(text: '500000');
    bool busy = false;
    context.shell.showSheet((_) => StatefulBuilder(builder: (context, setInner) {
          final p = context.palette;
          return AppSheet(
            title: 'Mở ca làm việc',
            body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 4),
              Text('Tiền mặt đầu ca (quỹ lẻ)', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
              const SizedBox(height: 10),
              _moneyField(context, cash, 'VD: 500000'),
            ]),
            footer: AppButton(busy ? 'Đang mở...' : 'Mở ca', icon: 'check', large: true, block: true, enabled: !busy,
                onTap: () async {
              final n = int.tryParse(cash.text.trim());
              if (n == null || n < 0) {
                context.shell.toast('Nhập số tiền hợp lệ', 'edit');
                return;
              }
              setInner(() => busy = true);
              final branchId = context.read<SessionState>().user?.branchId;
              final err = await c.openShift(openingCash: n, branchId: branchId);
              if (!context.mounted) return;
              if (err == null) {
                context.shell.closeSheet();
                context.shell.toast('Đã mở ca làm việc', 'check');
              } else {
                setInner(() => busy = false);
                context.shell.toast(err, 'edit');
              }
            }),
          );
        }));
  }

  // ---- cash in/out sheet ----
  void _cashSheet(BuildContext context, ShiftController c, bool isIn) {
    final amt = TextEditingController();
    final reason = TextEditingController();
    bool busy = false;
    context.shell.showSheet((_) => StatefulBuilder(builder: (context, setInner) {
          final p = context.palette;
          return AppSheet(
            title: isIn ? 'Thu thêm tiền mặt' : 'Chi tiền mặt',
            body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 4),
              Text('Số tiền', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
              const SizedBox(height: 10),
              _moneyField(context, amt, 'VD: 100000'),
              const SizedBox(height: 12),
              Text('Lý do', style: AppType.body(size: 13, weight: FontWeight.w800, color: p.ink2)),
              const SizedBox(height: 10),
              TextField(
                controller: reason,
                style: AppType.body(size: 14.5, weight: FontWeight.w600, color: p.ink),
                decoration: _deco(context, isIn ? 'VD: bổ sung quỹ' : 'VD: nhập nguyên liệu'),
              ),
            ]),
            footer: AppButton(busy ? 'Đang lưu...' : (isIn ? 'Xác nhận thu' : 'Xác nhận chi'),
                icon: 'check', large: true, block: true, enabled: !busy, onTap: () async {
              final n = int.tryParse(amt.text.trim());
              if (n == null || n <= 0) {
                context.shell.toast('Nhập số tiền hợp lệ', 'edit');
                return;
              }
              setInner(() => busy = true);
              final err = await c.cashMovement(isIn: isIn, amount: n, reason: reason.text.trim().isEmpty ? null : reason.text.trim());
              if (!context.mounted) return;
              if (err == null) {
                context.shell.closeSheet();
                context.shell.toast(isIn ? 'Đã ghi nhận thu tiền' : 'Đã ghi nhận chi tiền', 'check');
              } else {
                setInner(() => busy = false);
                context.shell.toast(err, 'edit');
              }
            }),
          );
        }));
  }

  // ---- close-shift sheet (denomination count) ----
  void _closeSheet(BuildContext context, ShiftController c, Shift s) {
    final counts = {for (final d in _denoms) d: TextEditingController()};
    bool busy = false;
    context.shell.showSheet((_) => StatefulBuilder(builder: (context, setInner) {
          final p = context.palette;
          var counted = 0;
          for (final d in _denoms) {
            counted += d * (int.tryParse(counts[d]!.text.trim()) ?? 0);
          }
          final expected = s.summary.expectedCash;
          final diff = counted - expected;
          return AppSheet(
            title: 'Đóng ca · đếm tiền',
            headerExtra: [AppBadge('Dự kiến ${kShort(expected)}', color: BadgeColor.gray)],
            body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 2),
              for (final d in _denoms) _denomRow(context, d, counts[d]!, () => setInner(() {})),
              const SizedBox(height: 12),
              CardBox(
                radius: 14,
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  KvRow('Tổng đếm được', Text(vnd(counted), style: AppType.body(size: 15, weight: FontWeight.w800, color: p.ink))),
                  KvRow('Dự kiến', Text(vnd(expected), style: AppType.body(size: 14, weight: FontWeight.w700, color: p.ink2))),
                  KvRow('Chênh lệch',
                      Text('${diff > 0 ? '+' : ''}${vnd(diff)}',
                          style: AppType.display(size: 16, color: diff == 0 ? p.greenD : (diff > 0 ? p.greenD : p.red))),
                      last: true, size: 16, padding: const EdgeInsets.only(top: 10)),
                ]),
              ),
            ]),
            footer: AppButton(busy ? 'Đang đóng...' : 'Xác nhận đóng ca', icon: 'check', large: true, block: true,
                enabled: !busy, onTap: () async {
              final denoms = {for (final d in _denoms) d: int.tryParse(counts[d]!.text.trim()) ?? 0};
              setInner(() => busy = true);
              final (err, closed) = await c.closeShift(denominations: denoms);
              if (!context.mounted) return;
              if (err == null) {
                context.shell.closeSheet();
                final df = closed?.difference ?? diff;
                context.shell.toast(
                    df == 0 ? 'Đã đóng ca · khớp quỹ' : 'Đã đóng ca · lệch ${vnd(df)}',
                    df == 0 ? 'check' : 'edit');
              } else {
                setInner(() => busy = false);
                context.shell.toast(err, 'edit');
              }
            }),
          );
        }));
  }

  Widget _denomRow(BuildContext context, int denom, TextEditingController ctl, VoidCallback onChanged) {
    final p = context.palette;
    final n = int.tryParse(ctl.text.trim()) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(
          width: 84,
          child: Text(vnd(denom), style: AppType.body(size: 14, weight: FontWeight.w800, color: p.ink)),
        ),
        const Text('×', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: TextField(
            controller: ctl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onChanged(),
            textAlign: TextAlign.center,
            style: AppType.body(size: 15, weight: FontWeight.w800, color: p.ink),
            decoration: InputDecoration(
              hintText: '0',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 9),
              filled: true,
              fillColor: p.paper,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: p.line2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: p.caramel)),
            ),
          ),
        ),
        const Spacer(),
        Text(vnd(denom * n), style: AppType.body(size: 13.5, weight: FontWeight.w700, color: n > 0 ? p.ink2 : p.faint)),
      ]),
    );
  }

  Widget _moneyField(BuildContext context, TextEditingController ctl, String hint) => TextField(
        controller: ctl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppType.body(size: 16, weight: FontWeight.w800, color: context.palette.ink),
        decoration: _deco(context, hint),
      );

  InputDecoration _deco(BuildContext context, String hint) {
    final p = context.palette;
    return InputDecoration(
      hintText: hint,
      hintStyle: AppType.body(size: 15, weight: FontWeight.w500, color: p.faint),
      filled: true,
      fillColor: p.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.line2, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.caramel, width: 1.5)),
    );
  }
}
