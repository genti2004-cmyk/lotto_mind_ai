import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';

import 'package:lotto_mind_ai/features/draws/domain/draw_result.dart';
import 'package:lotto_mind_ai/features/generator/provider/lotto_app_state.dart';
import 'package:lotto_mind_ai/features/system/domain/saved_system_play.dart';
import 'package:lotto_mind_ai/features/system/services/system_ticket_evaluation_service.dart';
import 'package:lotto_mind_ai/features/system/services/system_ai_number_service.dart';
import 'package:lotto_mind_ai/features/system/services/vew_system_service.dart';

class SystemGeneratorScreen extends StatefulWidget {
  const SystemGeneratorScreen({super.key});

  @override
  State<SystemGeneratorScreen> createState() => _SystemGeneratorScreenState();
}

class _SystemGeneratorScreenState extends State<SystemGeneratorScreen>
    with SingleTickerProviderStateMixin {
  static const double _pricePerRow = 1.20;
  static const String _boxName = 'system_play_tickets';
  static const _accent = Color(0xFF1B4FD6);

  final _service = const SystemTicketEvaluationService();
  final _systemAiService = SystemAiNumberService();
  final _vewService = const VewSystemService();
  final Set<int> _selectedNumbers = <int>{};
  final TextEditingController _losnummerController = TextEditingController();

  late final TabController _tabController;

  List<SavedSystemPlay> _saved = <SavedSystemPlay>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) setState(() {});
    });
    _setLosnummer(_randomLosnummer());
    _loadSavedTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _losnummerController.dispose();
    super.dispose();
  }

  String get _type {
    switch (_tabController.index) {
      case 1:
        return 'full';
      case 2:
        return 'vew';
      default:
        return 'normal';
    }
  }

  String get _typeLabel {
    switch (_type) {
      case 'full':
        return 'Vollsystem';
      case 'vew':
        return 'Intervall-System';
      default:
        return 'Normalschein';
    }
  }

  int get _maxNumbers {
    switch (_type) {
      case 'full':
        return 10;
      case 'vew':
        return 10;
      default:
        return 6;
    }
  }

  String get _losnummer => _normalizeDigits(_losnummerController.text, 7);
  String get _spiel77 => _losnummer;
  String get _super6 => _losnummer.substring(1);
  int get _superNumber => int.tryParse(_losnummer.substring(6)) ?? 0;

  Future<Box> _openBox() => Hive.openBox(_boxName);

  Future<void> _loadSavedTickets() async {
    try {
      final box = await _openBox();
      final values = box.values
          .whereType<Map>()
          .map((value) => SavedSystemPlay.fromMap(value))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _saved = values;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveTicket() async {
    final rows = _buildCurrentRows();
    if (rows.isEmpty) {
      _showSnack(_type == 'normal'
          ? 'Bitte genau 6 Zahlen wählen.'
          : 'Bitte zwischen 7 und $_maxNumbers Zahlen wählen.');
      return;
    }

    final losnummer = _losnummer;
    final ticket = SavedSystemPlay(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      type: _type,
      numbers: _selectedNumbers.toList()..sort(),
      rows: rows,
      pricePerRow: _pricePerRow,
      superNumber: int.tryParse(losnummer.substring(6)) ?? 0,
      losnummer: losnummer,
      spiel77: losnummer,
      super6: losnummer.substring(1),
    );

    final box = await _openBox();
    await box.put(ticket.id, ticket.toMap());
    await _loadSavedTickets();
    _showSnack('${ticket.typeLabel} gespeichert.');
  }

  Future<void> _deleteTicket(String id) async {
    final box = await _openBox();
    await box.delete(id);
    await _loadSavedTickets();
  }

  Future<void> _checkTicket(SavedSystemPlay ticket, DrawResult draw) async {
    final evaluation = _service.evaluate(
      rows: ticket.rows,
      draw: draw,
      superNumber: ticket.superNumber,
      spiel77: ticket.spiel77,
      super6: ticket.super6,
    );

    final updated = ticket.copyWith(
      lastCheckedDrawId: draw.id,
      lastCheckedAt: DateTime.now(),
      bestHits: evaluation.bestHits,
      winningRows: evaluation.winningRows,
      spiel77Matches: evaluation.spiel77Matches,
      super6Matches: evaluation.super6Matches,
      estimatedPrizeEuro: evaluation.totalEstimatedPrizeEuro,
      estimatedStakeEuro: evaluation.estimatedStakeEuro,
    );

    final box = await _openBox();
    await box.put(updated.id, updated.toMap());
    await _loadSavedTickets();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _EvaluationSheet(ticket: updated, evaluation: evaluation),
    );
  }

  Future<void> _checkAll(LottoAppState state) async {
    final draw = state.selectedDrawForCheck;
    if (draw == null) {
      _showSnack('Bitte zuerst eine Prüf-Ziehung auswählen.');
      return;
    }
    if (_saved.isEmpty) {
      _showSnack('Noch keine eigenen Systemscheine gespeichert.');
      return;
    }

    final box = await _openBox();
    for (final ticket in List<SavedSystemPlay>.from(_saved)) {
      final evaluation = _service.evaluate(
        rows: ticket.rows,
        draw: draw,
        superNumber: ticket.superNumber,
        spiel77: ticket.spiel77,
        super6: ticket.super6,
      );
      final updated = ticket.copyWith(
        lastCheckedDrawId: draw.id,
        lastCheckedAt: DateTime.now(),
        bestHits: evaluation.bestHits,
        winningRows: evaluation.winningRows,
        spiel77Matches: evaluation.spiel77Matches,
        super6Matches: evaluation.super6Matches,
        estimatedPrizeEuro: evaluation.totalEstimatedPrizeEuro,
        estimatedStakeEuro: evaluation.estimatedStakeEuro,
      );
      await box.put(updated.id, updated.toMap());
    }

    await _loadSavedTickets();
    _showSnack('Alle Systemscheine wurden geprüft.');
  }

  void _toggleNumber(int number) {
    setState(() {
      if (_selectedNumbers.contains(number)) {
        _selectedNumbers.remove(number);
        return;
      }
      if (_selectedNumbers.length >= _maxNumbers) {
        _showSnack('Maximal $_maxNumbers Zahlen für $_typeLabel.');
        return;
      }
      _selectedNumbers.add(number);
    });
  }

  void _useSmartNumbers(LottoAppState state, [int? forcedCount]) {
    final target = _type == 'normal' ? 6 : (forcedCount ?? _maxNumbers).clamp(7, _maxNumbers).toInt();
    final pool = _systemAiService.generateSystemNumbers(
      draws: state.analysisDrawResults,
      count: target,
      mode: _systemModeFromState(state),
    );
    setState(() {
      _selectedNumbers
        ..clear()
        ..addAll(pool);
    });
  }

  String _systemModeFromState(LottoAppState state) {
    final label = state.analysisProfileLabel.toLowerCase();
    if (label.contains('aggressiv')) return 'trend';
    if (label.contains('defensiv')) return 'rebound';
    return 'auto';
  }

  void _setLosnummer(String value) {
    final normalized = _normalizeDigits(value, 7);
    _losnummerController.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  void _randomizeLosnummer() {
    setState(() => _setLosnummer(_randomLosnummer()));
  }

  List<List<int>> _buildCurrentRows() {
    return _service.buildRows(type: _type, numbers: _selectedNumbers.toList());
  }

  String _randomLosnummer() {
    final random = Random(DateTime.now().microsecondsSinceEpoch);
    return List.generate(7, (_) => random.nextInt(10).toString()).join();
  }

  String _normalizeDigits(String value, int length) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= length) return digits.substring(0, length);
    return digits.padLeft(length, '0');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }

  String _euro(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final rows = _buildCurrentRows();
    final selectedDraw = state.selectedDrawForCheck;
    final valid = rows.isNotEmpty;
    final selectedNumbers = _selectedNumbers.toList()..sort();
    final vewReport = _type == 'vew' ? _vewService.coverageReport(selectedNumbers) : null;
    final fullRowsForPool = _type == 'vew' ? _vewService.fullSystemRows(selectedNumbers.length) : rows.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Systeme'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) {
            setState(() {
              while (_selectedNumbers.length > _maxNumbers) {
                final sorted = _selectedNumbers.toList()..sort();
                _selectedNumbers.remove(sorted.last);
              }
            });
          },
          tabs: const [
            Tab(text: 'Normal'),
            Tab(text: 'Voll'),
            Tab(text: 'Intervall'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          _HeroCard(
            typeLabel: _typeLabel,
            selectedCount: _selectedNumbers.length,
            maxCount: _maxNumbers,
            rows: rows.length,
            price: rows.length * _pricePerRow,
            drawLabel: selectedDraw == null
                ? 'Keine Prüf-Ziehung gewählt'
                : 'Prüfung: ${_formatDate(selectedDraw.drawDate)}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _useSmartNumbers(state),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(_type == 'normal' ? 'Smart 6' : 'AI $_maxNumbers'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(_selectedNumbers.clear),
                  icon: const Icon(Icons.clear_rounded),
                  label: const Text('Leeren'),
                ),
              ),
            ],
          ),
          if (_type != 'normal') ...[
            const SizedBox(height: 10),
            _SystemAiSizeBar(
              typeLabel: _typeLabel,
              onSelect: (count) => _useSmartNumbers(state, count),
            ),
          ],
          const SizedBox(height: 12),
          _NumberGrid(selected: _selectedNumbers, onTap: _toggleNumber),
          const SizedBox(height: 14),
          _LosnummerCard(
            controller: _losnummerController,
            superNumber: _superNumber,
            spiel77: _spiel77,
            super6: _super6,
            onChanged: (_) => setState(() {}),
            onRandom: _randomizeLosnummer,
          ),
          const SizedBox(height: 12),
          _PreviewCard(
            typeLabel: _typeLabel,
            numbers: selectedNumbers,
            rows: rows,
            pricePerRow: _pricePerRow,
            superNumber: _superNumber,
            losnummer: _losnummer,
            spiel77: _spiel77,
            super6: _super6,
            fullRowsForPool: fullRowsForPool,
          ),
          if (vewReport != null) ...[
            const SizedBox(height: 12),
            _VewProCoverageCard(report: vewReport),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: valid ? _saveTicket : null,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Diesen Schein speichern'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Meine Systemscheine',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: () => _checkAll(state),
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('Alle prüfen'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_saved.isEmpty)
            const _EmptySavedCard()
          else
            ..._saved.map(
                  (ticket) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SavedTicketCard(
                  ticket: ticket,
                  selectedDraw: selectedDraw,
                  onDelete: () => _deleteTicket(ticket.id),
                  onCheck: selectedDraw == null ? null : () => _checkTicket(ticket, selectedDraw),
                  euro: _euro,
                  formatDate: _formatDate,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.typeLabel,
    required this.selectedCount,
    required this.maxCount,
    required this.rows,
    required this.price,
    required this.drawLabel,
  });

  final String typeLabel;
  final int selectedCount;
  final int maxCount;
  final int rows;
  final double price;
  final String drawLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1B4FD6), Color(0xFF5B8CFF)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x221B4FD6), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lotto Mind AI Systemprüfung',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '$typeLabel · $selectedCount/$maxCount Zahlen · $rows Reihen · ${price.toStringAsFixed(2).replaceAll('.', ',')} €',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(drawLabel, style: const TextStyle(color: Color(0xFFE8EFFF))),
        ],
      ),
    );
  }
}

