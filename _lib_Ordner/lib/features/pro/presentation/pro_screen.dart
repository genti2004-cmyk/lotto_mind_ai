import 'package:flutter/material.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotto Pro Analyzer Pro'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pro/Future-Ausbau ist vorbereitet und kann hier später erweitert werden.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
