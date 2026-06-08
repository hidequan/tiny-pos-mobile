import 'package:flutter_test/flutter_test.dart';

import 'package:tiny_pos_mobile/main.dart';

void main() {
  testWidgets('Tiny POS shows the login role picker on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const TinyPosApp());
    await tester.pump();

    // The login screen presents the three role cards.
    expect(find.text('Tiny POS'), findsOneWidget);
    expect(find.text('Thu ngân'), findsOneWidget);
    expect(find.text('KDS / Bar'), findsOneWidget);
    expect(find.text('Quản trị'), findsOneWidget);
  });
}
