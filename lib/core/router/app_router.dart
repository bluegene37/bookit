// Gene - Nov, 03, 2026: GoRouter declarative navigation configuration
import 'package:go_router/go_router.dart';
import '../../features/discovery/presentation/home_discovery_screen.dart';
import '../../features/discovery/presentation/business_detail_screen.dart';
import '../../features/booking_engine/presentation/universal_booking_screen.dart';
import '../../features/client_bookings/presentation/client_bookings_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/admin/presentation/admin_shell_screen.dart';

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
