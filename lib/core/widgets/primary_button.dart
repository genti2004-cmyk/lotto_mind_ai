import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final content = icon == null
        ? Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)
        : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: compact ? 16 : 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: compact ? 42 : 54,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            gradient: isDisabled
                ? null
                : const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: isDisabled ? AppColors.border : null,
            boxShadow: isDisabled
                ? const []
                : const [
              BoxShadow(
                color: Color(0x1F2563EB),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: compact ? 12.5 : 15,
              fontWeight: FontWeight.w800,
              color: isDisabled ? AppColors.textMuted : Colors.white,
            ),
            child: IconTheme(
              data: IconThemeData(
                color: isDisabled ? AppColors.textMuted : Colors.white,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
