import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../tips/services/westlotto_launcher_service.dart';
import '../provider/lotto_app_state.dart';

class PlaySlipScreen extends StatefulWidget {
  const PlaySlipScreen({super.key});

  @override
  State<PlaySlipScreen> createState() => _PlaySlipScreenState();
}

class _PlaySlipScreenState extends State<PlaySlipScreen> {
  final Set<int> _selected = <int>{};
  int? _superNumber;
  bool _opening = false;

  void _toggle(int n) {
    setState(() {
      if (_selected.contains(n)) {
        _selected.remove(n);
      } else if (_selected.length < 6) {
        _selected.add(n);
      }
    });
  }

  void _loadFromAi(LottoAppState state) {
    final tip = state.lastGeneratedTip;
    if (tip == null || tip.isEmpty) return;

    setState(() {
      _selected
        ..clear()
        ..addAll(tip);
      _superNumber = state.lastGeneratedSuperNumber;
    });
  }



  Future<void> _saveToMyTips() async {
    if (_selected.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte genau 6 Zahlen auswählen.')),
      );
      return;
    }

    final sorted = _selected.toList()..sort();
    final state = context.read<LottoAppState>();
    state.setGeneratedNumbers(sorted, superNumber: _superNumber);
    await state.saveLastTip(source: 'playslip');

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tipp wurde in „Meine Tipps“ gespeichert.')),
    );
  }

  Future<void> _openWestLotto() async {
    if (_selected.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte genau 6 Zahlen auswählen.')),
      );
      return;
    }

    setState(() {
      _opening = true;
    });

    final sorted = _selected.toList()..sort();

    final result = await WestlottoLauncherService.openWithTip(
      numbers: sorted,
      superzahl: _superNumber, // ✅ korrekt
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result
              ? 'WestLotto geöffnet'
              : 'Konnte WestLotto nicht öffnen',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final sorted = _selected.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spielschein'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _loadFromAi(state),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI Tipp übernehmen'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 49,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (_, i) {
                final n = i + 1;
                final isSelected = _selected.contains(n);

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _toggle(n),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Gewählt: ${sorted.join(' - ')}${_superNumber == null ? '' : '   |   SZ: $_superNumber'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: sorted.isEmpty
                            ? null
                            : () {
                          setState(() {
                            _selected.clear();
                            _superNumber = null;
                          });
                        },
                        icon: const Icon(Icons.clear_rounded),
                        label: const Text('Leeren'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: sorted.length == 6 ? _saveToMyTips : null,
                        icon: const Icon(Icons.bookmark_add_rounded),
                        label: const Text('In Meine Tipps speichern'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _opening ? null : _openWestLotto,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(_opening ? 'Öffne...' : 'Bei WestLotto öffnen'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
