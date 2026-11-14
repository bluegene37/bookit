// Gene - Nov, 03, 2026: Tactile Neumorphic Login Screen with Quick-Fill Demo buttons and Supabase Auth
// Gene - Nov, 14, 2026: Removed direct kReleaseMode import in favor of unified AuthNotifier.isDemoModeEnabled
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../core/widgets/neumorphic_text_field.dart';
// Gene - Nov, 08, 2026: Added BookItLogo import for minimalist Geometric 'B' + Checkmark brand mark
import '../../../core/widgets/bookit_logo.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectPath;

  const LoginScreen({super.key, this.redirectPath});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /*
  // Gene - Nov, 03, 2026: Original sign-in & forgot-password handlers without email regex/min-length checks or safe controller disposal
  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).signIn(email, password);
    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (widget.redirectPath != null) {
        context.go(widget.redirectPath!);
      } else if (user?.isBusinessOwner == true) {
        context.go('/admin');
      } else {
        context.go('/');
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your registered email address to receive password reset instructions.'),
              const SizedBox(height: 14),
              TextField(
                controller: resetEmailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (resetEmailCtrl.text.isNotEmpty) {
                  ref.read(authProvider.notifier).resetPassword(resetEmailCtrl.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reset email sent to ${resetEmailCtrl.text}')),
                  );
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }
  */
  // Gene - Nov, 14, 2026: Added email regex + >= 6 char password validation, canAccessAdminPortal routing, and leak-free forgot-password dialog state
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const Set<String> _demoEmails = {
    'admin@bookit.dev',
    'retreat@bookit.dev',
    'staff@bookit.dev',
    'client@bookit.dev',
  };

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    final isAllowedDemoEmail = AuthNotifier.isDemoModeEnabled && _demoEmails.contains(email.toLowerCase());
    if (!isAllowedDemoEmail && password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).signIn(email, password);
    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (widget.redirectPath != null) {
        context.go(widget.redirectPath!);
      } else if (user?.canAccessAdminPortal == true) {
        context.go('/admin');
      } else {
        context.go('/');
      }
    }
  }

  void _showForgotPasswordDialog() {
    String resetEmail = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your registered email address to receive password reset instructions.'),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: resetEmail,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => resetEmail = value,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final trimmed = resetEmail.trim();
                if (!_emailRegex.hasMatch(trimmed)) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a valid email address.'),
                      backgroundColor: NeumorphicColors.warningFor(isDark),
                    ),
                  );
                  return;
                }
                ref.read(authProvider.notifier).resetPassword(trimmed);
                Navigator.pop(dialogContext);
                messenger.showSnackBar(
                  SnackBar(content: Text('Reset email sent to $trimmed')),
                );
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /*
                  // Gene - Nov, 03, 2026: Placeholder health_and_safety_rounded brand icon on LoginScreen
                  // Brand Icon
                  NeumorphicContainer(
                    isCircle: true,
                    width: 72,
                    height: 72,
                    child: Icon(Icons.health_and_safety_rounded, color: accent, size: 36),
                  ),
                  */
                  // Gene - Nov, 08, 2026: Replaced placeholder icon with minimalist Geometric 'B' + Checkmark BookItLogo
                  const BookItLogo(size: 72),
                  const SizedBox(height: 20),

                  Text(
                    'Welcome to BookIt',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to manage appointments or your clinic practice',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Neumorphic Form Card
                  NeumorphicContainer(
                    borderRadius: 24.0,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (authState.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              /*
                              // Gene - Nov, 03, 2026: Static red color failed WCAG AA on dark canvas (#181C24)
                              color: NeumorphicColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: NeumorphicColors.error.withValues(alpha: 0.3)),
                              */
                              // Gene - Nov, 14, 2026: Theme-aware error banner colors (>= 4.5:1 on Light & Dark)
                              color: NeumorphicColors.errorFor(isDark).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: NeumorphicColors.errorFor(isDark).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              authState.error!,
                              style: TextStyle(color: NeumorphicColors.errorFor(isDark), fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        NeumorphicTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'e.g. michael@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icon(Icons.email_outlined, size: 18, color: accent),
                        ),
                        const SizedBox(height: 18),

                        NeumorphicTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          obscureText: _obscurePassword,
                          prefixIcon: Icon(Icons.lock_outline, size: 18, color: accent),
                          /*
                          // Gene - Nov, 03, 2026: Password eye toggle IconButton missing tooltip & accessible contrast
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          */
                          // Gene - Nov, 14, 2026: Added accessible tooltip and WCAG AA icon contrast
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: isDark ? NeumorphicColors.darkTextMuted : NeumorphicColors.lightTextMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        NeumorphicButton(
                          isPrimary: true,
                          isLoading: authState.isLoading,
                          onPressed: _handleSignIn,
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  /*
                  // Gene - Nov, 05, 2026: Unconditional QUICK DEMO SIGN IN heading exposed even in production builds
                  // Quick Demo Accounts Fill
                  Text(
                    'QUICK DEMO SIGN IN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 12),
                  */
                  /*
                  // Gene - Nov, 03, 2026: Original 2-button demo sign-in row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.person, size: 16),
                          label: const Text('Patient Demo', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.black87,
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            _emailController.text = 'client@bookit.dev';
                            _passwordController.text = 'password123';
                            ref.read(authProvider.notifier).loginAsDemoClient();
                            context.go('/');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.admin_panel_settings, size: 16),
                          label: const Text('Admin Demo', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: BorderSide(color: accent.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            _emailController.text = 'admin@bookit.dev';
                            _passwordController.text = 'password123';
                            ref.read(authProvider.notifier).loginAsDemoAdmin();
                            context.go('/admin');
                          },
                        ),
                      ),
                    ],
                  ),
                  */

                  /*
                  // Gene - Nov, 05, 2026: Expanded 4-persona demo buttons matrix without production mode guard
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.person, size: 15),
                              label: const Text('Patient Demo', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              onPressed: () {
                                _emailController.text = 'client@bookit.dev';
                                _passwordController.text = 'password123';
                                ref.read(authProvider.notifier).loginAsDemoClient();
                                context.go('/');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.admin_panel_settings, size: 15),
                              label: const Text('Admin Demo', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                side: BorderSide(color: accent.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              onPressed: () {
                                _emailController.text = 'admin@bookit.dev';
                                _passwordController.text = 'password123';
                                ref.read(authProvider.notifier).loginAsDemoAdmin();
                                context.go('/admin');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.hotel_rounded, size: 15),
                              label: const Text('Retreat Demo', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.tealAccent : Colors.teal.shade700,
                                side: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              onPressed: () {
                                _emailController.text = 'retreat@bookit.dev';
                                _passwordController.text = 'password123';
                                ref.read(authProvider.notifier).loginAsDemoRetreatOwner();
                                context.go('/admin');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.badge_rounded, size: 15),
                              label: const Text('Staff Demo', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.lightBlueAccent : Colors.blue.shade700,
                                side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              onPressed: () {
                                _emailController.text = 'staff@bookit.dev';
                                _passwordController.text = 'password123';
                                ref.read(authProvider.notifier).loginAsDemoStaff();
                                context.go('/');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  */

                  // Gene - Nov, 05, 2026: Guarded demo persona matrix behind !kReleaseMode without gating heading or WCAG AA contrast / 48dp hit targets
                  // if (!kReleaseMode) ...[
                  //   Column(...)
                  // ],

                  // Gene - Nov, 14, 2026: Gate both heading and demo persona buttons behind AuthNotifier.isDemoModeEnabled with >= 4.5:1 WCAG contrast and 48dp touch targets
                  if (AuthNotifier.isDemoModeEnabled) ...[
                    Text(
                      'QUICK DEMO SIGN IN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isDark ? NeumorphicColors.darkTextMuted : NeumorphicColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.person, size: 15),
                                label: const Text('Patient Demo', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                                  side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: () {
                                  _emailController.text = 'client@bookit.dev';
                                  _passwordController.text = 'password123';
                                  ref.read(authProvider.notifier).loginAsDemoClient();
                                  context.go('/');
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.admin_panel_settings, size: 15),
                                label: const Text('Admin Demo', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accent,
                                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: () {
                                  _emailController.text = 'admin@bookit.dev';
                                  _passwordController.text = 'password123';
                                  ref.read(authProvider.notifier).loginAsDemoAdmin();
                                  context.go('/admin');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.hotel_rounded, size: 15),
                                label: const Text('Retreat Demo', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accent,
                                  side: BorderSide(color: accent.withValues(alpha: 0.45)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: () {
                                  _emailController.text = 'retreat@bookit.dev';
                                  _passwordController.text = 'password123';
                                  ref.read(authProvider.notifier).loginAsDemoRetreatOwner();
                                  context.go('/admin');
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.badge_rounded, size: 15),
                                label: const Text('Staff Demo', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: NeumorphicColors.infoFor(isDark),
                                  side: BorderSide(color: NeumorphicColors.infoFor(isDark).withValues(alpha: 0.45)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: () {
                                  _emailController.text = 'staff@bookit.dev';
                                  _passwordController.text = 'password123';
                                  ref.read(authProvider.notifier).loginAsDemoStaff();
                                  context.go('/');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Gene - Nov, 03, 2026: Wrapped sign-up footer link in Wrap to eliminate mobile flex overflows
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  /*
                  // Gene - Nov, 03, 2026: Previous Row widget that caused overflow on narrow widths
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?"),
                      TextButton(onPressed: () => context.push('/signup'), child: Text('Create Account')),
                    ],
                  ),
                  */
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
