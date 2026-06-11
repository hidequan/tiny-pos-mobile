import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiny_pos_mobile/main.dart';
import 'package:tiny_pos_mobile/state/session.dart';
import 'package:tiny_pos_mobile/models/auth_user.dart';

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

/// Pumps the app already signed-in as [staffRole], landing straight on that
/// role's shell (CASHIER→POS, BARISTA→KDS, MANAGER/ADMIN→admin).
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
  await t.pumpWidget(TinyPosApp(session: session));
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
