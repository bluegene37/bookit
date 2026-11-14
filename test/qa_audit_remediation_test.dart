// Gene - Nov, 14, 2026: Permanent QA remediation regression suite covering security/validation probes (A-G), 60-cell responsive & text-scale matrix, and 7x4 WCAG 2.1 AA accessibility matrix.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:bookit/core/constants/demo_data.dart';
import 'package:bookit/core/theme/neumorphic_theme.dart';
import 'package:bookit/core/widgets/neumorphic_button.dart';
import 'package:bookit/features/admin/presentation/admin_shell_screen.dart';
import 'package:bookit/features/admin/presentation/widgets/admin_onboarding_wizard.dart';
import 'package:bookit/features/admin/presentation/widgets/refund_dialog.dart';
import 'package:bookit/features/auth/presentation/login_screen.dart';
import 'package:bookit/features/auth/presentation/profile_screen.dart';
import 'package:bookit/features/auth/presentation/signup_screen.dart';
import 'package:bookit/features/booking_engine/presentation/universal_booking_screen.dart';
import 'package:bookit/features/client_bookings/presentation/client_bookings_screen.dart';
import 'package:bookit/features/discovery/presentation/business_detail_screen.dart';
import 'package:bookit/features/discovery/presentation/home_discovery_screen.dart';
import 'package:bookit/features/notifications/presentation/notifications_screen.dart';
import 'package:bookit/models/payment.dart';
import 'package:bookit/models/user_profile.dart';
import 'package:bookit/services/auth_service.dart';

class _ViewportProfile {
  final String label;
  final Size size;
  final double textScale;
  final Brightness brightness;

  const _ViewportProfile({
    required this.label,
    required this.size,
    required this.textScale,
    required this.brightness,
  });
}

const List<_ViewportProfile> _matrixProfiles = [
  _ViewportProfile(label: '320x568@1.5x Light', size: Size(320, 568), textScale: 1.5, brightness: Brightness.light),
  _ViewportProfile(label: '375x812@1.0x Light', size: Size(375, 812), textScale: 1.0, brightness: Brightness.light),
  _ViewportProfile(label: '375x812@1.5x Dark', size: Size(375, 812), textScale: 1.5, brightness: Brightness.dark),
  _ViewportProfile(label: '768x1024@1.0x Light', size: Size(768, 1024), textScale: 1.0, brightness: Brightness.light),
  _ViewportProfile(label: '1440x900@1.0x Dark', size: Size(1440, 900), textScale: 1.0, brightness: Brightness.dark),
];

Future<void> _loadMaterialFonts() async {
  final envRoot = Platform.environment['FLUTTER_ROOT'];
  final candidateDirs = <String>[
    if (envRoot != null && envRoot.isNotEmpty) '$envRoot/bin/cache/artifacts/material_fonts',
    '/Users/bluegene37/flutter/bin/cache/artifacts/material_fonts',
  ];

  Directory? fontDir;
  for (final path in candidateDirs) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      fontDir = dir;
      break;
    }
  }
  if (fontDir == null) return;

  final robotoLoader = FontLoader('Roboto');
  const robotoFiles = [
    'Roboto-Thin.ttf',
    'Roboto-Light.ttf',
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ];
  for (final filename in robotoFiles) {
    final file = File('${fontDir.path}/$filename');
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      robotoLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await robotoLoader.load();

  final iconsFile = File('${fontDir.path}/MaterialIcons-Regular.otf');
  if (iconsFile.existsSync()) {
    final iconsLoader = FontLoader('MaterialIcons');
    final bytes = await iconsFile.readAsBytes();
    iconsLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await iconsLoader.load();
  }
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

Future<void> _resetSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(null);
  tester.view.resetPhysicalSize();
}

