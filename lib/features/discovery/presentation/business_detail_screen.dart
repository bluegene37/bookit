// Gene - Nov, 03, 2026: Business Profile Screen with Services catalog, Doctors roster, and instant booking CTA
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../services/business_service.dart';
// Gene - Nov, 05, 2026: Added safe_network_image import
import '../../../core/widgets/safe_network_image.dart';

class BusinessDetailScreen extends ConsumerWidget {
  final String businessId;

  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessDetailProvider(businessId));
    final servicesAsync = ref.watch(businessServicesProvider(businessId));
    final staffAsync = ref.watch(businessStaffProvider(businessId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return businessAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error loading business: $e'))),
      data: (business) {
        if (business == null) {
          return const Scaffold(body: Center(child: Text('Business not found')));
        }

        final services = servicesAsync.value ?? [];
        final staff = staffAsync.value ?? [];

        return Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Sliver Banner
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: NeumorphicContainer(
                        isCircle: true,
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      /*
                      // Gene - Nov, 03, 2026: Raw Image.network
                      background: Image.network(
                        business.bannerUrl ?? 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
                      ),
                      */
                      // Gene - Nov, 05, 2026: SafeNetworkImage rendering with fallback icon
                      background: SafeNetworkImage(
                        imageUrl: business.bannerUrl,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.local_hospital_rounded,
                      ),
                    ),
                  ),

                  // Clinic Overview
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  business.category.toUpperCase(),
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${business.ratingAvg.toStringAsFixed(1)} (${business.ratingCount} reviews)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Text(
                            business.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                            ),
                          ),
                          if (business.address != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: accent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${business.address!}, ${business.city ?? ''}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),

                          if (business.description != null) ...[
                            Text(
                              business.description!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Staff / Doctors Roster
                          if (staff.isNotEmpty) ...[
                            /*
                            // Gene - Nov, 03, 2026: Hardcoded staff header
                            Text(
                              'Specialists & Staff',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                              ),
                            ),
                            */
                            // Gene - Nov, 04, 2026: Dynamic resource header based on template uiConfig
                            Text(
                              business.showStaffSelection
                                  ? 'Our ${business.resourceLabel}s'
                                  : 'Available ${business.resourceLabel}s',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 130,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: staff.length,
                                itemBuilder: (context, index) {
                                  final st = staff[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: NeumorphicContainer(
                                      width: 150,
                                      borderRadius: 18.0,
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundImage: NetworkImage(st.avatarUrl ?? 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=200'),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            st.name,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                          if (st.specialty != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              st.specialty!,
                                              style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Services Catalog
                          /*
                          // Gene - Nov, 03, 2026: Hardcoded procedures title
                          Text(
                            'Procedures & Services',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                            ),
                          ),
                          */
                          // Gene - Nov, 04, 2026: Dynamic service label header based on template uiConfig
                          Text(
                            '${business.serviceLabel} Catalog',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...services.map((srv) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: NeumorphicContainer(
                                borderRadius: 16.0,
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            srv.name,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                          ),
                                          if (srv.description != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              srv.description!,
                                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            srv.formattedDuration,
                                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      srv.formattedPrice,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 100), // spacing for bottom bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Sticky "Book Now" CTA
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: BoxDecoration(
                    color: (isDark ? NeumorphicColors.darkCanvas : NeumorphicColors.lightCanvas).withValues(alpha: 0.95),
                    border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                  ),
                  child: NeumorphicButton(
                    isPrimary: true,
                    onPressed: () => context.push('/book/${business.id}'),
                    child: Text('Book Appointment (${business.bookingModel.displayName.split('(').first.trim()})'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
