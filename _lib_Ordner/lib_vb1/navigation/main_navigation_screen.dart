import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lotto_mind_ai/features/tracking/presentation/tracking_screen.dart';

import 'package:lotto_mind_ai/features/dashboard/presentation/dashboard_screen.dart';
import 'package:lotto_mind_ai/features/generator/presentation/generator_screen.dart';
import 'package:lotto_mind_ai/features/draws/presentation/draw_results_screen.dart';
import 'package:lotto_mind_ai/features/analysis/presentation/analysis_screen.dart';
import 'package:lotto_mind_ai/features/settings/presentation/settings_screen.dart';
import 'package:lotto_mind_ai/features/system/presentation/system_generator_screen.dart';
import 'package:lotto_mind_ai/features/tips/presentation/my_tips_screen.dart';
import 'package:lotto_mind_ai/features/generator/provider/lotto_app_state.dart';

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
    DrawResultsScreen(),
    AnalysisScreen(),
    _MoreScreen(),
    TrackingScreen(),
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
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Prüfung',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analyse',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            label: 'Mehr',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Tracking',
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
          _MoreCard(
            title: 'Systeme',
            subtitle: 'Systemgenerator, System AI und Abgabe',
            icon: Icons.grid_view_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SystemGeneratorScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _MoreCard(
            title: 'Meine Tipps',
            subtitle: 'Gespeicherte Tipps verwalten',
            icon: Icons.list_alt_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyTipsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _MoreCard(
            title: 'Tracking Pro',
            subtitle: 'Eigene Tipps speichern und Trefferhistorie auswerten',
            icon: Icons.track_changes_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrackingScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _MoreCard(
            title: 'Einstellungen',
            subtitle: 'App, Regeln und Optionen',
            icon: Icons.settings,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
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