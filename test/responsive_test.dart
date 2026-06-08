import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiny_pos_mobile/main.dart';

/// Runs a condensed full walkthrough at several viewport sizes and asserts NO
/// exception (overflow / crash) at any of them. The 320-wide case is the real
/// stress test (the phone frame fills the width when it's below the 480 cap).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final sizes = <String, Size>{
    'tiny-320x568': const Size(320, 568), // iPhone SE (1st gen) — smallest
    'small-360x640': const Size(360, 640),
    'cap-480x900': const Size(480, 900), // exactly the max frame width
    'tablet-768x1024': const Size(768, 1024), // frame centered at 480
    'wide-1280x800': const Size(1280, 800), // desktop — frame centered at 480
  };

  Future<void> beat(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    await t.pump(const Duration(milliseconds: 350));
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) return;
    try {
      await t.ensureVisible(f.first);
    } catch (_) {}
    await t.tap(f.first, warnIfMissed: false);
    await beat(t);
  }

  void noCrash(WidgetTester t, String where, String size) {
    final ex = t.takeException();
    expect(ex, isNull, reason: '[$size] exception while $where: $ex');
  }

  Finder txt(String s) => find.text(s);

  for (final entry in sizes.entries) {
    final label = entry.key;
    final size = entry.value;

    testWidgets('Responsive [$label]: all roles + key sheets', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(const TinyPosApp());
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      noCrash(t, 'login', label);

      // ---- Cashier ----
      await tap(t, txt('Thu ngân'));
      noCrash(t, 'sell', label);
      await tap(t, txt('Cà phê sữa đá')); // product options sheet
      noCrash(t, 'product sheet', label);
      await tap(t, find.textContaining('Thêm ·'));
      await tap(t, txt('Xem đơn')); // cart sheet
      noCrash(t, 'cart sheet', label);
      await tap(t, find.textContaining('Thanh toán ·')); // payment
      noCrash(t, 'payment sheet', label);
      await tap(t, find.byIcon(Icons.close_rounded));
      await tap(t, txt('Đơn hàng'));
      noCrash(t, 'orders', label);
      await tap(t, txt('Sơ đồ bàn'));
      noCrash(t, 'tables', label);
      await tap(t, txt('Ca làm'));
      noCrash(t, 'shift', label);

      // ---- KDS ----
      await t.pumpWidget(const TinyPosApp()); // fresh -> login
      await t.pump(const Duration(milliseconds: 400));
      await tap(t, txt('KDS / Bar'));
      noCrash(t, 'kds queue', label);
      await tap(t, txt('Thống kê'));
      noCrash(t, 'kds stats', label);

      // ---- Admin ----
      await t.pumpWidget(const TinyPosApp());
      await t.pump(const Duration(milliseconds: 400));
      await tap(t, txt('Quản trị'));
      noCrash(t, 'admin home', label);
      await tap(t, txt('Thực đơn'));
      noCrash(t, 'admin menu', label);
      await tap(t, txt('Kho'));
      noCrash(t, 'inventory stock', label);
      await tap(t, txt('Định lượng (BOM)'));
      noCrash(t, 'inventory bom', label);
      await tap(t, txt('Báo cáo'));
      noCrash(t, 'reports', label);
      await tap(t, txt('Thêm'));
      noCrash(t, 'more', label);
      await tap(t, txt('Nhân viên & phân quyền'));
      noCrash(t, 'staff/RBAC', label);
    });
  }
}
