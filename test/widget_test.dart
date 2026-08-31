import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/main.dart';

void main() {
  testWidgets('Login screen shows Shop POS', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PosApp()));
    await tester.pumpAndSettle();
    expect(find.text('Shop POS'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
