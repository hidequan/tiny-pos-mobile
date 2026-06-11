import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiny_pos_mobile/main.dart';

void main() {
  testWidgets('Launches to the auth login screen when no session', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TinyPosApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Real username/password login (replaces the old demo role picker).
    expect(find.text('Tiny POS'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
  });
}
