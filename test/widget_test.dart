import 'package:flutter_test/flutter_test.dart';
import 'package:lotto_mind_ai/app/app.dart';

void main() {
  testWidgets('LottoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LottoApp());
    expect(find.byType(LottoApp), findsOneWidget);
  });
}