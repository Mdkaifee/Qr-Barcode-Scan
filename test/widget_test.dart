import 'package:flutter_test/flutter_test.dart';

import 'package:scanner/main.dart';

void main() {
  testWidgets('shows scan button after splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Scanner'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Scan'), findsOneWidget);
  });
}
