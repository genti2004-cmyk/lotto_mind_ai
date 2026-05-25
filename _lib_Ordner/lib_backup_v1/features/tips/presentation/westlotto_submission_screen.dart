import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../generator/provider/lotto_app_state.dart';
import '../services/westlotto_launcher_service.dart';
import '../widgets/ticket_card.dart';

class WestlottoSubmissionScreen extends StatefulWidget {
  const WestlottoSubmissionScreen({super.key});

  @override
  State<WestlottoSubmissionScreen> createState() =>
      _WestlottoSubmissionScreenState();
}

class _WestlottoSubmissionScreenState extends State<WestlottoSubmissionScreen> {
  bool _opening = false;

  Future<void> _copyAll(String text) async {
    final result = await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tipp in Zwischenablage kopiert'),
      ),
    );
  }

  Future<void> _openWestlotto(String text) async {
    setState(() {
      _opening = true;
    });

    final result = await WestlottoLauncherService.openWestlotto();

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

  String _buildWestlottoText(LottoAppState state) {
    final lines = <String>[];

    final lastTip = state.lastGeneratedTip;
    final superNumber = state.lastGeneratedSuperNumber;

    if (lastTip != null && lastTip.isNotEmpty) {
      final sorted = [...lastTip]..sort();
      lines.add(
        'Tipp 1: ${sorted.join(' - ')}'
            '${superNumber == null ? '' : ' | SZ: $superNumber'}',
      );
    }

    final savedTips = state.savedTips;
    var index = lines.isEmpty ? 1 : 2;

    for (final tip in savedTips.take(9)) {
      final numbers = [...tip.numbers]..sort();
      final sz = tip.superNumber;
      lines.add(
        'Tipp $index: ${numbers.join(' - ')}${sz == null ? '' : ' | SZ: $sz'}',
      );
      index++;
    }

    if (lines.isEmpty) {
      return 'Noch kein spielbarer Tipp vorhanden.';
    }

    return [
      'LottoMind AI – WestLotto Abgabe',
      '',
      ...lines,
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final ticketText = _buildWestlottoText(state);

    final lastTip = state.lastGeneratedTip;
    final superNumber = state.lastGeneratedSuperNumber;
    final hasCurrentTip = lastTip != null && lastTip.isNotEmpty;
    final savedTips = state.savedTips;

    final ticketItems = <Map<String, dynamic>>[];

    if (hasCurrentTip) {
      ticketItems.add({
        'title': 'Empfohlener Tipp',
        'numbers': List<int>.from(lastTip),
        'superNumber': superNumber,
      });
    }

    for (var i = 0; i < savedTips.length; i++) {
      final tip = savedTips[i];
      ticketItems.add({
        'title': 'Tipp ${i + 1}',
        'numbers': List<int>.from(tip.numbers),
        'superNumber': tip.superNumber,
      });
    }

    final hasPlayableTickets = ticketItems.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('WestLotto Abgabe'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _HeaderCard(),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Hauptaktion',
            subtitle: 'Direkt mit deinem vorbereiteten Tipp zu WestLotto.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusPill(
                  icon: Icons.check_circle_rounded,
                  label: hasPlayableTickets ? 'Spielbereit' : 'Noch kein Tipp',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _opening || !hasPlayableTickets
                        ? null
                        : () => _openWestlotto(ticketText),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(
                      _opening
                          ? 'Öffne WestLotto...'
                          : 'Jetzt bei WestLotto öffnen',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: !hasPlayableTickets
                        ? null
                        : () => _copyAll(ticketText),
                    icon: const Icon(Icons.copy_all_rounded),
                    label: const Text('Abgabe kopieren'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (ticketItems.isNotEmpty) ...[
            _SwipeTicketSection(
              items: ticketItems,
              onPlay: () => _openWestlotto(ticketText),
              onCopy: () => _copyAll(ticketText),
            ),
            const SizedBox(height: 14),
          ],
          _SectionCard(
            title: 'Abgabe-Vorschau',
            subtitle:
            'So wird der Text für Zwischenablage und WestLotto vorbereitet.',
            child: SelectableText(
              ticketText,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeTicketSection extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onPlay;
  final VoidCallback onCopy;

  const _SwipeTicketSection({
    required this.items,
    required this.onPlay,
    required this.onCopy,
  });

  @override
  State<_SwipeTicketSection> createState() => _SwipeTicketSectionState();
}

class _SwipeTicketSectionState extends State<_SwipeTicketSection> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.75);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Spielscheine',
      subtitle: 'Wische durch deine vorbereiteten Tipps.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(
            icon: Icons.swipe_rounded,
            label: '${_index + 1} / ${widget.items.length}',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 360,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              onPageChanged: (value) {
                setState(() {
                  _index = value;
                });
              },
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final numbers = (item['numbers'] as List).cast<int>();
                final sz = item['superNumber'] as int?;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: TicketCard(
                    title: item['title'] as String,
                    numbers: numbers,
                    superNumber: sz,
                    onPlay: widget.onPlay,
                    onCopy: widget.onCopy,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.items.length,
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
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
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WestLotto Flow',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Spielschein prüfen, Tipps bündeln und direkt zu WestLotto wechseln.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}