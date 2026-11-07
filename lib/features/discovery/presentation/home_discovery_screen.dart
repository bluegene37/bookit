// Gene - Nov, 03, 2026: Refactored HomeDiscoveryScreen with Client Profile navigation and 4-tab mobile BottomNavigationBar
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_text_field.dart';
import '../../../core/widgets/neumorphic_chip.dart';
import '../../../services/business_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/auth_service.dart';
// Gene - Nov, 05, 2026: Added demo_persona_switcher and safe_network_image imports
import '../../../core/widgets/demo_persona_switcher.dart';
import '../../../core/widgets/safe_network_image.dart';
// Gene - Nov 06, 2026: Added DiscoveryMapView import for interactive map view toggle
import 'widgets/discovery_map_view.dart';

class HomeDiscoveryScreen extends ConsumerWidget {
  const HomeDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gene - Nov, 03, 2026: Watch authProvider for profile icon and state reactivity
    final authState = ref.watch(authProvider);
    final businessesAsync = ref.watch(businessListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    // Gene - Nov, 7, 2026: Watch searchQueryProvider to render an interactive clear search button and filter reset state
    final searchQuery = ref.watch(searchQueryProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final isMapView = ref.watch(isDiscoveryMapViewProvider);
    // final themeMode = ref.watch(themeModeProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    /*
    // Gene - Nov, 03, 2026: Hardcoded static categories
    final categories = ['All', 'Dental', 'Medical', 'Recovery Stay', 'Wellness'];
    */
    // Gene - Nov, 04, 2026: Dynamic categories loaded from businessCategoriesProvider
    final categoriesAsync = ref.watch(businessCategoriesProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar with Brand Logo, Theme Toggle, and Notifications (Client Only)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // Brand Icon
                    NeumorphicContainer(
                      isCircle: true,
                      width: 44,
                      height: 44,
                      child: Icon(Icons.health_and_safety_rounded, color: accent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BookIt',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'Find clinics, doctors & services',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Web Only: Link to Admin Portal
                    /*
                    // Gene - Nov, 03, 2026: Unconditional wide TextButton.icon
                    if (kIsWeb) ...[
                      TextButton.icon(
                        icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                        label: const Text('Admin Portal'),
                        style: TextButton.styleFrom(foregroundColor: accent),
                        onPressed: () => context.go('/admin'),
                      ),
                      const SizedBox(width: 4),
                    ],
                    */
                    /*
                    // Gene - Nov, 04, 2026: Responsive Admin Portal button (compact icon on mobile, full label on wide screens)
                    if (kIsWeb) ...[
                      if (MediaQuery.of(context).size.width < 600)
                        IconButton(
                          tooltip: 'Admin Portal',
                          icon: Icon(Icons.admin_panel_settings_outlined, color: accent),
                          onPressed: () => context.go('/admin'),
                        )
                      else ...[
                        TextButton.icon(
                          icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                          label: const Text('Admin Portal'),
                          style: TextButton.styleFrom(foregroundColor: accent),
                          onPressed: () => context.go('/admin'),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                    */

                    // Gene - Nov, 05, 2026: Universal cross-platform Admin Portal entrypoint for business owners and testers
                    if (authState.isBusinessOwner || kIsWeb) ...[
                      if (MediaQuery.of(context).size.width < 600)
                        IconButton(
                          tooltip: 'Admin Portal',
                          icon: Icon(Icons.admin_panel_settings_outlined, color: accent),
                          onPressed: () => context.go('/admin'),
                        )
                      else ...[
                        TextButton.icon(
                          icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                          label: const Text('Admin Portal'),
                          style: TextButton.styleFrom(foregroundColor: accent),
                          onPressed: () => context.go('/admin'),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],

                    // Gene - Nov, 05, 2026: Quick Demo Persona Switcher dialog trigger
                    IconButton(
                      tooltip: 'Switch Demo Persona',
                      icon: Icon(Icons.switch_account_outlined, color: accent),
                      onPressed: () => DemoPersonaSwitcherDialog.show(context),
                    ),

                    // Theme Toggle Button (Light/Dark Mode)
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

                    // Notifications Button with Unread Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () => context.push('/notifications'),
                        ),
                        if (unreadCount > 0) ...[
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
                      ],
                    ),

                    // Gene - Nov, 03, 2026: Profile icon button in top discovery bar
                    IconButton(
                      tooltip: 'My Profile',
                      icon: CircleAvatar(
                        radius: 14,
                        backgroundColor: accent.withValues(alpha: 0.18),
                        child: Icon(
                          authState.isAuthenticated ? Icons.person : Icons.person_outline,
                          size: 18,
                          color: accent,
                        ),
                      ),
                      onPressed: () => context.push('/profile'),
                    ),
                  ],
                ),
              ),
            ),

            // Inset Search Field
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                /*
                child: NeumorphicTextField(
                  hintText: 'Search clinic, procedure (e.g. Dental Cleaning)...',
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black45),
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                  },
                ),
                */
                // Gene - Nov, 7, 2026: Added clear button suffixIcon when searchQuery is non-empty
                child: NeumorphicTextField(
                  hintText: 'Search clinic, procedure (e.g. Dental Cleaning)...',
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black45),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          icon: Icon(Icons.clear_rounded, size: 18, color: isDark ? Colors.white54 : Colors.black45),
                          onPressed: () {
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                  },
                ),
              ),
            ),

            // Categories Filter Bar
            /*
            // Gene - Nov, 03, 2026: Static ListView of categories
            SliverToBoxAdapter(
              child: SizedBox(
                height: 58,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: NeumorphicChip(
                        label: cat,
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state = cat;
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            */
            // Gene - Nov, 04, 2026: Dynamic categories filter bar loaded from businessCategoriesProvider
            SliverToBoxAdapter(
              child: SizedBox(
                height: 58,
                child: categoriesAsync.when(
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (categories) {
                    final allItems = ['All', ...categories.map((c) => c.name)];
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: allItems.length,
                      itemBuilder: (context, index) {
                        final cat = allItems[index];
                        final isSelected = selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: NeumorphicChip(
                            label: cat,
                            isSelected: isSelected,
                            onTap: () {
                              ref.read(selectedCategoryProvider.notifier).state = cat;
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                /*
                // Original section header Row
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Clinics & Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Showing active',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                    ),
                  ],
                ),
                */
                // Gene - Nov 06, 2026: Wrapped section header title in Expanded with ellipsis to prevent RenderFlex overflow on constrained mobile viewports
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Available Clinics & Services',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    /*
                    // Original static text
                    Text(
                      'Showing active',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                    ),
                    */
                    // Gene - Nov 06, 2026: Segmented toggle for List View vs OpenStreetMap Map View
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2330) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => ref.read(isDiscoveryMapViewProvider.notifier).state = false,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: !isMapView ? (isDark ? const Color(0xFF2D3748) : Colors.white) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.view_list_rounded, size: 14, color: !isMapView ? accent : (isDark ? Colors.white54 : Colors.black45)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'List',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: !isMapView ? FontWeight.w700 : FontWeight.w500,
                                      color: !isMapView ? accent : (isDark ? Colors.white54 : Colors.black45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => ref.read(isDiscoveryMapViewProvider.notifier).state = true,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isMapView ? (isDark ? const Color(0xFF2D3748) : Colors.white) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.map_rounded, size: 14, color: isMapView ? accent : (isDark ? Colors.white54 : Colors.black45)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Map',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isMapView ? FontWeight.w700 : FontWeight.w500,
                                      color: isMapView ? accent : (isDark ? Colors.white54 : Colors.black45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Business Cards List or Interactive Map View
            businessesAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
              data: (businesses) {
                if (businesses.isEmpty) {
                  /*
                  return const SliverFillRemaining(
                    child: Center(child: Text('No clinics matching your search criteria.')),
                  );
                  */
                  // Gene - Nov, 7, 2026: Enhanced empty search/category state with Reset Filters CTA button
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 12),
                            const Text(
                              'No clinics matching your search criteria.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            if (searchQuery.isNotEmpty || selectedCategory != 'All') ...[
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                                label: const Text('Reset Filters'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accent,
                                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  ref.read(searchQueryProvider.notifier).state = '';
                                  ref.read(selectedCategoryProvider.notifier).state = 'All';
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Gene - Nov 06, 2026: Render DiscoveryMapView when Map toggle is selected
                if (isMapView) {
                  return SliverFillRemaining(
                    hasScrollBody: true,
                    child: DiscoveryMapView(businesses: businesses),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final business = businesses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: GestureDetector(
                            onTap: () => context.push('/business/${business.id}'),
                            child: NeumorphicContainer(
                              borderRadius: 22.0,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Banner image with category pill
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: [
                                        /*
                                        // Gene - Nov, 03, 2026: Raw Image.network
                                        Image.network(
                                          business.bannerUrl ?? 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800',
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 150,
                                            color: Colors.grey.shade400,
                                            child: const Icon(Icons.local_hospital, size: 40),
                                          ),
                                        ),
                                        */
                                        // Gene - Nov, 05, 2026: SafeNetworkImage with fallback icon
                                        SafeNetworkImage(
                                          imageUrl: business.bannerUrl,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          fallbackIcon: Icons.local_hospital_rounded,
                                        ),
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.7),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              business.category.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  business.ratingAvg.toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  Text(
                                    business.name,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                                    ),
                                  ),
                                  if (business.address != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${business.address!}, ${business.city ?? ''}',
                                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),

                                  // Template Model Pill & Book CTA
                                  /*
                                  // Original Template Model Pill & Book CTA
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          business.bookingModel.displayName.split('(').first.trim(),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Book Now',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: accent,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_forward, size: 14, color: accent),
                                        ],
                                      ),
                                    ],
                                  ),
                                  */
                                  // Gene - Nov 06, 2026: Wrapped booking model badge in Flexible with text ellipsis to prevent RenderFlex overflow on narrow mobile screens
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            business.bookingModel.displayName.split('(').first.trim(),
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Book Now',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: accent,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_forward, size: 14, color: accent),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: businesses.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      // Gene - Nov, 03, 2026: 4-destination mobile BottomNavigationBar with Profile & Auth support
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        indicatorColor: accent.withValues(alpha: 0.18),
        onDestinationSelected: (index) {
          if (index == 1) {
            context.push('/my-bookings');
          } else if (index == 2) {
            context.push('/notifications');
          } else if (index == 3) {
            context.push('/profile');
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: accent),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: accent),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: NeumorphicColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            selectedIcon: Icon(Icons.notifications, color: accent),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: accent),
            label: 'Profile',
          ),
        ],
      ),
    );
    /*
    // Gene - Nov, 03, 2026: Previous 3-destination navigation bar
    return Scaffold(
      body: SafeArea(...),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [Explore, Appointments, Alerts],
      ),
    );
    */
    /*
    // Gene - Nov, 03, 2026: Previous Scaffold without client BottomNavigationBar
    return Scaffold(
      body: SafeArea(...),
    );
    */
  }
}
