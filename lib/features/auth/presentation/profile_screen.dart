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
          // Gene - Nov, 14, 2026: Use compact horizontal padding on narrow screens (< 360px) to prevent card compression
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 360 ? 14 : 20,
            vertical: 20,
          ),
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
                            /*
                            // Gene - Nov, 05, 2026: Used overloaded isBusinessOwner
                            user.isBusinessOwner ? Icons.local_hospital_rounded : Icons.person_rounded,
                            */
                            // Gene - Nov, 14, 2026: Check canAccessAdminPortal for clinical practitioners + owners
                            user.canAccessAdminPortal ? Icons.local_hospital_rounded : Icons.person_rounded,
                            size: 46,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        textAlign: TextAlign.center,
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
                      /*
                      // Gene - Nov, 05, 2026: Single-line Row + low-contrast tint badges
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
                      */
                      // Gene - Nov, 14, 2026: Wrapped role/status badges in Wrap with WCAG AA theme-aware colors and distinct practitioner label
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (user.canAccessAdminPortal
                                      ? (isDark ? NeumorphicColors.cyanLight : NeumorphicColors.cyanAccent)
                                      : accent)
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (user.canAccessAdminPortal
                                        ? (isDark ? NeumorphicColors.cyanLight : NeumorphicColors.cyanAccent)
                                        : accent)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              user.isBusinessOwner
                                  ? 'CLINIC ADMIN / OWNER'
                                  : (user.isStaff ? 'CLINIC PRACTITIONER' : 'CLIENT PATIENT'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: user.canAccessAdminPortal
                                    ? (isDark ? NeumorphicColors.cyanLight : NeumorphicColors.cyanAccent)
                                    : accent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: NeumorphicColors.successFor(isDark).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: NeumorphicColors.successFor(isDark).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: NeumorphicColors.successFor(isDark),
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
                      if (user.canAccessAdminPortal) ...[
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

                // Testing & Demo Tools
                // Gene - Nov, 14, 2026: Gate entire Demo & Role Management section behind AuthNotifier.isDemoModeEnabled so release builds expose zero privilege-escalation UI
                if (AuthNotifier.isDemoModeEnabled) ...[
                  const SizedBox(height: 24),
                  NeumorphicContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 20, color: accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Demo & Role Management',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                                ),
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
                              Flexible(
                                child: Text(
                                  user.isBusinessOwner ? 'Switch to Client View' : 'Switch to Clinic Admin',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
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
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: () => DemoPersonaSwitcherDialog.show(context),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Sign Out Button
                NeumorphicButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out successfully.')),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: NeumorphicColors.errorFor(isDark)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Sign Out',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: NeumorphicColors.errorFor(isDark),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Unauthenticated State
                NeumorphicContainer(
                  // Gene - Nov, 14, 2026: Adaptive padding on < 360px screens and Flexible button labels + gated demo accounts
                  padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 360 ? 20 : 32),
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
                        textAlign: TextAlign.center,
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
                            Flexible(
                              child: Text(
                                'Sign In',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
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
                            Flexible(
                              child: Text(
                                'Create Account',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (AuthNotifier.isDemoModeEnabled) ...[
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                            final stackDemoButtons = constraints.maxWidth < 280 * textScale;
                            final demoClientBtn = NeumorphicButton(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              onPressed: () {
                                ref.read(authProvider.notifier).loginAsDemoClient();
                              },
                              child: const Text(
                                'Demo Client',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            );
                            final demoAdminBtn = NeumorphicButton(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              onPressed: () {
                                ref.read(authProvider.notifier).loginAsDemoAdmin();
                              },
                              child: const Text(
                                'Demo Admin',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            );
                            if (stackDemoButtons) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  demoClientBtn,
                                  const SizedBox(height: 10),
                                  demoAdminBtn,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: demoClientBtn),
                                const SizedBox(width: 12),
                                Expanded(child: demoAdminBtn),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              /*
              // Gene - Nov, 05, 2026: Previous unauthenticated & ungated demo blocks preserved for traceability
              // NeumorphicContainer(padding: EdgeInsets.all(20), ... 'Demo & Role Management' ...)
              // Row(children: [Expanded(child: Demo Client), Expanded(child: Demo Admin)])
              */
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
