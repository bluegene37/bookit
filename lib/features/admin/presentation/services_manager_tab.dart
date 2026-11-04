// Gene - Nov, 03, 2026: Services and Procedures Manager Tab for Admin Web
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/business.dart';
import '../../../../models/service_item.dart';
import '../../../../services/business_service.dart';
import '../../../../services/supabase_service.dart';

class ServicesManagerTab extends ConsumerWidget {
  final Business business;

  const ServicesManagerTab({super.key, required this.business});

  /*
  // Gene - Nov, 03, 2026: Previous basic service dialog without payment policy configuration
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
  */

  // Gene - Nov, 04, 2026: Added Payments & Invoices tab navigation and service payment policy configuration
  void _showAddServiceDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '30');
    final depositCtrl = TextEditingController(text: '20');
    String paymentPolicy = 'full_upfront'; // 'full_upfront', 'deposit', 'pay_at_venue'
    String depositType = 'percentage'; // 'percentage', 'fixed'

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Clinical Service / Procedure'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Procedure Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (\$)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Duration (Minutes)'),
                    ),
                    const SizedBox(height: 16),

                    // Payment Policy Dropdown
                    const Text(
                      'Payment Policy',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: paymentPolicy,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'full_upfront',
                          child: Text('Full Upfront'),
                        ),
                        DropdownMenuItem(
                          value: 'deposit',
                          child: Text('Deposit'),
                        ),
                        DropdownMenuItem(
                          value: 'pay_at_venue',
                          child: Text('Pay at Venue'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            paymentPolicy = val;
                          });
                        }
                      },
                    ),

                    // Deposit Configuration Options
                    if (paymentPolicy == 'deposit') ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Deposit Type',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Row(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ignore: deprecated_member_use
                              Radio<String>(
                                value: 'percentage',
                                // ignore: deprecated_member_use
                                groupValue: depositType,
                                // ignore: deprecated_member_use
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => depositType = val);
                                  }
                                },
                              ),
                              const Text('Percentage'),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ignore: deprecated_member_use
                              Radio<String>(
                                value: 'fixed',
                                // ignore: deprecated_member_use
                                groupValue: depositType,
                                // ignore: deprecated_member_use
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => depositType = val);
                                  }
                                },
                              ),
                              const Text('Fixed Amount'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: depositCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: depositType == 'percentage'
                              ? 'Deposit Percentage (%)'
                              : 'Deposit Amount (\$)',
                          border: const OutlineInputBorder(),
                          prefixText: depositType == 'fixed' ? '\$ ' : null,
                          suffixText: depositType == 'percentage' ? '%' : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newService = ServiceItem(
                      id: 'srv-${DateTime.now().millisecondsSinceEpoch}',
                      businessId: business.id,
                      name: nameCtrl.text.trim().isEmpty ? 'Clinical Procedure' : nameCtrl.text.trim(),
                      durationMinutes: int.tryParse(durationCtrl.text.trim()) ?? 30,
                      price: double.tryParse(priceCtrl.text.trim()) ?? 50.0,
                      paymentPolicy: paymentPolicy,
                      depositType: depositType,
                      depositAmount: double.tryParse(depositCtrl.text.trim()) ?? 20.0,
                    );
                    SupabaseService.mockServices.add(newService);

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
          /*
          // Gene - Nov, 03, 2026: Unconstrained Column in header Row causing RenderFlex overflow on smaller screens
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
          */
          // Gene - Nov, 04, 2026: Added Payments & Invoices tab navigation and service payment policy configuration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
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
              ),
              const SizedBox(width: 12),
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
                                /*
                                // Gene - Nov, 03, 2026: Simple duration label without payment policy
                                Text(
                                  'Duration: ${s.formattedDuration}',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                                ),
                                */
                                // Gene - Nov, 04, 2026: Added Payments & Invoices tab navigation and service payment policy configuration
                                Row(
                                  children: [
                                    Text(
                                      'Duration: ${s.formattedDuration}',
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        s.paymentPolicy == 'deposit'
                                            ? (s.depositType == 'percentage'
                                                ? '${s.depositAmount.toInt()}% Deposit'
                                                : '\$${s.depositAmount.toStringAsFixed(0)} Deposit')
                                            : (s.paymentPolicy == 'pay_at_venue' ? 'Pay at Venue' : 'Full Upfront'),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent),
                                      ),
                                    ),
                                  ],
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
