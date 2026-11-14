// Gene - Nov, 03, 2026: Enhanced Authentication service with SignUp, SignIn, PasswordReset, Demo accounts, and Supabase Auth integration
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';
// Gene - Nov, 05, 2026: Added DemoData import for multi-persona switching and testing
import '../core/constants/demo_data.dart';

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

class AuthNotifier extends StateNotifier<AuthState> {
  /*
  // Gene - Nov, 05, 2026: Unconditional demo user auto-login on cold boot
  AuthNotifier() : super(AuthState(user: SupabaseService.mockCurrentUser));
  */
  // Gene - Nov, 14, 2026: Unified demo guard with test hook & unauthenticated cold start in release mode
  @visibleForTesting
  static bool debugSimulateReleaseMode = false;

  static bool get isDemoModeEnabled => !kReleaseMode && !debugSimulateReleaseMode;

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  AuthNotifier() : super(AuthState(user: isDemoModeEnabled ? SupabaseService.mockCurrentUser : null));

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
          final profileData = await client.from('profiles').select().eq('id', res.user!.id).single();
          state = AuthState(user: UserProfile.fromJson(profileData));
          return true;
        }
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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
        await client.auth.resetPasswordForEmail(normalizedEmail);
      }
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset link sent to $normalizedEmail',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
