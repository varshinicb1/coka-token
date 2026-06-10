import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CokaLogoBadge extends StatelessWidget {
  final double size;
  final bool showText;

  const CokaLogoBadge({super.key, this.size = 48, this.showText = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.cokaRed, AppColors.cokaOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size * 0.25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cokaRed.withValues(alpha: 0.3),
                  blurRadius: size * 0.3,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'CK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 4),
          Text(
            'COKA',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.volcanicDark,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}
