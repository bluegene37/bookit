// Gene - Nov, 22, 2026: Unit, widget, and config tests for bookit.genexis.dev email confirmation & auth callback flows
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:bookit/core/constants/demo_data.dart';
import 'package:bookit/core/constants/supabase_config.dart';
import 'package:bookit/features/auth/presentation/auth_callback_screen.dart';
import 'package:bookit/features/auth/presentation/login_screen.dart';
import 'package:bookit/features/auth/presentation/signup_screen.dart';
import 'package:bookit/services/auth_service.dart';

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState) : super() {
    state = initialState;
  }
}

GoRouter _buildCallbackTestRouter({
  String initialLocation = '/auth/callback',
  Duration waitTimeout = const Duration(milliseconds: 50),
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return AuthCallbackScreen(
            type: q['type'],
            code: q['code'],
            error: q['error'],
            errorCode: q['error_code'],
            errorDescription: q['error_description'],
            verificationWaitTimeout: waitTimeout,
          );
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Center(child: Text('LOGIN_ROUTE'))),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Center(child: Text('HOME_ROUTE'))),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const Scaffold(body: Center(child: Text('ADMIN_ROUTE'))),
      ),
    ],
  );
}

void main() {
  group('SupabaseConfig - bookit.genexis.dev Redirect URLs', () {
    test('provides canonical bookit.genexis.dev confirmation and recovery URLs', () {
      expect(SupabaseConfig.normalizedAppBaseUrl, 'https://bookit.genexis.dev');
      expect(
        SupabaseConfig.emailConfirmationRedirectUrl,
        'https://bookit.genexis.dev/auth/callback',
      );
      expect(
        SupabaseConfig.passwordResetRedirectUrl,
        'https://bookit.genexis.dev/auth/callback?type=recovery',
      );
    });
  });

  group('AuthNotifier - Confirmation Resend & Password Update', () {
    test('resendConfirmationEmail validates email, updates pending state, and clearPendingConfirmation resets', () async {
      final notifier = AuthNotifier();
      addTearDown(notifier.dispose);

      final invalidOk = await notifier.resendConfirmationEmail('not-an-email');
      expect(invalidOk, isFalse);
      expect(notifier.state.error, 'Please enter a valid email address.');

      final validOk = await notifier.resendConfirmationEmail('patient@example.com');
      expect(validOk, isTrue);
      expect(notifier.state.needsEmailConfirmation, isTrue);
      expect(notifier.state.pendingConfirmationEmail, 'patient@example.com');
      expect(notifier.state.successMessage, contains('patient@example.com'));

      notifier.clearPendingConfirmation();
      expect(notifier.state.needsEmailConfirmation, isFalse);
      expect(notifier.state.pendingConfirmationEmail, isNull);
      expect(notifier.state.error, isNull);
    });

    test('updatePassword validates minimum length and succeeds on valid password', () async {
      final notifier = AuthNotifier();
      addTearDown(notifier.dispose);

      final shortOk = await notifier.updatePassword('12345');
      expect(shortOk, isFalse);
      expect(notifier.state.error, 'Password must be at least 6 characters.');

      final validOk = await notifier.updatePassword('newSecret123');
      expect(validOk, isTrue);
      expect(notifier.state.error, isNull);
      expect(notifier.state.successMessage, contains('updated successfully'));
    });
  });

  group('AuthCallbackScreen Widget Tests', () {
    testWidgets('shows friendly expired-link guidance on callback error and navigates to /login', (tester) async {
      final router = _buildCallbackTestRouter(
        initialLocation:
            '/auth/callback?error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid+or+has+expired',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _TestAuthNotifier(const AuthState())),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verification Link Issue'), findsOneWidget);
      expect(find.textContaining('expired'), findsOneWidget);
      expect(find.textContaining('otp_expired'), findsNothing);
      expect(find.textContaining('access_denied'), findsNothing);

      await tester.tap(find.text('Back to Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN_ROUTE'), findsOneWidget);
    });

    testWidgets('shows Email Confirmed! when session is active and navigates to client or admin route', (tester) async {
      final router = _buildCallbackTestRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _TestAuthNotifier(AuthState(user: DemoData.demoClient)),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email Confirmed!'), findsOneWidget);
      await tester.tap(find.text('Continue to BookIt'));
      await tester.pumpAndSettle();
      expect(find.text('HOME_ROUTE'), findsOneWidget);
    });

    testWidgets('transitions from waiting state to Email Verified after timeout when unauthenticated', (tester) async {
      final router = _buildCallbackTestRouter(
        waitTimeout: const Duration(milliseconds: 50),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _TestAuthNotifier(const AuthState())),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      expect(find.text('Confirming your email...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();

      expect(find.text('Email Verified'), findsOneWidget);
      await tester.tap(find.text('Continue to Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN_ROUTE'), findsOneWidget);
    });

    testWidgets('recovery mode validates mismatch/short password and updates valid password', (tester) async {
      final router = _buildCallbackTestRouter(
        initialLocation: '/auth/callback?type=recovery',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _TestAuthNotifier(const AuthState())),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set New Password'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '123');
      await tester.enterText(find.byType(TextField).at(1), '123');
      await tester.tap(find.text('Update Password'));
      await tester.pump();
      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'secret123');
      await tester.enterText(find.byType(TextField).at(1), 'different123');
      await tester.tap(find.text('Update Password'));
      await tester.pump();
      expect(find.text('Passwords do not match.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'secret123');
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN_ROUTE'), findsOneWidget);
    });
  });

  group('SignupScreen & LoginScreen Confirmation UX', () {
    testWidgets('SignupScreen renders Check your email card with resend and sign-in actions when pending confirmation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _TestAuthNotifier(
                const AuthState(
                  pendingConfirmationEmail: 'newuser@example.com',
                  successMessage:
                      'We sent a confirmation link to newuser@example.com. Please check your inbox to activate your account.',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: SignupScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('newuser@example.com'), findsWidgets);
      expect(find.textContaining('bookit.genexis.dev'), findsOneWidget);
      expect(find.text('Resend Confirmation Email'), findsOneWidget);
      expect(find.text('Continue to Sign In'), findsOneWidget);
    });

    testWidgets('LoginScreen displays Resend confirmation email action when error prompts verification', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _TestAuthNotifier(
                const AuthState(
                  error:
                      'Please verify your email address before signing in. Check your inbox for the confirmation link.',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resend confirmation email'), findsOneWidget);
    });
  });

  group('Repository Domain Config Checks', () {
    test('supabase/config.toml and shared stripe helper allow bookit.genexis.dev', () {
      final configToml = File('supabase/config.toml').readAsStringSync();
      expect(configToml, contains('site_url = "https://bookit.genexis.dev"'));
      expect(configToml, contains('"https://bookit.genexis.dev/**"'));
      expect(configToml, contains('enable_confirmations = true'));

      final stripeHelper = File('supabase/functions/_shared/stripe.ts').readAsStringSync();
      expect(stripeHelper, contains("hostname === 'bookit.genexis.dev'"));
      expect(stripeHelper, contains("hostname.endsWith('.genexis.dev')"));
    });
  });
}
