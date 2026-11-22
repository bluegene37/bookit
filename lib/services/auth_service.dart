// Gene - Nov, 03, 2026: Enhanced Authentication service with SignUp, SignIn, PasswordReset, Demo accounts, and Supabase Auth integration
// Gene - Nov, 22, 2026: Added dart:async, supabase_flutter alias, and SupabaseConfig imports for live session hydration & shared demo guard
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../core/constants/supabase_config.dart';
// Gene - Nov, 22, 2026: Added AppErrorFormatter and AppErrorLogger imports for friendly auth error notifications
import '../core/utils/app_error_formatter.dart';
import '../core/utils/app_error_logger.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';
// Gene - Nov, 05, 2026: Added DemoData import for multi-persona switching and testing
import '../core/constants/demo_data.dart';

/*
// Gene - Nov, 03, 2026: Original AuthState before pendingConfirmationEmail support
class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  bool get isAuthenticated => user != null;
  bool get isBusinessOwner => user?.isBusinessOwner ?? false;
  // Gene - Nov, 14, 2026: Separate shared admin-workspace entry check from strict owner/admin billing privileges
  bool get canAccessAdminPortal => user?.canAccessAdminPortal ?? false;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}
*/

// Gene - Nov, 22, 2026: Added pendingConfirmationEmail and needsEmailConfirmation to AuthState for email verification flow
class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String? pendingConfirmationEmail;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.pendingConfirmationEmail,
  });

  bool get isAuthenticated => user != null;
  bool get needsEmailConfirmation => pendingConfirmationEmail != null;
  bool get isBusinessOwner => user?.isBusinessOwner ?? false;
  // Gene - Nov, 14, 2026: Separate shared admin-workspace entry check from strict owner/admin billing privileges
  bool get canAccessAdminPortal => user?.canAccessAdminPortal ?? false;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? error,
    String? successMessage,
    String? pendingConfirmationEmail,
    bool clearUser = false,
    bool clearPendingConfirmation = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      pendingConfirmationEmail: clearPendingConfirmation
          ? null
          : (pendingConfirmationEmail ?? this.pendingConfirmationEmail),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  /*
  // Gene - Nov, 05, 2026: Unconditional demo user auto-login on cold boot
  AuthNotifier() : super(AuthState(user: SupabaseService.mockCurrentUser));
  */
  /*
  // Gene - Nov, 14, 2026: Unified demo guard with test hook & unauthenticated cold start in release mode
  @visibleForTesting
  static bool debugSimulateReleaseMode = false;

  static bool get isDemoModeEnabled => !kReleaseMode && !debugSimulateReleaseMode;

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  AuthNotifier() : super(AuthState(user: isDemoModeEnabled ? SupabaseService.mockCurrentUser : null));
  */

  // Gene - Nov, 22, 2026: Delegate demo guard to SupabaseConfig, never auto-login mock user when live Supabase is connected, and hydrate active Supabase session
  @visibleForTesting
  static bool get debugSimulateReleaseMode => SupabaseConfig.debugSimulateReleaseMode;
  @visibleForTesting
  static set debugSimulateReleaseMode(bool value) =>
      SupabaseConfig.debugSimulateReleaseMode = value;

  static bool get isDemoModeEnabled => SupabaseConfig.isDemoModeEnabled;

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  StreamSubscription<supa.AuthState>? _authSub;

  AuthNotifier()
      : super(AuthState(
          user: (SupabaseService.client == null && isDemoModeEnabled)
              ? SupabaseService.mockCurrentUser
              : null,
        )) {
    _initSupabaseSession();
  }

  Future<void> _initSupabaseSession() async {
    final client = SupabaseService.client;
    if (client == null) return;

    final existingSession = client.auth.currentSession;
    if (existingSession != null && state.user == null) {
      final profile = await _loadUserProfile(client, existingSession.user);
      if (mounted) {
        state = AuthState(user: profile);
      }
    }

    _authSub = client.auth.onAuthStateChange.listen((authEvent) async {
      if (!mounted) return;
      final session = authEvent.session;
      if (session != null) {
        final profile = await _loadUserProfile(client, session.user);
        if (mounted) {
          state = AuthState(user: profile);
        }
      } else if (authEvent.event == supa.AuthChangeEvent.signedOut) {
        state = const AuthState(user: null);
      }
    });
  }

  Future<UserProfile> _loadUserProfile(
    supa.SupabaseClient client,
    supa.User authUser,
  ) async {
    try {
      final profileData = await client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      if (profileData != null) {
        return UserProfile.fromJson(profileData);
      }
    } catch (_) {
      // Fallback to auth user metadata if profile row query is delayed
    }

    return UserProfile(
      id: authUser.id,
      email: authUser.email ?? '',
      fullName: (authUser.userMetadata?['full_name'] as String?) ??
          (authUser.email?.split('@').first ?? 'BookIt User'),
      role: (authUser.userMetadata?['role'] as String?) ?? 'client',
      phone: authUser.userMetadata?['phone'] as String?,
      createdAt: DateTime.tryParse(authUser.createdAt) ?? DateTime.now(),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // Gene - Nov, 22, 2026: Clear stale auth error banner state when switching between Login and Signup screens
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null, successMessage: state.successMessage);
    }
  }

  // Gene - Nov, 22, 2026: Clear pending email verification state when returning to login or editing signup form
  void clearPendingConfirmation() {
    if (state.pendingConfirmationEmail != null || state.error != null) {
      state = state.copyWith(error: null, clearPendingConfirmation: true);
    }
  }

  // Gene - Nov, 03, 2026: Sign In implementation with Supabase Auth & Demo fallback
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      // Gene - Nov, 14, 2026: Strict email format validation before auth/string slicing (prevents RangeError on malformed input)
      final normalizedEmail = email.trim();
      final lowerEmail = normalizedEmail.toLowerCase();
      if (!_emailRegex.hasMatch(normalizedEmail)) {
        state = state.copyWith(isLoading: false, error: 'Please enter a valid email address.');
        return false;
      }

      final client = SupabaseService.client;
      if (client != null) {
        final res = await client.auth.signInWithPassword(email: normalizedEmail, password: password);
        if (res.user != null) {
          // Gene - Nov, 22, 2026: Use safe profile loader with metadata fallback instead of brittle .single()
          // final profileData = await client.from('profiles').select().eq('id', res.user!.id).single();
          // state = AuthState(user: UserProfile.fromJson(profileData));
          final profile = await _loadUserProfile(client, res.user!);
          state = AuthState(user: profile);
          return true;
        }
        // Gene - Nov, 22, 2026: Return explicit user-friendly failure when live Supabase auth yields null user instead of falling through to local mock
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to sign in. Please check your email and password and try again.',
        );
        return false;
      }

      // Gene - Nov, 03, 2026: Simple mock fallback role parsing
      // final role = (email.contains('admin') || email.contains('doctor') || email == 'admin@bookit.dev') ? 'business_owner' : 'client';

      // Gene - Nov, 05, 2026: Multi-Persona testing credentials fallback mapping without release guard
      // if (email == 'admin@bookit.dev') ...

      // Gene - Nov, 05, 2026: Guarded multi-persona fallback credentials behind !kReleaseMode to prevent production auth bypasses
      // if (!kReleaseMode) {
      //   if (email == 'admin@bookit.dev') ...
      // }
      // final role = (email.contains('admin') || email.contains('doctor') || email.contains('owner')) ? 'business_owner' : 'client';
      // state = AuthState(user: UserProfile(id: 'user-${email.hashCode}', ..., role: role, ...));

      // Gene - Nov, 14, 2026: Enforce demo guard via isDemoModeEnabled, enforce >= 6 char passwords for non-demo accounts, and eliminate substring privilege escalation
      if (isDemoModeEnabled) {
        if (lowerEmail == 'admin@bookit.dev') {
          state = AuthState(user: DemoData.demoAdmin);
          return true;
        } else if (lowerEmail == 'retreat@bookit.dev') {
          state = AuthState(user: DemoData.demoRetreatOwner);
          return true;
        } else if (lowerEmail == 'staff@bookit.dev') {
          state = AuthState(user: DemoData.demoStaff);
          return true;
        } else if (lowerEmail == 'client@bookit.dev') {
          state = AuthState(user: DemoData.demoClient);
          return true;
        }
      }

      if (password.length < 6) {
        state = state.copyWith(isLoading: false, error: 'Password must be at least 6 characters.');
        return false;
      }

      if (!isDemoModeEnabled) {
        state = state.copyWith(isLoading: false, error: 'Authentication service unavailable. Please check your credentials.');
        return false;
      }

      final localPart = normalizedEmail.split('@').first;
      final displayName = localPart.isEmpty
          ? 'Valued User'
          : (localPart.length == 1
              ? localPart.toUpperCase()
              : '${localPart[0].toUpperCase()}${localPart.substring(1)}');

      state = AuthState(
        user: UserProfile(
          id: 'user-${lowerEmail.hashCode.abs()}',
          email: normalizedEmail,
          fullName: displayName,
          role: 'client',
          createdAt: DateTime.now(),
        ),
      );
      return true;
    /*
    // Gene - Nov, 03, 2026: Raw exception string leaked HTTP status codes & AuthApiException text to LoginScreen
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
    */
    // Gene - Nov, 22, 2026: Log raw auth error internally and surface user-friendly login error message
    } catch (e, st) {
      AppErrorLogger.report(
        service: 'AuthNotifier',
        operation: 'signIn',
        error: e,
        stackTrace: st,
      );
      state = state.copyWith(
        isLoading: false,
        error: AppErrorFormatter.format(e, context: AppErrorContext.login),
      );
      return false;
    }
  }

  // Gene - Nov, 03, 2026: Sign Up implementation creating auth user & profile record
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'client',
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      // Gene - Nov, 14, 2026: Validate full name, email regex, and minimum password strength before registration
      final normalizedEmail = email.trim();
      final trimmedName = fullName.trim();
      if (trimmedName.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'Please enter your full name.');
        return false;
      }
      if (!_emailRegex.hasMatch(normalizedEmail)) {
        state = state.copyWith(isLoading: false, error: 'Please enter a valid email address.');
        return false;
      }
      if (password.length < 6) {
        state = state.copyWith(isLoading: false, error: 'Password must be at least 6 characters.');
        return false;
      }

      final client = SupabaseService.client;
      if (client != null) {
        /*
        // Gene - Nov, 03, 2026: SignUp without emailRedirectTo or pending-confirmation session check
        final res = await client.auth.signUp(
          email: normalizedEmail,
          password: password,
          data: {
            'full_name': trimmedName,
            'role': role,
            'phone': phone,
          },
        );
        if (res.user != null) {
          final newProfile = UserProfile(
            id: res.user!.id,
            email: normalizedEmail,
            fullName: trimmedName,
            role: role,
            phone: phone,
            createdAt: DateTime.now(),
          );
          state = AuthState(user: newProfile, successMessage: 'Account created successfully!');
          return true;
        }
        */
        // Gene - Nov, 22, 2026: Redirect confirmation link to bookit.genexis.dev and enter pending-confirmation state when session is null
        final res = await client.auth.signUp(
          email: normalizedEmail,
          password: password,
          emailRedirectTo: SupabaseConfig.emailConfirmationRedirectUrl,
          data: {
            'full_name': trimmedName,
            'role': role,
            'phone': phone,
          },
        );
        if (res.user != null) {
          if (res.session == null) {
            state = AuthState(
              user: null,
              isLoading: false,
              pendingConfirmationEmail: normalizedEmail,
              successMessage:
                  'We sent a confirmation link to $normalizedEmail. Please check your inbox to activate your account.',
            );
            return true;
          }
          final newProfile = UserProfile(
            id: res.user!.id,
            email: normalizedEmail,
            fullName: trimmedName,
            role: role,
            phone: phone,
            createdAt: DateTime.now(),
          );
          state = AuthState(user: newProfile, successMessage: 'Account created successfully!');
          return true;
        }
        // Gene - Nov, 22, 2026: Return explicit user-friendly failure when live Supabase signUp yields null user instead of falling through to local mock
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to create your account right now. Please try again.',
        );
        return false;
      }

      if (!isDemoModeEnabled) {
        state = state.copyWith(isLoading: false, error: 'Registration service unavailable.');
        return false;
      }

      // Mock Local Fallback
      final mockProfile = UserProfile(
        id: 'new-user-${normalizedEmail.toLowerCase().hashCode.abs()}',
        email: normalizedEmail,
        fullName: trimmedName,
        role: role,
        phone: phone,
        createdAt: DateTime.now(),
      );
      state = AuthState(user: mockProfile, successMessage: 'Account created successfully!');
      return true;
    // Gene - Nov, 03, 2026: Previous Sign Up catch block replaced by dev-mode fallback
    // } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); return false; }

    /*
    // Gene - Nov, 05, 2026: Provide seamless mock profile fallback in !kReleaseMode when Supabase auth is offline or rate-limited
    } catch (e) {
      if (isDemoModeEnabled) {
        debugPrint('Supabase signUp error ($e); establishing authenticated local persona in dev mode.');
        final mockProfile = UserProfile(
          id: 'new-user-${email.trim().toLowerCase().hashCode.abs()}',
          email: email.trim(),
          fullName: fullName.trim(),
          role: role,
          phone: phone,
          createdAt: DateTime.now(),
        );
        state = AuthState(user: mockProfile, successMessage: 'Account created successfully!');
        return true;
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
    */
    // Gene - Nov, 22, 2026: Surface formatted signup errors when live Supabase client is active; keep local fallback only when offline in demo mode
    } catch (e, st) {
      AppErrorLogger.report(
        service: 'AuthNotifier',
        operation: 'signUp',
        error: e,
        stackTrace: st,
      );
      if (SupabaseService.client == null && isDemoModeEnabled) {
        debugPrint('Offline signUp fallback ($e); establishing authenticated local persona in dev mode.');
        final mockProfile = UserProfile(
          id: 'new-user-${email.trim().toLowerCase().hashCode.abs()}',
          email: email.trim(),
          fullName: fullName.trim(),
          role: role,
          phone: phone,
          createdAt: DateTime.now(),
        );
        state = AuthState(user: mockProfile, successMessage: 'Account created successfully!');
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: AppErrorFormatter.format(e, context: AppErrorContext.signup),
      );
      return false;
    }
  }

  // Gene - Nov, 03, 2026: Password reset email trigger
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Gene - Nov, 14, 2026: Enforce valid email format on password reset requests
      final normalizedEmail = email.trim();
      if (!_emailRegex.hasMatch(normalizedEmail)) {
        state = state.copyWith(isLoading: false, error: 'Please enter a valid email address.');
        return false;
      }
      final client = SupabaseService.client;
      if (client != null) {
        /*
        // Gene - Nov, 03, 2026: Password reset call without explicit redirectTo URL
        await client.auth.resetPasswordForEmail(normalizedEmail);
        */
        // Gene - Nov, 22, 2026: Direct password recovery emails to bookit.genexis.dev callback route
        await client.auth.resetPasswordForEmail(
          normalizedEmail,
          redirectTo: SupabaseConfig.passwordResetRedirectUrl,
        );
      }
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset link sent to $normalizedEmail',
      );
      return true;
    /*
    // Gene - Nov, 03, 2026: Raw exception string leaked status codes on password reset failure
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
    */
    // Gene - Nov, 22, 2026: Log raw password reset error internally and surface user-friendly message
    } catch (e, st) {
      AppErrorLogger.report(
        service: 'AuthNotifier',
        operation: 'resetPassword',
        error: e,
        stackTrace: st,
      );
      state = state.copyWith(
        isLoading: false,
        error: AppErrorFormatter.format(e, context: AppErrorContext.passwordReset),
      );
      return false;
    }
  }

  // Gene - Nov, 22, 2026: Resend signup email confirmation targeting bookit.genexis.dev callback
  Future<bool> resendConfirmationEmail(String email) async {
    final normalizedEmail = email.trim();
    if (!_emailRegex.hasMatch(normalizedEmail)) {
      state = state.copyWith(
        isLoading: false,
        error: 'Please enter a valid email address.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final client = SupabaseService.client;
      if (client != null) {
        await client.auth.resend(
          type: supa.OtpType.signup,
          email: normalizedEmail,
          emailRedirectTo: SupabaseConfig.emailConfirmationRedirectUrl,
        );
      }
      state = state.copyWith(
        isLoading: false,
        pendingConfirmationEmail: normalizedEmail,
        successMessage:
            'Confirmation email resent to $normalizedEmail. Please check your inbox.',
      );
      return true;
    } catch (e, st) {
      AppErrorLogger.report(
        service: 'AuthNotifier',
        operation: 'resendConfirmationEmail',
        error: e,
        stackTrace: st,
      );
      state = state.copyWith(
        isLoading: false,
        error: AppErrorFormatter.format(e, context: AppErrorContext.signup),
      );
      return false;
    }
  }

  // Gene - Nov, 22, 2026: Complete password reset flow from /auth/callback?type=recovery
  Future<bool> updatePassword(String newPassword) async {
    if (newPassword.length < 6) {
      state = state.copyWith(
        isLoading: false,
        error: 'Password must be at least 6 characters.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final client = SupabaseService.client;
      if (client != null) {
        await client.auth.updateUser(
          supa.UserAttributes(password: newPassword),
        );
      }
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Your password has been updated successfully!',
      );
      return true;
    } catch (e, st) {
      AppErrorLogger.report(
        service: 'AuthNotifier',
        operation: 'updatePassword',
        error: e,
        stackTrace: st,
      );
      state = state.copyWith(
        isLoading: false,
        error: AppErrorFormatter.format(e, context: AppErrorContext.passwordReset),
      );
      return false;
    }
  }

  // Gene - Nov, 03, 2026: Quick Demo Account login for instant evaluation
  /*
  // Gene - Nov, 05, 2026: Unguarded demo shortcuts & role toggles allowed privilege switching if invoked in release mode
  void loginAsDemoClient() {
    state = AuthState(user: DemoData.demoClient);
  }

  void loginAsDemoAdmin() {
    state = AuthState(user: DemoData.demoAdmin);
  }

  // Gene - Nov, 05, 2026: Additional demo persona shortcuts for recovery stays and staff specialists
  void loginAsDemoRetreatOwner() {
    state = AuthState(user: DemoData.demoRetreatOwner);
  }

  void loginAsDemoStaff() {
    state = AuthState(user: DemoData.demoStaff);
  }

  // Gene - Nov, 05, 2026: Direct persona switching for testing
  void switchPersona(UserProfile profile) {
    state = AuthState(user: profile);
  }

  // Gene - Nov, 05, 2026: Reset in-memory demo datasets back to clean initial state
  void resetDemoData() {
    SupabaseService.resetToDefaultData();
    state = AuthState(user: DemoData.demoAdmin, successMessage: 'Demo data reset to default successfully!');
  }

  void toggleRole() {
    if (state.user == null) return;
    final currentRole = state.user!.role;
    final newRole = currentRole == 'client' ? 'business_owner' : 'client';
    state = state.copyWith(
      user: UserProfile(
        id: state.user!.id,
        email: state.user!.email,
        fullName: state.user!.fullName,
        role: newRole,
        phone: state.user!.phone,
        avatarUrl: state.user!.avatarUrl,
        createdAt: state.user!.createdAt,
      ),
    );
  }
  */
  // Gene - Nov, 14, 2026: Hardened all demo account shortcuts, persona switches, reset triggers, and role toggles behind isDemoModeEnabled
  void loginAsDemoClient() {
    if (!isDemoModeEnabled) return;
    state = AuthState(user: DemoData.demoClient);
  }

  void loginAsDemoAdmin() {
    if (!isDemoModeEnabled) return;
    state = AuthState(user: DemoData.demoAdmin);
  }

  // Gene - Nov, 05, 2026: Additional demo persona shortcuts for recovery stays and staff specialists
  void loginAsDemoRetreatOwner() {
    if (!isDemoModeEnabled) return;
    state = AuthState(user: DemoData.demoRetreatOwner);
  }

  void loginAsDemoStaff() {
    if (!isDemoModeEnabled) return;
    state = AuthState(user: DemoData.demoStaff);
  }

  // Gene - Nov, 05, 2026: Direct persona switching for testing
  void switchPersona(UserProfile profile) {
    if (!isDemoModeEnabled) return;
    state = AuthState(user: profile);
  }

  // Gene - Nov, 05, 2026: Reset in-memory demo datasets back to clean initial state
  void resetDemoData() {
    if (!isDemoModeEnabled) return;
    SupabaseService.resetToDefaultData();
    state = AuthState(user: DemoData.demoAdmin, successMessage: 'Demo data reset to default successfully!');
  }

  void toggleRole() {
    if (!isDemoModeEnabled || state.user == null) return;
    final currentRole = state.user!.role;
    final newRole = currentRole == 'client' ? 'business_owner' : 'client';
    state = state.copyWith(
      user: UserProfile(
        id: state.user!.id,
        email: state.user!.email,
        fullName: state.user!.fullName,
        role: newRole,
        phone: state.user!.phone,
        avatarUrl: state.user!.avatarUrl,
        createdAt: state.user!.createdAt,
      ),
    );
  }

  void signOut() {
    SupabaseService.client?.auth.signOut();
    state = const AuthState(user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/*
// Gene - Nov, 03, 2026: Previous minimal AuthNotifier implementation
class _PreviousAuthNotifier extends StateNotifier<AuthState> {
  _PreviousAuthNotifier() : super(AuthState(user: SupabaseService.mockCurrentUser));
  Future<void> signIn(String email, String password) async {...}
  void toggleRole() {...}
  void signOut() {...}
}
*/
