import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:lotto_mind_ai/features/generator/provider/lotto_app_state.dart';
import 'package:lotto_mind_ai/navigation/main_navigation_screen.dart';

void main() {
  testWidgets('LottoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<LottoAppState>(
        create: (_) => LottoAppState(),
        child: const MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Start'), findsWidgets);
    expect(find.text('Generator'), findsWidgets);
    expect(find.text('Meine Tipps'), findsWidgets);
    expect(find.text('Ziehungen'), findsWidgets);
    expect(find.text('Mehr'), findsWidgets);
  });
}