class _SystemAiSizeBar extends StatelessWidget {
  const _SystemAiSizeBar({required this.typeLabel, required this.onSelect});

  final String typeLabel;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'AI-Systempool 7–10 Zahlen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$typeLabel: AI berechnet den Zahlenpool. Vollsystem erzeugt alle 6er-Reihen, Intervall erzeugt reduzierte optimierte Reihen.',
            style: const TextStyle(color: Color(0xFF667085), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [7, 8, 9, 10]
                .map(
                  (count) => ActionChip(
                avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text('AI $count'),
                onPressed: () => onSelect(count),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}


class _VewProCoverageCard extends StatelessWidget {
  const _VewProCoverageCard({required this.report});

  final VewCoverageReport report;

  String pct(double value) => '${(value * 100).toStringAsFixed(1).replaceAll('.', ',')} %';

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Intervall Pro Abdeckung',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line('Basiszahlen', '${report.selectedNumbers}'),
          _Line('Intervall-Reihen', '${report.rows}'),
          _Line('Vollsystem', '${report.fullRows} Reihen'),
          _Line('Ersparnis', pct(report.reduction)),
          const Divider(height: 18),
          _Line('2er-Abdeckung', pct(report.pairCoverage)),
          _Line('3er-Abdeckung', pct(report.tripleCoverage)),
          _Line('4er-Abdeckung', pct(report.fourCoverage)),
          const SizedBox(height: 6),
          const Text(
            'Pro-Hinweis: Intervall reduziert den Einsatz und versucht trotzdem, wichtige 3er-/4er-Kombinationen breit abzudecken. Es ersetzt keine Vollsystem-Garantie.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _NumberGrid extends StatelessWidget {
  const _NumberGrid({required this.selected, required this.onTap});

  final Set<int> selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 49,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
      ),
      itemBuilder: (context, index) {
        final n = index + 1;
        final active = selected.contains(n);
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onTap(n),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            decoration: BoxDecoration(
              color: active ? _SystemGeneratorScreenState._accent : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: active ? _SystemGeneratorScreenState._accent : const Color(0xFFE1E7F0)),
            ),
            child: Center(
              child: Text(
                '$n',
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF172033),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LosnummerCard extends StatelessWidget {
  const _LosnummerCard({
    required this.controller,
    required this.superNumber,
    required this.spiel77,
    required this.super6,
    required this.onChanged,
    required this.onRandom,
  });

  final TextEditingController controller;
  final int superNumber;
  final String spiel77;
  final String super6;
  final ValueChanged<String> onChanged;
  final VoidCallback onRandom;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Losnummer & Zusatzspiele',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 7,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    labelText: '7-stellige Losnummer',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: onRandom,
                icon: const Icon(Icons.casino_rounded),
                tooltip: 'Neue Losnummer',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Line('Superzahl', '$superNumber'),
          _Line('Spiel 77', spiel77),
          _Line('Super 6', super6),
          const SizedBox(height: 6),
          const Text(
            'Regel: Spiel 77 nutzt die komplette 7-stellige Losnummer, Super 6 die letzten 6 Stellen, Superzahl die letzte Stelle.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.typeLabel,
    required this.numbers,
    required this.rows,
    required this.pricePerRow,
    required this.superNumber,
    required this.losnummer,
    required this.spiel77,
    required this.super6,
    required this.fullRowsForPool,
  });

  final String typeLabel;
  final List<int> numbers;
  final List<List<int>> rows;
  final double pricePerRow;
  final int superNumber;
  final String losnummer;
  final String spiel77;
  final String super6;
  final int fullRowsForPool;

  @override
  Widget build(BuildContext context) {
    final price = rows.length * pricePerRow;
    return _Panel(
      title: 'Aktueller Schein',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line('Typ', typeLabel),
          _Line('Zahlen', numbers.isEmpty ? '-' : numbers.join(' - ')),
          _Line('Reihen', '${rows.length}'),
          if (fullRowsForPool > rows.length)
            _Line('Vollsystem-Vergleich', '$fullRowsForPool Reihen'),
          _Line('Einsatz', '${price.toStringAsFixed(2).replaceAll('.', ',')} €'),
          const Divider(height: 18),
          _Line('Losnummer', losnummer),
          _Line('Superzahl', '$superNumber'),
          _Line('Spiel 77', spiel77),
          _Line('Super 6', super6),
        ],
      ),
    );
  }
}

class _SavedTicketCard extends StatelessWidget {
  const _SavedTicketCard({
    required this.ticket,
    required this.selectedDraw,
    required this.onDelete,
    required this.onCheck,
    required this.euro,
    required this.formatDate,
  });

  final SavedSystemPlay ticket;
  final DrawResult? selectedDraw;
  final VoidCallback onDelete;
  final VoidCallback? onCheck;
  final String Function(double value) euro;
  final String Function(DateTime value) formatDate;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '${ticket.typeLabel} · ${formatDate(ticket.createdAt)}',
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line('Zahlen', ticket.numbers.join(' - ')),
          _Line('Reihen', '${ticket.rowCount}'),
          _Line('Einsatz', euro(ticket.totalPrice)),
          _Line('Losnummer', ticket.losnummer),
          _Line('Superzahl', '${ticket.superNumber}'),
          _Line('Spiel 77', ticket.spiel77),
          _Line('Super 6', ticket.super6),
          if (ticket.hasEvaluation) ...[
            const Divider(height: 18),
            _Line('Beste Haupttreffer', '${ticket.bestHits ?? 0}'),
            _Line('Gewinnreihen', '${ticket.winningRows ?? 0}'),
            _Line('Modellwert', euro(ticket.estimatedPrizeEuro ?? 0)),
            _Line('Einsatz geprüft', euro(ticket.estimatedStakeEuro ?? ticket.totalPrice)),
            _Line('Netto Modell', euro(ticket.estimatedNetEuro)),
            _Line('ROI Modell', ticket.estimatedRoiLabel),
            _Line('Bewertung', ticket.estimatedPerformanceLabel),
            _Line('Spiel 77 Endziffern', '${ticket.spiel77Matches ?? 0}'),
            _Line('Super 6 Endziffern', '${ticket.super6Matches ?? 0}'),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCheck,
              icon: const Icon(Icons.fact_check_rounded),
              label: Text(selectedDraw == null ? 'Keine Prüf-Ziehung gewählt' : 'Gegen Prüf-Ziehung auswerten'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationSheet extends StatelessWidget {
  const _EvaluationSheet({required this.ticket, required this.evaluation});

  final SavedSystemPlay ticket;
  final SystemTicketEvaluation evaluation;

  String euro(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return '$fixed €';
  }

  @override
  Widget build(BuildContext context) {
    final classes = evaluation.classCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Auswertung ${ticket.typeLabel}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _Line('Geprüfte Reihen', '${evaluation.rowsChecked}'),
            _Line('Beste Treffer', '${evaluation.bestHits}'),
            _Line('Gewinnreihen', '${evaluation.winningRows}'),
            _Line('Modellwert gesamt', evaluation.totalEstimatedPrizeLabel),
            _Line('Einsatz Modell', evaluation.estimatedStakeLabel),
            _Line('Netto Modell', evaluation.estimatedNetLabel),
            _Line('ROI Modell', evaluation.roiLabel),
            _Line('Bewertung', evaluation.performanceLabel),
            _Line('Effizienz', evaluation.efficiencyLabel),
            _Line('Spiel 77', '${evaluation.spiel77Label} · ${euro(evaluation.spiel77EstimatedPrizeEuro)}'),
            _Line('Super 6', '${evaluation.super6Label} · ${euro(evaluation.super6EstimatedPrizeEuro)}'),
            if (classes.isNotEmpty) ...[
              const Divider(height: 20),
              ...classes.map((e) => _Line(e.key, '${e.value}x')),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptySavedCard extends StatelessWidget {
  const _EmptySavedCard();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      title: 'Noch keine eigenen Systemscheine',
      child: Text('Wähle Zahlen, speichere Normal/Voll/Intervall und prüfe später gegen eine Ziehung inklusive Spiel 77 und Super 6.'),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7F0)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF667085))),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
