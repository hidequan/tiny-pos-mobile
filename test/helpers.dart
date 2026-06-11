import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiny_pos_mobile/main.dart';
import 'package:tiny_pos_mobile/state/session.dart';
import 'package:tiny_pos_mobile/state/menu_controller.dart';
import 'package:tiny_pos_mobile/api/bill_repository.dart';
import 'package:tiny_pos_mobile/api/kds_repository.dart';
import 'package:tiny_pos_mobile/api/table_repository.dart';
import 'package:tiny_pos_mobile/api/reports_repository.dart';
import 'package:tiny_pos_mobile/api/admin_repository.dart';
import 'package:tiny_pos_mobile/state/bills_controller.dart';
import 'package:tiny_pos_mobile/state/kds_controller.dart';
import 'package:tiny_pos_mobile/state/tables_controller.dart';
import 'package:tiny_pos_mobile/state/reports_controller.dart';
import 'package:tiny_pos_mobile/state/admin_data_controller.dart';
import 'package:tiny_pos_mobile/models/auth_user.dart';
import 'package:tiny_pos_mobile/models/menu.dart';
import 'package:tiny_pos_mobile/models/bill.dart';
import 'package:tiny_pos_mobile/models/kds.dart';
import 'package:tiny_pos_mobile/models/table.dart';
import 'package:tiny_pos_mobile/models/report.dart';
import 'package:tiny_pos_mobile/models/admin.dart';

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

/// A no-op ReportsRepository with canned figures for widget tests.
class FakeReportsRepository extends ReportsRepository {
  FakeReportsRepository(super.api);
  @override
  Future<SalesSummary> salesSummary({DateTime? from, DateTime? to}) async => SalesSummary(
        revenue: 4250000, billCount: 142, avgBill: 29929, itemsSold: 312,
        discountTotal: 180000, refundedTotal: 0, takeAway: 110, dineIn: 32,
      );
  @override
  Future<List<BestSeller>> bestSelling({DateTime? from, DateTime? to, int limit = 10}) async => [
        BestSeller(productName: 'Cà phê sữa đá', quantity: 88, revenue: 2552000),
        BestSeller(productName: 'Bạc xỉu', quantity: 54, revenue: 1728000),
      ];
  @override
  Future<List<PayMethodStat>> paymentMethods({DateTime? from, DateTime? to}) async => [
        PayMethodStat(method: 'CASH', amount: 2800000, count: 96),
        PayMethodStat(method: 'QR', amount: 1450000, count: 46),
      ];
}

/// A no-op AdminRepository with canned master data for widget tests.
class FakeAdminRepository extends AdminRepository {
  FakeAdminRepository(super.api);
  @override
  Future<List<StaffMember>> users() async => [
        StaffMember(id: 'u1', username: 'cashier01', fullName: 'Trần Thị Bình', staffRole: 'CASHIER', status: 'ACTIVE'),
        StaffMember(id: 'u2', username: 'barista01', fullName: 'Quách Đông', staffRole: 'BARISTA', status: 'ACTIVE'),
      ];
  @override
  Future<List<StockBalance>> inventoryBalances() async => [
        StockBalance(id: 'b1', code: 'CF-BEAN', name: 'Cà phê hạt', unit: 'g', onHand: 9906, reserved: 112, minStock: 500),
        StockBalance(id: 'b2', code: 'MILK', name: 'Sữa tươi', unit: 'ml', onHand: 300, reserved: 0, minStock: 1000),
      ];
  @override
  Future<List<BomRecipe>> bomRecipes() async => [
        BomRecipe(id: 'r1', name: 'BOM Trân châu', isActive: true, items: [
          BomItem(ingredientName: 'Bột năng', quantity: 50, unit: 'g'),
        ]),
      ];
  @override
  Future<void> setProductStatus(String id, bool active) async {}
  @override
  Future<void> createProduct({required String categoryId, required String name, required int basePrice, bool active = true}) async {}
  @override
  Future<void> updateProduct(String id, {String? name, String? categoryId, int? basePrice, bool? active}) async {}
}

