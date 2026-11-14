// Gene - Nov, 05, 2026: Tactile Neumorphic Demo Persona Switcher and Reset Store Dialog
// Gene - Nov, 14, 2026: Removed direct kReleaseMode import in favor of unified AuthNotifier.isDemoModeEnabled
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/demo_data.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic_container.dart';
import '../../services/auth_service.dart';
import '../../services/business_service.dart';
import '../../services/booking_service.dart';
import '../../services/supabase_service.dart';
import '../../models/user_profile.dart';

class DemoPersonaSwitcherDialog extends ConsumerWidget {
  const DemoPersonaSwitcherDialog({super.key});

  /*
  // Gene - Nov, 05, 2026: Unconditional dialog presentation
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DemoPersonaSwitcherDialog(),
    );
  }
  */

  // Gene - Nov, 05, 2026: Disable demo persona switcher in production release builds (CWE-489)
  /*
  static void show(BuildContext context) {
    if (kReleaseMode) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DemoPersonaSwitcherDialog(),
    );
  }
  */
  // Gene - Nov, 14, 2026: Check unified AuthNotifier.isDemoModeEnabled guard so release-simulation & production builds lock out persona switching
  static void show(BuildContext context) {
    if (!AuthNotifier.isDemoModeEnabled) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DemoPersonaSwitcherDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final bgColor = isDark ? NeumorphicColors.darkCanvas : NeumorphicColors.lightCanvas;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 580,
      ),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Handle & Title
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                NeumorphicContainer(
                  isCircle: true,
                  width: 36,
                  height: 36,
                  child: Icon(Icons.switch_account_rounded, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Persona Switcher',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Instant persona swapping for testing user & admin flows',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Personas List
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: DemoData.allDemoUsers.map((persona) {
                    final isSelected = currentUser?.id == persona.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          ref.read(authProvider.notifier).switchPersona(persona);
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched to ${persona.fullName} (${persona.role.toUpperCase()})'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );

                          // Intelligent routing based on role
                          /*
                          // Gene - Nov, 05, 2026: Used overloaded isBusinessOwner instead of canAccessAdminPortal
                          if (persona.isBusinessOwner) {
                            context.go('/admin');
                          } else {
                            context.go('/');
                          }
                          */
                          // Gene - Nov, 14, 2026: Route both owners and staff to /admin via canAccessAdminPortal
                          if (persona.canAccessAdminPortal) {
                            context.go('/admin');
                          } else {
                            context.go('/');
                          }
                        },
                        child: NeumorphicContainer(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(14),
                          isInset: isSelected,
                          child: Row(
                            children: [
                              /*
                              CircleAvatar(
                                radius: 22,
                                backgroundImage: persona.avatarUrl != null ? NetworkImage(persona.avatarUrl!) : null,
                                child: persona.avatarUrl == null ? Text(persona.fullName[0]) : null,
                              ),
                              */
                              // Gene - Nov, 7, 2026: Added onBackgroundImageError handler to prevent uncaught NetworkImageLoadException on broken avatar URLs
                              CircleAvatar(
                                radius: 22,
                                backgroundImage: persona.avatarUrl != null ? NetworkImage(persona.avatarUrl!) : null,
                                onBackgroundImageError: persona.avatarUrl != null ? (_, _) {} : null,
                                child: persona.avatarUrl == null ? Text(persona.fullName[0]) : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            persona.fullName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildRoleBadge(persona.role, isDark),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _getPersonaSubtitle(persona),
                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: accent, size: 22)
                              else
                                Icon(Icons.arrow_forward_ios_rounded, color: textSecondary.withValues(alpha: 0.5), size: 14),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Reset Demo Data Button
            OutlinedButton.icon(
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset Demo Data to Initial State'),
              style: OutlinedButton.styleFrom(
                foregroundColor: NeumorphicColors.error,
                side: BorderSide(color: NeumorphicColors.error.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                _confirmResetData(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildRoleBadge(String role, bool isDark) {
    Color badgeColor;
    String label;

    switch (role) {
      case 'business_owner':
      case 'admin':
        badgeColor = NeumorphicColors.tealPrimary;
        label = 'Admin / Owner';
        break;
      case 'staff':
        badgeColor = NeumorphicColors.cyanAccent;
        label = 'Practitioner';
        break;
      case 'client':
      default:
        badgeColor = isDark ? Colors.purpleAccent : Colors.purple;
        label = 'Patient / Client';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _getPersonaSubtitle(UserProfile persona) {
    switch (persona.email) {
      case 'admin@bookit.dev':
        return 'Apex Dental, Lumina Dermatology & Vanguard';
      case 'retreat@bookit.dev':
        return 'Serenity Wellness Suites & Mindful Horizon';
      case 'staff@bookit.dev':
        return 'Specialist at Apex Dental Care';
      case 'client@bookit.dev':
      default:
        return 'Active bookings & treatment history';
    }
  }

  static void _confirmResetData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
          'This will reset all in-memory mock businesses, services, staff, customer bookings, reviews, and notifications back to their pristine default seed values.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: NeumorphicColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);

              // 1. Reset in-memory collections
              SupabaseService.resetToDefaultData();

              // 2. Refresh Riverpod providers
              ref.invalidate(businessListProvider);
              ref.invalidate(businessCategoriesProvider);
              ref.invalidate(businessTemplatesProvider);
              ref.invalidate(bookingsProvider);
              ref.read(authProvider.notifier).resetDemoData();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All demo data has been reset to default seeds!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Reset Everything', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
