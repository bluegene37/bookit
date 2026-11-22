// Gene - Nov, 22, 2026: Auth callback landing screen for bookit.genexis.dev email confirmation & password recovery links
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/utils/app_error_formatter.dart';
import '../../../core/widgets/bookit_logo.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_text_field.dart';
import '../../../services/auth_service.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  final String? type;
  final String? code;
  final String? error;
  final String? errorCode;
  final String? errorDescription;
  final Duration verificationWaitTimeout;

  const AuthCallbackScreen({
    super.key,
    this.type,
    this.code,
    this.error,
    this.errorCode,
    this.errorDescription,
    this.verificationWaitTimeout = const Duration(seconds: 3),
  });

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _waitElapsed = false;
  String? _localValidationError;
  Timer? _waitTimer;

  late final Map<String, String> _fragmentParams;

  @override
  void initState() {
    super.initState();
    _fragmentParams = _parseWebFragmentParams();

    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    if (!_hasCallbackError && !_isRecovery && !isAuthenticated) {
      _waitTimer = Timer(widget.verificationWaitTimeout, () {
        if (mounted) {
          setState(() => _waitElapsed = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Map<String, String> _parseWebFragmentParams() {
    if (!kIsWeb) return const {};
    try {
      final fragment = Uri.base.fragment.trim();
      if (fragment.isEmpty) return const {};
      final cleaned = fragment.startsWith('/') ? fragment.split('?').last : fragment;
      if (!cleaned.contains('=')) return const {};
      return Uri.splitQueryString(cleaned);
    } catch (_) {
      return const {};
    }
  }

  String? get _effectiveType =>
      widget.type ?? _fragmentParams['type'];

  String? get _effectiveError =>
      widget.error ?? _fragmentParams['error'];

  String? get _effectiveErrorCode =>
      widget.errorCode ?? _fragmentParams['error_code'];

  String? get _effectiveErrorDescription =>
      widget.errorDescription ?? _fragmentParams['error_description'];

  bool get _hasCallbackError =>
      (_effectiveError != null && _effectiveError!.trim().isNotEmpty) ||
      (_effectiveErrorCode != null && _effectiveErrorCode!.trim().isNotEmpty) ||
      (_effectiveErrorDescription != null &&
          _effectiveErrorDescription!.trim().isNotEmpty);

  bool get _isRecovery => _effectiveType?.toLowerCase() == 'recovery';

  Future<void> _handlePasswordUpdate() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);

    if (password.length < 6) {
      setState(() => _localValidationError = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _localValidationError = 'Passwords do not match.');
      return;
    }

    setState(() => _localValidationError = null);
    final ok = await ref.read(authProvider.notifier).updatePassword(password);
    if (!mounted) return;

    messenger.hideCurrentSnackBar();
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Your password has been updated! You can now sign in.'),
          backgroundColor: NeumorphicColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    } else {
      final errMsg = ref.read(authProvider).error ??
          'Unable to update your password right now. Please try again.';
      messenger.showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: NeumorphicColors.errorFor(isDark),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary =
        isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary =
        isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BookItLogo(size: 64),
                  const SizedBox(height: 24),
                  NeumorphicContainer(
                    borderRadius: 24.0,
                    padding: const EdgeInsets.all(24),
                    child: _buildCardBody(
                      context,
                      authState: authState,
                      isDark: isDark,
                      accent: accent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBody(
    BuildContext context, {
    required AuthState authState,
    required bool isDark,
    required Color accent,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (_hasCallbackError) {
      final friendlyError = AppErrorFormatter.format(
        supa.AuthApiException(
          _effectiveErrorDescription ?? _effectiveError ?? 'Verification failed',
          code: _effectiveErrorCode,
        ),
        context: _isRecovery ? AppErrorContext.passwordReset : AppErrorContext.login,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: NeumorphicColors.errorFor(isDark),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Verification Link Issue',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            friendlyError,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: textSecondary),
          ),
          const SizedBox(height: 24),
          NeumorphicButton(
            isPrimary: true,
            onPressed: () {
              ref.read(authProvider.notifier).clearPendingConfirmation();
              context.go('/login');
            },
            child: const Text('Back to Sign In'),
          ),
        ],
      );
    }

    if (_isRecovery) {
      final displayedError = _localValidationError ?? authState.error;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set New Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a new password for your BookIt account.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 20),
          if (displayedError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NeumorphicColors.errorFor(isDark).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: NeumorphicColors.errorFor(isDark).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: NeumorphicColors.errorFor(isDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      displayedError,
                      style: TextStyle(
                        color: NeumorphicColors.errorFor(isDark),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          NeumorphicTextField(
            controller: _passwordController,
            labelText: 'New Password',
            hintText: 'Enter new password (min 6 characters)',
            obscureText: _obscurePassword,
            prefixIcon: Icon(Icons.lock_outline, size: 18, color: accent),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: isDark
                    ? NeumorphicColors.darkTextMuted
                    : NeumorphicColors.lightTextMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 14),
          NeumorphicTextField(
            controller: _confirmController,
            labelText: 'Confirm Password',
            hintText: 'Repeat new password',
            obscureText: _obscurePassword,
            prefixIcon: Icon(Icons.lock_outline, size: 18, color: accent),
          ),
          const SizedBox(height: 24),
          NeumorphicButton(
            isPrimary: true,
            isLoading: authState.isLoading,
            onPressed: _handlePasswordUpdate,
            child: const Text('Update Password'),
          ),
        ],
      );
    }

    if (authState.isAuthenticated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(
              Icons.verified_rounded,
              size: 48,
              color: NeumorphicColors.success,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Email Confirmed!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your BookIt account is active and ready to use.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: textSecondary),
          ),
          const SizedBox(height: 24),
          NeumorphicButton(
            isPrimary: true,
            onPressed: () {
              context.go(authState.canAccessAdminPortal ? '/admin' : '/');
            },
            child: Text(
              authState.canAccessAdminPortal
                  ? 'Open Admin Portal'
                  : 'Continue to BookIt',
            ),
          ),
        ],
      );
    }

    if (!_waitElapsed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: CircularProgressIndicator(color: accent)),
          const SizedBox(height: 20),
          Text(
            'Confirming your email...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finishing verification on bookit.genexis.dev.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Icon(
            Icons.mark_email_read_rounded,
            size: 46,
            color: accent,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Email Verified',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your email confirmation has been processed. Sign in with your email and password to continue.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: textSecondary),
        ),
        const SizedBox(height: 24),
        NeumorphicButton(
          isPrimary: true,
          onPressed: () {
            ref.read(authProvider.notifier).clearPendingConfirmation();
            context.go('/login');
          },
          child: const Text('Continue to Sign In'),
        ),
      ],
    );
  }
}