Future<void> _pumpBounded(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _assertScreenMatrixCell({
  required WidgetTester tester,
  required String screenName,
  required Widget Function(ProviderContainer container) builder,
  void Function(ProviderContainer container)? configureAuth,
}) async {
  final oldOnError = FlutterError.onError;
  final recordedErrors = <FlutterErrorDetails>[];
  FlutterError.onError = (details) {
    recordedErrors.add(details);
  };
  try {
    for (final profile in _matrixProfiles) {
      recordedErrors.clear();
      await _setSurface(tester, profile.size);

      final container = ProviderContainer();
      if (configureAuth != null) {
        configureAuth(container);
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: NeumorphicTheme.lightTheme,
            darkTheme: NeumorphicTheme.darkTheme,
            themeMode: profile.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(textScaler: TextScaler.linear(profile.textScale)),
                child: child!,
              );
            },
            home: builder(container),
          ),
        ),
      );

      await _pumpBounded(tester);

      final syncException = tester.takeException();
      expect(
        syncException,
        isNull,
        reason: 'Unexpected exception on $screenName @ ${profile.label}: $syncException',
      );
      expect(
        recordedErrors,
        isEmpty,
        reason: 'FlutterError on $screenName @ ${profile.label}: '
            '${recordedErrors.map((e) => e.exceptionAsString()).join('\n')}',
      );

      container.dispose();
    }
  } finally {
    FlutterError.onError = oldOnError;
    await _resetSurface(tester);
  }
}

