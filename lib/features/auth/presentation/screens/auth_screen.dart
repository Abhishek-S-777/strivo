import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/auth/presentation/providers/auth_providers.dart';

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
            _emailController.text, _passwordController.text)
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
      HapticFeedback.heavyImpact();
    }
    // On success the router redirect handles navigation; keep the spinner.
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter your email above to reset your password.');
      return;
    }
    final result =
        await ref.read(authControllerProvider).sendPasswordReset(email);
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
          // Atmospheric glow
          Positioned(
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
          ),
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
                        // ── Wordmark ──
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

                        // ── Headline ──
                        Text(
                          _isLogin ? 'Welcome Back' : 'Join the Elite.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin
                              ? 'Log in to track your progression.'
                              : 'Precision tracking for serious lifters.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 36),

                        // ── Name (signup only) ──
                        if (!_isLogin) ...[
                          _FieldLabel('Full Name'),
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
                              if (!_isLogin && (v == null || v.trim().isEmpty)) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                        ],

                        // ── Email ──
                        _FieldLabel('Email Address'),
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
                            _FieldLabel('Password'),
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
                                _obscure
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
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
                              const Icon(LucideIcons.checkCircle,
                                  size: 13, color: AppColors.accent),
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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(20),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                  color: AppColors.error.withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.alertCircle,
                                    size: 16, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                        color: AppColors.error, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                        Center(
                          child: GestureDetector(
                            onTap: _isLoading ? null : _toggleMode,
                            child: Text.rich(
                              TextSpan(
                                text: _isLogin
                                    ? 'New to Strivo?  '
                                    : 'Already a member?  ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary),
                                children: [
                                  TextSpan(
                                    text: _isLogin ? 'Sign Up' : 'Log In',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
