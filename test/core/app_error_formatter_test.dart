// Gene - Nov, 22, 2026: Unit and widget tests verifying user-friendly error formatting and LoginScreen failure notifications
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bookit/core/utils/app_error_formatter.dart';
import 'package:bookit/features/auth/presentation/login_screen.dart';
import 'package:bookit/services/auth_service.dart';

void _expectNoRawStatusOrExceptionNoise(String formatted) {
  expect(formatted, isNot(contains('400')));
  expect(formatted, isNot(contains('401')));
  expect(formatted, isNot(contains('403')));
  expect(formatted, isNot(contains('404')));
  expect(formatted, isNot(contains('409')));
  expect(formatted, isNot(contains('422')));
  expect(formatted, isNot(contains('429')));
  expect(formatted, isNot(contains('500')));
  expect(formatted, isNot(contains('503')));
  expect(formatted, isNot(contains('statusCode')));
  expect(formatted, isNot(contains('AuthApiException')));
  expect(formatted, isNot(contains('AuthException')));
  expect(formatted, isNot(contains('PostgrestException')));
  expect(formatted, isNot(contains('FunctionException')));
  expect(formatted, isNot(contains('FunctionsHttpException')));
  expect(formatted, isNot(contains('StorageException')));
}

void main() {
  group('AppErrorFormatter - AuthException', () {
    test('maps invalid credentials (400) in login context cleanly', () {
      const err = AuthApiException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      );
      final formatted = AppErrorFormatter.format(err, context: AppErrorContext.login);
      expect(
        formatted,
        'Incorrect email or password. Please check your credentials and try again.',
      );
      _expectNoRawStatusOrExceptionNoise(formatted);
    });

    test('maps email_not_confirmed (400) to verification prompt', () {
      const err = AuthApiException(
        'Email not confirmed',
        statusCode: '400',
        code: 'email_not_confirmed',
      );
      final formatted = AppErrorFormatter.format(err, context: AppErrorContext.login);
      expect(formatted, contains('verify your email address'));
      _expectNoRawStatusOrExceptionNoise(formatted);
    });

    test('maps user_already_exists / email_exists (422) in signup context', () {
      const err = AuthApiException(
        'User already registered',
        statusCode: '422',
        code: 'user_already_exists',
      );
      final formatted = AppErrorFormatter.format(err, context: AppErrorContext.signup);
      expect(formatted, contains('already exists'));
      _expectNoRawStatusOrExceptionNoise(formatted);
    });

    test('maps AuthWeakPasswordException and weak_password code cleanly', () {
      final weakSubclass = AuthWeakPasswordException(
        message: 'Password is too weak',
        statusCode: '422',
        reasons: const ['length'],
      );
      final formattedSubclass = AppErrorFormatter.format(
        weakSubclass,
        context: AppErrorContext.signup,
      );
      expect(formattedSubclass, contains('too weak'));
      _expectNoRawStatusOrExceptionNoise(formattedSubclass);

      const weakCode = AuthApiException(
        'Password should be at least 6 characters',
        statusCode: '422',
        code: 'weak_password',
      );
      final formattedCode = AppErrorFormatter.format(
        weakCode,
        context: AppErrorContext.signup,
      );
      expect(formattedCode, contains('too weak'));
      _expectNoRawStatusOrExceptionNoise(formattedCode);
    });

    test('maps AuthSessionMissingException and AuthInvalidJwtException cleanly', () {
      final missing = AuthSessionMissingException();
      final invalidJwt = AuthInvalidJwtException('bad token');
      for (final err in [missing, invalidJwt]) {
        final formatted = AppErrorFormatter.format(err, context: AppErrorContext.login);
        expect(formatted, 'Your session has expired. Please sign in again.');
        _expectNoRawStatusOrExceptionNoise(formatted);
      }
    });

    test('maps AuthRetryableFetchException cleanly', () {
      final err = AuthRetryableFetchException(statusCode: '503');
      final formatted = AppErrorFormatter.format(err, context: AppErrorContext.login);
      expect(formatted, contains('check your internet connection'));
      _expectNoRawStatusOrExceptionNoise(formatted);
    });

    test('maps rate limits (429) specifically for login, signup, and passwordReset', () {
      const err = AuthApiException(
        'For security purposes, you can only request this after 45 seconds.',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      );

      final loginMsg = AppErrorFormatter.format(err, context: AppErrorContext.login);
      final signupMsg = AppErrorFormatter.format(err, context: AppErrorContext.signup);
      final resetMsg = AppErrorFormatter.format(err, context: AppErrorContext.passwordReset);

      expect(loginMsg, contains('Too many sign-in attempts'));
      expect(signupMsg, contains('Too many sign-up attempts'));
      expect(resetMsg, contains('password reset email'));
      _expectNoRawStatusOrExceptionNoise(loginMsg);
      _expectNoRawStatusOrExceptionNoise(signupMsg);
      _expectNoRawStatusOrExceptionNoise(resetMsg);
    });

    test('falls back cleanly by status code without leaking status numbers', () {
      const err400Login = AuthApiException('Bad request', statusCode: '400');
      const err401Signup = AuthApiException('Unauthorized', statusCode: '401');
      const err400Reset = AuthApiException('Bad request', statusCode: '400');
      const err403 = AuthApiException('Forbidden', statusCode: '403');
      const err422Signup = AuthApiException('Unprocessable', statusCode: '422');
      const err500 = AuthApiException('Internal server error', statusCode: '500');

      expect(
        AppErrorFormatter.format(err400Login, context: AppErrorContext.login),
        'Incorrect email or password. Please check your credentials and try again.',
      );
      expect(
        AppErrorFormatter.format(err401Signup, context: AppErrorContext.signup),
        'Please check your registration details and try again.',
      );
      expect(
        AppErrorFormatter.format(err400Reset, context: AppErrorContext.passwordReset),
        'Please check your email address and try again.',
      );
      expect(
        AppErrorFormatter.format(err403, context: AppErrorContext.login),
        'You do not have permission to perform this action.',
      );
      expect(
        AppErrorFormatter.format(err422Signup, context: AppErrorContext.signup),
        'Please check your email and password details and try again.',
      );
      expect(
        AppErrorFormatter.format(err500, context: AppErrorContext.login),
        'Our authentication service is temporarily unavailable. Please try again shortly.',
      );

      for (final err in [err400Login, err401Signup, err400Reset, err403, err422Signup, err500]) {
        _expectNoRawStatusOrExceptionNoise(
          AppErrorFormatter.format(err, context: AppErrorContext.login),
        );
      }
    });
  });

  group('AppErrorFormatter - PostgrestException', () {
    test('maps RLS, duplicate, constraint, not found, and raw SQL errors cleanly', () {
      const rls = PostgrestException(message: 'new row violates row-level security policy', code: '42501');
      const dup = PostgrestException(message: 'duplicate key value violates unique constraint', code: '23505');
      const notNull = PostgrestException(message: 'null value in column', code: '23502');
      const fk = PostgrestException(message: 'violates foreign key constraint', code: '23503');
      const check = PostgrestException(message: 'violates check constraint', code: '23514');
      const invalidInput = PostgrestException(message: 'invalid input syntax for type uuid', code: '22P02');
      const noRow = PostgrestException(message: 'JSON object requested, multiple (or no) rows returned', code: 'PGRST116');
      const expiredJwt = PostgrestException(message: 'JWT expired', code: 'PGRST301');
      const timeout = PostgrestException(message: 'canceling statement due to statement timeout', code: '57014');
      const rawSql = PostgrestException(message: 'SELECT * FROM bookings WHERE id = 1 failed', code: 'XX000');

      expect(AppErrorFormatter.format(rls), contains('permission'));
      expect(AppErrorFormatter.format(dup, context: AppErrorContext.booking), contains('time slot'));
      expect(AppErrorFormatter.format(dup, context: AppErrorContext.review), contains('already submitted a review'));
      expect(AppErrorFormatter.format(dup, context: AppErrorContext.business), contains('already exists'));
      expect(AppErrorFormatter.format(notNull), contains('required fields'));
      expect(AppErrorFormatter.format(fk), contains('linked information'));
      expect(AppErrorFormatter.format(check), contains('not valid'));
      expect(AppErrorFormatter.format(invalidInput), contains('Invalid information format'));
      expect(AppErrorFormatter.format(noRow), contains('could not be found'));
      expect(AppErrorFormatter.format(expiredJwt), contains('session has expired'));
      expect(AppErrorFormatter.format(timeout), contains('took too long'));

      final rawSqlFormatted = AppErrorFormatter.format(rawSql, context: AppErrorContext.booking);
      expect(rawSqlFormatted, 'Unable to complete your booking right now. Please try again.');
      expect(rawSqlFormatted, isNot(contains('SELECT')));
    });
  });

  group('AppErrorFormatter - FunctionException & StorageException', () {
    test('maps FunctionsFetchException and FunctionsHttpException across statuses', () {
      const fetchErr = FunctionsFetchException(reasonPhrase: 'Failed to fetch');
      expect(
        AppErrorFormatter.format(fetchErr),
        'Unable to connect to the server. Please check your internet connection and try again.',
      );

      const clean400 = FunctionsHttpException(
        status: 400,
        details: {'error': 'Booking is already paid in full.'},
      );
      expect(
        AppErrorFormatter.format(clean400, context: AppErrorContext.payment),
        'Booking is already paid in full.',
      );

      const noisy400 = FunctionsHttpException(
        status: 400,
        details: {'error': 'Edge Function returned a non-2xx status code: 400'},
      );
      final noisyFormatted = AppErrorFormatter.format(
        noisy400,
        context: AppErrorContext.payment,
      );
      expect(noisyFormatted, 'Unable to process your payment right now. Please try again.');
      _expectNoRawStatusOrExceptionNoise(noisyFormatted);

      const http401 = FunctionsHttpException(status: 401, details: 'Unauthorized');
      const http403 = FunctionsHttpException(status: 403, details: 'Forbidden');
      const http404Payment = FunctionsHttpException(status: 404, details: 'Not found');
      const http409 = FunctionsHttpException(status: 409, details: 'Conflict');
      const http429 = FunctionsHttpException(status: 429, details: 'Rate limited');
      const http503 = FunctionsHttpException(status: 503, details: 'Service unavailable');

      expect(AppErrorFormatter.format(http401), contains('session has expired'));
      expect(AppErrorFormatter.format(http403), contains('permission'));
      expect(
        AppErrorFormatter.format(http404Payment, context: AppErrorContext.refund),
        'This payment or booking record could not be found.',
      );
      expect(AppErrorFormatter.format(http409), contains('conflicts'));
      expect(AppErrorFormatter.format(http429), contains('Too many requests'));
      expect(AppErrorFormatter.format(http503), contains('temporarily unavailable'));
    });

    test('maps StorageException statuses cleanly', () {
      const s403 = StorageException('Forbidden', statusCode: '403');
      const s413 = StorageException('Payload too large', statusCode: '413');
      const s404 = StorageException('Not found', statusCode: '404');
      const s500 = StorageException('Server error', statusCode: '500');

      expect(AppErrorFormatter.format(s403), contains('permission'));
      expect(AppErrorFormatter.format(s413), contains('too large'));
      expect(AppErrorFormatter.format(s404), contains('could not be found'));
      expect(AppErrorFormatter.format(s500), 'Unable to process the file right now. Please try again.');
    });
  });

  group('AppErrorFormatter - Runtime, Network & Stringified Errors', () {
    test('maps TimeoutException, ClientException, FormatException, and StateError', () {
      expect(
        AppErrorFormatter.format(TimeoutException('Timed out')),
        contains('timed out'),
      );
      expect(
        AppErrorFormatter.format(http.ClientException('XMLHttpRequest error')),
        contains('check your internet connection'),
      );
      expect(
        AppErrorFormatter.format(const FormatException('Unexpected character')),
        contains('unexpected response'),
      );
      expect(
        AppErrorFormatter.format(StateError('Stripe checkout returned mock session in production mode.')),
        'Online card checkout is temporarily unavailable. Please choose another payment method or try again later.',
      );
    });

    test('strips stringified AuthApiException noise while preserving clean user Exceptions', () {
      final stringified = Exception(
        'AuthApiException(message: Invalid login credentials, statusCode: 400, code: invalid_credentials)',
      );
      final formattedStringified = AppErrorFormatter.format(
        stringified,
        context: AppErrorContext.login,
      );
      expect(
        formattedStringified,
        'Incorrect email or password. Please check your credentials and try again.',
      );
      _expectNoRawStatusOrExceptionNoise(formattedStringified);

      final cleanException = Exception('Please choose a later time.');
      expect(
        AppErrorFormatter.format(cleanException, context: AppErrorContext.booking),
        'Please choose a later time.',
      );

      final genericStatusString = Exception('Request failed with status 500 from upstream');
      final fallbackFormatted = AppErrorFormatter.format(
        genericStatusString,
        context: AppErrorContext.login,
      );
      expect(
        fallbackFormatted,
        'Unable to sign in right now. Please check your email and password and try again.',
      );
      _expectNoRawStatusOrExceptionNoise(fallbackFormatted);
    });
  });

  group('LoginScreen & AuthNotifier Error UX', () {
    testWidgets('shows friendly error banner & SnackBar on failed sign-in and clears via clearError()', (tester) async {
      AuthNotifier.debugSimulateReleaseMode = true;
      addTearDown(() => AuthNotifier.debugSimulateReleaseMode = false);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrongpass123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      final err = container.read(authProvider).error;
      expect(err, isNotNull);
      _expectNoRawStatusOrExceptionNoise(err!);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text(err), findsNWidgets(2)); // Inline banner + floating SnackBar

      container.read(authProvider.notifier).clearError();
      await tester.pump();
      expect(container.read(authProvider).error, isNull);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });
  });
}
