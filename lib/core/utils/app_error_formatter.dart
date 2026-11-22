// Gene - Nov, 22, 2026: Centralized user-friendly error message formatter stripping raw exception names and HTTP/DB status codes
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppErrorContext {
  general,
  login,
  signup,
  passwordReset,
  booking,
  payment,
  refund,
  business,
  service,
  staff,
  review,
  map,
}

class AppErrorFormatter {
  AppErrorFormatter._();

  static final RegExp _exceptionClassPattern = RegExp(
    r'\b(AuthApiException|AuthException|AuthRetryableFetchException|AuthSessionMissingException|AuthWeakPasswordException|AuthInvalidJwtException|AuthUnknownException|PostgrestException|FunctionException|FunctionsHttpException|FunctionsFetchException|FunctionsRelayException|StorageException|ClientException|SocketException|HandshakeException|TlsException|FormatException|PlatformException|StateError|TypeError|RangeError|NoSuchMethodError|Bad state:|Instance of)\b',
  );

  static final RegExp _statusOrMetaPattern = RegExp(
    r'(statusCode|status:|code:|details:|hint:|reasonPhrase|non-2xx|HTTP\s*[45]\d{2}|\b(?:400|401|403|404|409|422|429|500|502|503|504)\b)',
    caseSensitive: false,
  );

  static final RegExp _sqlOrTracePattern = RegExp(
    r'(\n#0|#0\s+|\{|\}|postgres|supabase\.co)',
    caseSensitive: false,
  );

  static final RegExp _sqlKeywordPattern = RegExp(
    r'\b(?:SELECT|INSERT|UPDATE|DELETE)\s',
  );

  static String format(
    Object error, {
    AppErrorContext context = AppErrorContext.general,
    String? fallback,
  }) {
    if (error is AuthException) {
      return _formatAuthException(error, context: context, fallback: fallback);
    }
    if (error is PostgrestException) {
      return _formatPostgrestException(error, context: context, fallback: fallback);
    }
    if (error is FunctionException) {
      return _formatFunctionException(error, context: context, fallback: fallback);
    }
    if (error is StorageException) {
      return _formatStorageException(error);
    }
    if (error is TimeoutException) {
      return 'The request timed out. Please check your internet connection and try again.';
    }
    if (error is http.ClientException) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }
    if (error is FormatException) {
      return 'We received an unexpected response from the server. Please try again.';
    }
    if (error is StateError) {
      final msg = error.message.toLowerCase();
      if (msg.contains('stripe') || msg.contains('mock session')) {
        return 'Online card checkout is temporarily unavailable. Please choose another payment method or try again later.';
      }
      return fallback ?? _defaultForContext(context);
    }

    final typeName = error.runtimeType.toString();
    if (typeName.contains('SocketException') ||
        typeName.contains('HandshakeException') ||
        typeName.contains('TlsException')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    return _formatGenericError(error, context: context, fallback: fallback);
  }