Future<void> _verifyWcagTarget({
  required WidgetTester tester,
  required String targetName,
  required Size size,
  required Brightness brightness,
  required Widget Function() builder,
  void Function(ProviderContainer container)? configureAuth,
}) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  await _setSurface(tester, size);
  final container = ProviderContainer();
  if (configureAuth != null) {
    configureAuth(container);
  }

  try {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: NeumorphicTheme.lightTheme,
          darkTheme: NeumorphicTheme.darkTheme,
          themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          home: builder(),
        ),
      ),
    );
    await _pumpBounded(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  } finally {
    handle.dispose();
    container.dispose();
    await _resetSurface(tester);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = _QaHttpOverrides();
    await _loadMaterialFonts();
  });

  group('Gate 2 & Gate 5: Auth, Validation, RBAC & Navigation Probes (A-G)', () {
    test('Probes A1-A3 & B2: AuthNotifier rejects malformed emails, short passwords, and email-substring escalation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(authProvider.notifier);

      for (final badEmail in ['@example.com', 'user@', 'not-an-email', '', '   ']) {
        final signInOk = await notifier.signIn(badEmail, 'password123');
        expect(signInOk, isFalse, reason: 'signIn should reject "$badEmail"');
        expect(container.read(authProvider).error, 'Please enter a valid email address.');

        final resetOk = await notifier.resetPassword(badEmail);
        expect(resetOk, isFalse, reason: 'resetPassword should reject "$badEmail"');

        final signUpOk = await notifier.signUp(
          email: badEmail,
          password: 'password123',
          fullName: 'Test User',
        );
        expect(signUpOk, isFalse, reason: 'signUp should reject "$badEmail"');
      }

      // Short password rejected on non-demo account
      final shortPassOk = await notifier.signIn('patient@example.com', '12345');
      expect(shortPassOk, isFalse);
      expect(container.read(authProvider).error, 'Password must be at least 6 characters.');

      // Email-substring privilege escalation blocked
      for (final attackerEmail in ['fakeadmin@evil.com', 'doctor.spoof@evil.com', 'owner.test@evil.com']) {
        final ok = await notifier.signIn(attackerEmail, 'password123');
        expect(ok, isTrue);
        final user = container.read(authProvider).user;
        expect(user, isNotNull);
        expect(user!.role, 'client', reason: '$attackerEmail must remain client');
        expect(user.isBusinessOwner, isFalse);
        expect(user.canAccessAdminPortal, isFalse);
      }
    });

    testWidgets('Probes C & D: LoginScreen & SignupScreen form validation & controller lifecycle stay safe', (tester) async {
      await _setSurface(tester, const Size(430, 900));
      addTearDown(() => _resetSurface(tester));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // LoginScreen: malformed email validation + Forgot Password dialog
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await _pumpBounded(tester);

      await tester.enterText(find.byType(TextField).at(0), 'invalid-email');
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      expect(find.text('Reset Password'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).last, 'bad-reset');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();
      expect(find.text('Please enter a valid email address.'), findsWidgets);

      ScaffoldMessenger.of(tester.element(find.byType(LoginScreen))).clearSnackBars();
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).last, 'client@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();
      expect(find.text('Reset email sent to client@example.com'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(LoginScreen))).clearSnackBars();
      await tester.pump();

      // SignupScreen: validation feedback + no disposal error
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            key: ValueKey('signup-app'),
            home: SignupScreen(),
          ),
        ),
      );
      await _pumpBounded(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Alex Rivera');
      await tester.enterText(find.byType(TextField).at(1), 'alex@example.com');
      await tester.enterText(find.byType(TextField).at(3), '123');
      await tester.enterText(find.byType(TextField).at(4), '123');
      final createAccountBtn = find.widgetWithText(NeumorphicButton, 'Create Account');
      await tester.ensureVisible(createAccountBtn);
      await _pumpBounded(tester);
      await tester.tap(createAccountBtn);
      await tester.pump();
      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Probe F: debugSimulateReleaseMode locks down demo shortcuts, demo auth bypass, and demo UI badges', (tester) async {
      AuthNotifier.debugSimulateReleaseMode = true;
      addTearDown(() => AuthNotifier.debugSimulateReleaseMode = false);

      expect(AuthNotifier.isDemoModeEnabled, isFalse);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Starts unauthenticated in release mode
      expect(container.read(authProvider).user, isNull);

      final notifier = container.read(authProvider.notifier);
      notifier.loginAsDemoAdmin();
      notifier.loginAsDemoClient();
      notifier.loginAsDemoRetreatOwner();
      notifier.loginAsDemoStaff();
      notifier.switchPersona(DemoData.demoAdmin);
      notifier.resetDemoData();
      notifier.toggleRole();
      expect(container.read(authProvider).user, isNull);

      final demoBypassOk = await notifier.signIn('admin@bookit.dev', '123456');
      expect(demoBypassOk, isFalse);
      expect(container.read(authProvider).user, isNull);

      await _setSurface(tester, const Size(430, 900));
      addTearDown(() => _resetSurface(tester));

      for (final screen in const <Widget>[
        LoginScreen(),
        ProfileScreen(),
        HomeDiscoveryScreen(),
        ClientBookingsScreen(),
        AdminShellScreen(),
      ]) {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: screen),
          ),
        );
        await _pumpBounded(tester);
        expect(find.textContaining('Patient Demo'), findsNothing);
        expect(find.textContaining('Admin Demo'), findsNothing);
        expect(find.textContaining('Retreat Demo'), findsNothing);
        expect(find.textContaining('Staff Demo'), findsNothing);
        expect(find.textContaining('Switch Demo Persona'), findsNothing);
      }
    });

    testWidgets('Probe E: Multi-tenant isolation for owners, empty-owner zero-state, and staff RBAC scoping', (tester) async {
      // 1. Retreat owner sees retreat clinics and NEVER sees Apex Dental
      await _setSurface(tester, const Size(1440, 900));
      addTearDown(() => _resetSurface(tester));

      final retreatContainer = ProviderContainer();
      addTearDown(retreatContainer.dispose);
      retreatContainer.read(authProvider.notifier).loginAsDemoRetreatOwner();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: retreatContainer,
          child: const MaterialApp(home: AdminShellScreen()),
        ),
      );
      await _pumpBounded(tester);

      expect(find.textContaining('Serenity Post-Op Recovery & Wellness Suites'), findsWidgets);
      expect(find.textContaining('Apex Dental & Orthodontic Care'), findsNothing);

      // 2. Owner with zero businesses sees zero-state screen
      final zeroContainer = ProviderContainer();
      addTearDown(zeroContainer.dispose);
      zeroContainer.read(authProvider.notifier).switchPersona(
            UserProfile(
              id: 'owner-brand-new-999',
              email: 'newowner@clinic.com',
              fullName: 'Dr. Brand New',
              role: 'business_owner',
              createdAt: DateTime(2026, 11, 14),
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: zeroContainer,
          child: const MaterialApp(home: AdminShellScreen()),
        ),
      );
      await _pumpBounded(tester);
      expect(find.text('Welcome to BookIt Workspace'), findsOneWidget);

      // 3. Staff user is admitted to assigned clinic without Add Business, Payments & Invoices, or Template & Settings
      final staffContainer = ProviderContainer();
      addTearDown(staffContainer.dispose);
      staffContainer.read(authProvider.notifier).loginAsDemoStaff();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: staffContainer,
          child: const MaterialApp(home: AdminShellScreen()),
        ),
      );
      await _pumpBounded(tester);

      expect(find.text('Access Restricted'), findsNothing);
      expect(find.textContaining('Apex Dental & Orthodontic Care'), findsWidgets);
      expect(find.text('Dashboard Overview'), findsOneWidget);
      expect(find.text('Add Business'), findsNothing);
      expect(find.text('Payments & Invoices'), findsNothing);
      expect(find.text('Template & Settings'), findsNothing);

      // Mobile view caps BottomNavigationBar at 5 operational tabs for staff (no Payments or Settings)
      await _setSurface(tester, const Size(375, 812));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: staffContainer,
          child: const MaterialApp(home: AdminShellScreen()),
        ),
      );
      await _pumpBounded(tester);
      final bottomBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomBar.items.length, 5);
      expect(bottomBar.items.first.label, 'Overview');
      expect(bottomBar.items.any((i) => i.label == 'Payments' || i.label == 'Settings'), isFalse);
    });

    testWidgets('Probe G: Cold-start deep links (/signup, /business/:id, /book/:id) navigate Back safely without GoError', (tester) async {
      await _setSurface(tester, const Size(430, 900));
      addTearDown(() => _resetSurface(tester));

      for (final initialRoute in [
        '/signup',
        '/business/11111111-1111-1111-1111-111111111111',
        '/book/11111111-1111-1111-1111-111111111111',
      ]) {
        final router = GoRouter(
          initialLocation: initialRoute,
          routes: [
            GoRoute(path: '/', builder: (_, _) => const HomeDiscoveryScreen()),
            GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
            GoRoute(
              path: '/business/:id',
              builder: (_, state) => BusinessDetailScreen(businessId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/book/:id',
              builder: (_, state) => UniversalBookingScreen(businessId: state.pathParameters['id']!),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              theme: NeumorphicTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        );
        await _pumpBounded(tester);

        final backButton = find.byTooltip('Back');
        expect(backButton, findsOneWidget, reason: 'Back button expected on $initialRoute');
        await tester.tap(backButton);
        await _pumpBounded(tester);

        expect(find.byType(HomeDiscoveryScreen), findsOneWidget, reason: 'Should safely fall back to / from $initialRoute');
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Gate 3: 60-Cell Responsive & Text-Scale Matrix (12 screens/dialogs x 5 profiles)', () {
    testWidgets('Matrix: HomeDiscoveryScreen across all 5 viewport/textScale/theme profiles', (tester) async {
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'HomeDiscoveryScreen',
        builder: (_) => const HomeDiscoveryScreen(),
      );
    });

    testWidgets('Matrix: BusinessDetailScreen across all 5 viewport/textScale/theme profiles', (tester) async {
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'BusinessDetailScreen',
        builder: (_) => const BusinessDetailScreen(businessId: '11111111-1111-1111-1111-111111111111'),
      );
    });

    testWidgets('Matrix: UniversalBookingScreen across all 5 viewport/textScale/theme profiles', (tester) async {
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'UniversalBookingScreen',
        builder: (_) => const UniversalBookingScreen(businessId: '11111111-1111-1111-1111-111111111111'),
      );
    });

    testWidgets('Matrix: LoginScreen across all 5 viewport/textScale/theme profiles', (tester) async {
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'LoginScreen',
        builder: (_) => const LoginScreen(),
      );
    });

    testWidgets('Matrix: SignupScreen across all 5 viewport/textScale/theme profiles', (tester) async {
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'SignupScreen',
        builder: (_) => const SignupScreen(),
      );
    });

    testWidgets('Matrix: ProfileScreen (Authenticated) across all 5 viewport/textScale/theme profiles', (tester) async {
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'ProfileScreen (Authenticated)',
        configureAuth: (c) => c.read(authProvider.notifier).loginAsDemoAdmin(),
        builder: (_) => const ProfileScreen(),
      );
    });

    testWidgets('Matrix: ProfileScreen (Unauthenticated) across all 5 viewport/textScale/theme profiles', (tester) async {
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'ProfileScreen (Unauthenticated)',
        configureAuth: (c) => c.read(authProvider.notifier).signOut(),
        builder: (_) => const ProfileScreen(),
      );
    });

    testWidgets('Matrix: ClientBookingsScreen across all 5 viewport/textScale/theme profiles', (tester) async {
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'ClientBookingsScreen',
        configureAuth: (c) => c.read(authProvider.notifier).loginAsDemoClient(),
        builder: (_) => const ClientBookingsScreen(),
      );
    });

    testWidgets('Matrix: NotificationsScreen across all 5 viewport/textScale/theme profiles', (tester) async {
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'NotificationsScreen',
        builder: (_) => const NotificationsScreen(),
      );
    });

    testWidgets('Matrix: AdminShellScreen across all 5 viewport/textScale/theme profiles', (tester) async {
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'AdminShellScreen',
        configureAuth: (c) => c.read(authProvider.notifier).loginAsDemoAdmin(),
        builder: (_) => const AdminShellScreen(),
      );
    });

    testWidgets('Matrix: AdminOnboardingWizard across all 5 viewport/textScale/theme profiles', (tester) async {
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'AdminOnboardingWizard',
        builder: (_) => const Scaffold(body: AdminOnboardingWizard()),
      );
    });

    testWidgets('Matrix: RefundDialog across all 5 viewport/textScale/theme profiles', (tester) async {
      final samplePayment = Payment(
        id: 'p-qa-1',
        bookingId: 'b-qa-1',
        businessId: '11111111-1111-1111-1111-111111111111',
        clientId: DemoData.clientUserId,
        grossAmount: 225.0,
        netAmount: 218.25,
        paymentMethod: 'stripe_card',
        createdAt: DateTime(2026, 11, 14),
      );
      await _assertScreenMatrixCell(
        tester: tester,
        screenName: 'RefundDialog',
        builder: (_) => Scaffold(body: RefundDialog(payment: samplePayment)),
      );
    });
  });

  group('Gate 4: WCAG 2.1 AA Accessibility Matrix (7 targets x 4 guidelines)', () {
    testWidgets('WCAG: HomeDiscoveryScreen Light (375x812)', (tester) async {
      await _verifyWcagTarget(
        tester: tester,
        targetName: 'HomeDiscoveryScreen Light',
        size: const Size(375, 812),
        brightness: Brightness.light,
        builder: () => const HomeDiscoveryScreen(),
      );
    });

    testWidgets('WCAG: HomeDiscoveryScreen Dark (375x812)', (tester) async {
      await _verifyWcagTarget(
        tester: tester,
        targetName: 'HomeDiscoveryScreen Dark',
        size: const Size(375, 812),
        brightness: Brightness.dark,
        builder: () => const HomeDiscoveryScreen(),
      );
    });

    testWidgets('WCAG: LoginScreen Light (375x812)', (tester) async {
      await _verifyWcagTarget(
        tester: tester,
        targetName: 'LoginScreen Light',
        size: const Size(375, 812),
        brightness: Brightness.light,
        builder: () => const LoginScreen(),
      );
    });

    testWidgets('WCAG: SignupScreen Light (375x812)', (tester) async {
      await _verifyWcagTarget(
        tester: tester,
        targetName: 'SignupScreen Light',
        size: const Size(375, 812),
        brightness: Brightness.light,
        builder: () => const SignupScreen(),
      );
    });

    testWidgets('WCAG: SignupScreen Dark (375x812)', (tester) async {
      await _verifyWcagTarget(
        tester: tester,
        targetName: 'SignupScreen Dark',
        size: const Size(375, 812),
        brightness: Brightness.dark,
        builder: () => const SignupScreen(),
      );
    });

    testWidgets('WCAG: AdminShellScreen Light (1440x900)', (tester) async {
      await _verifyWcagTarget(
        tester: tester,
        targetName: 'AdminShellScreen Light',
        size: const Size(1440, 900),
        brightness: Brightness.light,
        configureAuth: (c) => c.read(authProvider.notifier).loginAsDemoAdmin(),
        builder: () => const AdminShellScreen(),
      );
    });

    testWidgets('WCAG: AdminShellScreen Dark (1440x900)', (tester) async {
      await _verifyWcagTarget(
        tester: tester,
        targetName: 'AdminShellScreen Dark',
        size: const Size(1440, 900),
        brightness: Brightness.dark,
        configureAuth: (c) => c.read(authProvider.notifier).loginAsDemoAdmin(),
        builder: () => const AdminShellScreen(),
      );
    });

    testWidgets('WCAG: BusinessDetailScreen Light (375x812)', (tester) async {
      await _verifyWcagTarget(
        tester: tester,
        targetName: 'BusinessDetailScreen Light',
        size: const Size(375, 812),
        brightness: Brightness.light,
        builder: () => const BusinessDetailScreen(businessId: '11111111-1111-1111-1111-111111111111'),
      );
    });

    testWidgets('WCAG: AdminShellScreen Light (375x812)', (tester) async {
      await _verifyWcagTarget(
        tester: tester,
        targetName: 'AdminShellScreen Light (Mobile)',
        size: const Size(375, 812),
        brightness: Brightness.light,
        configureAuth: (c) => c.read(authProvider.notifier).loginAsDemoAdmin(),
        builder: () => const AdminShellScreen(),
      );
    });
  });
}

