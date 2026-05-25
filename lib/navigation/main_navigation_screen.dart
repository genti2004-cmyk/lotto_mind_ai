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
          const _MoreSectionTitle('Expertenfunktionen'),
          _MoreCard(
            title: 'Analyse',
            subtitle: 'Intervall-, Häufigkeits- und Musteranalyse ansehen',
            icon: Icons.analytics_rounded,
            onTap: () => _open(context, const AnalysisScreen()),
          ),
          const SizedBox(height: 12),
          _MoreCard(
            title: 'Tracking Pro',
            subtitle: 'Tipp-Verlauf und Trefferhistorie für Pro-Nutzer',
            icon: Icons.track_changes_rounded,
            onTap: () => _open(context, const TrackingScreen()),
          ),
          const SizedBox(height: 12),
          _MoreCard(
            title: 'Systemschein',
            subtitle: 'Systemgenerator, System AI und Abgabe vorbereiten',
            icon: Icons.grid_view_rounded,
            onTap: () => _open(context, const SystemGeneratorScreen()),
          ),
          const SizedBox(height: 22),
          const _MoreSectionTitle('Verwaltung'),
          _MoreCard(
            title: 'Export Center',
            subtitle: 'Backups, Datenexport und Wiederherstellung',
            icon: Icons.ios_share_rounded,
            onTap: () => _open(context, const ExportCenterScreen()),
          ),
          const SizedBox(height: 12),
          _MoreCard(
            title: 'Normal / Pro / Premium',
            subtitle: 'Produktstufen und spätere Premium-Funktionen',
            icon: Icons.workspace_premium_rounded,
            onTap: () => _open(context, const ProScreen()),
          ),
          const SizedBox(height: 12),
          _MoreCard(
            title: 'Einstellungen',
            subtitle: 'App, Regeln und Optionen',
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
  final IconData icon;
  final VoidCallback onTap;

  const _MoreCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            Icon(icon, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