  static String _formatAuthException(
    AuthException error, {
    required AppErrorContext context,
    String? fallback,
  }) {
    if (error is AuthRetryableFetchException) {
      return 'Unable to reach the authentication server. Please check your internet connection and try again.';
    }
    if (error is AuthSessionMissingException || error is AuthInvalidJwtException) {
      return 'Your session has expired. Please sign in again.';
    }
    if (error is AuthWeakPasswordException) {
      return 'Your password is too weak. Please choose a stronger password with at least 6 characters.';
    }

    final code = (error.code ?? '').toLowerCase().trim();
    final msg = error.message.toLowerCase();
    final status = (error.statusCode ?? '').trim();

    if (code == 'invalid_credentials' ||
        code == 'invalid_grant' ||
        msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password')) {
      return 'Incorrect email or password. Please check your credentials and try again.';
    }
    if (code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
      return 'Please verify your email address before signing in. Check your inbox for the confirmation link.';
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        msg.contains('already registered') ||
        msg.contains('already exists')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (code == 'phone_exists') {
      return 'An account with this phone number already exists.';
    }
    if (code == 'user_not_found' || msg.contains('user not found')) {
      return 'No account was found with this email address. Please check your email or create a new account.';
    }
    if (code == 'user_banned' || msg.contains('banned')) {
      return 'This account has been suspended. Please contact support for assistance.';
    }
    if (code == 'weak_password' ||
        msg.contains('weak password') ||
        msg.contains('password should be at least')) {
      return 'Your password is too weak. Please use at least 6 characters with a stronger combination.';
    }
    if (code == 'same_password' || msg.contains('different from the old password')) {
      return 'Please choose a new password that is different from your current one.';
    }
    if (code == 'signup_disabled') {
      return 'New account registration is currently disabled. Please contact support.';
    }
    if (code == 'email_provider_disabled' || code == 'provider_disabled') {
      return 'Email sign-in is currently unavailable. Please try again later.';
    }
    if (code == 'over_request_rate_limit' ||
        code == 'over_email_send_rate_limit' ||
        code == 'over_sms_send_rate_limit' ||
        status == '429' ||
        msg.contains('rate limit') ||
        msg.contains('too many requests') ||
        msg.contains('only request this after')) {
      return _rateLimitMessage(context);
    }
    if (code == 'otp_expired' || code == 'flow_state_expired') {
      return 'This verification or reset link has expired. Please request a new one.';
    }
    if (code == 'session_expired' ||
        code == 'session_missing' ||
        code == 'session_not_found' ||
        code == 'bad_jwt' ||
        code == 'no_authorization') {
      return 'Your session has expired. Please sign in again.';
    }
    if (code == 'request_timeout' ||
        code == 'hook_timeout' ||
        code == 'hook_timeout_after_retry') {
      return 'The request timed out. Please check your connection and try again.';
    }
    if (code == 'email_address_invalid' ||
        (msg.contains('email') && msg.contains('invalid'))) {
      return 'Please enter a valid email address.';
    }
    if (code == 'validation_failed' || code == 'bad_json') {
      switch (context) {
        case AppErrorContext.login:
          return 'Please check your email address and password and try again.';
        case AppErrorContext.signup:
          return 'Please check your registration details and try again.';
        default:
          return 'Please check the information you entered and try again.';
      }
    }

    if (status == '400' || status == '401') {
      switch (context) {
        case AppErrorContext.login:
          return 'Incorrect email or password. Please check your credentials and try again.';
        case AppErrorContext.signup:
          return 'Please check your registration details and try again.';
        case AppErrorContext.passwordReset:
          return 'Please check your email address and try again.';
        default:
          return 'Your session is invalid or expired. Please sign in again.';
      }
    }
    if (status == '403') {
      return 'You do not have permission to perform this action.';
    }
    if (status == '422') {
      if (context == AppErrorContext.signup) {
        return 'Please check your email and password details and try again.';
      }
      return 'Please check the information you entered and try again.';
    }
    if (status.startsWith('5')) {
      return 'Our authentication service is temporarily unavailable. Please try again shortly.';
    }

    if (_hasNetworkNoise(msg)) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }
    if (_hasTimeoutNoise(msg)) {
      return 'The request timed out. Please check your internet connection and try again.';
    }

    return fallback ?? _defaultForContext(context);
  }

  static String _formatPostgrestException(
    PostgrestException error, {
    required AppErrorContext context,
    String? fallback,
  }) {
    final code = (error.code ?? '').toUpperCase().trim();
    final msg = error.message.toLowerCase();

    if (code == '42501' ||
        msg.contains('row-level security') ||
        msg.contains('permission denied')) {
      return 'You do not have permission to perform this action. Please sign in with an authorized account.';
    }
    if (code == 'PGRST301' ||
        msg.contains('jwt expired') ||
        msg.contains('invalid jwt')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (code == '23505' ||
        msg.contains('duplicate key') ||
        msg.contains('unique constraint')) {
      return _duplicateMessage(context);
    }
    if (code == '23503') {
      return 'Some linked information could not be found. Please refresh and try again.';
    }
    if (code == '23502') {
      return 'Please fill out all required fields before saving.';
    }
    if (code == '23514') {
      return 'Some of the details entered are not valid. Please review and try again.';
    }
    if (code == '22P02') {
      return 'Invalid information format. Please refresh the page and try again.';
    }
    if (code == 'PGRST116') {
      return 'The requested item could not be found. It may have been removed.';
    }
    if (code == '57014') {
      return 'The request took too long. Please try again.';
    }

    if (context == AppErrorContext.booking &&
        (msg.contains('already booked') ||
            msg.contains('slot') ||
            msg.contains('overlap') ||
            msg.contains('conflict') ||
            msg.contains('capacity') ||
            msg.contains('unavailable'))) {
      return 'This time slot is no longer available. Please select another time.';
    }

    return fallback ?? _defaultForContext(context);
  }

  static String _formatFunctionException(
    FunctionException error, {
    required AppErrorContext context,
    String? fallback,
  }) {
    if (error is FunctionsFetchException || error.status == 0) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }

    switch (error.status) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        if (context == AppErrorContext.payment ||
            context == AppErrorContext.refund) {
          return 'This payment or booking record could not be found.';
        }
        return 'The requested service could not be found. Please try again later.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
    }

    if (error.status >= 500) {
      return 'The service is temporarily unavailable. Please try again shortly.';
    }

    final details = error.details;
    if (details is Map) {
      final candidate = details['error'] ?? details['message'];
      if (candidate is String) {
        final clean = _extractCleanUserMessage(candidate);
        if (clean != null) return clean;
      }
    } else if (details is String) {
      final clean = _extractCleanUserMessage(details);
      if (clean != null) return clean;
    }

    if (error.status == 409) {
      return 'This action conflicts with the current record status. Please refresh and try again.';
    }

