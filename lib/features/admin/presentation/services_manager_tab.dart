// Gene - Nov, 03, 2026: Services and Procedures Manager Tab for Admin Web
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/business.dart';
import '../../../../models/service_item.dart';
import '../../../../services/business_service.dart';
// Gene - Nov 07, 2026: Commented out unused direct supabase_service import since persistence is delegated to BusinessService
// import '../../../../services/supabase_service.dart';

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

  /*
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
  */

  // Gene - Nov 07, 2026: Unified Add/Edit Service Dialog with description, payment policy, BusinessService persistence, and live provider invalidation
  void _showServiceFormDialog(BuildContext context, WidgetRef ref, {ServiceItem? existingService}) {
    final isEditing = existingService != null;
    final nameCtrl = TextEditingController(text: existingService?.name ?? '');
    final descCtrl = TextEditingController(text: existingService?.description ?? '');
    final priceCtrl = TextEditingController(
      text: existingService != null ? existingService.price.toStringAsFixed(0) : '',
    );
    final durationCtrl = TextEditingController(
      text: existingService != null ? '${existingService.durationMinutes}' : '30',
    );
    final depositCtrl = TextEditingController(
      text: existingService != null ? existingService.depositAmount.toStringAsFixed(0) : '20',
    );
    String paymentPolicy = existingService?.paymentPolicy == 'deposit_required'
        ? 'deposit'
        : (existingService?.paymentPolicy ?? 'full_upfront');
    if (paymentPolicy != 'full_upfront' && paymentPolicy != 'deposit' && paymentPolicy != 'pay_at_venue') {
      paymentPolicy = 'pay_at_venue';
    }
    String depositType = existingService?.depositType ?? 'percentage';
    bool isActive = existingService?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Clinical Service / Procedure' : 'Add Clinical Service / Procedure'),
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
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
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
                    if (isEditing) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active in Client Booking Catalog', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        value: isActive,
                        onChanged: (val) => setDialogState(() => isActive = val),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final parsedName = nameCtrl.text.trim().isEmpty ? 'Clinical Procedure' : nameCtrl.text.trim();
                    final parsedDesc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
                    final parsedDuration = int.tryParse(durationCtrl.text.trim()) ?? 30;
                    final parsedPrice = double.tryParse(priceCtrl.text.trim()) ?? 50.0;
                    final parsedDeposit = double.tryParse(depositCtrl.text.trim()) ?? 20.0;

                    if (isEditing) {
                      final updated = existingService.copyWith(
                        name: parsedName,
                        description: parsedDesc,
                        durationMinutes: parsedDuration,
                        price: parsedPrice,
                        paymentPolicy: paymentPolicy,
                        depositType: depositType,
                        depositAmount: parsedDeposit,
                        isActive: isActive,
                      );
                      await ref.read(businessServiceProvider).updateService(updated);
                    } else {
                      final newService = ServiceItem(
                        id: 'srv-${DateTime.now().millisecondsSinceEpoch}',
                        businessId: business.id,
                        name: parsedName,
                        description: parsedDesc,
                        durationMinutes: parsedDuration,
                        price: parsedPrice,
                        paymentPolicy: paymentPolicy,
                        depositType: depositType,
                        depositAmount: parsedDeposit,
                        isActive: true,
                      );
                      await ref.read(businessServiceProvider).addService(newService);
                    }

                    ref.invalidate(adminBusinessServicesProvider(business.id));
                    ref.invalidate(businessServicesProvider(business.id));

                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEditing ? 'Service updated successfully!' : 'Service added successfully!')),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Service'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleServiceActive(BuildContext context, WidgetRef ref, ServiceItem service) async {
    final updated = service.copyWith(isActive: !service.isActive);
    await ref.read(businessServiceProvider).updateService(updated);
    ref.invalidate(adminBusinessServicesProvider(business.id));
    ref.invalidate(businessServicesProvider(business.id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updated.isActive ? '${service.name} restored to active catalog.' : '${service.name} archived from client catalog.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /*
    final servicesAsync = ref.watch(businessServicesProvider(business.id));
    */
    // Gene - Nov 07, 2026: Watch adminBusinessServicesProvider so Admin sees both active and archived procedures
    final servicesAsync = ref.watch(adminBusinessServicesProvider(business.id));
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
                onPressed: () => _showServiceFormDialog(context, ref),
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
                                /*
                                Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                */
                                // Gene - Nov 07, 2026: Display Active / Archived badge alongside procedure title
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      s.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: s.isActive ? null : (isDark ? Colors.white38 : Colors.black38),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: s.isActive
                                            ? NeumorphicColors.success.withValues(alpha: 0.15)
                                            : Colors.grey.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        s.isActive ? 'Active' : 'Archived',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: s.isActive ? NeumorphicColors.success : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                                        (s.paymentPolicy == 'deposit' || s.paymentPolicy == 'deposit_required')
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
                          /*
                          Text(
                            s.formattedPrice,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent),
                          ),
                          */
                          // Gene - Nov 07, 2026: Added Edit Procedure and Active/Archive toggle buttons on service card
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s.formattedPrice,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Edit Procedure',
                                icon: Icon(Icons.edit_outlined, size: 18, color: accent),
                                onPressed: () => _showServiceFormDialog(context, ref, existingService: s),
                              ),
                              IconButton(
                                tooltip: s.isActive ? 'Archive Procedure' : 'Restore Procedure',
                                icon: Icon(
                                  s.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
                                  size: 18,
                                  color: s.isActive ? (isDark ? Colors.white54 : Colors.black45) : NeumorphicColors.success,
                                ),
                                onPressed: () => _toggleServiceActive(context, ref, s),
                              ),
                            ],
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
