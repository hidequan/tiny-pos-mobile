import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Runs a condensed walkthrough at several viewport sizes (signed in per role)
/// and asserts NO exception (overflow / crash) at any of them. The 320-wide
/// case is the real stress test (the phone frame fills the width below 480).
void main() {
  final sizes = <String, Size>{
    'tiny-320x568': const Size(320, 568),
    'small-360x640': const Size(360, 640),
    'cap-480x900': const Size(480, 900),
    'tablet-768x1024': const Size(768, 1024),
    'wide-1280x800': const Size(1280, 800),
  };

  Finder txt(String s) => find.text(s);
  Future<void> tap(WidgetTester t, Finder f) => tapIfPresent(t, f);

  for (final entry in sizes.entries) {
    final label = entry.key;
    final size = entry.value;

    void noCrash(WidgetTester t, String where) {
      final ex = t.takeException();
      expect(ex, isNull, reason: '[$label] exception while $where: $ex');
    }

    testWidgets('Responsive [$label]: all roles + key sheets', (t) async {
      // ---- Cashier ----
      await pumpSignedIn(t, staffRole: 'CASHIER', size: size);
      noCrash(t, 'sell');
      await tap(t, txt('Cà phê sữa đá')); // direct add (real menu, no modifiers)
      noCrash(t, 'add product');
      await tap(t, txt('Xem đơn'));
      noCrash(t, 'cart sheet');
      await tap(t, find.textContaining('Thanh toán ·'));
      noCrash(t, 'payment sheet');
      await tap(t, find.byIcon(Icons.close_rounded));
      await tap(t, txt('Sơ đồ bàn'));
      noCrash(t, 'tables');
      await tap(t, txt('Ca làm'));
      noCrash(t, 'shift');

      // ---- KDS ----
      await pumpSignedIn(t, staffRole: 'BARISTA', size: size);
      noCrash(t, 'kds queue');
      await tap(t, txt('Thống kê'));
      noCrash(t, 'kds stats');

      // ---- Admin ----
      await pumpSignedIn(t, staffRole: 'ADMIN', size: size);
      noCrash(t, 'admin home');
      await tap(t, txt('Kho'));
      noCrash(t, 'inventory');
      await tap(t, txt('Báo cáo'));
      noCrash(t, 'reports');
      await tap(t, txt('Thêm'));
      await tap(t, txt('Nhân viên & phân quyền'));
      noCrash(t, 'staff/RBAC');
    });
  }
}
