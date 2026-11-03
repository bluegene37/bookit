// Gene - Nov, 03, 2026: Enhanced Authentication service with SignUp, SignIn, PasswordReset, Demo accounts, and Supabase Auth integration
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

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
  AuthNotifier() : super(AuthState(user: SupabaseService.mockCurrentUser));

  // Gene - Nov, 03, 2026: Sign In implementation with Supabase Auth & Demo fallback
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final res = await client.auth.signInWithPassword(email: email, password: password);
        if (res.user != null) {
          final profileData = await client.from('profiles').select().eq('id', res.user!.id).single();
          state = AuthState(user: UserProfile.fromJson(profileData));
          return true;
        }
      }

      // Demo/Mock Fallback Accounts
      final role = (email.contains('admin') || email.contains('doctor') || email == 'admin@bookit.dev')
          ? 'business_owner'
          : 'client';

      state = AuthState(
        user: UserProfile(
          id: email == 'admin@bookit.dev' ? '00000000-0000-0000-0000-000000000001' : 'user-${email.hashCode}',
          email: email,
          fullName: email == 'admin@bookit.dev'
              ? 'Dr. Alexander Vance'
              : (email.split('@').first[0].toUpperCase() + email.split('@').first.substring(1)),
          role: role,
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
      final client = SupabaseService.client;
      if (client != null) {
        final res = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': role,
            'phone': phone,
          },
        );
        if (res.user != null) {
          final newProfile = UserProfile(
            id: res.user!.id,
            email: email,
            fullName: fullName,
            role: role,
            phone: phone,
            createdAt: DateTime.now(),
          );
          state = AuthState(user: newProfile, successMessage: 'Account created successfully!');
          return true;
        }
      }

      // Mock Local Fallback
      final mockProfile = UserProfile(
        id: 'new-user-${email.hashCode}',
        email: email,
        fullName: fullName,
        role: role,
        phone: phone,
        createdAt: DateTime.now(),
      );
      state = AuthState(user: mockProfile, successMessage: 'Account created successfully!');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Gene - Nov, 03, 2026: Password reset email trigger
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = SupabaseService.client;
      if (client != null) {
        await client.auth.resetPasswordForEmail(email);
      }
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset link sent to $email',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Gene - Nov, 03, 2026: Quick Demo Account login for instant evaluation
  void loginAsDemoClient() {
    state = AuthState(
      user: UserProfile(
        id: '00000000-0000-0000-0000-000000000003',
        email: 'client@bookit.dev',
        fullName: 'Michael Chen',
        role: 'client',
        phone: '+1 (555) 345-6789',
        createdAt: DateTime.now(),
      ),
    );
  }

  void loginAsDemoAdmin() {
    state = AuthState(user: SupabaseService.mockCurrentUser);
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
