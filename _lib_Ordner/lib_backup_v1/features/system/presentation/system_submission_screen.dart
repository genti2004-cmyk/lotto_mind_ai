import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/number_ball.dart';
import '../../generator/provider/lotto_app_state.dart';
import '../domain/system_mode.dart';
import '../domain/system_price_breakdown.dart';
import '../domain/system_ticket.dart';
import 'system_pdf_preview_screen.dart';

class SystemSubmissionScreen extends StatelessWidget {
  const SystemSubmissionScreen({super.key});

  String _euro(double value) =>
      '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

  SystemTicket _buildTicket(LottoAppState state) {
    return SystemTicket(
      mode: state.systemPlayType == SystemPlayType.full
          ? SystemMode.full
          : SystemMode.vew,
      baseNumbers: List<int>.from(state.systemBaseNumbers),
      rows: state.systemRows,
      drawCount: 1,
      withSpiel77: false,
      withSuper6: false,
    );
  }

  SystemPriceBreakdown _buildPrice(LottoAppState state) {
    final lotto = state.systemRows.length * 1.20;

    return SystemPriceBreakdown(
      lotto: lotto,
      spiel77: 0,
      super6: 0,
      processingFee: 0,
      total: lotto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();

    final ticket = _buildTicket(state);
    final price = _buildPrice(state);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('System Abgabe'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Übersicht',
            child: Column(
              children: [
                _row('System', ticket.mode.label),
                _row(
                  'Basiszahlen',
                  ticket.baseNumbers.isEmpty
                      ? '-'
                      : ticket.baseNumbers.join(' • '),
                ),
                _row('Reihen', '${ticket.rowCount}'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Preis',
            child: Column(
              children: [
                _row('LOTTO', _euro(price.lotto)),
                _row('Gesamt', _euro(price.total), bold: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Systemreihen',
            child: Column(
              children: ticket.rows.take(12).map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: row.map((n) => NumberBall(number: n)).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SystemPdfPreviewScreen(
                    ticket: ticket,
                    price: price,
                    withSpiel77: ticket.withSpiel77,
                    withSuper6: ticket.withSuper6,
                    playSaturday: true,
                    playWednesday: false,
                    weeks: ticket.drawCount,
                  )
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF Vorschau'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('System erfolgreich vorbereitet'),
                ),
              );
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('System bestätigen'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}