/// A no-op TableRepository with a canned floor map for widget tests.
class FakeTableRepository extends TableRepository {
  FakeTableRepository(super.api);
  @override
  Future<List<TableArea>> map() async => _fakeAreas();
  @override
  Future<TableSessionDetail> sessionDetail(String sessionId) async => TableSessionDetail(
        id: sessionId, status: 'WAITING', guestCount: 2, tableId: 'tA02', tableCode: 'A02',
        bills: [
          Bill(
            id: 'tb1', billCode: 'B260611-D01', status: 'SENT_TO_BAR_UNPAID', serviceType: 'DINE_IN',
            subtotal: 58000, discountTotal: 0, grandTotal: 58000, paidTotal: 0, note: null, paidAt: null,
            items: [
              BillItem(id: 'ti1', variantId: 'v1', productName: 'Cà phê sữa đá', variantName: null,
                  sizeName: 'M', unitPrice: 29000, quantity: 2, lineTotal: 58000, note: null, status: 'WAITING'),
            ],
          ),
        ],
      );
  @override
  Future<String> openTable(String tableId, {int guestCount = 1}) async => 'sess-new';
  @override
  Future<void> addItems(String sessionId, List<BillItemInput> items, {String? billId}) async {}
  @override
  Future<void> close(String sessionId) async {}
  @override
  Future<void> clean(String tableId) async {}
}

List<TableArea> _fakeAreas() => [
      TableArea(id: 'area1', name: 'Tầng 1', level: 1, tables: [
        CafeTable(id: 'tA01', code: 'A01', name: null, seats: 4, status: 'EMPTY', posX: 0, posY: 0, session: null),
        CafeTable(
          id: 'tA02', code: 'A02', name: null, seats: 4, status: 'OCCUPIED', posX: 0, posY: 0,
          session: TableSessionSummary(id: 'sess-A02', status: 'WAITING', guestCount: 2, billCount: 1, total: 58000),
        ),
        CafeTable(id: 'tA03', code: 'A03', name: null, seats: 2, status: 'DIRTY', posX: 0, posY: 0, session: null),
      ]),
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
  final tables = TablesController(FakeTableRepository(session.api))..debugSetAreas(_fakeAreas());
  final reports = ReportsController(FakeReportsRepository(session.api))
    ..debugSet(
      summary: SalesSummary(
        revenue: 4250000, billCount: 142, avgBill: 29929, itemsSold: 312,
        discountTotal: 180000, refundedTotal: 0, takeAway: 110, dineIn: 32,
      ),
      bestSellers: [BestSeller(productName: 'Cà phê sữa đá', quantity: 88, revenue: 2552000)],
      payments: [PayMethodStat(method: 'CASH', amount: 2800000, count: 96)],
    );
  final adminData = AdminDataController(FakeAdminRepository(session.api))
    ..debugSet(
      staff: [
        StaffMember(id: 'u1', username: 'cashier01', fullName: 'Trần Thị Bình', staffRole: 'CASHIER', status: 'ACTIVE'),
        StaffMember(id: 'u2', username: 'barista01', fullName: 'Quách Đông', staffRole: 'BARISTA', status: 'ACTIVE'),
      ],
      balances: [
        StockBalance(id: 'b1', code: 'CF-BEAN', name: 'Cà phê hạt', unit: 'g', onHand: 9906, reserved: 112, minStock: 500),
        StockBalance(id: 'b2', code: 'MILK', name: 'Sữa tươi', unit: 'ml', onHand: 300, reserved: 0, minStock: 1000),
      ],
      boms: [
        BomRecipe(id: 'r1', name: 'BOM Trân châu', isActive: true, items: [
          BomItem(ingredientName: 'Bột năng', quantity: 50, unit: 'g'),
        ]),
      ],
    );
  await t.pumpWidget(TinyPosApp(
      session: session, menu: menu, billRepo: billRepo, bills: bills, kds: kds, tables: tables,
      reports: reports, adminData: adminData));
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
