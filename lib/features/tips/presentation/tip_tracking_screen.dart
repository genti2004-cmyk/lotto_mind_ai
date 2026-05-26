import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../generator/domain/generator_strategy.dart';
import '../../generator/domain/tip_tracking_entry.dart';
import '../../generator/provider/lotto_app_state.dart';

class TipTrackingScreen extends StatefulWidget {
  const TipTrackingScreen({super.key});

  @override
  State<TipTrackingScreen> createState() => _TipTrackingScreenState();
}

class _TipTrackingScreenState extends State<TipTrackingScreen> {
  int _filter = 0;

  Future<void> _showMessage(String text) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        ),
      );
  }

  List<TipTrackingEntry> _filteredEntries(List<TipTrackingEntry> entries) {
    final sorted = List<TipTrackingEntry>.from(entries)
      ..sort((a, b) {
        final date = b.drawDate.compareTo(a.drawDate);
        if (date != 0) return date;
        final hit = b.hitCount.compareTo(a.hitCount);
        if (hit != 0) return hit;
        if (a.superHit != b.superHit) return a.superHit ? -1 : 1;
        return b.checkedAt.compareTo(a.checkedAt);
      });

    return switch (_filter) {
      1 => sorted.where((entry) => entry.isWinRelevant).toList(),
      2 => sorted.where((entry) => entry.hitCount >= 3).toList(),
      3 => sorted.where((entry) => entry.superHit).toList(),
      _ => sorted,
    };
  }

  Future<void> _refreshTracking() async {
    final state = context.read<LottoAppState>();
    if (state.selectedDrawForCheck == null) {
      await _showMessage('Bitte zuerst eine Prüf-Ziehung auswählen.');
      return;
    }
    if (state.savedTips.isEmpty) {
      await _showMessage('Keine gespeicherten Tipps vorhanden.');
      return;
    }

    await state.rebuildTipTrackingNow();
    await state.evaluateSavedTipsAgainstSelectedDraw();
    await _showMessage('Tracking aktualisiert und Auswertung erstellt.');
  }

  Future<void> _clearTracking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Treffer-Verlauf löschen'),
        content: const Text(
          'Soll der gespeicherte Treffer-Verlauf wirklich gelöscht werden? Deine Tipps bleiben erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirmed) return;
    await context.read<LottoAppState>().clearTipTracking();
    await _showMessage('Treffer-Verlauf gelöscht.');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final entries = state.tipTrackingEntries;
    final visibleEntries = _filteredEntries(entries);
    final distribution = _buildDistribution(entries);
    final stats = _TrackingStats.from(entries);
    final draw = state.selectedDrawForCheck;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Tracking Final'),
        actions: [
          IconButton(
            tooltip: 'Tracking aktualisieren',
            onPressed: _refreshTracking,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _HeroCard(
              stats: stats,
              selectedDrawLabel: draw == null ? 'Keine Prüf-Ziehung gewählt' : _dateLabel(draw.drawDate),
              savedTipCount: state.savedTips.length,
            ),
            const SizedBox(height: 14),
            _ActionPanel(
              selectedDrawLabel: draw == null ? 'Nicht gewählt' : _dateLabel(draw.drawDate),
              savedTipCount: state.savedTips.length,
              onRefresh: _refreshTracking,
              onClear: entries.isEmpty ? null : _clearTracking,
            ),
            const SizedBox(height: 14),
            _DistributionCard(distribution: distribution),
            const SizedBox(height: 14),
            _FilterTabs(
              index: _filter,
              onChanged: (value) => setState(() => _filter = value),
              total: entries.length,
              wins: stats.winRelevant,
              hits3Plus: stats.hits3Plus,
              superHits: stats.superHits,
            ),
            const SizedBox(height: 14),
            if (visibleEntries.isEmpty)
              _EmptyTrackingCard(hasEntries: entries.isNotEmpty)
            else
              ...visibleEntries.map(
                    (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TrackingEntryCard(entry: entry),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<int, int> _buildDistribution(List<TipTrackingEntry> entries) {
    final map = <int, int>{for (var i = 0; i <= 6; i++) i: 0};
    for (final entry in entries) {
      map[entry.hitCount] = (map[entry.hitCount] ?? 0) + 1;
    }
    return map;
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _TrackingStats {
  const _TrackingStats({
    required this.total,
    required this.bestHit,
    required this.averageHits,
    required this.winRelevant,
    required this.hits3Plus,
    required this.superHits,
    required this.distinctDraws,
  });

  final int total;
  final int bestHit;
  final double averageHits;
  final int winRelevant;
  final int hits3Plus;
  final int superHits;
  final int distinctDraws;

  factory _TrackingStats.from(List<TipTrackingEntry> entries) {
    if (entries.isEmpty) {
      return const _TrackingStats(
        total: 0,
        bestHit: 0,
        averageHits: 0,
        winRelevant: 0,
        hits3Plus: 0,
        superHits: 0,
        distinctDraws: 0,
      );
    }

    final totalHits = entries.fold<int>(0, (sum, entry) => sum + entry.hitCount);
    final best = entries.map((entry) => entry.hitCount).reduce((a, b) => a > b ? a : b);
    return _TrackingStats(
      total: entries.length,
      bestHit: best,
      averageHits: totalHits / entries.length,
      winRelevant: entries.where((entry) => entry.isWinRelevant).length,
      hits3Plus: entries.where((entry) => entry.hitCount >= 3).length,
      superHits: entries.where((entry) => entry.superHit).length,
      distinctDraws: entries.map((entry) => entry.drawId).toSet().length,
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.stats,
    required this.selectedDrawLabel,
    required this.savedTipCount,
  });

  final _TrackingStats stats;
  final String selectedDrawLabel;
  final int savedTipCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x260D47A1), blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.track_changes_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treffer-Tracking Final',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Eigene Tipps gegen Ziehungen prüfen und Verlauf behalten.',
                      style: TextStyle(color: Colors.white70, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(label: 'Prüfungen', value: '${stats.total}'),
              _HeroMetric(label: 'Ziehungen', value: '${stats.distinctDraws}'),
              _HeroMetric(label: 'Beste Treffer', value: '${stats.bestHit}'),
              _HeroMetric(label: 'Ø Treffer', value: stats.averageHits.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aktuelle Prüf-Ziehung: $selectedDrawLabel • Gespeicherte Tipps: $savedTipCount',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.selectedDrawLabel,
    required this.savedTipCount,
    required this.onRefresh,
    required this.onClear,
  });

  final String selectedDrawLabel;
  final int savedTipCount;
  final VoidCallback onRefresh;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prüfung', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Prüf-Ziehung: $selectedDrawLabel • Tipps: $savedTipCount',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Jetzt prüfen'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Verlauf löschen',
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.distribution});
  final Map<int, int> distribution;

  @override
  Widget build(BuildContext context) {
    final maxValue = distribution.values.fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 999999);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Treffer-Verteilung', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          for (var hits = 6; hits >= 0; hits--)
            _DistributionRow(
              label: '$hits Treffer',
              value: distribution[hits] ?? 0,
              maxValue: maxValue,
              highlight: hits >= 3,
            ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.highlight,
  });

  final String label;
  final int value;
  final int maxValue;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final factor = value / maxValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(height: 10, color: const Color(0xFFE9EEF7)),
                  FractionallySizedBox(
                    widthFactor: factor.clamp(0.0, 1.0),
                    child: Container(
                      height: 10,
                      color: highlight ? const Color(0xFF1565C0) : const Color(0xFF90A4AE),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.index,
    required this.onChanged,
    required this.total,
    required this.wins,
    required this.hits3Plus,
    required this.superHits,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final int total;
  final int wins;
  final int hits3Plus;
  final int superHits;

  @override
  Widget build(BuildContext context) {
    final items = <_FilterItem>[
      _FilterItem('Alle', total),
      _FilterItem('Gewinn', wins),
      _FilterItem('3+', hits3Plus),
      _FilterItem('Superzahl', superHits),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
              child: ChoiceChip(
                selected: index == i,
                onSelected: (_) => onChanged(i),
                label: Text('${items[i].label} ${items[i].count}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterItem {
  const _FilterItem(this.label, this.count);
  final String label;
  final int count;
}

class _TrackingEntryCard extends StatelessWidget {
  const _TrackingEntryCard({required this.entry});
  final TipTrackingEntry entry;

  @override
  Widget build(BuildContext context) {
    final isWin = entry.isWinRelevant;
    return _Panel(
      borderColor: isWin ? const Color(0xFF2E7D32).withOpacity(0.35) : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isWin ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isWin ? Icons.emoji_events_rounded : Icons.fact_check_rounded,
                  color: isWin ? const Color(0xFF2E7D32) : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.hitLabel} · ${entry.prizeClassLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ziehung ${entry.drawDateLabel} • ${entry.tipStrategy.label}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _HitBadge(count: entry.hitCount, superHit: entry.superHit),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Tipp', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _NumberWrap(numbers: entry.tipNumbers, matchedNumbers: entry.matchedNumbers),
          const SizedBox(height: 12),
          const Text('Ziehung', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _NumberWrap(numbers: entry.drawNumbers, matchedNumbers: entry.matchedNumbers),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Treffer', value: entry.matchedNumbers.isEmpty ? 'Keine' : entry.matchedNumbers.join(', ')),
              _InfoChip(label: 'Superzahl', value: entry.superHit ? 'richtig' : '${entry.tipSuperNumber ?? '-'} / ${entry.drawSuperNumber ?? '-'}'),
              _InfoChip(label: 'Modellwert', value: entry.estimatedPrizeLabel),
            ],
          ),
        ],
      ),
    );
  }

}

class _NumberWrap extends StatelessWidget {
  const _NumberWrap({required this.numbers, required this.matchedNumbers});
  final List<int> numbers;
  final List<int> matchedNumbers;

  @override
  Widget build(BuildContext context) {
    final matched = matchedNumbers.toSet();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: numbers.map((number) {
        final isMatched = matched.contains(number);
        return Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMatched ? const Color(0xFF2E7D32) : AppColors.primary,
            boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Text(
            number.toString().padLeft(2, '0'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
          ),
        );
      }).toList(),
    );
  }
}

class _HitBadge extends StatelessWidget {
  const _HitBadge({required this.count, required this.superHit});
  final int count;
  final bool superHit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: count >= 3 || superHit ? const Color(0xFFE8F5E9) : const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        superHit ? '$count + SZ' : '$count',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: count >= 3 || superHit ? const Color(0xFF2E7D32) : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
      ),
    );
  }
}

class _EmptyTrackingCard extends StatelessWidget {
  const _EmptyTrackingCard({required this.hasEntries});
  final bool hasEntries;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            hasEntries ? 'Keine Einträge für diesen Filter.' : 'Noch kein Tracking vorhanden.',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Wähle eine Prüf-Ziehung und tippe auf „Jetzt prüfen“. Danach bleibt der Verlauf erhalten.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.borderColor});
  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}
