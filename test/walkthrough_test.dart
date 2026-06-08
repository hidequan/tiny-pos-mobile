import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiny_pos_mobile/main.dart';
import 'package:tiny_pos_mobile/state/app_state.dart';

/// Walks every role / tab / sheet and asserts NO exception (crash, RenderFlex
/// overflow, null deref, bad state) is thrown while building or interacting.
/// Uses pump() with fixed durations — never pumpAndSettle() — because the app
/// has perpetual animations (KDS 1s timer, pulsing badges) that never settle.
void main() {
  setUpAll(() {
    // Tests run offline; don't let google_fonts attempt network fetches.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> boot(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(430, 932)); // a phone viewport
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(const TinyPosApp());
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  // Settle a couple of frames (transition + content) without waiting forever.
  Future<void> beat(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    await t.pump(const Duration(milliseconds: 350));
  }

  // Tap the first widget matching [finder] if present; scroll into view first.
  Future<bool> tap(WidgetTester t, Finder finder) async {
    if (finder.evaluate().isEmpty) return false;
    final one = finder.first;
    try {
      await t.ensureVisible(one);
    } catch (_) {/* not in a scrollable — fine */}
    await t.tap(one, warnIfMissed: false);
    await beat(t);
    return true;
  }

  Finder txt(String s) => find.text(s);

  // Fail the test (with a clear label) if any exception — crash, RenderFlex
  // overflow, null deref, bad state — was thrown during the preceding step.
  void noCrash(WidgetTester t, String where) {
    final ex = t.takeException();
    expect(ex, isNull, reason: 'Exception while $where: $ex');
  }

  testWidgets('Login screen renders', (t) async {
    await boot(t);
    expect(txt('Tiny POS'), findsOneWidget);
    expect(txt('Thu ngân'), findsOneWidget);
    expect(txt('KDS / Bar'), findsOneWidget);
    expect(txt('Quản trị'), findsOneWidget);
    noCrash(t, 'login render');
  });

  testWidgets('Cashier: all tabs + product/cart/payment sheets', (t) async {
    await boot(t);
    await tap(t, txt('Thu ngân'));
    noCrash(t, 'enter cashier / sell');

    // product with options -> sheet
    await tap(t, txt('Cà phê sữa đá'));
    noCrash(t, 'open product options sheet');
    // tap some options
    await tap(t, txt('L'));
    await tap(t, txt('50%'));
    await tap(t, txt('Trân châu'));
    noCrash(t, 'select options');
    // add to cart (button label starts with "Thêm ·")
    await tap(t, find.textContaining('Thêm ·'));
    noCrash(t, 'confirm add to cart');

    // add a no-option product directly
    await tap(t, txt('Espresso'));
    noCrash(t, 'add simple product');

    // open cart via the cart bar ("Xem đơn")
    await tap(t, txt('Xem đơn'));
    noCrash(t, 'open cart sheet');
    // apply promo + change order type
    await tap(t, txt('Khuyến mãi'));
    noCrash(t, 'toggle promo');
    // go to payment
    await tap(t, find.textContaining('Thanh toán ·'));
    noCrash(t, 'open payment sheet');
    // try each payment method
    await tap(t, txt('Chuyển khoản / QR'));
    noCrash(t, 'payment QR');
    await tap(t, txt('Thẻ ngân hàng'));
    noCrash(t, 'payment card');
    await tap(t, txt('Ví MoMo'));
    noCrash(t, 'payment momo');
    await tap(t, txt('Tiền mặt'));
    // pick a quick cash amount then complete
    await tap(t, txt('500.000đ'));
    noCrash(t, 'cash received');
    await tap(t, find.textContaining('Hoàn tất'));
    noCrash(t, 'complete order / success sheet');
    await tap(t, txt('Đơn mới'));
    noCrash(t, 'after pay');

    // other cashier tabs
    await tap(t, txt('Đơn hàng'));
    noCrash(t, 'orders tab');
    await tap(t, txt('Sơ đồ bàn'));
    noCrash(t, 'tables tab');
    // tap a busy table -> sheet
    await tap(t, txt('A1'));
    noCrash(t, 'table detail sheet');
    await tap(t, find.byIcon(Icons.close_rounded));
    await tap(t, txt('Ca làm'));
    noCrash(t, 'shift tab');
    await tap(t, find.textContaining('ca'));
    noCrash(t, 'toggle shift');
  });

  testWidgets('v0.1.1: product search filters the grid', (t) async {
    await boot(t);
    await tap(t, txt('Thu ngân'));
    await t.enterText(find.byType(TextField).first, 'Latte');
    await beat(t);
    expect(find.text('Matcha Latte'), findsOneWidget);
    expect(find.text('Espresso'), findsNothing); // filtered out
    noCrash(t, 'product search filter');
  });

  testWidgets('KDS: queue interactions + done + stats', (t) async {
    await boot(t);
    await tap(t, txt('KDS / Bar'));
    noCrash(t, 'enter KDS queue');
    // toggle a ticket item done
    await tap(t, txt('Bạc xỉu'));
    noCrash(t, 'toggle kds item');
    // filter chips
    await tap(t, txt('Bếp / bánh'));
    await tap(t, txt('Tất cả'));
    noCrash(t, 'kds filters');
    // bump a ticket
    await tap(t, find.textContaining('Xong tất cả'));
    noCrash(t, 'bump ticket');
    // tabs
    await tap(t, txt('Đã xong'));
    noCrash(t, 'kds done tab');
    await tap(t, txt('Thống kê'));
    noCrash(t, 'kds stats tab');
  });

  testWidgets('v0.1.2: add-staff form appends a member', (t) async {
    await boot(t);
    await tap(t, txt('Quản trị'));
    await tap(t, txt('Thêm'));
    await tap(t, txt('Nhân viên & phân quyền'));
    await tap(t, txt('+ Thêm'));
    noCrash(t, 'open add-staff form');
    await t.enterText(find.byType(TextField).first, 'Nguyễn Test');
    await tap(t, txt('Lưu nhân viên'));
    noCrash(t, 'submit add-staff');
    expect(find.text('Nguyễn Test'), findsOneWidget);
  });

  testWidgets('v0.1.2: state persists cart + theme across instances', (t) async {
    SharedPreferences.setMockInitialValues({});
    final s1 = AppState();
    await s1.load();
    s1.toggleDarkMode();
    s1.addSimple(s1.products.firstWhere((p) => p.id == 'p4')); // Espresso (no options)
    expect(s1.cartCount, 1);

    final s2 = AppState();
    await s2.load();
    expect(s2.userDark, isTrue);
    expect(s2.cartCount, 1);
  });

  testWidgets('Admin: all tabs + sub-pages + sheets', (t) async {
    await boot(t);
    await tap(t, txt('Quản trị'));
    noCrash(t, 'enter admin home');

    await tap(t, txt('Thực đơn'));
    noCrash(t, 'admin menu');
    // open edit-product sheet
    await tap(t, txt('Cà phê sữa đá'));
    noCrash(t, 'edit product sheet');
    await tap(t, find.byIcon(Icons.close_rounded));
    // add product sheet
    await tap(t, find.byIcon(Icons.add_rounded));
    noCrash(t, 'add product sheet');
    await tap(t, find.byIcon(Icons.close_rounded));

    await tap(t, txt('Kho'));
    noCrash(t, 'admin inventory (stock)');
    await tap(t, txt('Định lượng (BOM)'));
    noCrash(t, 'admin inventory (BOM)');

    await tap(t, txt('Báo cáo'));
    noCrash(t, 'admin reports');
    await tap(t, txt('Hôm nay'));
    noCrash(t, 'reports range');

    await tap(t, txt('Thêm'));
    noCrash(t, 'admin more');
    // sub-pages
    await tap(t, txt('Nhân viên & phân quyền'));
    noCrash(t, 'staff/RBAC sub-page');
    await tap(t, find.byIcon(Icons.chevron_left_rounded));
    await tap(t, txt('Khuyến mãi'));
    noCrash(t, 'promos sub-page');
    await tap(t, find.byIcon(Icons.chevron_left_rounded));
    await tap(t, txt('Chi nhánh'));
    noCrash(t, 'branches sub-page');
    await tap(t, find.byIcon(Icons.chevron_left_rounded));
    await tap(t, txt('Ca làm việc'));
    noCrash(t, 'shift-admin sub-page');
    await tap(t, find.byIcon(Icons.chevron_left_rounded));
    // settings sheet
    await tap(t, txt('Cài đặt hệ thống'));
    noCrash(t, 'settings sheet');
  });
}
