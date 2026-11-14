// Gene - Nov, 03, 2026: Tactile Neumorphic Sign Up Screen with Role Selection & Supabase Auth
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../core/widgets/neumorphic_text_field.dart';
import '../../../core/widgets/neumorphic_chip.dart';
// Gene - Nov, 08, 2026: Added BookItLogo import for minimalist Geometric 'B' + Checkmark brand mark
import '../../../core/widgets/bookit_logo.dart';
import '../../../services/auth_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'client'; // 'client' or 'business_owner'
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    /*
    // Gene - Nov, 05, 2026: Sign up without email format regex or minimum 6-character password check
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields.')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    */
    // Gene - Nov, 14, 2026: Validate non-empty fields, email regex format, and minimum 6-character password before signUp
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields.')),
      );
      return;
    }
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).signUp(
      email: email,
      password: password,
      fullName: name,
      role: _selectedRole,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    );

    /*
    // Gene - Nov, 03, 2026: Sign up without explicit failure SnackBar feedback
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account registered! Welcome to BookIt.'),
          backgroundColor: NeumorphicColors.success,
        ),
      );
      if (_selectedRole == 'business_owner') {
        context.go('/admin');
      } else {
        context.go('/');
      }
    }
    */

    // Gene - Nov, 05, 2026: Provide immediate user feedback and error SnackBar if registration fails
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account registered! Welcome to BookIt.'),
          backgroundColor: NeumorphicColors.success,
        ),
      );
      if (_selectedRole == 'business_owner') {
        context.go('/admin');
      } else {
        context.go('/');
      }
    } else if (mounted) {
      final errorMsg = ref.read(authProvider).error ?? 'Registration failed. Please check your credentials and try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: NeumorphicColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w700)),
        /*
        // Gene - Nov, 03, 2026: Leading back button without tooltip or deep-link GoRouter.canPop() safety
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        */
        // Gene - Nov, 14, 2026: Added semantic Back tooltip and canPop() fallback to '/' on cold-start deep links
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  // Gene - Nov, 08, 2026: Added minimalist Geometric 'B' + Checkmark BookItLogo above Join BookIt heading
                  const BookItLogo(size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Join BookIt',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Seamless booking for medical, dental, and specialty care',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Role Selection Pills
                  /*
                  // Gene - Nov, 03, 2026: Fixed 2-column Row clipped role chip labels at 320px/375px 1.5x text scale
                  Row(
                    children: [
                      Expanded(
                        child: NeumorphicChip(
                          label: 'Patient / Client',
                          icon: Icons.person_outline,
                          isSelected: _selectedRole == 'client',
                          onTap: () => setState(() => _selectedRole = 'client'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeumorphicChip(
                          label: 'Clinic / Business',
                          icon: Icons.storefront_outlined,
                          isSelected: _selectedRole == 'business_owner',
                          onTap: () => setState(() => _selectedRole = 'business_owner'),
                        ),
                      ),
                    ],
                  ),
                  */
                  // Gene - Nov, 14, 2026: Stack role chips vertically on narrow/scaled viewports to eliminate horizontal clipping and vertical overflow
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                      final stackChips = constraints.maxWidth < 360 * textScale;
                      final clientChip = NeumorphicChip(
                        label: 'Patient / Client',
                        icon: Icons.person_outline,
                        isSelected: _selectedRole == 'client',
                        onTap: () => setState(() => _selectedRole = 'client'),
                      );
                      final clinicChip = NeumorphicChip(
                        label: 'Clinic / Business',
                        icon: Icons.storefront_outlined,
                        isSelected: _selectedRole == 'business_owner',
                        onTap: () => setState(() => _selectedRole = 'business_owner'),
                      );
                      if (stackChips) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            clientChip,
                            const SizedBox(height: 10),
                            clinicChip,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: clientChip),
                          const SizedBox(width: 12),
                          Expanded(child: clinicChip),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Form Container
                  NeumorphicContainer(
                    borderRadius: 24.0,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (authState.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: NeumorphicColors.errorFor(isDark).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: NeumorphicColors.errorFor(isDark).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              authState.error!,
                              style: TextStyle(color: NeumorphicColors.errorFor(isDark), fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        NeumorphicTextField(
                          controller: _nameController,
                          labelText: 'Full Name',
                          hintText: 'e.g. Michael Chen or Dr. Sarah Lin',
                          prefixIcon: Icon(Icons.person_outline, size: 18, color: accent),
                        ),
                        const SizedBox(height: 14),

                        NeumorphicTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'e.g. michael@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icon(Icons.email_outlined, size: 18, color: accent),
                        ),
                        const SizedBox(height: 14),

                        NeumorphicTextField(
                          controller: _phoneController,
                          labelText: 'Phone Number (Optional)',
                          hintText: 'e.g. +1 (555) 000-0000',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icon(Icons.phone_outlined, size: 18, color: accent),
                        ),
                        const SizedBox(height: 14),

                        NeumorphicTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Create a password (min 6 characters)',
                          obscureText: _obscurePassword,
                          prefixIcon: Icon(Icons.lock_outline, size: 18, color: accent),
                          /*
                          // Gene - Nov, 03, 2026: Password visibility IconButton missing semantic tooltip
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          */
                          // Gene - Nov, 14, 2026: Added accessible tooltip and WCAG-compliant icon color
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: isDark ? NeumorphicColors.darkTextMuted : NeumorphicColors.lightTextMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 14),

                        NeumorphicTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          hintText: 'Repeat password',
                          obscureText: _obscurePassword,
                          prefixIcon: Icon(Icons.lock_outline, size: 18, color: accent),
                        ),
                        const SizedBox(height: 24),

                        NeumorphicButton(
                          isPrimary: true,
                          isLoading: authState.isLoading,
                          onPressed: _handleSignUp,
                          child: const Text('Create Account'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Gene - Nov, 03, 2026: Wrapped sign-in footer link in Wrap to eliminate mobile flex overflows
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already registered?',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/login'),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  /*
                  // Gene - Nov, 03, 2026: Previous Row widget that caused overflow on narrow widths
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already registered?'),
                      TextButton(onPressed: () => context.push('/login'), child: Text('Sign In')),
                    ],
                  ),
                  */
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
