import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/number_ball.dart';

class TicketCard extends StatelessWidget {
  final List<int> numbers;
  final int? superNumber;
  final String title;
  final VoidCallback? onPlay;
  final VoidCallback? onCopy;

  const TicketCard({
    super.key,
    required this.numbers,
    required this.superNumber,
    required this.title,
    this.onPlay,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          /// NUMBERS
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: numbers.map((n) {
              return NumberBall(number: n, size: 36);
            }).toList(),
          ),

          const SizedBox(height: 12),

          /// SUPERZAHL
          Row(
            children: [
              const Text(
                'Superzahl:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  superNumber?.toString() ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// BUTTONS
          Column(
            children: [
              /// PLAY BUTTON (MAIN ACTION)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('JETZT SPIELEN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              /// COPY BUTTON
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                  label: const Text('Kopieren'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}