import 'package:flutter/material.dart';
import 'package:strivo/core/theme/app_colors.dart';

/// Wordmark, headline, and subtitle at the top of the auth form. The copy
/// switches between the log-in and sign-up modes.
class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.isLogin, super.key});
  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'STRIVO',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          isLogin ? 'Welcome Back' : 'Join the Elite.',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isLogin
              ? 'Log in to track your progression.'
              : 'Precision tracking for serious lifters.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