    return fallback ?? _defaultForContext(context);
  }

  static String _formatStorageException(StorageException error) {
    final status = (error.statusCode ?? '').trim();
    if (status == '401' || status == '403') {
      return 'You do not have permission to upload or access this file.';
    }
    if (status == '413') {
      return 'The selected file is too large. Please choose a smaller file.';
    }
    if (status == '404') {
      return 'The requested file could not be found.';
    }
    return 'Unable to process the file right now. Please try again.';
  }

  static String _formatGenericError(
    Object error, {
    required AppErrorContext context,
    String? fallback,
  }) {
    final raw = error.toString().trim();
    final stripped = raw
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .trim();
    final lower = stripped.toLowerCase();

    if (_hasNetworkNoise(lower)) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }
    if (_hasTimeoutNoise(lower)) {
      return 'The request timed out. Please check your internet connection and try again.';
    }

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please check your credentials and try again.';
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('email_not_confirmed')) {
      return 'Please verify your email address before signing in. Check your inbox for the confirmation link.';
    }
    if (lower.contains('already registered') ||
        lower.contains('user_already_exists') ||
        lower.contains('email_exists')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (lower.contains('rate limit') ||
        lower.contains('over_request_rate_limit') ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('429')) {
      return _rateLimitMessage(context);
    }
    if (lower.contains('weak_password') || lower.contains('weak password')) {
      return 'Your password is too weak. Please use at least 6 characters with a stronger combination.';
    }
    if (lower.contains('user_not_found')) {
      return 'No account was found with this email address. Please check your email or create a new account.';
    }
    if (lower.contains('user_banned')) {
      return 'This account has been suspended. Please contact support for assistance.';
    }
    if (lower.contains('jwt expired') ||
        lower.contains('invalid_jwt') ||
        lower.contains('session_expired')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (lower.contains('23505') || lower.contains('duplicate key')) {
      return _duplicateMessage(context);
    }
    if (lower.contains('42501') || lower.contains('row-level security')) {
      return 'You do not have permission to perform this action. Please sign in with an authorized account.';
    }
    if (lower.contains('23502')) {
      return 'Please fill out all required fields before saving.';
    }
    if (lower.contains('pgrst116')) {
      return 'The requested item could not be found. It may have been removed.';
    }

    final clean = _extractCleanUserMessage(stripped);
    if (clean != null) return clean;

    return fallback ?? _defaultForContext(context);
  }

  static const Set<String> _bareHttpPhrases = {
    'bad request',
    'unauthorized',
    'forbidden',
    'not found',
    'conflict',
    'unprocessable entity',
    'too many requests',
    'internal server error',
    'bad gateway',
    'service unavailable',
    'gateway timeout',
  };

  static String? _extractCleanUserMessage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.length > 220) return null;
    if (_bareHttpPhrases.contains(trimmed.toLowerCase())) return null;
    if (_exceptionClassPattern.hasMatch(trimmed)) return null;
    if (_statusOrMetaPattern.hasMatch(trimmed)) return null;
    if (_sqlOrTracePattern.hasMatch(trimmed)) return null;
    if (_sqlKeywordPattern.hasMatch(trimmed)) return null;
    return trimmed;
  }

  static bool _hasNetworkNoise(String lower) {
    return lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('failed to fetch') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('network is unreachable') ||
        lower.contains('clientexception') ||
        lower.contains('handshakeexception');
  }

  static bool _hasTimeoutNoise(String lower) {
    return lower.contains('timeoutexception') || lower.contains('timed out');
  }

  static String _rateLimitMessage(AppErrorContext context) {
    switch (context) {
      case AppErrorContext.passwordReset:
        return 'Please wait a minute before requesting another password reset email.';
      case AppErrorContext.signup:
        return 'Too many sign-up attempts. Please wait a moment and try again.';
      default:
        return 'Too many sign-in attempts. Please wait a moment and try again.';
    }
  }

  static String _duplicateMessage(AppErrorContext context) {
    switch (context) {
      case AppErrorContext.booking:
        return 'This time slot has just been booked. Please select another available time.';
      case AppErrorContext.review:
        return 'You have already submitted a review for this booking.';
      default:
        return 'This record already exists. Please check your details and try again.';
    }
  }

  static String _defaultForContext(AppErrorContext context) {
    switch (context) {
      case AppErrorContext.login:
        return 'Unable to sign in right now. Please check your email and password and try again.';
      case AppErrorContext.signup:
        return 'Unable to create your account right now. Please check your details and try again.';
      case AppErrorContext.passwordReset:
        return 'Unable to send the password reset email right now. Please try again.';
      case AppErrorContext.booking:
        return 'Unable to complete your booking right now. Please try again.';
      case AppErrorContext.payment:
        return 'Unable to process your payment right now. Please try again.';
      case AppErrorContext.refund:
        return 'Unable to process the refund right now. Please try again.';
      case AppErrorContext.business:
        return 'Unable to save your business details right now. Please try again.';
      case AppErrorContext.service:
        return 'Unable to save the service right now. Please try again.';
      case AppErrorContext.staff:
        return 'Unable to save the staff details right now. Please try again.';
      case AppErrorContext.review:
        return 'Unable to submit your review right now. Please try again.';
      case AppErrorContext.map:
        return 'Could not open map navigation on this device.';
      case AppErrorContext.general:
        return 'Something went wrong. Please try again.';
    }
  }
}
