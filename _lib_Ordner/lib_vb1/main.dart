import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'features/generator/provider/lotto_app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await initializeDateFormatting('de_DE', null);

  final appState = LottoAppState();
  await appState.loadFromStorage();

  runApp(
    ChangeNotifierProvider<LottoAppState>.value(
      value: appState,
      child: const LottoApp(),
    ),
  );
}
