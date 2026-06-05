import 'package:flutter_test/flutter_test.dart';
import 'package:richerchasai/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const RiCherChasAIApp());
    expect(find.text('RiCherChasAI'), findsOneWidget);
  });
}
