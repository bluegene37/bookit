// Gene - Nov, 03, 2026: Admin Web Shell with responsive NavigationRail and tab orchestration
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../services/business_service.dart';
import '../../../services/auth_service.dart';
// import '../../../models/business.dart';
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
          appBar: AppBar(
            title: Row(
              children: [
                NeumorphicContainer(
                  isCircle: true,
                  width: 36,
                  height: 36,
                  child: Icon(Icons.admin_panel_settings, size: 20, color: accent),
                ),
                const SizedBox(width: 10),
                Text(
                  'BookIt Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                // Clinic Selector Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedBusinessId,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 18),
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
                ),
              ],
            ),
            actions: [
              // Switch back to Client App
              TextButton.icon(
                icon: const Icon(Icons.storefront_outlined, size: 16),
                label: const Text('Client App View'),
                style: TextButton.styleFrom(foregroundColor: accent),
                onPressed: () {
                  ref.read(authProvider.notifier).toggleRole();
                  context.go('/');
                },
              ),
              const SizedBox(width: 14),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 850;

              return Row(
                children: [
                  // Responsive Desktop NavigationRail
                  if (isDesktop) ...[
                    NavigationRail(
                      selectedIndex: _selectedTabIndex,
                      onDestinationSelected: (idx) => setState(() => _selectedTabIndex = idx),
                      backgroundColor: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
                      labelType: NavigationRailLabelType.all,
                      selectedIconTheme: IconThemeData(color: accent),
                      selectedLabelTextStyle: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 12),
                      unselectedLabelTextStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 11,
                      ),
                      destinations: const [
                        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Overview')),
                        NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: Text('Calendar')),
                        NavigationRailDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: Text('Template')),
                        NavigationRailDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services), label: Text('Services')),
                        NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Staff')),
                      ],
                    ),
                    VerticalDivider(width: 1, color: isDark ? Colors.white10 : Colors.black12),
                  ],

                  // Tab Body
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTabIndex,
                      children: [
                        DashboardOverviewTab(business: selectedBusiness),
                        CalendarAgendaTab(business: selectedBusiness),
                        BusinessSettingsTab(business: selectedBusiness),
                        ServicesManagerTab(business: selectedBusiness),
                        StaffManagerTab(business: selectedBusiness),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Bottom Navigation Bar on Mobile Form Factors
          bottomNavigationBar: MediaQuery.of(context).size.width < 850
              ? NavigationBar(
                  selectedIndex: _selectedTabIndex,
                  onDestinationSelected: (idx) => setState(() => _selectedTabIndex = idx),
                  indicatorColor: accent.withValues(alpha: 0.2),
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
                    NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'),
                    NavigationDestination(icon: Icon(Icons.tune_outlined), label: 'Template'),
                    NavigationDestination(icon: Icon(Icons.medical_services_outlined), label: 'Services'),
                    NavigationDestination(icon: Icon(Icons.people_outline), label: 'Staff'),
                  ],
                )
              : null,
        );
      },
    );
  }
}
