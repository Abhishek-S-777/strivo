import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/features/auth/presentation/providers/auth_providers.dart';
import 'package:strivo/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:strivo/features/auth/presentation/widgets/auth_glow.dart';
import 'package:strivo/features/auth/presentation/widgets/auth_header.dart';
import 'package:strivo/features/auth/presentation/widgets/auth_mode_toggle.dart';
import 'package:strivo/features/auth/presentation/widgets/field_label.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final controller = ref.read(authControllerProvider);
    final result = _isLogin
        ? await controller.signIn(
            _emailController.text,
            _passwordController.text,
          )
        : await controller.signUp(
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          );

    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _isLoading = false;
        _error = result.error;
      });
      unawaited(HapticFeedback.heavyImpact());
    }
    // On success the router redirect handles navigation; keep the spinner.
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter your email above to reset your password.');
      return;
    }
    final result = await ref
        .read(authControllerProvider)
        .sendPasswordReset(email);
    if (!mounted) return;
    if (result.success) {
      setState(() => _error = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } else {
      setState(() => _error = result.error);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AuthGlow(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthHeader(isLogin: _isLogin),
                        const SizedBox(height: 36),

                        // ── Name (signup only) ──
                        if (!_isLogin) ...[
                          const FieldLabel('Full Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'John Doe',
                              prefixIcon: Icon(LucideIcons.user, size: 18),
                            ),
                            validator: (v) {
                              if (!_isLogin &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                        ],

                        // ── Email ──
                        const FieldLabel('Email Address'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            hintText: 'name@example.com',
                            prefixIcon: Icon(LucideIcons.mail, size: 18),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // ── Password ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const FieldLabel('Password'),
                            if (_isLogin)
                              GestureDetector(
                                onTap: _forgotPassword,
                                child: Text(
                                  'Forgot Password?',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(LucideIcons.lock, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (!_isLogin && v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.checkCircle,
                                size: 13,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'MINIMUM 6 CHARACTERS',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.textTertiary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // ── Error ──
                        if (_error != null) ...[
                          const SizedBox(height: 18),
                          AuthErrorBanner(message: _error!),
                        ],

                        const SizedBox(height: 28),

                        // ── Submit ──
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: AppColors.onPrimary,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Log In' : 'Create Account',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Toggle ──
                        AuthModeToggle(
                          isLogin: _isLogin,
                          onTap: _isLoading ? null : _toggleMode,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
