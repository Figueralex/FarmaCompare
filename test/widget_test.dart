import 'package:flutter_test/flutter_test.dart';
import 'package:farmacompare/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FarmaCompareApp());
    expect(find.byType(FarmaCompareApp), findsOneWidget);
  });
}
