import 'package:flutter/material.dart';

import 'package:lotto_mind_ai/features/dashboard/presentation/dashboard_screen.dart';
import 'package:lotto_mind_ai/features/generator/presentation/generator_screen.dart';
import 'package:lotto_mind_ai/features/tips/presentation/my_tips_screen.dart';
import 'package:lotto_mind_ai/features/draws/presentation/draw_results_screen.dart';
import 'package:lotto_mind_ai/features/analysis/presentation/analysis_screen.dart';
import 'package:lotto_mind_ai/features/settings/presentation/settings_screen.dart';
import 'package:lotto_mind_ai/features/settings/presentation/export_center_screen.dart';
import 'package:lotto_mind_ai/features/system/presentation/system_generator_screen.dart';
import 'package:lotto_mind_ai/features/tracking/presentation/tracking_screen.dart';
import 'package:lotto_mind_ai/features/pro/presentation/pro_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _index = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    GeneratorScreen(),
    MyTipsScreen(),
    DrawResultsScreen(),
    _MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Start',
          ),
          NavigationDestination(
            icon: Icon(Icons.casino_outlined),
            selectedIcon: Icon(Icons.casino),
            label: 'Generator',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined),
            selectedIcon: Icon(Icons.bookmarks),
            label: 'Meine Tipps',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Ziehungen',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_rounded),
            selectedIcon: Icon(Icons.menu_open_rounded),
            label: 'Mehr',
          ),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mehr'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _MoreHeader(),
          const SizedBox(height: 18),
          const _MoreSectionTitle('Analyse & Auswertung'),
          _MoreCard(
            title: 'Analyse',
            subtitle: 'Zahlenmuster, Häufigkeiten und Intervalle ansehen.',
            badge: 'Pro',
            icon: Icons.analytics_rounded,
            onTap: () => _open(context, const AnalysisScreen()),
          ),
          const SizedBox(height: 12),
          _MoreCard(
            title: 'Tracking Pro',
            subtitle: 'Gespeicherte Tipps langfristig beobachten und Treffer vergleichen.',
            badge: 'Pro',
            icon: Icons.track_changes_rounded,
            onTap: () => _open(context, const TrackingScreen()),
          ),
          const SizedBox(height: 22),
          const _MoreSectionTitle('Tipp-Erweiterungen'),
          _MoreCard(
            title: 'Systemschein',
            subtitle: 'Mehrere Kombinationen strukturiert erzeugen und prüfen.',
            badge: 'Pro',
            icon: Icons.grid_view_rounded,
            onTap: () => _open(context, const SystemGeneratorScreen()),
          ),
          const SizedBox(height: 22),
          const _MoreSectionTitle('Verwaltung'),
          _MoreCard(
            title: 'Export Center',
            subtitle: 'Backups, Datenexport und Wiederherstellung verwalten.',
            badge: 'Premium',
            icon: Icons.ios_share_rounded,
            onTap: () => _open(context, const ExportCenterScreen()),
          ),
          const SizedBox(height: 12),
          _MoreCard(
            title: 'Normal / Pro / Premium',
            subtitle: 'Funktionsumfang und zukünftige App-Versionen ansehen.',
            badge: 'Info',
            icon: Icons.workspace_premium_rounded,
            onTap: () => _open(context, const ProScreen()),
          ),
          const SizedBox(height: 12),
          _MoreCard(
            title: 'Einstellungen',
            subtitle: 'App-Optionen, Regeln und lokale Einstellungen anpassen.',
            badge: 'Normal',
            icon: Icons.settings_rounded,
            onTap: () => _open(context, const SettingsScreen()),
          ),
        ],
      ),
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _MoreHeader extends StatelessWidget {
  const _MoreHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Weitere Funktionen',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hier findest du Analyse, Systemtipps, Exporte und Einstellungen. Die wichtigsten Alltagsfunktionen bleiben unten in der Hauptnavigation.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreSectionTitle extends StatelessWidget {
  final String title;

  const _MoreSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade700,
            ),
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final VoidCallback onTap;

  const _MoreCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black12,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 25, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _PlanBadge(label: badge),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String label;

  const _PlanBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isPremium = label == 'Premium';
    final Color color = isPremium ? Colors.deepPurple : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
