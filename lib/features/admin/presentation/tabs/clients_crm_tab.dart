// Gene - Nov 06, 2026: Implemented ClientsCrmTab with patient directory, LTV metrics, retention filter chips, and clinical dossier launcher
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/widgets/neumorphic_chip.dart';
import '../../../../models/client_crm_profile.dart';
import '../../../../services/crm_service.dart';
import '../widgets/client_dossier_modal.dart';
import '../widgets/kpi_metric_card.dart';

class ClientsCrmTab extends ConsumerWidget {
  final String businessId;

  const ClientsCrmTab({super.key, required this.businessId});

  void _openClientDossier(BuildContext context, ClientCrmProfile client) {
    showDialog(
      context: context,
      builder: (context) => ClientDossierModal(
        client: client,
        businessId: businessId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(businessClientsProvider(businessId));
    final searchQuery = ref.watch(crmSearchQueryProvider);
    final selectedTag = ref.watch(crmSelectedTagProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Description
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patients & Clients Directory',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track patient visit histories, lifetime value (LTV), clinical allergies, and staff notes',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Clients Async State
          clientsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(child: Text('Error loading clients: $err')),
            data: (allClients) {
              // Calculate High-Level Metrics
              final totalClients = allClients.length;
              final returningClients = allClients.where((c) => c.totalVisits > 1).length;
              final returningRate = totalClients > 0 ? (returningClients / totalClients) * 100 : 0.0;
              final totalGross = allClients.fold<double>(0.0, (acc, c) => acc + c.totalSpend);
              final avgLtv = totalClients > 0 ? totalGross / totalClients : 0.0;
              final vipCount = allClients.where((c) => c.statusTag == 'VIP').length;

              // Filtered list
              final filtered = allClients.where((client) {
                final matchQuery = searchQuery.isEmpty ||
                    client.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                    (client.email != null && client.email!.toLowerCase().contains(searchQuery.toLowerCase())) ||
                    (client.phone != null && client.phone!.contains(searchQuery));
                final matchTag = selectedTag == 'All' || client.statusTag == selectedTag;
                return matchQuery && matchTag;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Metric Summary Bar
                  Row(
                    children: [
                      Expanded(
                        child: KpiMetricCard(
                          label: 'Total Patients',
                          value: '$totalClients',
                          icon: Icons.people_alt_rounded,
                          accentColor: accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: KpiMetricCard(
                          label: 'Returning Rate',
                          value: '${returningRate.toStringAsFixed(0)}%',
                          icon: Icons.repeat_rounded,
                          accentColor: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: KpiMetricCard(
                          label: 'Average Patient LTV',
                          value: '\$${avgLtv.toStringAsFixed(0)}',
                          icon: Icons.monetization_on_rounded,
                          accentColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: KpiMetricCard(
                          label: 'VIP Patients',
                          value: '$vipCount',
                          icon: Icons.star_rounded,
                          accentColor: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search Field & Retention Filter Chips Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2330) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: TextField(
                            onChanged: (val) => ref.read(crmSearchQueryProvider.notifier).state = val,
                            decoration: InputDecoration(
                              hintText: 'Search patients by name, email, or phone...',
                              hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                              prefixIcon: Icon(Icons.search, size: 18, color: accent),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'VIP', 'Regular', 'New', 'Lapsed'].map((tag) {
                              final isSelected = selectedTag == tag;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: NeumorphicChip(
                                  label: tag,
                                  isSelected: isSelected,
                                  onTap: () => ref.read(crmSelectedTagProvider.notifier).state = tag,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Client Directory List / Cards
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 12),
                            Text(
                              'No patients match your search criteria',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filtered.map((client) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NeumorphicContainer(
                          borderRadius: 18,
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              // Avatar Initial
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: accent.withValues(alpha: 0.12),
                                child: Text(
                                  client.name.isNotEmpty ? client.name[0].toUpperCase() : 'P',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Name & Contact
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            client.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _StatusPill(tag: client.statusTag),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${client.email ?? 'No email'} • ${client.phone ?? 'No phone'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                                      ),
                                    ),
                                    if (client.medicalFlags.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        children: client.medicalFlags.map((flag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: NeumorphicColors.error.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              flag,
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: NeumorphicColors.error),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Visits & Last Date
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${client.totalVisits} visit${client.totalVisits == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      client.lastVisit != null
                                          ? 'Last: ${DateFormat('MMM d, yyyy').format(client.lastVisit!)}'
                                          : 'No prior visits',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Lifetime Spend
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      client.formattedSpend,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: accent,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Lifetime Spend',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Action: Open Dossier
                              NeumorphicButton(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                icon: Icons.folder_shared_outlined,
                                onPressed: () => _openClientDossier(context, client),
                                child: const Text('Open Dossier', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String tag;
  const _StatusPill({required this.tag});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (tag) {
      case 'VIP':
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade800;
        break;
      case 'Regular':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade700;
        break;
      case 'Lapsed':
        bg = Colors.grey.withValues(alpha: 0.2);
        fg = Colors.grey.shade600;
        break;
      case 'New':
      default:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
