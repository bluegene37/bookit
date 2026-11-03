// Gene - Nov, 03, 2026: GoRouter configuration with Web Admin default and mobile Client-only route guard
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/discovery/presentation/home_discovery_screen.dart';
import '../../features/discovery/presentation/business_detail_screen.dart';
import '../../features/booking_engine/presentation/universal_booking_screen.dart';
import '../../features/client_bookings/presentation/client_bookings_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/admin/presentation/admin_shell_screen.dart';

// Gene - Nov, 03, 2026: Android & iOS are strictly Client-only; Web opens into Admin Portal
final appRouter = GoRouter(
  initialLocation: kIsWeb ? '/admin' : '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeDiscoveryScreen(),
    ),
    GoRoute(
      path: '/business/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BusinessDetailScreen(businessId: id);
      },
    ),
    GoRoute(
      path: '/book/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return UniversalBookingScreen(businessId: id);
      },
    ),
    GoRoute(
      path: '/my-bookings',
      builder: (context, state) => const ClientBookingsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/admin',
      redirect: (context, state) {
        // Enforce: Mobile devices (Android/iOS) must be Client-only!
        if (!kIsWeb) {
          return '/';
        }
        return null;
      },
      builder: (context, state) => const AdminShellScreen(),
    ),
  ],
);

/*
// Gene - Nov, 03, 2026: Previous router configuration without platform client/admin separation
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeDiscoveryScreen(),
    ),
    GoRoute(
      path: '/business/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BusinessDetailScreen(businessId: id);
      },
    ),
    GoRoute(
      path: '/book/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return UniversalBookingScreen(businessId: id);
      },
    ),
    GoRoute(
      path: '/my-bookings',
      builder: (context, state) => const ClientBookingsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminShellScreen(),
    ),
  ],
);
*/
