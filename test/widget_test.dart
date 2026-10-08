import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch_flutter_app/main.dart';

void main() {
  testWidgets('CineMatch app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CineMatchApp());
    expect(find.text('CINEMATCH'), findsOneWidget);
  });
}
