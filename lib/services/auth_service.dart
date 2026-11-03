// Gene - Nov, 03, 2026: Authentication service and Riverpod state provider with role toggling for testing
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
  bool get isBusinessOwner => user?.isBusinessOwner ?? false;

  AuthState copyWith({UserProfile? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(user: SupabaseService.mockCurrentUser));

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final res = await client.auth.signInWithPassword(email: email, password: password);
        if (res.user != null) {
          final profileData = await client.from('profiles').select().eq('id', res.user!.id).single();
          state = AuthState(user: UserProfile.fromJson(profileData));
          return;
        }
      }
      // Demo mock fallback
      state = AuthState(
        user: UserProfile(
          id: 'user-demo-1',
          email: email,
          fullName: email.split('@').first,
          role: email.contains('admin') ? 'business_owner' : 'client',
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
