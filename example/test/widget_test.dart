import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('GPS Time home page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const GpsTimeExampleApp());
    expect(find.text('GPS Time Plugin'), findsOneWidget);
    expect(find.text('Start GPS'), findsOneWidget);
  });
}
