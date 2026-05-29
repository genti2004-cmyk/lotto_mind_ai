import 'dart:ui';

import 'widgets/ai_learning_boost_control_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/widgets/number_ball.dart';
import '../../../core/widgets/primary_button.dart';
import '../../analysis/presentation/ai_max_mode_screen.dart';
import '../../analysis/domain/number_analysis_score.dart';
import '../../analysis/presentation/win_simulation_screen.dart';
import '../../draws/domain/draw_data_status.dart';
import '../../generator/provider/lotto_app_state.dart';
import '../../generator/domain/generator_strategy.dart';
import '../../generator/services/ai_master_mode_service.dart';
import '../../system/presentation/system_generator_screen.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  int _tabIndex = 0;
  final Set<int> _visitedTabs = <int>{0};
  bool _showAnalysisDetails = false;
  bool _showProDetails = false;

  void _goToTab(int index) {
    if (_tabIndex == index) return;
    setState(() {
      _tabIndex = index;
      _visitedTabs.add(index);
    });
  }

  void _toggleAnalysisDetails() {
    setState(() {
      _showAnalysisDetails = !_showAnalysisDetails;
    });
  }

  void _toggleProDetails() {
    setState(() {
      _showProDetails = !_showProDetails;
    });
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _generateRandom() async {
    await context.read<LottoAppState>().generateRandomTip();
    await _showMessage('Zufallstipp wurde erstellt.');
  }

  Future<void> _saveLastTip() async {
    final state = context.read<LottoAppState>();
    await state.saveLastTip(
      source: _sourceForCurrentStrategy(state.lastGeneratedStrategy),
      strategy: state.lastGeneratedStrategy == GeneratorStrategy.unknown
          ? _strategyForCurrentTab()
          : state.lastGeneratedStrategy,
    );
    await _showMessage('Tipp wurde gespeichert.');
  }

  Future<void> _generateAnalysis() async {
    try {
      await context.read<LottoAppState>().generateAnalysisTip(
        strategy: _tabIndex == 2 ? GeneratorStrategy.pro : GeneratorStrategy.analysis,
      );
      await _showMessage(_tabIndex == 2 ? 'Pro-Tipp wurde erstellt.' : 'Analyse-Tipp wurde erstellt.');
    } catch (e) {
      await _showMessage(e.toString());
    }
  }

  Future<void> _generateSignalTip() async {
    try {
      await context.read<LottoAppState>().generateSignalTip();
      await _showMessage('Signal-Tipp wurde erstellt.');
    } catch (e) {
      await _showMessage(e.toString());
    }
  }

  Future<void> _applyBestTip() async {
    final state = context.read<LottoAppState>();
    await state.applyBestAnalyzedTip();
    await state.saveLastTip(source: 'analysis_pro', strategy: GeneratorStrategy.pro);
    await _showMessage('Pro-Tipp wurde übernommen und in Meine Tipps gespeichert.');
  }

  Future<void> _copyLastTip() async {
    final state = context.read<LottoAppState>();
    final tip = state.lastGeneratedTip;
    final superNumber = state.lastGeneratedSuperNumber;

    if (tip == null || tip.isEmpty) {
      await _showMessage('Noch kein Tipp vorhanden.');
      return;
    }

    final text = superNumber == null
        ? tip.join(', ')
        : '${tip.join(', ')} | SZ: $superNumber';

    await Clipboard.setData(ClipboardData(text: text));
    await _showMessage('Tipp wurde kopiert.');
  }


  GeneratorStrategy _strategyForCurrentTab() {
    switch (_tabIndex) {
      case 0:
        return GeneratorStrategy.basis;
      case 1:
        return GeneratorStrategy.analysis;
      case 2:
        return GeneratorStrategy.pro;
      case 3:
        return GeneratorStrategy.system;
      default:
        return GeneratorStrategy.unknown;
    }
  }

  String _sourceForCurrentStrategy(GeneratorStrategy strategy) {
    switch (strategy) {
      case GeneratorStrategy.basis:
        return 'basis';
      case GeneratorStrategy.analysis:
        return 'analysis';
      case GeneratorStrategy.signal:
        return 'signal';
      case GeneratorStrategy.pro:
        return 'analysis_pro';
      case GeneratorStrategy.system:
        return 'system';
      case GeneratorStrategy.manual:
        return 'manual';
      default:
        return _strategyForCurrentTab().name;
    }
  }

  String _currentModeLabel() {
    switch (_tabIndex) {
      case 0:
        return 'Basis';
      case 1:
        return 'Analyse';
      case 2:
        return 'Pro';
      case 3:
        return 'System';
      default:
        return 'Analyse';
    }
  }

  Widget _buildTabContent(LottoAppState state) {
    final currentTip = _CurrentTipPanel(
      state: state,
      onSave: state.lastGeneratedTip == null ? null : _saveLastTip,
      onCopy: state.lastGeneratedTip == null ? null : _copyLastTip,
    );

    switch (_tabIndex) {
      case 0:
        return _TabScrollView(
          child: _NormalPanel(
            state: state,
            onGenerate: _generateRandom,
            onSave: state.lastGeneratedTip == null ? null : _saveLastTip,
            onCopy: state.lastGeneratedTip == null ? null : _copyLastTip,
          ),
          currentTip: currentTip,
        );
      case 1:
        return _TabScrollView(
          child: _AiPanel(
            state: state,
            onGenerate: _generateAnalysis,
            onGenerateSignal: _generateSignalTip,
            onApplyBest: state.bestAnalyzedTip.length == 6 ? _applyBestTip : null,
            showDetails: _showAnalysisDetails,
            onToggleDetails: _toggleAnalysisDetails,
          ),
          currentTip: currentTip,
        );
      case 2:
        return _TabScrollView(
          child: _JackpotPanel(
            state: state,
            onGenerate: _generateAnalysis,
            onApplyBest: state.bestAnalyzedTip.length == 6 ? _applyBestTip : null,
            showDetails: _showProDetails,
            onToggleDetails: _toggleProDetails,
          ),
          currentTip: currentTip,
        );
      case 3:
        return _TabScrollView(
          child: _SystemEntryPanel(state: state),
          currentTip: currentTip,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final summary = state.analysisSummary;
    final dataStatus = DrawDataStatus.fromDraws(state.drawResults);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFF), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  primary: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    _HeroHeader(
                      state: state,
                      summary: summary,
                    ),
                    const SizedBox(height: 16),
                    _MetricsGrid(
                      cards: [
                        _MetricData(
                          title: 'Ziehungen',
                          value: '${summary.drawCount}',
                          icon: Icons.dataset_rounded,
                        ),
                        _MetricData(
                          title: 'Zielziehung',
                          value: state.analysisDrawFilterLabel,
                          icon: Icons.event_available_rounded,
                        ),
                        _MetricData(
                          title: '1. Strategie verstehen',
                          value: _currentModeLabel(),
                          icon: Icons.route_rounded,
                        ),
                        _MetricData(
                          title: 'Datenfenster',
                          value: state.analysisWindowLabel,
                          icon: Icons.calendar_view_week_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _GeneratorDataStatusCard(dataStatus: dataStatus),
                    const SizedBox(height: 12),
                    _ModeTabs(
                      index: _tabIndex,
                      onChanged: _goToTab,
                    ),
                    const SizedBox(height: 12),
                    _GeneratorFlowGuide(
                      modeLabel: _currentModeLabel(),
                      targetLabel: state.analysisDrawFilterLabel,
                      hasCurrentTip: state.lastGeneratedTip != null &&
                          state.lastGeneratedTip!.isNotEmpty,
                    ),
                    const SizedBox(height: 12),
                    _StrategyChoiceGuide(index: _tabIndex),
                    const SizedBox(height: 16),
                    RepaintBoundary(
                      key: ValueKey<int>(_tabIndex),
                      child: _visitedTabs.contains(_tabIndex)
                          ? _buildTabContent(state)
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                    _GeneratorPdfExportButton(
                      state: state,
                      modeLabel: _currentModeLabel(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _GeneratorDataStatusCard extends StatelessWidget {
  final DrawDataStatus dataStatus;

  const _GeneratorDataStatusCard({required this.dataStatus});

  @override
  Widget build(BuildContext context) {
    final color = dataStatus.hasCurrentCoreData ? AppColors.success : AppColors.warning;
    final icon = dataStatus.hasCurrentCoreData
        ? Icons.verified_rounded
        : Icons.info_outline_rounded;

    return _SubCard(
      title: 'Datenbasis für den Generator',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dataStatus.title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dataStatus.analysisBaseLabel} • Pflichtdaten: ${dataStatus.coreDataLabel} • Zusatzdaten: ${dataStatus.additionalDataLabel}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _GeneratorPdfExportButton extends StatelessWidget {
  final LottoAppState state;
  final String modeLabel;

  const _GeneratorPdfExportButton({
    required this.state,
    required this.modeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final lastTip = state.lastGeneratedTip;
    final numbers = (lastTip != null && lastTip.isNotEmpty)
        ? List<int>.from(lastTip)
        : List<int>.from(state.bestAnalyzedTip);
    final hasNumbers = numbers.isNotEmpty;

    return _SubCard(
      title: 'PDF Export',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineInfo(
            label: 'Basis',
            value: hasNumbers ? numbers.join(' • ') : 'Noch kein Tipp vorhanden',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !hasNumbers
                  ? null
                  : () {
                PdfExportService.generateAnalysisPdf(
                  numbers: numbers,
                  systemType: modeLabel,
                  profile: state.analysisProfileLabel,
                  drawDay: state.analysisDrawFilterLabel,
                  drawCount: state.analysisDrawCount,
                  roi: 0,
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('PDF Export öffnen'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final IconData icon;

  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _HeroHeader extends StatelessWidget {
  final LottoAppState state;
  final AnalysisSummary summary;

  const _HeroHeader({
    required this.state,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                const Color(0xFFF2F7FF).withOpacity(0.86),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.72)),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 26,
                offset: Offset(0, 14),
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
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x262563EB),
                          blurRadius: 14,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lotto Mind AI',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Erstelle Tipps in einem klaren Ablauf: Ziel wählen, Strategie nutzen, Tipp speichern und später prüfen.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.textSecondary.withOpacity(0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _HighlightStrip(
                items: [
                  _HighlightItem(
                    icon: Icons.timeline_rounded,
                    title: 'Zeitraum',
                    value: state.analysisWindowLabel,
                  ),
                  _HighlightItem(
                    icon: Icons.bolt_rounded,
                    title: 'Heißeste Zahlen',
                    value: summary.hotNumbers.isEmpty
                        ? '-'
                        : summary.hotNumbers
                        .take(3)
                        .map((e) => e.number.toString().padLeft(2, '0'))
                        .join(' • '),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightItem {
  final IconData icon;
  final String title;
  final String value;

  const _HighlightItem({
    required this.icon,
    required this.title,
    required this.value,
  });
}

class _HighlightStrip extends StatelessWidget {
  final List<_HighlightItem> items;

  const _HighlightStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
          padding: EdgeInsets.only(bottom: item == items.last ? 0 : 10),
          child: Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final List<_MetricData> cards;

  const _MetricsGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900
            ? 4
            : width >= 620
            ? 2
            : 2;
        final itemWidth = (width - ((crossAxisCount - 1) * 12)) / crossAxisCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(
              width: itemWidth,
              child: _MetricCard(data: card),
            ),
          )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}


class _GeneratorFlowGuide extends StatelessWidget {
  final String modeLabel;
  final String targetLabel;
  final bool hasCurrentTip;

  const _GeneratorFlowGuide({
    required this.modeLabel,
    required this.targetLabel,
    required this.hasCurrentTip,
  });

  @override
  Widget build(BuildContext context) {
    return _SubCard(
      title: 'So funktioniert der Generator',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FlowStep(
            number: '1',
            title: 'Ziel wählen',
            text: targetLabel == 'Alle'
                ? 'Wähle im Analyse-Modus Mittwoch oder Samstag, wenn der Tipp eindeutig zugeordnet werden soll.'
                : 'Aktuelle Zielauswahl: $targetLabel.',
          ),
          const SizedBox(height: 10),
          _FlowStep(
            number: '2',
            title: 'Strategie nutzen',
            text: 'Aktueller Bereich: $modeLabel.',
          ),
          const SizedBox(height: 10),
          _FlowStep(
            number: '3',
            title: 'Tipp speichern',
            text: hasCurrentTip
                ? 'Ein Tipp ist vorhanden. Speichere ihn in Meine Tipps, damit er später geprüft wird.'
                : 'Erzeuge zuerst einen Tipp. Danach erscheint er unten als aktueller Tipp.',
          ),
        ],
      ),
    );
  }
}


class _StrategyChoiceGuide extends StatelessWidget {
  final int index;

  const _StrategyChoiceGuide({required this.index});

  String get _title {
    switch (index) {
      case 0:
        return 'Strategie: Basis';
      case 1:
        return 'Strategie: Analyse / Signal';
      case 2:
        return 'Strategie: Pro';
      case 3:
        return 'Strategie: System';
      default:
        return 'Strategie wählen';
    }
  }

  IconData get _icon {
    switch (index) {
      case 0:
        return Icons.casino_rounded;
      case 1:
        return Icons.psychology_alt_rounded;
      case 2:
        return Icons.local_fire_department_rounded;
      case 3:
        return Icons.grid_view_rounded;
      default:
        return Icons.route_rounded;
    }
  }

  String get _description {
    switch (index) {
      case 0:
        return 'Schneller Einstieg für einen einfachen, ausgewogenen Tipp.';
      case 1:
        return 'Musteranalyse aus Häufigkeit, Rückstand, Intervall und Streuung.';
      case 2:
        return 'Erweiterte Kandidaten, Details und Simulationen für Strategievergleich.';
      case 3:
        return 'Mehrere Reihen beziehungsweise Systemschein statt einzelner Reihe.';
      default:
        return 'Strategie wählen, Tipp erzeugen und in Meine Tipps speichern.';
    }
  }

  String get _bestFor {
    switch (index) {
      case 0:
        return 'direkt loslegen';
      case 1:
        return 'nachvollziehbare Signale';
      case 2:
        return 'Expertenprüfung';
      case 3:
        return 'mehrere Reihen';
      default:
        return 'Tipp-Erstellung';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Am besten: $_bestFor',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
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

class _FlowStep extends StatelessWidget {
  final String number;
  final String title;
  final String text;

  const _FlowStep({
    required this.number,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeTabItem {
  final String label;
  final IconData icon;

  const _ModeTabItem({
    required this.label,
    required this.icon,
  });
}

class _ModeTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _ModeTabs({
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _ModeTabItem(label: 'Basis', icon: Icons.casino_rounded),
      _ModeTabItem(label: 'Analyse', icon: Icons.psychology_alt_rounded),
      _ModeTabItem(label: 'Pro', icon: Icons.local_fire_department_rounded),
      _ModeTabItem(label: 'System', icon: Icons.grid_view_rounded),
    ];

    return Row(
      children: List.generate(items.length, (i) {
        final selected = i == index;
        final item = items[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  )
                      : null,
                  color: selected ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? Colors.transparent : AppColors.border,
                  ),
                  boxShadow: selected
                      ? const [
                    BoxShadow(
                      color: Color(0x1F2563EB),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ]
                      : const [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 17,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _TabScrollView extends StatelessWidget {
  final Widget child;
  final Widget currentTip;

  const _TabScrollView({
    required this.child,
    required this.currentTip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const SizedBox(height: 14),
        currentTip,
        const SizedBox(height: 10),
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PanelCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SubCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SubCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _NormalPanel extends StatelessWidget {
  final LottoAppState state;
  final Future<void> Function() onGenerate;
  final Future<void> Function()? onSave;
  final Future<void> Function()? onCopy;

  const _NormalPanel({
    required this.state,
    required this.onGenerate,
    required this.onSave,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final lastTip = state.lastGeneratedTip;

    return _PanelCard(
      title: 'Basis-Tipp',
      subtitle: 'Basis ist der einfache Einstieg: schnell erzeugen, direkt speichern, ohne Expertenwerte.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubCard(
            title: '1. Tipp erzeugen',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Der Basis-Tipp nutzt keine Expertenlogik. Er ist ideal zum schnellen Start und kann danach direkt in Meine Tipps gespeichert werden.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Zufallstipp generieren',
                  icon: Icons.casino_rounded,
                  onPressed: onGenerate,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 180,
                      child: PrimaryButton(
                        label: 'In Meine Tipps speichern',
                        icon: Icons.bookmark_add_rounded,
                        onPressed: onSave,
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: OutlinedButton.icon(
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Kopieren'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SubCard(
            title: '2. Aktueller Stand',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InlineInfo(
                  label: 'Strategie',
                  value: 'Basis',
                ),
                const SizedBox(height: 6),
                _InlineInfo(
                  label: 'Letzter Tipp',
                  value: lastTip == null || lastTip.isEmpty
                      ? '-'
                      : lastTip.join(' • '),
                ),
                const SizedBox(height: 6),
                _InlineInfo(
                  label: 'Superzahl',
                  value: state.lastGeneratedSuperNumber?.toString() ?? '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _MasterModeCard extends StatelessWidget {
  final LottoAppState state;

  const _MasterModeCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final recommendation = state.aiMasterRecommendation;
    final appState = context.read<LottoAppState>();

    return _SubCard(
      title: 'Master Mode',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChoiceButton(
                label: 'Aus',
                selected: state.aiMasterMode == AiMasterMode.off,
                onTap: () => appState.setAiMasterMode(AiMasterMode.off),
              ),
              _ChoiceButton(
                label: 'Auto',
                selected: state.aiMasterMode == AiMasterMode.autoBalanced,
                onTap: () => appState.setAiMasterMode(AiMasterMode.autoBalanced),
              ),
              _ChoiceButton(
                label: 'Trend',
                selected: state.aiMasterMode == AiMasterMode.trend,
                onTap: () => appState.setAiMasterMode(AiMasterMode.trend),
              ),
              _ChoiceButton(
                label: 'Rebound',
                selected: state.aiMasterMode == AiMasterMode.rebound,
                onTap: () => appState.setAiMasterMode(AiMasterMode.rebound),
              ),
              _ChoiceButton(
                label: 'Jackpot',
                selected: state.aiMasterMode == AiMasterMode.jackpot,
                onTap: () => appState.setAiMasterMode(AiMasterMode.jackpot),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InlineInfo(label: 'Strategie', value: recommendation.strategyLabel),
          const SizedBox(height: 6),
          _InlineInfo(label: 'Ziel-Fenster', value: '${recommendation.drawCount} Ziehungen'),
          const SizedBox(height: 6),
          _InlineInfo(label: 'Master-Qualität', value: recommendation.confidenceLabel),
          const SizedBox(height: 10),
          Text(
            recommendation.reasoning,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (state.isAiMasterModeEnabled) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => appState.applyAiMasterModeNow(),
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Master jetzt anwenden'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiPanel extends StatelessWidget {
  final LottoAppState state;
  final Future<void> Function() onGenerate;
  final Future<void> Function() onGenerateSignal;
  final Future<void> Function()? onApplyBest;
  final bool showDetails;
  final VoidCallback onToggleDetails;

  const _AiPanel({
    required this.state,
    required this.onGenerate,
    required this.onGenerateSignal,
    required this.onApplyBest,
    required this.showDetails,
    required this.onToggleDetails,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Analyse-Tipp',
      subtitle: 'Analyse und Signal nutzen historische Muster wie Häufigkeit, Rückstand, Intervall, Bereiche und Abstände.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubCard(
            title: '1. Ziel und Datenfenster wählen',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ControlLabel('Ziehungstag'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChoiceButton(
                      label: 'Beide',
                      selected:
                      state.analysisDrawFilter == AnalysisDrawFilter.all,
                      onTap: () => context
                          .read<LottoAppState>()
                          .setAnalysisDrawFilter(AnalysisDrawFilter.all),
                    ),
                    _ChoiceButton(
                      label: 'Mittwoch',
                      selected: state.analysisDrawFilter ==
                          AnalysisDrawFilter.wednesday,
                      onTap: () => context
                          .read<LottoAppState>()
                          .setAnalysisDrawFilter(AnalysisDrawFilter.wednesday),
                    ),
                    _ChoiceButton(
                      label: 'Samstag',
                      selected: state.analysisDrawFilter ==
                          AnalysisDrawFilter.saturday,
                      onTap: () => context
                          .read<LottoAppState>()
                          .setAnalysisDrawFilter(AnalysisDrawFilter.saturday),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _ControlLabel('Analyse-Ziehungen'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StepButton(
                      label: '-10',
                      onTap: () {
                        final s = context.read<LottoAppState>();
                        final next = s.analysisDrawCount - 10 < 1
                            ? 1
                            : s.analysisDrawCount - 10;
                        s.setAnalysisDrawCount(next);
                      },
                    ),
                    _StepButton(
                      label: '-1',
                      onTap: () {
                        final s = context.read<LottoAppState>();
                        final next = s.analysisDrawCount - 1 < 1
                            ? 1
                            : s.analysisDrawCount - 1;
                        s.setAnalysisDrawCount(next);
                      },
                    ),
                    SizedBox(
                      width: 220,
                      child: Builder(
                        builder: (context) {
                          final maxCount = state.maxAnalysisDrawCount < 1
                              ? 1
                              : state.maxAnalysisDrawCount;
                          final safeValue = state.analysisDrawCount
                              .clamp(1, maxCount)
                              .toDouble();
                          final canSlide = maxCount > 1;

                          if (!canSlide) {
                            return Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.border,
                                ),
                              ),
                              child: const Text(
                                'Zu wenig Ziehungen',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          return Slider(
                            value: safeValue,
                            min: 1,
                            max: maxCount.toDouble(),
                            divisions: maxCount - 1,
                            label: safeValue.round().toString(),
                            onChanged: (value) {
                              context
                                  .read<LottoAppState>()
                                  .setAnalysisDrawCount(value.round());
                            },
                          );
                        },
                      ),
                    ),
                    _StepButton(
                      label: '+1',
                      onTap: () {
                        final s = context.read<LottoAppState>();
                        final next = s.analysisDrawCount + 1 >
                            s.maxAnalysisDrawCount
                            ? s.maxAnalysisDrawCount
                            : s.analysisDrawCount + 1;
                        s.setAnalysisDrawCount(next);
                      },
                    ),
                    _StepButton(
                      label: '+10',
                      onTap: () {
                        final s = context.read<LottoAppState>();
                        final next = s.analysisDrawCount + 10 >
                            s.maxAnalysisDrawCount
                            ? s.maxAnalysisDrawCount
                            : s.analysisDrawCount + 10;
                        s.setAnalysisDrawCount(next);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 180,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<LottoAppState>().setAnalysisToRecent52();
                        },
                        icon: const Icon(Icons.history_rounded),
                        label: const Text('Letzte 52'),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<LottoAppState>().setAnalysisToAllHistory();
                        },
                        icon: const Icon(Icons.all_inclusive_rounded),
                        label: const Text('Komplett'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _ControlLabel('Profil'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChoiceButton(
                      label: 'Defensiv',
                      selected:
                      state.analysisProfile == AnalysisProfile.defensive,
                      onTap: () => context
                          .read<LottoAppState>()
                          .setAnalysisProfile(AnalysisProfile.defensive),
                    ),
                    _ChoiceButton(
                      label: 'Mittel',
                      selected:
                      state.analysisProfile == AnalysisProfile.balanced,
                      onTap: () => context
                          .read<LottoAppState>()
                          .setAnalysisProfile(AnalysisProfile.balanced),
                    ),
                    _ChoiceButton(
                      label: 'Aggressiv',
                      selected:
                      state.analysisProfile == AnalysisProfile.aggressive,
                      onTap: () => context
                          .read<LottoAppState>()
                          .setAnalysisProfile(AnalysisProfile.aggressive),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _InlineInfo(label: 'Fenster', value: state.analysisWindowLabel),
                const SizedBox(height: 6),
                _InlineInfo(
                  label: 'Ziehungen',
                  value: '${state.analysisDrawCount}',
                ),
                const SizedBox(height: 6),
                _InlineInfo(
                  label: 'Qualität',
                  value: state.analysisStrengthLabel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _MasterModeCard(state: state),

          const SizedBox(height: 14),
          AiLearningBoostControlCard(state: state),

          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Analyse-Tipp berechnen',
            icon: Icons.auto_awesome_rounded,
            onPressed: onGenerate,
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Signal-Tipp berechnen',
            icon: Icons.insights_rounded,
            onPressed: onGenerateSignal,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 180,
                child: PrimaryButton(
                  label: 'Expertenanalyse',
                  icon: Icons.psychology_alt_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AiMaxModeScreen(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: PrimaryButton(
                  label: 'Simulation',
                  icon: Icons.query_stats_rounded,
                  compact: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WinSimulationScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailsToggleCard(
            title: 'Details & Erklärung',
            text: showDetails
                ? 'Signalmodell, Modell-Hinweise und Rücktest-Details ausblenden.'
                : 'Signalmodell, Modell-Hinweise und Rücktest-Details erst bei Bedarf laden.',
            expanded: showDetails,
            onPressed: onToggleDetails,
          ),
          if (showDetails) ...[
            const SizedBox(height: 14),
            _AiDetailsPanel(
              state: state,
              onApplyBest: onApplyBest,
            ),
          ],
        ],
      ),
    );
  }
}


class _DetailsToggleCard extends StatelessWidget {
  final String title;
  final String text;
  final bool expanded;
  final VoidCallback onPressed;

  const _DetailsToggleCard({
    required this.title,
    required this.text,
    required this.expanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _SubCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            label: Text(expanded ? 'Details ausblenden' : 'Details anzeigen'),
          ),
        ],
      ),
    );
  }
}

class _AiDetailsPanel extends StatelessWidget {
  final LottoAppState state;
  final Future<void> Function()? onApplyBest;

  const _AiDetailsPanel({
    required this.state,
    required this.onApplyBest,
  });

  @override
  Widget build(BuildContext context) {
    final ai = state.analysisAiSummary;
    final bestTip = state.bestAnalyzedTip;
    final signalNumbers = state.signalTipNumbers;
    final signalScores = state.signalScores(limit: 6);
    final lastSimulation = state.bestCurrentTipWindow?.summary;
    final bestSimulation = state.bestAiTipWindow?.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SubCard(
          title: '2. Signalmodell',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Der Signal-Tipp kombiniert Häufigkeit, Rückstand, Intervall und einfache Muster. Er zeigt auffällige Zahlen aus vergangenen Ziehungen und ist keine sichere Vorhersage.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _BallRow(title: 'Signal-Tipp', numbers: signalNumbers),
              const SizedBox(height: 12),
              _SignalReasonList(scores: signalScores),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SubCard(
          title: '3. Modell-Hinweise',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InlineInfo(label: 'Titel', value: ai.title),
              const SizedBox(height: 6),
              _InlineInfo(label: 'Sicherheit', value: ai.confidence),
              const SizedBox(height: 12),
              _ConfidenceBar(confidenceText: ai.confidence),
              const SizedBox(height: 12),
              _BallRow(title: 'Empfohlen', numbers: ai.recommendedNumbers),
              const SizedBox(height: 12),
              _BallRow(title: 'Eher meiden', numbers: ai.avoidNumbers),
              const SizedBox(height: 12),
              Text(
                ai.reasoning,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SubCard(
          title: '4. Tipp übernehmen',
          child: bestTip.length != 6
              ? const Text(
                  'Noch kein Pro-Tipp verfügbar.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BallRow(title: 'Bester Tipp', numbers: bestTip),
                    if (bestSimulation != null) ...[
                      const SizedBox(height: 12),
                      _SimulationSummaryCard(
                        title: 'Rücktest Pro',
                        simulation: bestSimulation,
                      ),
                    ],
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Analyse-Tipp übernehmen',
                      icon: Icons.download_done_rounded,
                      onPressed: onApplyBest,
                    ),
                    if (lastSimulation != null) ...[
                      const SizedBox(height: 12),
                      _SimulationSummaryCard(
                        title: 'Rücktest aktueller Tipp',
                        simulation: lastSimulation,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProDetailsPanel extends StatelessWidget {
  final LottoAppState state;
  final Future<void> Function()? onApplyBest;

  const _ProDetailsPanel({
    required this.state,
    required this.onApplyBest,
  });

  @override
  Widget build(BuildContext context) {
    if (state.bestAnalyzedTip.length != 6) {
      return const _SubCard(
        title: 'Pro-Kandidat',
        child: Text(
          'Noch kein Pro-Tipp verfügbar. Berechne zuerst einen Pro-Tipp.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return _SubCard(
      title: 'Pro-Kandidat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BallRow(
            title: 'Pro-Kandidat',
            numbers: state.bestAnalyzedTip,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Kandidaten übernehmen',
            icon: Icons.download_done_rounded,
            onPressed: onApplyBest,
          ),
        ],
      ),
    );
  }
}

class _JackpotPanel extends StatelessWidget {
  final LottoAppState state;
  final Future<void> Function() onGenerate;
  final Future<void> Function()? onApplyBest;
  final bool showDetails;
  final VoidCallback onToggleDetails;

  const _JackpotPanel({
    required this.state,
    required this.onGenerate,
    required this.onApplyBest,
    required this.showDetails,
    required this.onToggleDetails,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Pro-Strategie',
      subtitle: 'Pro ist der Expertenbereich für Kandidaten, Simulationen und detailliertere Strategiearbeit.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _JackpotModeInfo(),
          const SizedBox(height: 14),
          _SubCard(
            title: 'Strategie',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diese Ansicht nutzt denselben stabilen Analysekern, zeigt aber bewusst mehr Expertenfunktionen und Simulationen.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _InlineInfo(
                  label: 'Strategie',
                  value: 'Analyse + Simulation',
                ),
                const SizedBox(height: 6),
                _InlineInfo(
                  label: 'Ziel',
                  value: 'Pro-Variante mit mehr Details',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Pro-Tipp berechnen',
            icon: Icons.local_fire_department_rounded,
            onPressed: onGenerate,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 180,
                child: PrimaryButton(
                  label: 'Expertenanalyse öffnen',
                  icon: Icons.bolt_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AiMaxModeScreen(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: PrimaryButton(
                  label: 'Simulation',
                  icon: Icons.query_stats_rounded,
                  compact: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WinSimulationScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailsToggleCard(
            title: 'Pro-Details',
            text: showDetails
                ? 'Pro-Kandidat und weitere Details ausblenden.'
                : 'Pro-Kandidat erst anzeigen, wenn du ihn wirklich brauchst.',
            expanded: showDetails,
            onPressed: onToggleDetails,
          ),
          if (showDetails) ...[
            const SizedBox(height: 14),
            _ProDetailsPanel(
              state: state,
              onApplyBest: onApplyBest,
            ),
          ],
        ],
      ),
    );
  }
}

class _SystemEntryPanel extends StatelessWidget {
  final LottoAppState state;

  const _SystemEntryPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Systemspiele',
      subtitle: 'System ist für mehrere Reihen und strukturierte Spielvarianten gedacht.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubCard(
            title: 'Aktueller Stand',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InlineInfo(label: 'Systemart', value: state.systemPlayTypeLabel),
                const SizedBox(height: 6),
                _InlineInfo(
                  label: 'Systemgröße',
                  value: '${state.selectedSystemSize}',
                ),
                const SizedBox(height: 6),
                _InlineInfo(
                  label: 'Manuell',
                  value: state.manualSystemNumbers.isEmpty
                      ? '-'
                      : state.manualSystemNumbers.join(' • '),
                ),
                const SizedBox(height: 6),
                _InlineInfo(label: 'Reihen', value: '${state.systemRows.length}'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Systemspiele haben einen eigenen Ablauf: System wählen, Zahlen setzen, Reihen erzeugen, speichern oder exportieren.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Zum Systembereich',
            icon: Icons.grid_view_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SystemGeneratorScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CurrentTipPanel extends StatelessWidget {
  final LottoAppState state;
  final Future<void> Function()? onSave;
  final Future<void> Function()? onCopy;

  const _CurrentTipPanel({
    required this.state,
    required this.onSave,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final tip = state.lastGeneratedTip;
    final superNumber = state.lastGeneratedSuperNumber;
    final lastSimulation = state.bestCurrentTipWindow?.summary;

    return _PanelCard(
      title: 'Aktueller Tipp',
      subtitle: 'Hier siehst du den zuletzt erzeugten Tipp. Speichere ihn, damit er später unter Meine Tipps geprüft werden kann.',
      child: tip == null || tip.isEmpty
          ? const Text(
        'Noch kein Tipp generiert.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubCard(
            title: 'Spielschein',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BallRow(title: 'Zahlen', numbers: tip),
                const SizedBox(height: 10),
                _InlineInfo(
                  label: 'Superzahl',
                  value: superNumber?.toString() ?? '-',
                ),
              ],
            ),
          ),
          if (lastSimulation != null) ...[
            const SizedBox(height: 12),
            _SimulationSummaryCard(
              title: 'Gewinn-Anzeige',
              simulation: lastSimulation,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 180,
                child: PrimaryButton(
                  label: 'In Meine Tipps speichern',
                  icon: Icons.bookmark_add_rounded,
                  onPressed: onSave,
                ),
              ),
              SizedBox(
                width: 180,
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Kopieren'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimulationSummaryCard extends StatelessWidget {
  final String title;
  final dynamic simulation;

  const _SimulationSummaryCard({
    required this.title,
    required this.simulation,
  });

  num _numValue(String field, [num fallback = 0]) {
    try {
      final dynamic value;
      switch (field) {
        case 'weightedScore':
          value = simulation.weightedScore;
          break;
        case 'estimatedEuroTotalValue':
          value = simulation.estimatedEuroTotalValue;
          break;
        case 'totalDraws':
          value = simulation.totalDraws;
          break;
        case 'hit3':
          value = simulation.hit3;
          break;
        case 'hit4':
          value = simulation.hit4;
          break;
        case 'hit5':
          value = simulation.hit5;
          break;
        case 'hit6':
          value = simulation.hit6;
          break;
        default:
          value = fallback;
      }
      return value is num ? value : fallback;
    } catch (_) {
      return fallback;
    }
  }

  int _hitFromDistribution(int hit) {
    try {
      final map = simulation.hitDistribution;
      if (map is Map<int, int>) return map[hit] ?? 0;
      if (map is Map) {
        final value = map[hit];
        return value is int ? value : 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  String _riskLabel(num score) {
    if (score >= 12) return 'Niedriger';
    if (score >= 6) return 'Mittel';
    return 'Höher';
  }

  @override
  Widget build(BuildContext context) {
    final euro = _numValue('estimatedEuroTotalValue', 0).toDouble();
    final draws = _numValue('totalDraws', 0).toInt();
    final weighted = _numValue('weightedScore', 0).toDouble();

    final hit3 = _numValue('hit3', _hitFromDistribution(3)).toInt();
    final hit4 = _numValue('hit4', _hitFromDistribution(4)).toInt();
    final hit5 = _numValue('hit5', _hitFromDistribution(5)).toInt();
    final hit6 = _numValue('hit6', _hitFromDistribution(6)).toInt();

    final avg = draws > 0 ? euro / draws : 0.0;

    return _SubCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineInfo(
            label: 'Modellwert',
            value: '${euro.toStringAsFixed(2).replaceAll('.', ',')} €',
          ),
          const SizedBox(height: 6),
          _InlineInfo(
            label: 'Ø pro Ziehung',
            value: '${avg.toStringAsFixed(2).replaceAll('.', ',')} €',
          ),
          const SizedBox(height: 6),
          _InlineInfo(label: 'Risiko', value: _riskLabel(weighted)),
          const SizedBox(height: 6),
          _InlineInfo(
            label: 'Treffer-Score',
            value: weighted.toStringAsFixed(1),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HitPill(label: '3er', value: '$hit3'),
              _HitPill(label: '4er', value: '$hit4'),
              _HitPill(label: '5er', value: '$hit5'),
              _HitPill(label: '6er', value: '$hit6'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HitPill extends StatelessWidget {
  final String label;
  final String value;

  const _HitPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ControlLabel extends StatelessWidget {
  final String text;

  const _ControlLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          )
              : null,
          color: selected ? null : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _StepButton({
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: onTap,
          child: Text(label),
        ),
      ),
    );
  }
}


class _SignalReasonList extends StatelessWidget {
  const _SignalReasonList({required this.scores});

  final List<NumberAnalysisScore> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return const Text(
        'Noch nicht genug Ziehungen für eine Signal-Erklärung.',
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Warum diese Zahlen auffällig sind:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...scores.map(
          (score) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NumberBall(number: score.number, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${score.mainReason} · Hybrid ${score.hybridPercentLabel}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          score.reasonBullets.join(' · '),
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${score.hitCount} Treffer im Fenster · ${score.lastSeenLabel} · ${score.intervalLabel}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hinweis: Das Signalmodell bewertet vergangene Auffälligkeiten. Es ist keine sichere Vorhersage.',
          style: TextStyle(
            fontSize: 11,
            height: 1.35,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InlineInfo extends StatelessWidget {
  final String label;
  final String value;

  const _InlineInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 260) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BallRow extends StatelessWidget {
  final String title;
  final List<int> numbers;

  const _BallRow({
    required this.title,
    required this.numbers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        numbers.isEmpty
            ? const Text(
          '-',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        )
            : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: numbers.map((n) => NumberBall(number: n)).toList(),
        ),
      ],
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final String confidenceText;

  const _ConfidenceBar({required this.confidenceText});

  @override
  Widget build(BuildContext context) {
    double value;
    if (confidenceText.toLowerCase().contains('sehr')) {
      value = 1.0;
    } else if (confidenceText.toLowerCase().contains('stark')) {
      value = 0.8;
    } else if (confidenceText.toLowerCase().contains('mittel')) {
      value = 0.6;
    } else if (confidenceText.toLowerCase().contains('begrenzt')) {
      value = 0.35;
    } else {
      value = 0.18;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 10,
        backgroundColor: AppColors.surfaceSoft,
      ),
    );
  }
}

class _JackpotModeInfo extends StatelessWidget {
  const _JackpotModeInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.deepOrange.withOpacity(0.25),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: Colors.deepOrange,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jackpot-Fokus',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepOrange,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hier wird derselbe stabile Analysekern verwendet, aber mit stärkerem Fokus auf chancenorientierte Spielweise.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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