// --- Offline HTTP Mock Intercepting Nominatim & Network Images ([QA-012]) ---

class _QaHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _QaMockHttpClient();
}

class _QaMockHttpClient implements HttpClient {
  static final List<int> _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  );

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _QaMockHttpClientRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _QaMockHttpClientRequest(url);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _QaMockHttpClientRequest implements HttpClientRequest {
  final Uri url;

  _QaMockHttpClientRequest(this.url);

  @override
  final HttpHeaders headers = _QaMockHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = 0;

  @override
  bool persistentConnection = false;

  @override
  Encoding encoding = utf8;

  @override
  bool bufferOutput = true;

  @override
  String get method => 'GET';

  @override
  Uri get uri => url;

  @override
  void add(List<int> data) {}

  @override
  void write(Object? object) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async {
    final path = url.path;
    final host = url.host;
    if (host.contains('nominatim') || path.contains('search') || path.contains('reverse')) {
      final isSearch = path.contains('search') || url.queryParameters.containsKey('q');
      final payload = isSearch
          ? jsonEncode([
              {
                'lat': '37.7749',
                'lon': '-122.4194',
                'display_name': 'San Francisco, California, United States',
                'address': {
                  'road': 'Market Street',
                  'city': 'San Francisco',
                  'state': 'California',
                  'country': 'United States',
                },
              },
            ])
          : jsonEncode({
              'lat': '37.7749',
              'lon': '-122.4194',
              'display_name': 'San Francisco, California, United States',
              'address': {
                'road': 'Market Street',
                'city': 'San Francisco',
                'state': 'California',
                'country': 'United States',
              },
            });
      return _QaMockHttpClientResponse(utf8.encode(payload));
    }
    return _QaMockHttpClientResponse(_QaMockHttpClient._transparentPng);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _QaMockHttpHeaders implements HttpHeaders {
  @override
  void forEach(void Function(String name, List<String> values) action) {
    action('content-type', ['application/json']);
  }

  @override
  String? value(String name) => name.toLowerCase() == 'content-type' ? 'application/json' : null;

  @override
  List<String>? operator [](String name) => name.toLowerCase() == 'content-type' ? ['application/json'] : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _QaMockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final List<int> _bytes;

  _QaMockHttpClientResponse(this._bytes);

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _bytes.length;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  final HttpHeaders headers = _QaMockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
