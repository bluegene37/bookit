// Gene - Nov, 03, 2026: Staff and Doctor Roster Manager Tab for Admin Web
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/business.dart';
import '../../../../services/business_service.dart';

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
            },
          ),
        ],
      ),
    );
  }
}
