// Gene - Nov, 03, 2026: Widget tests for LoginScreen and ProfileScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/features/auth/presentation/login_screen.dart';
import 'package:bookit/features/auth/presentation/profile_screen.dart';

void main() {
  group('Auth Screens Widget Tests', () {
    testWidgets('LoginScreen renders email, password fields, and demo buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Welcome to BookIt'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Patient Demo'), findsOneWidget);
      expect(find.text('Admin Demo'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders user details, settings list, and sign out', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('My Appointments'), findsOneWidget);
      expect(find.text('Notifications & Reminders'), findsOneWidget);
      expect(find.text('Appearance Mode'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });
}
