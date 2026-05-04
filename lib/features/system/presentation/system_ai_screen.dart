import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generator/provider/lotto_app_state.dart';

class SystemAiScreen extends StatelessWidget {
  const SystemAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final rows = state.generatedSystemRows;
    final scoredRows = state.systemAiRowScores;
    final optimizedRows = state.optimizedSystemAiRows;
    final topRows = state.systemAiTopRows;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('VEW / Vollsystem AI'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HeroPanel(
            summary: state.systemAiSummary,
            optimizedSummary: state.optimizedSystemAiSummary,
            playTypeLabel: state.systemPlayTypeLabel,
            rowCount: rows.length,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCardButton(
                  label: 'Vollsystem',
                  icon: Icons.grid_view_rounded,
                  onTap: () async {
                    await context.read<LottoAppState>().generateFullSystemTip();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionCardButton(
                  label: 'VEW System',
                  icon: Icons.auto_awesome_mosaic_rounded,
                  onTap: () async {
                    await context.read<LottoAppState>().generateVewSystemTip();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WideActionButton(
            label: 'AI optimiertes System',
            icon: Icons.auto_fix_high_rounded,
            onTap: () async {
              await context.read<LottoAppState>().generateOptimizedSystemTip();
            },
          ),
          const SizedBox(height: 18),
          if (topRows.isNotEmpty) ...[
            _TopRowsCard(scoredRows: scoredRows),
            const SizedBox(height: 18),
          ],
          if (optimizedRows.isNotEmpty) ...[
            _OptimizedRowsCard(rows: optimizedRows),
            const SizedBox(height: 18),
          ],
          if (rows.isEmpty)
            const _EmptyStateCard()
          else
            ...scoredRows.map((item) {
              final row = item.row;
              final isTop = topRows.isNotEmpty && _listEquals(row, topRows.first);
              final isOptimized = optimizedRows.any((e) => _listEquals(e.row, row));

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SystemRowCard(
                  item: item,
                  isTop: isTop,
                  isOptimized: isOptimized,
                ),
              );
            }),
        ],
      ),
    );
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _HeroPanel extends StatelessWidget {
  final String summary;
  final String optimizedSummary;
  final String playTypeLabel;
  final int rowCount;

  const _HeroPanel({
    required this.summary,
    required this.optimizedSummary,
    required this.playTypeLabel,
    required this.rowCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System AI Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            optimizedSummary,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Typ',
                  value: playTypeLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Reihen',
                  value: '$rowCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Future<void> Function() onTap;

  const _ActionCardButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Future<void> Function() onTap;

  const _WideActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111827),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TopRowsCard extends StatelessWidget {
  final List<dynamic> scoredRows;

  const _TopRowsCard({
    required this.scoredRows,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'AI Top Reihen',
      subtitle: 'Die drei stärksten Reihen nach Score, ROI und Musterfit',
      child: Column(
        children: scoredRows.take(3).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index == 2 ? 0 : 10),
            child: _MiniRowTile(
              rank: index + 1,
              row: item.row,
              label: item.label,
              scoreText: 'Score ${item.score.toStringAsFixed(1)}',
              color: index == 0
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF2563EB),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OptimizedRowsCard extends StatelessWidget {
  final List<dynamic> rows;

  const _OptimizedRowsCard({
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'AI Optimierte Auswahl',
      subtitle: 'Reduzierte Reihen für ein effizienteres System',
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index == rows.length - 1 ? 0 : 10),
            child: _MiniRowTile(
              rank: index + 1,
              row: item.row,
              label: 'ROI ${item.roi.toStringAsFixed(1)}%',
              scoreText: 'Score ${item.score.toStringAsFixed(1)}',
              color: const Color(0xFFEA580C),
            ),
          );
        }).toList(),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFF6B7280),
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

class _MiniRowTile extends StatelessWidget {
  final int rank;
  final List<int> row;
  final String label;
  final String scoreText;
  final Color color;

  const _MiniRowTile({
    required this.rank,
    required this.row,
    required this.label,
    required this.scoreText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.join(' - '),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                scoreText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemRowCard extends StatelessWidget {
  final dynamic item;
  final bool isTop;
  final bool isOptimized;

  const _SystemRowCard({
    required this.item,
    required this.isTop,
    required this.isOptimized,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isTop
        ? const Color(0xFF16A34A)
        : isOptimized
        ? const Color(0xFFEA580C)
        : const Color(0xFFE5E7EB);

    final bgColor = isTop
        ? const Color(0xFF16A34A).withOpacity(0.08)
        : isOptimized
        ? const Color(0xFFEA580C).withOpacity(0.08)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: isTop || isOptimized ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isTop)
                const _StatusBadge(
                  label: 'AI TOP',
                  color: Color(0xFF16A34A),
                ),
              if (isOptimized && !isTop)
                const _StatusBadge(
                  label: 'AI OPTIMIERT',
                  color: Color(0xFFEA580C),
                ),
              _StatusBadge(
                label: item.label,
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.row.join(' - '),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Score',
                  value: item.score.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: 'ROI',
                  value: '${item.roi.toStringAsFixed(1)}%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: '4+ Chance',
                  value: '${item.hit4Chance}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Modellwert',
                  value:
                  '${item.estimatedEuro.toStringAsFixed(2).replaceAll('.', ',')} €',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: '3er Basis',
                  value: '${item.hit3Base}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 42,
            color: Color(0xFF2563EB),
          ),
          SizedBox(height: 12),
          Text(
            'Noch keine Reihen generiert.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Erzeuge zuerst ein Vollsystem, VEW-System oder direkt ein AI optimiertes System.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}