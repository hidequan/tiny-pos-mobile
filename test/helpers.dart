import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiny_pos_mobile/main.dart';
import 'package:tiny_pos_mobile/state/session.dart';
import 'package:tiny_pos_mobile/state/menu_controller.dart';
import 'package:tiny_pos_mobile/api/bill_repository.dart';
import 'package:tiny_pos_mobile/api/kds_repository.dart';
import 'package:tiny_pos_mobile/state/bills_controller.dart';
import 'package:tiny_pos_mobile/state/kds_controller.dart';
import 'package:tiny_pos_mobile/models/auth_user.dart';
import 'package:tiny_pos_mobile/models/menu.dart';
import 'package:tiny_pos_mobile/models/bill.dart';
import 'package:tiny_pos_mobile/models/kds.dart';

/// A no-op KdsRepository returning canned tickets for widget tests.
class FakeKdsRepository extends KdsRepository {
  FakeKdsRepository(super.api);
  @override
  Future<List<KdsTicket>> tickets() async => _fakeTickets();
  @override
  Future<KdsStats> stats() async => KdsStats(1, 1, 3);
  @override
  Future<void> readyItem(String itemId) async {}
  @override
  Future<void> completeTicket(String id) async {}
}

List<KdsTicket> _fakeTickets() => [
      KdsTicket(
        id: 't1', ticketCode: 'T260611-0001', status: 'WAITING', tableLabel: null,
        serviceType: 'TAKE_AWAY', sentAt: null,
        items: [
          KdsTicketItem(id: 'i1', status: 'WAITING', productName: 'Cà phê sữa đá', variantName: null, quantity: 2, mods: 'M · 70% đường'),
          KdsTicketItem(id: 'i2', status: 'READY', productName: 'Bạc xỉu', variantName: null, quantity: 1, mods: ''),
        ],
      ),
    ];

/// A BillRepository that returns canned bills (no network) for widget tests.
class FakeBillRepository extends BillRepository {
  FakeBillRepository(super.api);
  Bill _bill(String status) => Bill(
        id: 'b-test', billCode: 'B-TEST-001', status: status, serviceType: 'TAKE_AWAY',
        subtotal: 29000, discountTotal: 0, grandTotal: 29000,
        paidTotal: status == 'PAID' ? 29000 : 0, note: null, paidAt: null, items: const [],
      );
  @override
  Future<Bill> createBill({
    required String serviceType,
    List<BillItemInput> items = const [],
    String? tableSessionId,
    String? customerId,
    String? note,
    String? idempotencyKey,
  }) async => _bill('DRAFT');
  @override
  Future<Bill> payCash(String billId, {required int received, int? amount}) async => _bill('PAID');
}

/// A fake authenticated user so widget tests bypass the real network login.
AuthUser fakeUser(String staffRole) => AuthUser(
      id: 'test-id',
      username: 'tester',
      fullName: 'Nhân Viên Test',
      staffRole: staffRole,
      branchId: 'test-branch',
      roles: [staffRole],
      permissions: const [
        'bill.create', 'bill.pay', 'menu.view', 'table.open', 'voucher.apply',
        'shift.open', 'shift.close', 'kds.view', 'report.view', 'product.manage',
      ],
    );

MenuProduct _p(String id, String cat, String name, int price) => MenuProduct(
      id: id,
      categoryId: cat,
      name: name,
      description: null,
      basePrice: price,
      available: true,
      hasModifiers: false,
      isFeatured: false,
      tag: null,
      imageRaw: null,
      variants: [ProductVariant('$id-v', null, null, null, price, true)],
      toppingIds: const [],
    );

/// A small offline menu so cashier widget tests don't hit the network.
Menu fakeMenu() => Menu(
      [MenuCategory('cf', 'Cà phê', 0), MenuCategory('tea', 'Trà', 1)],
      const [],
      const [],
      [
        _p('p1', 'cf', 'Cà phê sữa đá', 29000),
        _p('p2', 'cf', 'Espresso', 35000),
        _p('p3', 'cf', 'Bạc xỉu', 32000),
        _p('p4', 'tea', 'Matcha Latte', 52000),
      ],
    );

/// Pumps the app already signed-in as [staffRole], landing straight on that
/// role's shell (CASHIER→POS, BARISTA→KDS, MANAGER/ADMIN→admin), with a
/// preloaded offline menu.
Future<void> pumpSignedIn(
  WidgetTester t, {
  required String staffRole,
  Size size = const Size(430, 932),
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await t.binding.setSurfaceSize(size);
  addTearDown(() => t.binding.setSurfaceSize(null));
  // Let TinyPosApp create AppState via the provider (so it's disposed at test
  // end and the KDS 1s timer is cancelled — no "pending timer" assertion).
  final session = SessionState()..debugSignIn(fakeUser(staffRole));
  final menu = PosMenuController(session.api)..debugSetMenu(fakeMenu());
  final billRepo = FakeBillRepository(session.api);
  final bills = BillsController(billRepo)
    ..debugSetBills([
      Bill(
        id: 'b1', billCode: 'B260611-0001', status: 'PAID', serviceType: 'TAKE_AWAY',
        subtotal: 58000, discountTotal: 0, grandTotal: 58000, paidTotal: 58000,
        note: null, paidAt: null, createdAt: null, items: const [],
      ),
    ]);
  final kds = KdsController(FakeKdsRepository(session.api))..debugSetData(_fakeTickets(), KdsStats(1, 1, 3));
  await t.pumpWidget(TinyPosApp(session: session, menu: menu, billRepo: billRepo, bills: bills, kds: kds));
  await t.pump();
  await t.pump(const Duration(milliseconds: 450));
}

/// pump() helper avoiding pumpAndSettle (perpetual KDS timer / pulse anims).
Future<void> beat(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 350));
  await t.pump(const Duration(milliseconds: 350));
}

Future<void> tapIfPresent(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) return;
  try {
    await t.ensureVisible(f.first);
  } catch (_) {}
  await t.tap(f.first, warnIfMissed: false);
  await beat(t);
}
