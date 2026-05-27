import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/domain/product_plan.dart';
import '../../../features/generator/provider/lotto_app_state.dart';
import '../../../features/settings/domain/app_edition.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LottoAppState>();
    final activeEdition = state.edition;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Normal / Pro / Premium'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const _IntroCard(),
            const SizedBox(height: 16),
            for (final plan in ProductPlan.all) ...[
              _PlanCard(
                plan: plan,
                active: plan.edition == activeEdition,
                onSelect: () => state.setEdition(plan.edition),
              ),
              const SizedBox(height: 14),
            ],
            const _NoteCard(),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Funktionsumfang klar erklärt',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Diese Seite bereitet Normal, Pro und Premium vor. Aktuell ist das eine transparente Struktur, keine harte Bezahlsperre.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ProductPlan plan;
  final bool active;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.active,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _planColor(plan.edition, theme);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.55) : Colors.grey.shade200,
            width: active ? 1.6 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 5),
              color: Colors.black12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PlanIcon(edition: plan.edition),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (active) _ActiveBadge(color: color),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.shortDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: active ? color : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              plan.audience,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade800,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _FeatureList(title: 'Enthalten', items: plan.included, color: color),
            if (plan.planned.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FeatureList(title: 'Vorbereitet', items: plan.planned, color: Colors.grey.shade700),
            ],
          ],
        ),
      ),
    );
  }

  Color _planColor(AppEdition edition, ThemeData theme) {
    switch (edition) {
      case AppEdition.free:
        return Colors.green.shade700;
      case AppEdition.pro:
        return theme.colorScheme.primary;
      case AppEdition.future:
        return Colors.deepPurple;
    }
  }
}

class _PlanIcon extends StatelessWidget {
  final AppEdition edition;

  const _PlanIcon({required this.edition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color;
    final IconData icon;
    switch (edition) {
      case AppEdition.free:
        color = Colors.green.shade700;
        icon = Icons.check_circle_outline_rounded;
        break;
      case AppEdition.pro:
        color = theme.colorScheme.primary;
        icon = Icons.insights_rounded;
        break;
      case AppEdition.future:
        color = Colors.deepPurple;
        icon = Icons.diamond_outlined;
        break;
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final Color color;

  const _ActiveBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'aktiv',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;

  const _FeatureList({
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        'Hinweis: Die Stufen dienen aktuell zur Produktstruktur und zum Testen. Eine echte Freischaltung kann später über In-App-Käufe, Lizenzprüfung oder Account-System angebunden werden.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade800,
          height: 1.35,
        ),
      ),
    );
  }
}
