import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/number_ball.dart';
import '../../../core/widgets/primary_button.dart';

import '../../generator/provider/lotto_app_state.dart';
import '../domain/tip_evaluation_result.dart';
import 'westlotto_submission_screen.dart';

import 'package:lotto_mind_ai/features/generator/domain/tip_tracking_entry.dart';
import 'package:lotto_mind_ai/features/draws/domain/draw_result.dart';
import 'package:lotto_mind_ai/features/draws/domain/draw_type.dart';
import 'package:lotto_mind_ai/features/generator/domain/lotto_tip.dart';

class MyTipsScreen extends StatefulWidget {
  const MyTipsScreen({super.key});

  @override
  State<MyTipsScreen> createState() => _MyTipsScreenState();
}

class _MyTipsScreenState extends State<MyTipsScreen> {
  final TextEditingController _searchController = TextEditingController();

  int _filterIndex = 0;
  String _searchText = '';
  final Set<String> _selectedTipIds = <String>{};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchText = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        ),
      );
  }

  List<LottoTip> _resolveTips(LottoAppState state) {
    final List<LottoTip> base = switch (_filterIndex) {
      1 => state.favoriteTips,
      2 => state.regularTips,
      _ => state.savedTips,
    };

    if (_searchText.isEmpty) return base;

    final query = _searchText.toLowerCase();
    return base.where((tip) {
      final numbersText = tip.numbers.join(' ');
      final superText = tip.superNumber?.toString() ?? '';
      final sourceText = _sourceLabel(tip.source).toLowerCase();
      final dateText = _formatDateTime(tip.createdAt).toLowerCase();
      final targetText = tip.targetLabel.toLowerCase();

      return numbersText.contains(query) ||
          superText.contains(query) ||
          sourceText.contains(query) ||
          targetText.contains(query) ||
          dateText.contains(query);
    }).toList();
  }

  List<LottoTip> _selectedTipsFromState(LottoAppState state) {
    return state.savedTips.where((tip) => _selectedTipIds.contains(tip.id)).toList();
  }

  void _toggleSelection(LottoTip tip) {
    setState(() {
      _selectionMode = true;
      if (_selectedTipIds.contains(tip.id)) {
        _selectedTipIds.remove(tip.id);
      } else {
        _selectedTipIds.add(tip.id);
      }
      if (_selectedTipIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTipIds.clear();
      _selectionMode = false;
    });
  }

  void _selectAll(List<LottoTip> tips) {
    setState(() {
      _selectionMode = true;
      _selectedTipIds
        ..clear()
        ..addAll(tips.map((e) => e.id));
    });
  }

  Future<void> _copyTip(LottoTip tip) async {
    final text = _buildPlainText([tip]);
    await Clipboard.setData(ClipboardData(text: text));
    await _showMessage('Tipp wurde kopiert.');
  }

  Future<void> _copySelected() async {
    final state = context.read<LottoAppState>();
    final tips = _selectedTipsFromState(state);
    if (tips.isEmpty) {
      await _showMessage('Keine Tipps ausgewählt.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: _buildPlainText(tips)));
    await _showMessage('Ausgewählte Tipps wurden kopiert.');
  }

  Future<void> _openWestlottoSubmission() async {
    final state = context.read<LottoAppState>();
    final tips = _selectedTipsFromState(state);
    if (tips.isEmpty) {
      await _showMessage('Keine Tipps ausgewählt.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: _buildPlainText(tips)));

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const WestlottoSubmissionScreen(),
      ),
    );
  }

  Future<void> _openSingleWestlottoSubmission(LottoTip tip) async {
    await Clipboard.setData(ClipboardData(text: _buildPlainText([tip])));

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const WestlottoSubmissionScreen(),
      ),
    );
  }

  Future<void> _applyTip(LottoTip tip) async {
    context.read<LottoAppState>().setGeneratedNumbers(
      tip.numbers,
      superNumber: tip.superNumber,
    );
    await _showMessage('Tipp wurde in den Generator übernommen.');
  }

  Future<void> _toggleFavorite(LottoTip tip) async {
    await context.read<LottoAppState>().toggleTipFavorite(tip.id);
    await _showMessage(
      tip.isFavorite ? 'Favorit entfernt.' : 'Als Favorit gespeichert.',
    );
  }

  Future<void> _deleteTip(LottoTip tip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tipp löschen'),
        content: Text(
          'Soll der Tipp ${tip.numbers.join(', ')} wirklich gelöscht werden?',
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

    await context.read<LottoAppState>().removeTip(tip.id);
    _selectedTipIds.remove(tip.id);
    if (_selectedTipIds.isEmpty) {
      _selectionMode = false;
    }

    if (mounted) setState(() {});
    await _showMessage('Tipp wurde gelöscht.');
  }

  Future<void> _deleteSelected() async {
    if (_selectedTipIds.isEmpty) {
      await _showMessage('Keine Tipps ausgewählt.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Auswahl löschen'),
        content: Text(
          'Sollen ${_selectedTipIds.length} ausgewählte Tipps wirklich gelöscht werden?',
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

    final state = context.read<LottoAppState>();
    final ids = _selectedTipIds.toList(growable: false);
    for (final id in ids) {
      await state.removeTip(id);
    }

    _clearSelection();
    await _showMessage('Ausgewählte Tipps gelöscht.');
  }

  String _buildPlainText(List<LottoTip> tips) {
    return tips.asMap().entries.map((entry) {
      final tip = entry.value;
      final superPart = tip.superNumber == null ? '' : ' | SZ: ${tip.superNumber}';
      return 'Tipp ${entry.key + 1}: ${tip.numbers.join(', ')}$superPart';
    }).join('\n');
  }

  Future<void> _checkAllSavedTipsPro() async {
    final state = context.read<LottoAppState>();
    final draw = state.selectedDrawForCheck;
    final results = await state.evaluateSavedTipsAgainstSelectedDraw();
    if (results.isEmpty) {
      if (draw == null) {
        await _showMessage('Keine Prüfung möglich: Bitte zuerst eine Prüf-Ziehung wählen.');
      } else if (state.savedTips.isEmpty) {
        await _showMessage('Keine Prüfung möglich: Es gibt noch keine gespeicherten Tipps.');
      } else {
        await _showMessage('Keine passende Prüfung: Nur Tipps mit passender Zielziehung werden ausgewertet.');
      }
      return;
    }
    final wins = results.where((result) => result.hasAnyWin).length;
    await _showMessage('Prüfung fertig: ${results.length} passende Tipp(s), $wins Gewinn-Treffer.');
  }

  Future<void> _checkCurrentSystemPro() async {
    final state = context.read<LottoAppState>();
    final result = await state.evaluateCurrentSystemAgainstSelectedDraw();
    if (result == null) {
      await _showMessage('Kein System oder keine Prüf-Ziehung vorhanden.');
      return;
    }
    await _showMessage(result.summaryLabel);
  }

  Future<void> _clearProResults() async {
    await context.read<LottoAppState>().clearTipEvaluationResults();
    await _showMessage('Auswertungsverlauf geleert.');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final filteredTips = _resolveTips(state);
    final draw = state.selectedDrawForCheck;
    final stats = _TipsStats.fromState(state);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Text(
            _selectionMode
                ? '${_selectedTipIds.length} ausgewählt'
                : 'Meine Tipps',
            key: ValueKey<String>(_selectionMode ? 'selection' : 'normal'),
          ),
        ),
        actions: [
          if (_selectionMode)
            IconButton(
              tooltip: 'Auswahl beenden',
              onPressed: _clearSelection,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _HeroPanel(
                    totalTips: stats.total,
                    favoriteTips: stats.favorites,
                    regularTips: stats.regular,
                    selectedTips: _selectedTipIds.length,
                    selectionMode: _selectionMode,
                    draw: draw,
                  ),
                  const SizedBox(height: 14),
                  _PhaseCProEvaluationPanel(
                    draw: draw,
                    normalTipCount: state.savedTips.length,
                    results: state.tipEvaluationResults,
                    onCheckAllNormal: draw == null || state.savedTips.isEmpty
                        ? null
                        : _checkAllSavedTipsPro,
                    onCheckSystem: draw == null ? null : _checkCurrentSystemPro,
                    onClear: state.tipEvaluationResults.isEmpty ? null : _clearProResults,
                  ),
                  const SizedBox(height: 14),
                  _SearchBar(controller: _searchController),
                  const SizedBox(height: 12),
                  _FilterTabs(
                    index: _filterIndex,
                    onChanged: (value) {
                      setState(() {
                        _filterIndex = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _BulkToolbar(
                    selectionMode: _selectionMode,
                    hasAnyVisibleTips: filteredTips.isNotEmpty,
                    allVisibleSelected: filteredTips.isNotEmpty &&
                        filteredTips.every((tip) => _selectedTipIds.contains(tip.id)),
                    selectedCount: _selectedTipIds.length,
                    onSelectAll: filteredTips.isEmpty ? null : () => _selectAll(filteredTips),
                    onClearSelection: _selectionMode ? _clearSelection : null,
                    onCopySelected:
                    _selectionMode && _selectedTipIds.isNotEmpty ? _copySelected : null,
                    onDeleteSelected:
                    _selectionMode && _selectedTipIds.isNotEmpty ? _deleteSelected : null,
                    onOpenWestlotto:
                    _selectionMode && _selectedTipIds.isNotEmpty ? _openWestlottoSubmission : null,
                  ),
                  const SizedBox(height: 14),
                  if (filteredTips.isEmpty)
                    _EmptyTipsState(hasAnyTips: state.savedTips.isNotEmpty)
                  else
                    ...filteredTips.map(
                          (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _TipTicketCard(
                          tip: tip,
                          sourceLabel: _sourceLabel(tip.source),
                          isSelected: _selectedTipIds.contains(tip.id),
                          selectionMode: _selectionMode,
                          hitCount: state.hitCountForTip(tip.id),
                          matchedNumbers: state.matchedNumbersForTip(tip.id),
                          evaluationResult: _latestResultForTip(tip, state.tipEvaluationResults),
                          canUseFavorites: state.gate.canUseFavorites,
                          onSelect: () => _toggleSelection(tip),
                          onCopy: () => _copyTip(tip),
                          onApply: () => _applyTip(tip),
                          onSubmit: () => _openSingleWestlottoSubmission(tip),
                          onDelete: () => _deleteTip(tip),
                          onToggleFavorite: state.gate.canUseFavorites
                              ? () => _toggleFavorite(tip)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PhaseCProEvaluationPanel extends StatelessWidget {
  const _PhaseCProEvaluationPanel({
    required this.draw,
    required this.normalTipCount,
    required this.results,
    required this.onCheckAllNormal,
    required this.onCheckSystem,
    required this.onClear,
  });

  final DrawResult? draw;
  final int normalTipCount;
  final List<TipEvaluationResult> results;
  final VoidCallback? onCheckAllNormal;
  final VoidCallback? onCheckSystem;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final latest = results.isEmpty ? null : results.first;
    final winCount = results.where((result) => result.hasAnyWin).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fact_check_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipps prüfen',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      draw == null
                          ? 'Bitte zuerst eine Prüf-Ziehung wählen.'
                          : 'Gespeicherte Tipps gegen ${_formatDate(draw!.drawDate)} prüfen.',
                      style: const TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProActionButton(
                icon: Icons.confirmation_number_rounded,
                label: 'Alle Normal-Tipps prüfen ($normalTipCount)',
                onTap: onCheckAllNormal,
              ),
              _ProActionButton(
                icon: Icons.account_tree_rounded,
                label: 'Systemtipps prüfen',
                onTap: onCheckSystem,
              ),
              _ProActionButton(
                icon: Icons.delete_sweep_rounded,
                label: 'Verlauf leeren',
                onTap: onClear,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (latest == null)
            const Text(
              'Noch keine Prüfung vorhanden. Nach der Prüfung siehst du hier die letzten Ergebnisse.',
              style: TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            )
          else ...[
            _ProResultSummary(result: latest, totalResults: results.length, winCount: winCount),
            const SizedBox(height: 10),
            ...results.take(3).map(
                  (result) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _MiniEvaluationTile(result: result),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProActionButton extends StatelessWidget {
  const _ProActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProResultSummary extends StatelessWidget {
  const _ProResultSummary({required this.result, required this.totalResults, required this.winCount});
  final TipEvaluationResult result;
  final int totalResults;
  final int winCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.hasAnyWin ? Colors.green.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: result.hasAnyWin ? Colors.green.withOpacity(0.25) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.summaryLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            '$totalResults Auswertung(en) · $winCount Gewinnsignal(e) · Modellwert ${result.totalEstimatedPrizeLabel} · Netto ${result.estimatedNetLabel} · ${result.spiel77.label} · ${result.super6.label}',
            style: const TextStyle(fontSize: 11, height: 1.35, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MiniEvaluationTile extends StatelessWidget {
  const _MiniEvaluationTile({required this.result});
  final TipEvaluationResult result;

  @override
  Widget build(BuildContext context) {
    final best = result.bestRow;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: result.hasAnyWin ? Colors.green.withOpacity(0.10) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              result.hasAnyWin ? Icons.emoji_events_rounded : Icons.analytics_rounded,
              size: 18,
              color: result.hasAnyWin ? Colors.green : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.playKind.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  best == null ? 'Keine Reihe' : '${best.hitLabel} · ${best.prizeClass.label} · ${best.estimatedPrizeLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, height: 1.25, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${result.totalRows}x', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const SizedBox(height: 2),
              Text(result.totalEstimatedPrizeLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipsStats {
  const _TipsStats({
    required this.total,
    required this.favorites,
    required this.regular,
  });

  final int total;
  final int favorites;
  final int regular;

  factory _TipsStats.fromState(LottoAppState state) {
    return _TipsStats(
      total: state.savedTips.length,
      favorites: state.favoriteTips.length,
      regular: state.regularTips.length,
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.totalTips,
    required this.favoriteTips,
    required this.regularTips,
    required this.selectedTips,
    required this.selectionMode,
    required this.draw,
  });

  final int totalTips;
  final int favoriteTips;
  final int regularTips;
  final int selectedTips;
  final bool selectionMode;
  final DrawResult? draw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: const Icon(
                  Icons.local_activity_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meine gespeicherten Tipps',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectionMode
                          ? '$selectedTips Tipps markiert • bereit für Kopie, Abgabe oder Löschen'
                          : 'Hier siehst du Zielziehung, Status und Treffer deiner gespeicherten Tipps.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.84),
                      ),
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
              _HeroStatChip(label: 'Gesamt', value: '$totalTips'),
              _HeroStatChip(label: 'Favoriten', value: '$favoriteTips'),
              _HeroStatChip(label: 'Normal', value: '$regularTips'),
              _HeroStatChip(
                label: 'Prüf-Ziehung',
                value: draw == null ? 'Keine' : _formatDate(draw!.drawDate),
                wide: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({
    required this.label,
    required this.value,
    this.wide = false,
  });

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: wide ? 150 : 92),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.76),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Suche nach Zahlen, Superzahl, Quelle oder Datum',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
            tooltip: 'Suche leeren',
            onPressed: controller.clear,
            icon: const Icon(Icons.close_rounded),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _FilterButton(
            label: 'Alle',
            selected: index == 0,
            onTap: () => onChanged(0),
          ),
          _FilterButton(
            label: 'Favoriten',
            selected: index == 1,
            onTap: () => onChanged(1),
          ),
          _FilterButton(
            label: 'Normal',
            selected: index == 2,
            onTap: () => onChanged(2),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])
                : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkToolbar extends StatelessWidget {
  const _BulkToolbar({
    required this.selectionMode,
    required this.hasAnyVisibleTips,
    required this.allVisibleSelected,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onCopySelected,
    required this.onDeleteSelected,
    required this.onOpenWestlotto,
  });

  final bool selectionMode;
  final bool hasAnyVisibleTips;
  final bool allVisibleSelected;
  final int selectedCount;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final VoidCallback? onCopySelected;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onOpenWestlotto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectionMode
                      ? '$selectedCount Tipps ausgewählt'
                      : 'Mehrere Tipps auswählen',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionPill(
                icon: allVisibleSelected ? Icons.checklist_rtl_rounded : Icons.select_all_rounded,
                label: allVisibleSelected ? 'Alle markiert' : 'Alle sichtbaren markieren',
                onTap: hasAnyVisibleTips ? onSelectAll : null,
                isPrimary: !selectionMode,
              ),
              _ActionPill(
                icon: Icons.copy_all_rounded,
                label: 'Auswahl kopieren',
                onTap: onCopySelected,
              ),
              _ActionPill(
                icon: Icons.open_in_browser_rounded,
                label: 'Zur Abgabe',
                onTap: onOpenWestlotto,
              ),
              _ActionPill(
                icon: Icons.delete_outline_rounded,
                label: 'Auswahl löschen',
                onTap: onDeleteSelected,
                destructive: true,
              ),
              if (selectionMode)
                _ActionPill(
                  icon: Icons.close_rounded,
                  label: 'Auswahl beenden',
                  onTap: onClearSelection,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final Color textColor = disabled
        ? AppColors.textMuted
        : destructive
        ? AppColors.danger
        : isPrimary
        ? Colors.white
        : AppColors.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: disabled || !isPrimary
              ? null
              : const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          color: disabled
              ? AppColors.surfaceSoft
              : destructive
              ? AppColors.dangerSoft
              : isPrimary
              ? null
              : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: destructive
                ? AppColors.danger.withOpacity(0.18)
                : disabled
                ? AppColors.border
                : isPrimary
                ? Colors.transparent
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


TipEvaluationResult? _latestResultForTip(
  LottoTip tip,
  List<TipEvaluationResult> results,
) {
  for (final result in results) {
    if (!_sameNumbers(tip.numbers, result.baseNumbers)) continue;
    if (tip.superNumber != result.superNumber) continue;
    return result;
  }
  return null;
}

bool _sameNumbers(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  final left = List<int>.from(a)..sort();
  final right = List<int>.from(b)..sort();
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

_TipStatus _buildTipStatus(LottoTip tip, TipEvaluationResult? result) {
  if (result != null) {
    final best = result.bestRow;
    final label = best == null
        ? 'Geprüft: keine Reihe gefunden'
        : best.prizeClass.isWin
            ? 'Geprüft: ${best.prizeClass.label}'
            : 'Geprüft: ${best.hitLabel}';
    return _TipStatus(
      icon: result.hasAnyWin ? Icons.emoji_events_rounded : Icons.fact_check_rounded,
      label: label,
      detail: 'Prüf-Ziehung: ${_formatDate(result.draw.drawDate)}',
      background: result.hasAnyWin ? AppColors.successSoft : AppColors.surfaceSoft,
      border: result.hasAnyWin ? AppColors.success.withOpacity(0.22) : AppColors.border,
      color: result.hasAnyWin ? AppColors.success : AppColors.textPrimary,
    );
  }

  if (tip.targetDrawType == DrawType.unknown) {
    return _TipStatus(
      icon: Icons.help_outline_rounded,
      label: 'Zielziehung offen',
      detail: 'Dieser Tipp ist älter oder noch keinem Mittwoch/Samstag zugeordnet.',
      background: AppColors.warningSoft,
      border: AppColors.warning.withOpacity(0.22),
      color: AppColors.warning,
    );
  }

  final targetDate = tip.targetDrawDate;
  if (targetDate == null) {
    return _TipStatus(
      icon: Icons.event_available_rounded,
      label: 'Ziel: ${tip.targetDrawType.label}',
      detail: 'Wähle eine passende ${tip.targetDrawType.label}-Ziehung für die Prüfung.',
      background: AppColors.infoSoft,
      border: AppColors.border,
      color: AppColors.primary,
    );
  }

  final today = DateUtils.dateOnly(DateTime.now());
  final targetDay = DateUtils.dateOnly(targetDate);
  if (targetDay.isAfter(today)) {
    return _TipStatus(
      icon: Icons.schedule_rounded,
      label: 'Wartet auf ${tip.targetDrawType.label}',
      detail: 'Gültig für ${_formatDate(targetDate)}. Prüfung erst nach der Ziehung.',
      background: AppColors.infoSoft,
      border: AppColors.border,
      color: AppColors.primary,
    );
  }

  return _TipStatus(
    icon: Icons.playlist_add_check_circle_rounded,
    label: 'Bereit zur Prüfung',
    detail: 'Passende ${tip.targetDrawType.label}-Ziehung wählen und prüfen.',
    background: AppColors.surfaceSoft,
    border: AppColors.border,
    color: AppColors.textPrimary,
  );
}

class _TipStatus {
  const _TipStatus({
    required this.icon,
    required this.label,
    required this.detail,
    required this.background,
    required this.border,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color background;
  final Color border;
  final Color color;
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final _TipStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(status.icon, size: 18, color: status.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: status.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.detail,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
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

class _TipTicketCard extends StatelessWidget {
  const _TipTicketCard({
    required this.tip,
    required this.sourceLabel,
    required this.isSelected,
    required this.selectionMode,
    required this.hitCount,
    required this.matchedNumbers,
    required this.evaluationResult,
    required this.canUseFavorites,
    required this.onSelect,
    required this.onCopy,
    required this.onApply,
    required this.onSubmit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  final LottoTip tip;
  final String sourceLabel;
  final bool isSelected;
  final bool selectionMode;
  final int hitCount;
  final List<int> matchedNumbers;
  final TipEvaluationResult? evaluationResult;
  final bool canUseFavorites;
  final VoidCallback onSelect;
  final VoidCallback onCopy;
  final VoidCallback onApply;
  final VoidCallback onSubmit;
  final VoidCallback onDelete;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final status = _buildTipStatus(tip, evaluationResult);

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onLongPress: onSelect,
      onTap: selectionMode ? onSelect : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFFEDF4FF), Color(0xFFF7FAFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [AppColors.surface, AppColors.surfaceSoft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    sourceLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                if (selectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onSelect(),
                  )
                else ...[
                  if (canUseFavorites)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onToggleFavorite,
                      icon: Icon(
                        tip.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        color: tip.isFavorite ? Colors.amber : AppColors.textSecondary,
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'copy':
                          onCopy();
                          break;
                        case 'apply':
                          onApply();
                          break;
                        case 'submit':
                          onSubmit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'copy', child: Text('Kopieren')),
                      PopupMenuItem(value: 'apply', child: Text('In Generator übernehmen')),
                      PopupMenuItem(value: 'submit', child: Text('Zur Abgabe vorbereiten')),
                      PopupMenuItem(value: 'delete', child: Text('Löschen')),
                    ],
                  ),
                ],
              ],
            ),
            Text(
              _formatDateTime(tip.createdAt),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_available_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    tip.targetLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _StatusBanner(status: status),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tip.numbers
                  .map((n) => NumberBall(number: n, highlighted: matchedNumbers.contains(n)))
                  .toList(),
            ),
            if (tip.superNumber != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.looks_one_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Superzahl ${tip.superNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InfoBadge(
                    icon: Icons.analytics_rounded,
                    label: evaluationResult == null ? 'Noch nicht geprüft' : '$hitCount Richtige',
                    valueColor: evaluationResult != null && hitCount >= 3 ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoBadge(
                    icon: Icons.track_changes_rounded,
                    label: evaluationResult == null
                        ? 'Treffer erscheinen nach Prüfung'
                        : (matchedNumbers.isEmpty ? 'Keine Zahl getroffen' : 'Treffer: ${matchedNumbers.join(', ')}'),
                  ),
                ),
              ],
            ),
            if (!selectionMode) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Übernehmen',
                      icon: Icons.playlist_add_check_circle_rounded,
                      onPressed: onApply,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Kopieren'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    this.valueColor = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTipsState extends StatelessWidget {
  const _EmptyTipsState({required this.hasAnyTips});

  final bool hasAnyTips;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasAnyTips
                ? 'Kein Tipp passt zu deiner Suche oder zum aktuellen Filter.'
                : 'Noch keine gespeicherten Tipps vorhanden.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasAnyTips
                ? 'Passe Suche oder Filter an, dann erscheinen wieder passende Tickets.'
                : 'Erstelle im Generator einen Tipp und speichere ihn. Danach erscheint er hier als Ticket.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _sourceLabel(String raw) {
  switch (raw) {
    case 'manual':
      return 'Manuell gespeichert';
    case 'analysis':
      return 'Analyse Tipp';
    case 'random':
      return 'Smart Generator';
    case 'ai':
      return 'AI Generator';
    default:
      if (raw.startsWith('voll_')) {
        return 'Vollsystem ${raw.replaceFirst('voll_', '')}';
      }
      if (raw.startsWith('vew_')) {
        return 'Intervall ${raw.replaceFirst('vew_', '')}';
      }
      return raw;
  }
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month.${value.year} • $hour:$minute';
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.${value.year}';
}
