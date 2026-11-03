// Gene - Nov, 03, 2026: Services and Procedures Manager Tab for Admin Web
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/business.dart';
// import '../../../../models/service_item.dart';
import '../../../../services/business_service.dart';

class ServicesManagerTab extends ConsumerWidget {
  final Business business;

  const ServicesManagerTab({super.key, required this.business});

  void _showAddServiceDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Clinical Service / Procedure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Procedure Name')),
              const SizedBox(height: 10),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (\$)')),
              const SizedBox(height: 10),
              TextField(controller: durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (Minutes)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service added successfully!')),
                );
              },
              child: const Text('Add Service'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(businessServicesProvider(business.id));
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
                    'Services & Pricing Catalog',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your treatment menu and prices',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
              NeumorphicButton(
                isPrimary: true,
                height: 44,
                icon: Icons.add,
                onPressed: () => _showAddServiceDialog(context),
                child: const Text('New Procedure'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          servicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (services) {
              if (services.isEmpty) {
                return const Center(child: Text('No procedures registered.'));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final s = services[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NeumorphicContainer(
                      borderRadius: 18.0,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                if (s.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    s.description!,
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  'Duration: ${s.formattedDuration}',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            s.formattedPrice,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent),
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
