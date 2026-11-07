import 'package:flutter/material.dart';
import 'package:strivo/core/theme/app_colors.dart';

/// The decorative radial glow behind the auth screen.
class AuthGlow extends StatelessWidget {
  const AuthGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -160,
      right: -120,
      child: Container(
        width: 360,
        height: 360,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withAlpha(38),
              AppColors.background.withAlpha(0),
            ],
          ),
        ),
      ),
    );
  }
}
