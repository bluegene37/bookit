// Gene - Nov, 03, 2026: Tactile Neumorphic Profile Screen with Account Management, Role Switching, and Supabase integration
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../services/auth_service.dart';
// Gene - Nov, 05, 2026: Added demo_persona_switcher import
import '../../../core/widgets/demo_persona_switcher.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
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
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              if (user != null) ...[
                // User Avatar & Name Card
                NeumorphicContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar with Neumorphic Ring
                      NeumorphicContainer(
                        isCircle: true,
                        width: 90,
                        height: 90,
                        child: Center(
                          child: Icon(
                            user.isBusinessOwner ? Icons.local_hospital_rounded : Icons.person_rounded,
                            size: 46,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                        ),
                      ),
                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.phone!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (user.isBusinessOwner ? NeumorphicColors.cyanAccent : accent).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (user.isBusinessOwner ? NeumorphicColors.cyanAccent : accent).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              user.isBusinessOwner ? 'CLINIC ADMIN / OWNER' : 'CLIENT PATIENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: user.isBusinessOwner ? NeumorphicColors.cyanAccent : accent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: NeumorphicColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: NeumorphicColors.success.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: NeumorphicColors.success,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Navigation Actions
                NeumorphicContainer(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    children: [
                      // Gene - Nov, 7, 2026: Added direct quick-navigation links to Browse Clinics and Clinic Admin Workspace
                      if (user.isBusinessOwner) ...[
                        ListTile(
                          leading: Icon(Icons.admin_panel_settings_outlined, color: accent),
                          title: const Text('Clinic Admin Workspace', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Manage appointments, reception queue, and services'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/admin'),
                        ),
                        Divider(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                          height: 1,
                        ),
                      ],
                      ListTile(
                        leading: Icon(Icons.explore_outlined, color: accent),
                        title: const Text('Browse Clinics & Services', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Discover practices, recovery stays, and wellness sessions'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/'),
                      ),
                      Divider(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                        height: 1,
                      ),
                      ListTile(
                        leading: Icon(Icons.calendar_month_outlined, color: accent),
                        title: const Text('My Appointments', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('View and manage your upcoming bookings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/my-bookings'),
                      ),
                      Divider(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                        height: 1,
                      ),
                      ListTile(
                        leading: Icon(Icons.notifications_outlined, color: accent),
                        title: const Text('Notifications & Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('SMS and email appointment alerts'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/notifications'),
                      ),
                      Divider(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                        height: 1,
                      ),
                      ListTile(
                        leading: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          color: isDark ? Colors.amber : NeumorphicColors.lightTextSecondary,
                        ),
                        title: const Text('Appearance Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(isDark ? 'Dark Neumorphic Soft UI' : 'Light Neumorphic Soft UI'),
                        trailing: Switch(
                          value: isDark,
                          activeThumbColor: accent,
                          onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Testing & Demo Tools
                NeumorphicContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 20, color: accent),
                          const SizedBox(width: 8),
                          Text(
                            'Demo & Role Management',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Switch roles to experience BookIt from both client and business administrator viewpoints.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      NeumorphicButton(
                        onPressed: () {
                          ref.read(authProvider.notifier).toggleRole();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched role to ${user.isBusinessOwner ? 'Client' : 'Business Owner'}'),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.swap_horiz_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              user.isBusinessOwner ? 'Switch to Client View' : 'Switch to Clinic Admin',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Gene - Nov, 05, 2026: Open comprehensive Demo Persona Switcher modal
                      OutlinedButton.icon(
                        icon: const Icon(Icons.switch_account_rounded, size: 16),
                        label: const Text('Open Persona Switcher & Reset Store'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(color: accent.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        onPressed: () => DemoPersonaSwitcherDialog.show(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Out Button
                NeumorphicButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out successfully.')),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: NeumorphicColors.error),
                      SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: NeumorphicColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Unauthenticated State
                NeumorphicContainer(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      NeumorphicContainer(
                        isCircle: true,
                        width: 80,
                        height: 80,
                        child: Icon(Icons.lock_outline_rounded, size: 40, color: accent),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome to BookIt',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to book dental appointments, manage recovery stays, and view confirmation tickets.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      NeumorphicButton(
                        isPrimary: true,
                        onPressed: () => context.push('/login'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      NeumorphicButton(
                        onPressed: () => context.push('/signup'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Create Account', style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Divider(color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 16),
                      Text(
                        'Or explore demo accounts:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: NeumorphicButton(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              onPressed: () {
                                ref.read(authProvider.notifier).loginAsDemoClient();
                              },
                              child: const Text('Demo Client', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: NeumorphicButton(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              onPressed: () {
                                ref.read(authProvider.notifier).loginAsDemoAdmin();
                              },
                              child: const Text('Demo Admin', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
