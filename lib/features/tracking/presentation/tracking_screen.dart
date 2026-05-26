import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../draws/domain/draw_result.dart';
import '../../generator/provider/lotto_app_state.dart';
import '../../winnings/domain/lotto_win_value_model.dart';
import '../domain/tracked_tip.dart';
import '../services/tracking_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TrackingService _service = TrackingService();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'de_DE');

  bool _loading = true;
  bool _working = false;
  String? _loadError;
  List<TrackedTip> _tips = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final tips = await _service.loadTips().timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _tips = tips;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _tips = const [];
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _runWork(Future<void> Function() task) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final draws = List<DrawResult>.from(state.drawResults)
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));
    final summaries = _service.buildStrategySummaries(_tips);
    final savedTipCount = state.savedTips.length;
    final checkCount = _tips.fold<int>(0, (sum, tip) => sum + tip.checks.length);

    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: const Text('Tracking Pro'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _working ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _TrackingErrorView(
        message: _loadError!,
        onRetry: _load,
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TrackingIntroCard(
            savedTipCount: savedTipCount,
            trackingTipCount: _tips.length,
            checkCount: checkCount,
          ),
          const SizedBox(height: 14),
          _CreateFromCurrentTipCard(
            lastGeneratedTip: state.lastGeneratedTip,
            onSave: (numbers) => _runWork(() => _saveCurrentTip(numbers)),
          ),
          const SizedBox(height: 14),
          _BulkActionsCard(
            working: _working,
            drawCount: draws.length,
            tipCount: _tips.length,
            onEvaluateLatest: draws.isEmpty || _tips.isEmpty
                ? null
                : () => _runWork(() => _evaluateAll(draws: draws, limit: 1)),
            onEvaluate52: draws.isEmpty || _tips.isEmpty
                ? null
                : () => _runWork(() => _evaluateAll(draws: draws, limit: 52)),
            onEvaluateAll: draws.isEmpty || _tips.isEmpty
                ? null
                : () => _runWork(() => _evaluateAll(draws: draws)),
          ),
          const SizedBox(height: 14),
          _SummaryCard(tips: _tips),
          const SizedBox(height: 14),
          if (summaries.isNotEmpty) ...[
            _StrategySummaryCard(summaries: summaries),
            const SizedBox(height: 14),
          ],
          if (_tips.isEmpty)
            const _EmptyCard()
          else
            ..._tips.map(
                  (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TrackedTipCard(
                  tip: tip,
                  draws: draws,
                  dateFormat: _dateFormat,
                  onDelete: () => _runWork(() => _deleteTip(tip.id)),
                  onClearChecks: () => _runWork(() => _clearChecks(tip.id)),
                  onEvaluateLatest: draws.isEmpty ? null : () => _runWork(() => _evaluateTip(tip, draws.first)),
                  onEvaluate52: draws.isEmpty ? null : () => _runWork(() => _evaluateTipAgainstDraws(tip, draws, 52)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentTip(List<int> numbers) async {
    final appState = context.read<LottoAppState>();
    final superNumber = _sameNumbers(appState.lastGeneratedTip, numbers)
        ? appState.lastGeneratedSuperNumber
        : null;

    await appState.saveTipFromNumbers(
      numbers,
      superNumber: superNumber,
      source: 'tracking_pro',
    );

    final tip = _service.createTip(
      title: 'Aktueller Tipp ${_dateFormat.format(DateTime.now())}',
      type: TrackedTipType.ai,
      baseNumbers: numbers,
      rows: [numbers],
      superNumber: superNumber,
      stakePerDraw: LottoWinValueModel.stakePerLottoRow,
    );
    await _service.saveTip(tip);
    await _load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tipp wurde in Meine Tipps gespeichert und zusätzlich ins Tracking übernommen.')),
    );
  }

  bool _sameNumbers(List<int>? a, List<int> b) {
    if (a == null || a.length != b.length) return false;
    final left = List<int>.from(a)..sort();
    final right = List<int>.from(b)..sort();
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  Future<void> _deleteTip(String id) async {
    await _service.deleteTip(id);
    await _load();
  }

  Future<void> _clearChecks(String id) async {
    await _service.clearChecks(id);
    await _load();
  }

  Future<void> _evaluateTip(TrackedTip tip, DrawResult draw) async {
    final updated = _service.evaluateAndAppend(tip: tip, draw: draw);
    await _service.saveTip(updated);
    await _load();
  }

  Future<void> _evaluateTipAgainstDraws(TrackedTip tip, List<DrawResult> draws, int limit) async {
    final updated = _service.evaluateAgainstDraws(tip: tip, draws: draws, limit: limit);
    await _service.saveTip(updated);
    await _load();
  }

  Future<void> _evaluateAll({required List<DrawResult> draws, int? limit}) async {
    final updated = _service.evaluateAllAgainstDraws(tips: _tips, draws: draws, limit: limit);
    await _service.saveTips(updated);
    await _load();
  }
}


class _TrackingIntroCard extends StatelessWidget {
  final int savedTipCount;
  final int trackingTipCount;
  final int checkCount;

  const _TrackingIntroCard({
    required this.savedTipCount,
    required this.trackingTipCount,
    required this.checkCount,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.lightBlueAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Statistik & Verlauf',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Meine Tipps bleibt deine zentrale Ablage. Tracking Pro wertet gespeicherte Tipps langfristig aus und vergleicht Strategien.',
            style: TextStyle(color: Colors.white.withOpacity(0.74), height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Meine Tipps', value: '$savedTipCount')),
              Expanded(child: _Metric(label: 'im Tracking', value: '$trackingTipCount')),
              Expanded(child: _Metric(label: 'Prüfungen', value: '$checkCount')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateFromCurrentTipCard extends StatelessWidget {
  final List<int>? lastGeneratedTip;
  final ValueChanged<List<int>> onSave;

  const _CreateFromCurrentTipCard({
    required this.lastGeneratedTip,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final tip = lastGeneratedTip == null ? <int>[] : List<int>.from(lastGeneratedTip!)..sort();
    final canSave = tip.length == 6;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipp ins Tracking übernehmen',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            canSave ? 'Der zuletzt generierte Tipp wird zuerst in Meine Tipps gespeichert und zusätzlich für Statistik in Tracking Pro übernommen.' : 'Noch kein 6er-Tipp im Generator vorhanden.',
            style: TextStyle(color: Colors.white.withOpacity(0.72)),
          ),
          const SizedBox(height: 12),
          if (canSave) _NumberWrap(numbers: tip),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canSave ? () => onSave(tip) : null,
              icon: const Icon(Icons.save_rounded),
              label: const Text('In Meine Tipps + Tracking'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkActionsCard extends StatelessWidget {
  final bool working;
  final int drawCount;
  final int tipCount;
  final VoidCallback? onEvaluateLatest;
  final VoidCallback? onEvaluate52;
  final VoidCallback? onEvaluateAll;

  const _BulkActionsCard({
    required this.working,
    required this.drawCount,
    required this.tipCount,
    required this.onEvaluateLatest,
    required this.onEvaluate52,
    required this.onEvaluateAll,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Statistik berechnen',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (working)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$tipCount Tipp(s) • $drawCount Ziehung(en) verfügbar',
            style: TextStyle(color: Colors.white.withOpacity(0.70)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: working ? null : onEvaluateLatest,
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text('Letzte Ziehung'),
              ),
              OutlinedButton.icon(
                onPressed: working ? null : onEvaluate52,
                icon: const Icon(Icons.history_rounded),
                label: const Text('Letzte 52'),
              ),
              OutlinedButton.icon(
                onPressed: working ? null : onEvaluateAll,
                icon: const Icon(Icons.all_inclusive_rounded),
                label: const Text('Alle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<TrackedTip> tips;

  const _SummaryCard({required this.tips});

  @override
  Widget build(BuildContext context) {
    final checks = tips.fold<int>(0, (sum, tip) => sum + tip.checks.length);
    final stake = tips.fold<double>(0, (sum, tip) => sum + tip.totalStake);
    final prize = tips.fold<double>(0, (sum, tip) => sum + tip.totalPrize);
    final roi = LottoWinValueModel.roiPercent(prize: prize, stake: stake);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tracking-Statistik',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Tipps', value: '${tips.length}')),
              Expanded(child: _Metric(label: 'Prüfungen', value: '$checks')),
              Expanded(child: _Metric(label: 'ROI', value: '${roi.toStringAsFixed(1).replaceAll('.', ',')} %')),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Einsatz ${LottoWinValueModel.formatEuro(stake)} • Gewinn ${LottoWinValueModel.formatEuro(prize)} • Netto ${LottoWinValueModel.formatSignedEuro(prize - stake)}',
            style: TextStyle(color: Colors.white.withOpacity(0.72)),
          ),
        ],
      ),
    );
  }
}

class _StrategySummaryCard extends StatelessWidget {
  final List<TrackingStrategySummary> summaries;

  const _StrategySummaryCard({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final best = summaries.first;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Strategien vergleichen',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Aktuell vorne: ${best.type.label} • ${best.roiLabel}',
            style: TextStyle(color: Colors.white.withOpacity(0.76)),
          ),
          const SizedBox(height: 12),
          ...summaries.map(
                (summary) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.055),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(summary.type.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(
                            '${summary.tipCount} Tipp(s) • ${summary.checkCount} Prüfung(en) • Best ${summary.bestHits} Treffer',
                            style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(summary.roiLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        Text(summary.performanceLabel, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackedTipCard extends StatelessWidget {
  final TrackedTip tip;
  final List<DrawResult> draws;
  final DateFormat dateFormat;
  final VoidCallback onDelete;
  final VoidCallback onClearChecks;
  final VoidCallback? onEvaluateLatest;
  final VoidCallback? onEvaluate52;

  const _TrackedTipCard({
    required this.tip,
    required this.draws,
    required this.dateFormat,
    required this.onDelete,
    required this.onClearChecks,
    required this.onEvaluateLatest,
    required this.onEvaluate52,
  });

  @override
  Widget build(BuildContext context) {
    final latestCheck = tip.checks.isEmpty ? null : tip.checks.first;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tip.title,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                color: const Color(0xFF12223B),
                onSelected: (value) {
                  if (value == 'clear') onClearChecks();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'clear', child: Text('Prüfungen löschen')),
                  PopupMenuItem(value: 'delete', child: Text('Tipp löschen')),
                ],
              ),
            ],
          ),
          Text(
            '${tip.type.label} • ${tip.rowCount} Reihe(n) • Einsatz ${LottoWinValueModel.formatEuro(tip.stakePerDraw)}',
            style: TextStyle(color: Colors.white.withOpacity(0.70)),
          ),
          const SizedBox(height: 10),
          _NumberWrap(numbers: tip.baseNumbers),
          const SizedBox(height: 12),
          _TipMiniStats(tip: tip),
          const SizedBox(height: 12),
          if (latestCheck == null)
            Text('Noch keine Prüfung vorhanden.', style: TextStyle(color: Colors.white.withOpacity(0.72)))
          else
            _CheckPreview(check: latestCheck, dateFormat: dateFormat),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEvaluateLatest,
                icon: const Icon(Icons.fact_check_rounded),
                label: Text(draws.isEmpty ? 'Keine Ziehungen' : 'Letzte prüfen'),
              ),
              OutlinedButton.icon(
                onPressed: onEvaluate52,
                icon: const Icon(Icons.history_rounded),
                label: const Text('52 Rücktest'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipMiniStats extends StatelessWidget {
  final TrackedTip tip;

  const _TipMiniStats({required this.tip});

  @override
  Widget build(BuildContext context) {
    if (tip.checks.isEmpty) {
      return const SizedBox.shrink();
    }

    final bestHits = tip.checks.fold<int>(0, (best, check) => check.bestHits > best ? check.bestHits : best);
    final winRows = tip.checks.fold<int>(0, (sum, check) => sum + check.winningRows);
    final roi = tip.roiPercent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _Metric(label: 'Prüfungen', value: '${tip.checks.length}')),
          Expanded(child: _Metric(label: 'Best', value: '$bestHits Treffer')),
          Expanded(child: _Metric(label: 'ROI', value: '${roi.toStringAsFixed(1).replaceAll('.', ',')} %')),
          Expanded(child: _Metric(label: 'Gewinnreihen', value: '$winRows')),
        ],
      ),
    );
  }
}

class _CheckPreview extends StatelessWidget {
  final TrackedTipCheck check;
  final DateFormat dateFormat;

  const _CheckPreview({required this.check, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final winClass = check.bestWinClass == null ? '-' : 'GK ${check.bestWinClass}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Letzte Prüfung: ${dateFormat.format(check.drawDate)}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Beste Reihe: ${check.bestHits} Treffer • $winClass • Gewinn ${LottoWinValueModel.formatEuro(check.prize)}',
            style: TextStyle(color: Colors.white.withOpacity(0.78)),
          ),
          Text(
            'Netto ${LottoWinValueModel.formatSignedEuro(check.netValue)} • ROI ${check.roiPercent.toStringAsFixed(1).replaceAll('.', ',')} %',
            style: TextStyle(color: Colors.white.withOpacity(0.78)),
          ),
          const SizedBox(height: 6),
          Text(
            'Verteilung: 2er ${check.hitDistribution[2] ?? 0} • 3er ${check.hitDistribution[3] ?? 0} • 4er ${check.hitDistribution[4] ?? 0} • 5er ${check.hitDistribution[5] ?? 0} • 6er ${check.hitDistribution[6] ?? 0}',
            style: TextStyle(color: Colors.white.withOpacity(0.66), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
      ],
    );
  }
}

class _NumberWrap extends StatelessWidget {
  final List<int> numbers;

  const _NumberWrap({required this.numbers});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: numbers
          .map(
            (n) => Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            n.toString().padLeft(2, '0'),
            style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w900),
          ),
        ),
      )
          .toList(),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: child,
    );
  }
}


class _TrackingErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TrackingErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tracking konnte nicht geladen werden',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(color: Colors.white.withOpacity(0.72)),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Erneut laden'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 42),
          const SizedBox(height: 10),
          const Text(
            'Noch keine Tipps im Tracking',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Speichere Tipps zuerst in Meine Tipps. Für langfristige Statistik kannst du sie zusätzlich ins Tracking übernehmen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.68)),
          ),
        ],
      ),
    );
  }
}
