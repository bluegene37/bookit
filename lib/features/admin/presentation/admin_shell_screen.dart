// Gene - Nov, 03, 2026: Built full SaaS Web Dashboard layout with Top Bar, Sidebar, and responsive content area
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../services/business_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../../models/business.dart';
import 'dashboard_overview_tab.dart';
import 'calendar_agenda_tab.dart';
import 'business_settings_tab.dart';
import 'services_manager_tab.dart';
import 'staff_manager_tab.dart';

class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  int _selectedTabIndex = 0;
  String? _selectedBusinessId;

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(businessListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return businessesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error loading business: $e'))),
      data: (businesses) {
        if (businesses.isEmpty) {
          return const Scaffold(body: Center(child: Text('No business profiles found.')));
        }

        _selectedBusinessId ??= businesses.first.id;
        final selectedBusiness = businesses.firstWhere(
          (b) => b.id == _selectedBusinessId,
          orElse: () => businesses.first,
        );

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
                      child: Text(
                        '${b.name} (${b.category})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

          // Admin Profile Avatar
          Row(
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
                    'Administrator',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Web Left Sidebar Navigation ---
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
          const SizedBox(height: 20),
          _buildSidebarSectionHeader('CLINIC WORKSPACE', isDark),
          const SizedBox(height: 6),
          _buildSidebarItem(0, 'Dashboard Overview', Icons.dashboard_rounded, accent, isDark),
          _buildSidebarItem(1, 'Appointments Calendar', Icons.calendar_month_rounded, accent, isDark),
          _buildSidebarItem(2, 'Services & Pricing', Icons.medical_services_rounded, accent, isDark),
          _buildSidebarItem(3, 'Doctors & Specialists', Icons.people_alt_rounded, accent, isDark),

          const SizedBox(height: 24),
          _buildSidebarSectionHeader('TEMPLATE & ENGINE', isDark),
          const SizedBox(height: 6),
          _buildSidebarItem(4, 'Template & Settings', Icons.tune_rounded, accent, isDark),

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
                Row(
                  children: [
                    Icon(Icons.cloud_done_rounded, size: 16, color: accent),
                    const SizedBox(width: 8),
                    const Text('Supabase Cloud', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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

  Widget _buildSidebarItem(int index, String title, IconData icon, Color accent, bool isDark) {
    final isSelected = _selectedTabIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTabIndex = index),
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
}

/*
// Gene - Nov, 03, 2026: Preserved previous Scaffold and NavigationRail layout
class _PreviousAdminShellState extends State {
}
*/
