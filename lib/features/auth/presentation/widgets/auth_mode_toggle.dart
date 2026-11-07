import 'package:flutter/material.dart';
import 'package:strivo/core/theme/app_colors.dart';

/// Link that switches the auth form between log-in and sign-up. [onTap] is null
/// while a request is in flight.
class AuthModeToggle extends StatelessWidget {
  const AuthModeToggle({required this.isLogin, required this.onTap, super.key});
  final bool isLogin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Text.rich(
          TextSpan(
            text: isLogin ? 'New to Strivo?  ' : 'Already a member?  ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: isLogin ? 'Sign Up' : 'Log In',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
