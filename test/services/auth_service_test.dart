// Gene - Nov, 03, 2026: Unit tests for AuthNotifier, role toggling, and demo sign-in
import 'package:flutter_test/flutter_test.dart';
import 'package:bookit/services/auth_service.dart';

void main() {
  group('AuthNotifier Tests', () {
    late AuthNotifier authNotifier;

    setUp(() {
      authNotifier = AuthNotifier();
    });

    test('initial state has default mock user with business_owner role', () {
      expect(authNotifier.state.isAuthenticated, isTrue);
      expect(authNotifier.state.user?.isBusinessOwner, isTrue);
    });

    test('loginAsDemoClient sets client role and client details', () {
      authNotifier.loginAsDemoClient();
      expect(authNotifier.state.isAuthenticated, isTrue);
      expect(authNotifier.state.user?.role, equals('client'));
      expect(authNotifier.state.user?.isBusinessOwner, isFalse);
      expect(authNotifier.state.user?.email, equals('client@bookit.dev'));
    });

    test('loginAsDemoAdmin sets business_owner role and admin details', () {
      authNotifier.loginAsDemoClient(); // First switch away
      authNotifier.loginAsDemoAdmin(); // Switch to admin
      expect(authNotifier.state.isAuthenticated, isTrue);
      expect(authNotifier.state.user?.role, equals('business_owner'));
      expect(authNotifier.state.user?.isBusinessOwner, isTrue);
    });

    test('toggleRole toggles between client and business_owner', () {
      authNotifier.loginAsDemoClient();
      expect(authNotifier.state.user?.role, equals('client'));

      authNotifier.toggleRole();
      expect(authNotifier.state.user?.role, equals('business_owner'));

      authNotifier.toggleRole();
      expect(authNotifier.state.user?.role, equals('client'));
    });

    test('signOut clears authenticated user state', () {
      expect(authNotifier.state.isAuthenticated, isTrue);
      authNotifier.signOut();
      expect(authNotifier.state.isAuthenticated, isFalse);
      expect(authNotifier.state.user, isNull);
    });

    // Gene - Nov, 05, 2026: Added unit tests for signUp with role assignment and authentication state verification
    test('signUp creates user profile and authenticates session', () async {
      final success = await authNotifier.signUp(
        email: 'dr.newclinic@bookit.dev',
        password: 'securePassword123',
        fullName: 'Dr. Sarah Connor',
        role: 'business_owner',
      );
      expect(success, isTrue);
      expect(authNotifier.state.isAuthenticated, isTrue);
      expect(authNotifier.state.user?.email, equals('dr.newclinic@bookit.dev'));
      expect(authNotifier.state.user?.fullName, equals('Dr. Sarah Connor'));
      expect(authNotifier.state.user?.isBusinessOwner, isTrue);
    });
  });
}
