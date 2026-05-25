import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lotto_mind_ai/features/generator/provider/lotto_app_state.dart';
import 'package:lotto_mind_ai/navigation/main_navigation_screen.dart';

void main() {
  runApp(const LottoApp());
}
enum ProFeature {
  unlimitedHistoryImport,
  advancedAnalysisProfiles,
  pdfExport,
  premiumAnalysis,
  cloudBackup,
}
class LottoApp extends StatelessWidget {
  const LottoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LottoAppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Lotto Pro Analyzer',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}