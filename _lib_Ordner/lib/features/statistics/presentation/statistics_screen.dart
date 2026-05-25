import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/number_ball.dart';
import '../../../core/widgets/section_title.dart';
import '../../generator/provider/lotto_app_state.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final draws = state.drawResults;
    final tips = state.savedTips;
    final favoriteTips = state.favoriteTips;

    final Map<int, int> frequency = {
      for (int i = 1; i <= 49; i++) i: 0,
    };

    for (final draw in draws) {
      for (final number in draw.numbers) {
        frequency[number] = (frequency[number] ?? 0) + 1;
      }
    }

    final sortedDesc = frequency.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        if (c != 0) return c;
        return a.key.compareTo(b.key);
      });

    final sortedAsc = frequency.entries.toList()
      ..sort((a, b) {
        final c = a.value.compareTo(b.value);
        if (c != 0) return c;
        return a.key.compareTo(b.key);
      });

    final hotNumbers = sortedDesc.take(6).toList();
    final coldNumbers = sortedAsc.take(6).toList();

    int totalNumbers = draws.fold<int>(0, (sum, draw) => sum + draw.numbers.length);
    int evenTotal = 0;
    int oddTotal = 0;
    int lowTotal = 0;
    int highTotal = 0;

    for (final draw in draws) {
      for (final number in draw.numbers) {
        if (number.isEven) {
          evenTotal++;
        } else {
          oddTotal++;
        }

        if (number <= 24) {
          lowTotal++;
        } else {
          highTotal++;
        }
      }
    }

    final averageSum = draws.isEmpty
        ? 0.0
        : draws
        .map((draw) => draw.numbers.fold<int>(0, (a, b) => a + b))
        .reduce((a, b) => a + b) /
        draws.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionTitle(
              title: 'Statistik',
              subtitle: 'Hot/Cold, Summen und Tipp-Auswertung',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Ziehungen',
                    value: '${draws.length}',
                    icon: Icons.fact_check_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Tipps',
                    value: '${tips.length}',
                    icon: Icons.confirmation_number_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Favoriten',
                    value: '${favoriteTips.length}',
                    icon: Icons.star_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grundauswertung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Zahlen gesamt',
                    value: '$totalNumbers',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Ø Summenwert pro Ziehung',
                    value: averageSum.toStringAsFixed(1),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Gerade Zahlen',
                    value: '$evenTotal',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Ungerade Zahlen',
                    value: '$oddTotal',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Niedrige Zahlen (1–24)',
                    value: '$lowTotal',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Hohe Zahlen (25–49)',
                    value: '$highTotal',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hot Numbers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: hotNumbers
                        .map(
                          (entry) => _FrequencyBall(
                        number: entry.key,
                        count: entry.value,
                        highlighted: true,
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cold Numbers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: coldNumbers
                        .map(
                          (entry) => _FrequencyBall(
                        number: entry.key,
                        count: entry.value,
                        highlighted: false,
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Beste Häufigkeiten',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...sortedDesc.take(10).map(
                        (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InfoRow(
                        label: 'Zahl ${entry.key.toString().padLeft(2, '0')}',
                        value: '${entry.value}x',
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyBall extends StatelessWidget {
  final int number;
  final int count;
  final bool highlighted;

  const _FrequencyBall({
    required this.number,
    required this.count,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NumberBall(
          number: number,
          highlighted: highlighted,
        ),
        const SizedBox(height: 6),
        Text(
          '${count}x',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}