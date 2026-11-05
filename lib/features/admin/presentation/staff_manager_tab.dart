// Gene - Nov, 03, 2026: Staff and Doctor Roster Manager Tab for Admin Web
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/business.dart';
import '../../../../services/business_service.dart';
// Gene - Nov 06, 2026: Added StaffShiftEditorDialog import for shift matrix & break management
import 'widgets/staff_shift_editor_dialog.dart';

class StaffManagerTab extends ConsumerWidget {
  final Business business;

  const StaffManagerTab({super.key, required this.business});

  void _showAddStaffDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final specialtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Practitioner / Specialist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Doctor Name (e.g. Dr. Alex Vance, DDS)')),
              const SizedBox(height: 10),
              TextField(controller: specialtyCtrl, decoration: const InputDecoration(labelText: 'Specialty (e.g. Orthodontist)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Staff member registered!')),
                );
              },
              child: const Text('Save Staff Member'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(businessStaffProvider(business.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doctors & Specialists Roster',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage practitioners, shifts, and credentials',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
              NeumorphicButton(
                isPrimary: true,
                height: 44,
                icon: Icons.person_add,
                onPressed: () => _showAddStaffDialog(context),
                child: const Text('Add Specialist'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          staffAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (staff) {
              if (staff.isEmpty) {
                return const Center(child: Text('No practitioners registered yet.'));
              }

              /*
              // Gene - Nov, 03, 2026: Original staff card without shift schedule display and editor
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: staff.length,
                itemBuilder: (context, index) {
                  final st = staff[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NeumorphicContainer(
                      borderRadius: 18.0,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundImage: NetworkImage(st.avatarUrl ?? 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=200'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(st.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                if (st.specialty != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    st.specialty!,
                                    style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600),
                                  ),
                                ],
                                if (st.bio != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    st.bio!,
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: NeumorphicColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NeumorphicColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
              */

              // Gene - Nov 06, 2026: Enhanced staff card with shift summary badge and StaffShiftEditorDialog launcher
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: staff.length,
                itemBuilder: (context, index) {
                  final st = staff[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NeumorphicContainer(
                      borderRadius: 18.0,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundImage: NetworkImage(
                              st.avatarUrl ??
                                  'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=200',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        st.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: NeumorphicColors.success.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: NeumorphicColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (st.specialty != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    st.specialty!,
                                    style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: accent.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule_rounded, size: 12, color: accent),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          st.shiftSummary,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          NeumorphicButton(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            onPressed: () => StaffShiftEditorDialog.show(context, st, business.id),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_calendar_rounded, size: 14, color: accent),
                                const SizedBox(width: 6),
                                const Text(
                                  'Edit Shifts',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
