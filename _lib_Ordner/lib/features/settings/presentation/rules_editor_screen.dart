import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generator/provider/lotto_app_state.dart';

class RulesEditorScreen extends StatefulWidget {
  const RulesEditorScreen({super.key});

  @override
  State<RulesEditorScreen> createState() => _RulesEditorScreenState();
}

class _RulesEditorScreenState extends State<RulesEditorScreen> {
  late TextEditingController preferredController;
  late TextEditingController excludedController;
  late TextEditingController requiredController;
  late TextEditingController minSumController;
  late TextEditingController maxSumController;

  late int minEven;
  late int maxEven;
  late int minLow;
  late int maxLow;

  @override
  void initState() {
    super.initState();

    final rules = context.read<LottoAppState>().rules;

    preferredController =
        TextEditingController(text: rules.preferredNumbers.join(','));
    excludedController =
        TextEditingController(text: rules.excludedNumbers.join(','));
    requiredController =
        TextEditingController(text: rules.requiredNumbers.join(','));

    minSumController = TextEditingController(text: rules.minSum.toString());
    maxSumController = TextEditingController(text: rules.maxSum.toString());

    minEven = rules.minEven;
    maxEven = rules.maxEven;
    minLow = rules.minLowNumbers;
    maxLow = rules.maxLowNumbers;
  }

  @override
  void dispose() {
    preferredController.dispose();
    excludedController.dispose();
    requiredController.dispose();
    minSumController.dispose();
    maxSumController.dispose();
    super.dispose();
  }

  List<int> parseNumbers(String input) {
    return input
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((e) => e >= 1 && e <= 49)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> save() async {
    final parsedMinSum = int.tryParse(minSumController.text.trim());
    final parsedMaxSum = int.tryParse(maxSumController.text.trim());

    if (parsedMinSum == null || parsedMaxSum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gültige Summenwerte eingeben.')),
      );
      return;
    }

    if (minEven > maxEven || minLow > maxLow || parsedMinSum > parsedMaxSum) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gültige Bereiche eingeben.')),
      );
      return;
    }

    final state = context.read<LottoAppState>();

    final updated = state.rules.copyWith(
      preferredNumbers: parseNumbers(preferredController.text),
      excludedNumbers: parseNumbers(excludedController.text),
      requiredNumbers: parseNumbers(requiredController.text),
      minEven: minEven,
      maxEven: maxEven,
      minLowNumbers: minLow,
      maxLowNumbers: maxLow,
      minSum: parsedMinSum,
      maxSum: parsedMaxSum,
    );

    await state.setRules(updated);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Regeln gespeichert')),
    );

    Navigator.pop(context);
  }

  Future<void> reset() async {
    await context.read<LottoAppState>().resetRulesAndSave();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Standardregeln geladen')),
    );

    Navigator.pop(context);
  }

  Widget numberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'z.B. 100',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget csvField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'z.B. 7,12,18',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget rangeRow(
      String label,
      int min,
      int max,
      Function(int) onMin,
      Function(int) onMax,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Min',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: min,
                    isExpanded: true,
                    items: List.generate(7, (i) => i)
                        .map(
                          (e) => DropdownMenuItem<int>(
                        value: e,
                        child: Text('$e'),
                      ),
                    )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onMin(v);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Max',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: max,
                    isExpanded: true,
                    items: List.generate(7, (i) => i)
                        .map(
                          (e) => DropdownMenuItem<int>(
                        value: e,
                        child: Text('$e'),
                      ),
                    )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onMax(v);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse-Regeln'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          csvField('Bevorzugte Zahlen', preferredController),
          const SizedBox(height: 12),
          csvField('Ausgeschlossene Zahlen', excludedController),
          const SizedBox(height: 12),
          csvField('Pflichtzahlen', requiredController),
          const SizedBox(height: 20),

          rangeRow(
            'Gerade Zahlen',
            minEven,
            maxEven,
                (v) => setState(() => minEven = v),
                (v) => setState(() => maxEven = v),
          ),
          const SizedBox(height: 16),

          rangeRow(
            'Niedrige Zahlen (1–24)',
            minLow,
            maxLow,
                (v) => setState(() => minLow = v),
                (v) => setState(() => maxLow = v),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: numberField('Min Summe', minSumController),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: numberField('Max Summe', maxSumController),
              ),
            ],
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: save,
            child: const Text('Speichern'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: reset,
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }
}