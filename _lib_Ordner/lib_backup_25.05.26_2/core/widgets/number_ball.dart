import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NumberBall extends StatelessWidget {
  final int number;
  final double size;
  final bool highlighted;

  const NumberBall({
    super.key,
    required this.number,
    this.size = 42,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = highlighted ? Colors.white : AppColors.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: highlighted
            ? const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        )
            : const LinearGradient(
          colors: [
            Color(0xFFF8FBFF),
            AppColors.surfaceSoft,
          ],
        ),
        border: Border.all(
          color: highlighted ? AppColors.primaryDark : AppColors.border,
          width: 1.1,
        ),
        boxShadow: highlighted
            ? const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ]
            : const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        number.toString().padLeft(2, '0'),
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
          color: textColor,
        ),
      ),
    );
  }
}