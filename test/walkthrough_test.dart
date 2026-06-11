import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiny_pos_mobile/main.dart';
import 'package:tiny_pos_mobile/state/app_state.dart';

import 'helpers.dart';

/// Walks every role / tab / sheet (signed in via injected session) and asserts
/// NO exception (crash, RenderFlex overflow, null deref) is thrown. Uses pump()
/// with fixed durations — never pumpAndSettle() — because the app has perpetual
/// animations (KDS 1s timer, pulsing badges) that never settle.
void main() {
  Finder txt(String s) => find.text(s);

  void noCrash(WidgetTester t, String where) {
    final ex = t.takeException();
    expect(ex, isNull, reason: 'Exception while $where: $ex');
  }

  Future<void> tap(WidgetTester t, Finder f) => tapIfPresent(t, f);

  testWidgets('Auth login screen renders when signed out', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(const TinyPosApp());
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(txt('Đăng nhập'), findsWidgets);
    expect(find.byType(TextField), findsWidgets); // username + password
    noCrash(t, 'auth login render');
  });

  testWidgets('Cashier: all tabs + product/cart/payment sheets', (t) async {
    await pumpSignedIn(t, staffRole: 'CASHIER');
    noCrash(t, 'enter cashier / sell');

    // Real menu products (no modifiers) add directly to the cart.
    await tap(t, txt('Cà phê sữa đá'));
    noCrash(t, 'add product to cart');
    await tap(t, txt('Espresso'));
    noCrash(t, 'add another product');

    await tap(t, txt('Xem đơn'));
    noCrash(t, 'open cart sheet');
    await tap(t, txt('Khuyến mãi'));
    noCrash(t, 'toggle promo');
    await tap(t, find.textContaining('Thanh toán ·'));
    noCrash(t, 'open payment sheet');
    await tap(t, txt('Chuyển khoản / QR'));
    await tap(t, txt('Thẻ ngân hàng'));
    await tap(t, txt('Ví MoMo'));
    await tap(t, txt('Tiền mặt'));
    noCrash(t, 'payment methods');
    await tap(t, txt('500.000đ'));
    await tap(t, find.textContaining('Hoàn tất'));
    noCrash(t, 'complete order / success sheet');
    await tap(t, txt('Đơn mới'));
    noCrash(t, 'after pay');

    await tap(t, txt('Đơn hàng'));
    noCrash(t, 'orders tab');
    await tap(t, txt('Sơ đồ bàn'));
    noCrash(t, 'tables tab');
    await tap(t, txt('A1'));
    noCrash(t, 'table detail sheet');
    await tap(t, find.byIcon(Icons.close_rounded));
    await tap(t, txt('Ca làm'));
    noCrash(t, 'shift tab');
    await tap(t, find.textContaining('ca'));
    noCrash(t, 'toggle shift');
  });

  testWidgets('v0.1.1: product search filters the grid', (t) async {
    await pumpSignedIn(t, staffRole: 'CASHIER');
    await t.enterText(find.byType(TextField).first, 'Latte');
    await beat(t);
    expect(find.text('Matcha Latte'), findsOneWidget);
    expect(find.text('Espresso'), findsNothing);
    noCrash(t, 'product search filter');
  });

  testWidgets('KDS: queue interactions + done + stats', (t) async {
    await pumpSignedIn(t, staffRole: 'BARISTA');
    noCrash(t, 'enter KDS queue');
    await tap(t, txt('Bạc xỉu'));
    noCrash(t, 'toggle kds item');
    await tap(t, txt('Bếp / bánh'));
    await tap(t, txt('Tất cả'));
    noCrash(t, 'kds filters');
    await tap(t, find.textContaining('Xong tất cả'));
    noCrash(t, 'bump ticket');
    await tap(t, txt('Đã xong'));
    noCrash(t, 'kds done tab');
    await tap(t, txt('Thống kê'));
    noCrash(t, 'kds stats tab');
  });

  testWidgets('Scan: profile sheets (cashier) + search clear', (t) async {
    await pumpSignedIn(t, staffRole: 'CASHIER');
    await tap(t, txt('TB'));
    noCrash(t, 'cashier profile sheet');
    await tap(t, find.byIcon(Icons.close_rounded));
    await t.enterText(find.byType(TextField).first, 'zzzzz');
    await beat(t);
    expect(find.text('Không có món'), findsOneWidget);
    await tap(t, find.byIcon(Icons.close_rounded));
    expect(find.text('Cà phê sữa đá'), findsWidgets);
    noCrash(t, 'search clear');
  });

  testWidgets('Scan: KDS profile sheet', (t) async {
    await pumpSignedIn(t, staffRole: 'BARISTA');
    await tap(t, txt('QD'));
    noCrash(t, 'kds profile sheet');
  });

  testWidgets('Scan: admin profile + branch pick + add-promo + add-branch', (t) async {
    await pumpSignedIn(t, staffRole: 'ADMIN');
    await tap(t, txt('AN'));
    noCrash(t, 'admin profile sheet');
    await tap(t, find.byIcon(Icons.close_rounded));
    await tap(t, txt('Cầu Giấy ▾'));
    noCrash(t, 'branch pick sheet');
    await tap(t, find.byIcon(Icons.close_rounded));
    await tap(t, txt('Thêm'));
    await tap(t, txt('Khuyến mãi'));
    await tap(t, txt('+ Tạo'));
    noCrash(t, 'add-promo form');
    await t.enterText(find.byType(TextField).first, 'KM Test');
    await tap(t, txt('Lưu khuyến mãi'));
    noCrash(t, 'submit add-promo');
    expect(find.text('KM Test'), findsOneWidget);
    await tap(t, find.byIcon(Icons.chevron_left_rounded));
    await tap(t, txt('Chi nhánh'));
    await tap(t, txt('Thêm chi nhánh'));
    noCrash(t, 'add-branch form');
    await t.enterText(find.byType(TextField).first, 'CN Test');
    await tap(t, txt('Lưu chi nhánh'));
    noCrash(t, 'submit add-branch');
    expect(find.text('CN Test'), findsOneWidget);
  });

  testWidgets('v0.1.2: add-staff form appends a member', (t) async {
    await pumpSignedIn(t, staffRole: 'ADMIN');
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
    await pumpSignedIn(t, staffRole: 'ADMIN');
    noCrash(t, 'enter admin home');
    await tap(t, txt('Thực đơn'));
    noCrash(t, 'admin menu');
    await tap(t, txt('Cà phê sữa đá'));
    noCrash(t, 'edit product sheet');
    await tap(t, find.byIcon(Icons.close_rounded));
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
    await tap(t, txt('Nhân viên & phân quyền'));
    noCrash(t, 'staff/RBAC sub-page');
  });
}
