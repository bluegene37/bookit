// Gene - Nov, 03, 2026: Discovery and Search Hub for Dental, Medical, and Universal businesses
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_text_field.dart';
import '../../../core/widgets/neumorphic_chip.dart';
import '../../../services/business_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';

class HomeDiscoveryScreen extends ConsumerWidget {
  const HomeDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(businessListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final authState = ref.watch(authProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    final categories = ['All', 'Dental', 'Medical', 'Recovery Stay', 'Wellness'];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar with Logo, Role Switcher, and Notifications
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
                      child: Icon(Icons.calendar_month_rounded, color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
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
                                  authState.isBusinessOwner ? 'OWNER VIEW' : 'CLIENT VIEW',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent),
                                ),
                              ),
                            ],
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

                    // Role Switcher Button
                    IconButton(
                      tooltip: 'Toggle Owner / Client Role',
                      icon: Icon(
                        authState.isBusinessOwner ? Icons.admin_panel_settings : Icons.person_outline,
                        color: accent,
                      ),
                      onPressed: () {
                        ref.read(authProvider.notifier).toggleRole();
                        final newIsOwner = !authState.isBusinessOwner;
                        if (newIsOwner) {
                          context.go('/admin');
                        }
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
                  ],
                ),
              ),
            ),

            // Inset Search Field
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: NeumorphicTextField(
                  hintText: 'Search clinic, procedure (e.g. Dental Cleaning)...',
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black45),
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                  },
                ),
              ),
            ),

            // Categories Filter Bar
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

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
              ),
            ),

            // Business Cards List
            businessesAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
              data: (businesses) {
                if (businesses.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No clinics matching your search criteria.')),
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
    );
  }
}
