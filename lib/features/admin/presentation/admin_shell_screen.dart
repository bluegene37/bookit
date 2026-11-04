// Gene - Nov, 03, 2026: Built full SaaS Web Dashboard layout with Top Bar, Sidebar, and responsive content area
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../services/business_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../../models/business.dart';
import 'dashboard_overview_tab.dart';
import 'calendar_agenda_tab.dart';
import 'business_settings_tab.dart';
import 'services_manager_tab.dart';
import 'staff_manager_tab.dart';
import 'tabs/payments_invoices_tab.dart';
// Gene - Nov, 04, 2026: Added AdminOnboardingWizard import for business template registration
import 'widgets/admin_onboarding_wizard.dart';
// Gene - Nov, 05, 2026: Added demo_persona_switcher import
import '../../../core/widgets/demo_persona_switcher.dart';

class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key});

  // Gene - Nov, 04, 2026: Added Payments & Invoices tab navigation and service payment policy configuration
  static const List<NavigationRailDestination> railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_rounded),
      label: Text('Overview'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.calendar_month_rounded),
      label: Text('Calendar'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.medical_services_rounded),
      label: Text('Services'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_alt_rounded),
      label: Text('Staff'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_rounded),
      label: Text('Payments'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.tune_rounded),
      label: Text('Settings'),
    ),
  ];

  static const List<BottomNavigationBarItem> bottomNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      label: 'Overview',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_month_rounded),
      label: 'Calendar',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.medical_services_rounded),
      label: 'Services',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people_alt_rounded),
      label: 'Staff',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_rounded),
      label: 'Payments',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.tune_rounded),
      label: 'Settings',
    ),
  ];

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  int _selectedTabIndex = 0;
  String? _selectedBusinessId;

  @override
  Widget build(BuildContext context) {
    // Gene - Nov, 03, 2026: Check authentication before rendering Admin Web Dashboard
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    if (authState.user == null) {
      return _buildAdminAuthGate(context, isDark, accent);
    }

    final businessesAsync = ref.watch(businessListProvider);

    return businessesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error loading business: $e'))),
      data: (businesses) {
        /*
        // Gene - Nov, 03, 2026: Previous plain text empty state
        if (businesses.isEmpty) {
          return const Scaffold(body: Center(child: Text('No business profiles found.')));
        }
        */
        // Gene - Nov, 04, 2026: Interactive Onboarding Zero-State triggering business registration wizard
        if (businesses.isEmpty) {
          return _buildZeroStateScreen(context, isDark, accent);
        }

        _selectedBusinessId ??= businesses.first.id;
        final selectedBusiness = businesses.firstWhere(
          (b) => b.id == _selectedBusinessId,
          orElse: () => businesses.first,
        );

        /*
        // Gene - Nov, 04, 2026: Previous unconditional desktop layout with static 250px sidebar
        return Scaffold(
          body: Column(
            children: [
              // 1. Web Top Navigation Bar
              _buildWebTopBar(context, ref, businesses, selectedBusiness, isDark, accent),

              // 2. Web Body: Left Sidebar + Main Dashboard Area
              Expanded(
                child: Row(
                  children: [
                    // Left Navigation Sidebar
                    _buildWebSidebar(context, isDark, accent, selectedBusiness),

                    // Main Website Dashboard Area
                    Expanded(
                      child: Container(
                        color: isDark ? NeumorphicColors.darkCanvas : NeumorphicColors.lightCanvas,
                        child: IndexedStack(
                          index: _selectedTabIndex,
                          children: [
                            DashboardOverviewTab(business: selectedBusiness),
                            CalendarAgendaTab(business: selectedBusiness),
                            ServicesManagerTab(business: selectedBusiness),
                            StaffManagerTab(business: selectedBusiness),
                            PaymentsInvoicesTab(business: selectedBusiness),
                            BusinessSettingsTab(business: selectedBusiness),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        */

        // Gene - Nov, 04, 2026: Added fully responsive layout supporting Desktop (sidebar), Tablet, and Mobile (BottomNav & Drawer)
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 900;

        final tabContent = Container(
          color: isDark ? NeumorphicColors.darkCanvas : NeumorphicColors.lightCanvas,
          child: IndexedStack(
            index: _selectedTabIndex,
            children: [
              DashboardOverviewTab(business: selectedBusiness),
              CalendarAgendaTab(business: selectedBusiness),
              ServicesManagerTab(business: selectedBusiness),
              StaffManagerTab(business: selectedBusiness),
              PaymentsInvoicesTab(business: selectedBusiness),
              BusinessSettingsTab(business: selectedBusiness),
            ],
          ),
        );

        if (isCompact) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
              elevation: 0,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              /*
              // Gene - Nov, 04, 2026: Unconstrained DropdownButton causing RenderFlex overflow on narrow AppBar titles
              title: DropdownButton<String>(
                value: _selectedBusinessId,
                underline: const SizedBox(),
                isDense: true,
                dropdownColor: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                items: businesses.map((b) {
                  return DropdownMenuItem(
                    value: b.id,
                    child: Text(
                      b.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBusinessId = val);
                },
              ),
              */
              // Gene - Nov, 04, 2026: Constrained DropdownButton with isExpanded: true to prevent mobile AppBar overflow
              title: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedBusinessId,
                  underline: const SizedBox(),
                  isDense: true,
                  dropdownColor: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  items: businesses.map((b) {
                    return DropdownMenuItem(
                      value: b.id,
                      child: Text(
                        b.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBusinessId = val);
                  },
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Add Business',
                  icon: Icon(Icons.add_circle_outline_rounded, color: accent),
                  onPressed: () {
                    showDialog<String>(
                      context: context,
                      builder: (_) => const AdminOnboardingWizard(),
                    ).then((newId) {
                      if (newId != null && mounted) {
                        setState(() => _selectedBusinessId = newId);
                      }
                    });
                  },
                ),
                // Gene - Nov, 05, 2026: Mobile AppBar Demo Persona Switcher action
                IconButton(
                  tooltip: 'Switch Demo Persona',
                  icon: Icon(Icons.switch_account_outlined, color: accent),
                  onPressed: () => DemoPersonaSwitcherDialog.show(context),
                ),
                IconButton(
                  tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: isDark ? Colors.amber : NeumorphicColors.lightTextSecondary,
                  ),
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (ref.watch(unreadNotificationCountProvider) > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: NeumorphicColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${ref.watch(unreadNotificationCountProvider)}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            drawer: Drawer(
              backgroundColor: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
              child: SafeArea(
                child: _buildWebSidebar(context, isDark, accent, selectedBusiness, isDrawer: true),
              ),
            ),
            body: tabContent,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedTabIndex,
              onTap: (index) => setState(() => _selectedTabIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: accent,
              unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
              backgroundColor: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
              items: AdminShellScreen.bottomNavItems,
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              // 1. Web Top Navigation Bar
              _buildWebTopBar(context, ref, businesses, selectedBusiness, isDark, accent),

              // 2. Web Body: Left Sidebar + Main Dashboard Area
              Expanded(
                child: Row(
                  children: [
                    // Left Navigation Sidebar
                    _buildWebSidebar(context, isDark, accent, selectedBusiness),

                    // Main Website Dashboard Area
                    Expanded(child: tabContent),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Web Top Navigation Bar ---
  Widget _buildWebTopBar(
    BuildContext context,
    WidgetRef ref,
    List<Business> businesses,
    Business currentBusiness,
    bool isDark,
    Color accent,
  ) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final currentUser = ref.watch(authProvider).user;

    /*
    // Gene - Nov, 03, 2026: Rigid Row layout with Spacer that overflows under high text scaling or narrow desktop viewports
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          // Brand Logo
          NeumorphicContainer(
            isCircle: true,
            width: 40,
            height: 40,
            child: Icon(Icons.shield_outlined, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'BookIt',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'WEB ADMIN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              Text(
                'Universal Practice Workspace',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),
          Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(width: 20),

          // Clinic Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: NeumorphicColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedBusinessId,
                  underline: const SizedBox(),
                  isDense: true,
                  dropdownColor: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  items: businesses.map((b) {
                    return DropdownMenuItem(
                      value: b.id,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          '${b.name} (${b.category})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBusinessId = val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),
          NeumorphicButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: () {
              showDialog<String>(
                context: context,
                builder: (_) => const AdminOnboardingWizard(),
              ).then((newId) {
                if (newId != null && mounted) {
                  setState(() => _selectedBusinessId = newId);
                }
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  'Add Business',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Template Model Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  currentBusiness.bookingModel == BookingModelType.slotBased
                      ? Icons.access_time_rounded
                      : Icons.date_range_rounded,
                  size: 14,
                  color: accent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Template: ${currentBusiness.bookingModel.displayName.split('(').first.trim()}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Gene - Nov, 05, 2026: Desktop TopBar Demo Persona Switcher action
          IconButton(
            tooltip: 'Switch Demo Persona',
            icon: Icon(Icons.switch_account_outlined, color: accent),
            onPressed: () => DemoPersonaSwitcherDialog.show(context),
          ),
          const SizedBox(width: 4),

          // Theme Toggle Button
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? Colors.amber : NeumorphicColors.lightTextSecondary,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(width: 8),

          // Notifications
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: NeumorphicColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(width: 16),

          // Gene - Nov, 03, 2026: Interactive Admin Profile Menu with Sign Out & Navigation
          PopupMenuButton<String>(
            tooltip: 'Account Menu',
            offset: const Offset(0, 48),
            color: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            onSelected: (action) {
              if (action == 'profile') {
                context.push('/profile');
              } else if (action == 'client_view') {
                context.go('/');
              } else if (action == 'sign_out') {
                ref.read(authProvider.notifier).signOut();
                context.go('/login?redirect=/admin');
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser?.fullName ?? 'Dr. Alexander Vance',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      currentUser?.email ?? 'admin@bookit.dev',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 10),
                    Text('Profile & Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'client_view',
                child: Row(
                  children: [
                    Icon(Icons.phone_android_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Switch to Client View'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'sign_out',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: NeumorphicColors.error),
                    SizedBox(width: 10),
                    Text('Sign Out', style: TextStyle(color: NeumorphicColors.error)),
                  ],
                ),
              ),
            ],
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: accent.withValues(alpha: 0.2),
                    child: Icon(Icons.person, size: 20, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.fullName ?? 'Dr. Alexander Vance',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Administrator ▾',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    */

    // Gene - Nov, 04, 2026: Responsive horizontal-scroll-protected Web Top Bar with spaceBetween alignment to eliminate overflows under any font scale or desktop viewport width
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Left Group: Brand, Title, Clinic Selector, Add Business
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NeumorphicContainer(
                        isCircle: true,
                        width: 40,
                        height: 40,
                        child: Icon(Icons.shield_outlined, color: accent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'BookIt',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'WEB ADMIN',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent, letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Universal Practice Workspace',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(width: 20),

                      // Clinic Selector Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: NeumorphicColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _selectedBusinessId,
                              underline: const SizedBox(),
                              isDense: true,
                              dropdownColor: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              items: businesses.map((b) {
                                return DropdownMenuItem(
                                  value: b.id,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 220),
                                    child: Text(
                                      '${b.name} (${b.category})',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedBusinessId = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      NeumorphicButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        onPressed: () {
                          showDialog<String>(
                            context: context,
                            builder: (_) => const AdminOnboardingWizard(),
                          ).then((newId) {
                            if (newId != null && mounted) {
                              setState(() => _selectedBusinessId = newId);
                            }
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, size: 16, color: accent),
                            const SizedBox(width: 6),
                            Text(
                              'Add Business',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 24),

                  // Right Group: Template Badge, Theme Toggle, Notifications, Account Menu
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              currentBusiness.bookingModel == BookingModelType.slotBased
                                  ? Icons.access_time_rounded
                                  : Icons.date_range_rounded,
                              size: 14,
                              color: accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Template: ${currentBusiness.bookingModel.displayName.split('(').first.trim()}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      IconButton(
                        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        icon: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          color: isDark ? Colors.amber : NeumorphicColors.lightTextSecondary,
                        ),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                      ),
                      const SizedBox(width: 8),

                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            tooltip: 'Notifications',
                            onPressed: () => context.push('/notifications'),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: NeumorphicColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(width: 16),

                      PopupMenuButton<String>(
                        tooltip: 'Account Menu',
                        offset: const Offset(0, 48),
                        color: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        onSelected: (action) {
                          if (action == 'profile') {
                            context.push('/profile');
                          } else if (action == 'client_view') {
                            context.go('/');
                          } else if (action == 'sign_out') {
                            ref.read(authProvider.notifier).signOut();
                            context.go('/login?redirect=/admin');
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser?.fullName ?? 'Dr. Alexander Vance',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  currentUser?.email ?? 'admin@bookit.dev',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, size: 18),
                                SizedBox(width: 10),
                                Text('Profile & Settings'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'client_view',
                            child: Row(
                              children: [
                                Icon(Icons.phone_android_rounded, size: 18),
                                SizedBox(width: 10),
                                Text('Switch to Client View'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'sign_out',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded, size: 18, color: NeumorphicColors.error),
                                SizedBox(width: 10),
                                Text('Sign Out', style: TextStyle(color: NeumorphicColors.error)),
                              ],
                            ),
                          ),
                        ],
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: accent.withValues(alpha: 0.2),
                                child: Icon(Icons.person, size: 20, color: accent),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentUser?.fullName ?? 'Dr. Alexander Vance',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Administrator ▾',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /*
  // Gene - Nov, 04, 2026: Previous fixed sidebar without drawer support
  Widget _buildWebSidebar(BuildContext context, bool isDark, Color accent, Business business) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
  */
  // Gene - Nov, 04, 2026: Added isDrawer support for responsive mobile & tablet drawer navigation
  Widget _buildWebSidebar(BuildContext context, bool isDark, Color accent, Business business, {bool isDrawer = false}) {
    return Container(
      width: isDrawer ? null : 250,
      decoration: BoxDecoration(
        color: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
        border: isDrawer
            ? null
            : Border(
                right: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSidebarSectionHeader('CLINIC WORKSPACE', isDark),
          const SizedBox(height: 6),
          _buildSidebarItem(0, 'Dashboard Overview', Icons.dashboard_rounded, accent, isDark, isDrawer: isDrawer),
          _buildSidebarItem(1, 'Appointments Calendar', Icons.calendar_month_rounded, accent, isDark, isDrawer: isDrawer),
          _buildSidebarItem(2, 'Services & Pricing', Icons.medical_services_rounded, accent, isDark, isDrawer: isDrawer),
          _buildSidebarItem(3, 'Doctors & Specialists', Icons.people_alt_rounded, accent, isDark, isDrawer: isDrawer),
          _buildSidebarItem(4, 'Payments & Invoices', Icons.receipt_long_rounded, accent, isDark, isDrawer: isDrawer),

          const SizedBox(height: 24),
          _buildSidebarSectionHeader('TEMPLATE & ENGINE', isDark),
          const SizedBox(height: 6),
          _buildSidebarItem(5, 'Template & Settings', Icons.tune_rounded, accent, isDark, isDrawer: isDrawer),

          // Gene - Nov, 03, 2026: Added Session & Quick Navigation to Sidebar
          const SizedBox(height: 20),
          _buildSidebarSectionHeader('SESSION', isDark),
          const SizedBox(height: 6),
          /*
          // Gene - Nov, 03, 2026: Previous unconstrained Row text causing overflow in narrow sidebar/drawer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.phone_android_rounded, size: 18, color: isDark ? Colors.white60 : Colors.black54),
                      const SizedBox(width: 12),
                      Text(
                        'Client App View',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref.read(authProvider.notifier).signOut();
                  context.go('/login?redirect=/admin');
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: NeumorphicColors.error),
                      SizedBox(width: 12),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: NeumorphicColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          */
          // Gene - Nov, 04, 2026: Wrapped Client App View and Sign Out in Expanded with ellipsis for responsive sidebar & drawer layout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.phone_android_rounded, size: 18, color: isDark ? Colors.white60 : Colors.black54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Client App View',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref.read(authProvider.notifier).signOut();
                  context.go('/login?redirect=/admin');
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: NeumorphicColors.error),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: NeumorphicColors.error,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Bottom System Status Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*
                // Gene - Nov, 03, 2026: Unconstrained text in status badge
                Row(
                  children: [
                    Icon(Icons.cloud_done_rounded, size: 16, color: accent),
                    const SizedBox(width: 8),
                    const Text('Supabase Cloud', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                */
                // Gene - Nov, 04, 2026: Wrapped in Expanded with ellipsis for responsive drawer widths
                Row(
                  children: [
                    Icon(Icons.cloud_done_rounded, size: 16, color: accent),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Supabase Cloud',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Project: xjivgzyfewvdhiceaned',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
    );
  }

  /*
  // Gene - Nov, 04, 2026: Previous sidebar item without isDrawer auto-close
  Widget _buildSidebarItem(int index, String title, IconData icon, Color accent, bool isDark) {
    final isSelected = _selectedTabIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTabIndex = index),
  */
  // Gene - Nov, 04, 2026: Added isDrawer auto-close on sidebar selection for mobile
  Widget _buildSidebarItem(int index, String title, IconData icon, Color accent, bool isDark, {bool isDrawer = false}) {
    final isSelected = _selectedTabIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedTabIndex = index);
            if (isDrawer) {
              Navigator.of(context).pop();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? accent.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: accent.withValues(alpha: 0.4), width: 1.2) : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? accent : (isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? accent : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Gene - Nov, 04, 2026: Admin zero-state welcome screen when no businesses are registered
  Widget _buildZeroStateScreen(BuildContext context, bool isDark, Color accent) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: NeumorphicContainer(
              padding: const EdgeInsets.all(36),
              borderRadius: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeumorphicContainer(
                    isCircle: true,
                    width: 80,
                    height: 80,
                    child: Icon(Icons.storefront_rounded, size: 40, color: accent),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to BookIt Workspace',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have any registered businesses yet. Choose from our curated industry templates to launch your practice, clinic, or studio in minutes.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  NeumorphicButton(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    onPressed: () {
                      showDialog<String>(
                        context: context,
                        builder: (_) => const AdminOnboardingWizard(),
                      ).then((newId) {
                        if (newId != null && mounted) {
                          setState(() => _selectedBusinessId = newId);
                        }
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_business_rounded, color: accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Register Your Business',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Gene - Nov, 03, 2026: Web Admin Authentication Gate for unauthenticated or logged-out users
  Widget _buildAdminAuthGate(BuildContext context, bool isDark, Color accent) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: NeumorphicContainer(
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeumorphicContainer(
                    isCircle: true,
                    width: 76,
                    height: 76,
                    child: Icon(Icons.admin_panel_settings_rounded, size: 40, color: accent),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'BookIt Web Admin Portal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please sign in with clinic administrator credentials to access practice management.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Sign In to Practice Portal', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => context.go('/login?redirect=/admin'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text('Quick Sign In as Demo Admin'),
                    onPressed: () {
                      ref.read(authProvider.notifier).loginAsDemoAdmin();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Return to Client Booking Portal'),
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*
// Gene - Nov, 03, 2026: Preserved previous Scaffold and NavigationRail layout
class _PreviousAdminShellState extends State {
}
*/
