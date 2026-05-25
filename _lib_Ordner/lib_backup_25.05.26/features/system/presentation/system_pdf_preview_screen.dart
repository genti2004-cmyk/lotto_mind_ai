import 'package:flutter/material.dart';
import '../domain/system_mode.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/number_ball.dart';
import '../domain/system_ticket.dart';
import '../domain/system_price_breakdown.dart';

class SystemPdfPreviewScreen extends StatelessWidget {
  final SystemTicket ticket;
  final SystemPriceBreakdown price;

  final bool withSpiel77;
  final bool withSuper6;
  final bool playSaturday;
  final bool playWednesday;
  final int weeks;

  const SystemPdfPreviewScreen({
    super.key,
    required this.ticket,
    required this.price,
    required this.withSpiel77,
    required this.withSuper6,
    required this.playSaturday,
    required this.playWednesday,
    required this.weeks,
  });

  String _euro(double value) =>
      '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PDF Vorschau'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'System Übersicht',
            child: Column(
              children: [
                _row('System', ticket.mode.label),
                _row('Basiszahlen',
                    ticket.baseNumbers.isEmpty ? '-' : ticket.baseNumbers.join(' • ')),
                _row('Reihen', '${ticket.rowCount}'),
                _row('Wochen', '$weeks'),
                _row('Samstag', playSaturday ? 'Ja' : 'Nein'),
                _row('Mittwoch', playWednesday ? 'Ja' : 'Nein'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _Section(
            title: 'Zusatzspiele',
            child: Column(
              children: [
                _row('Spiel 77', withSpiel77 ? 'Aktiv' : 'Nein'),
                _row('Super 6', withSuper6 ? 'Aktiv' : 'Nein'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _Section(
            title: 'Preis',
            child: Column(
              children: [
                _row('LOTTO', _euro(price.lotto)),
                _row('Spiel 77', _euro(price.spiel77)),
                _row('Super 6', _euro(price.super6)),
                _row('Gesamt', _euro(price.total), bold: true),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _Section(
            title: 'Systemreihen',
            child: Column(
              children: ticket.rows.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                    row.map((n) => NumberBall(number: n)).toList(),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF Export (nächster Schritt)'),
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('PDF exportieren'),
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