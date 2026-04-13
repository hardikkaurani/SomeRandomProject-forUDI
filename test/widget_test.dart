import 'package:flutter_test/flutter_test.dart';
import 'package:sms_parser_basically/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('0 income messages found'), findsOneWidget);
  });
}
