// Gene - Nov 06, 2026: Implemented ClientDossierModal displaying complete patient clinical history, spend LTV, medical flags, and staff notes
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../models/client_crm_profile.dart';
import '../../../../services/crm_service.dart';

class ClientDossierModal extends ConsumerStatefulWidget {
  final ClientCrmProfile client;
  final String businessId;

  const ClientDossierModal({
    super.key,
    required this.client,
    required this.businessId,
  });

  @override
  ConsumerState<ClientDossierModal> createState() => _ClientDossierModalState();
}

class _ClientDossierModalState extends ConsumerState<ClientDossierModal> {
  late ClientCrmProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.client;
  }

  void _showAddNoteDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Clinical / Internal Note'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Prefers morning appointments, sensitive to numbing agents, advised on post-op care...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = noteController.text.trim();
              if (text.isNotEmpty) {
                ref.read(crmServiceProvider).addInternalNote(_profile.id, text);
                setState(() {
                  final timestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  _profile = _profile.copyWith(
                    internalStaffNotes: ['[$timestamp] $text', ..._profile.internalStaffNotes],
                  );
                });
                ref.invalidate(businessClientsProvider(widget.businessId));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clinical note added to patient record!')),
                );
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
        child: NeumorphicContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, Name, Status Tag, Close
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Text(
                      _profile.name.isNotEmpty ? _profile.name[0].toUpperCase() : 'P',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent),
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
                                _profile.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusTagPill(tag: _profile.statusTag),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_profile.email ?? 'No email on file'} • ${_profile.phone ?? 'No phone on file'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // KPI Summary Metrics Bar
              Row(
                children: [
                  Expanded(child: _KpiMiniTile(title: 'Lifetime Spend', value: _profile.formattedSpend, color: accent)),
                  const SizedBox(width: 10),
                  Expanded(child: _KpiMiniTile(title: 'Total Visits', value: '${_profile.totalVisits}', color: Colors.blueAccent)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiMiniTile(
                      title: 'No-Show Rate',
                      value: '${_profile.noShowRate.toStringAsFixed(0)}%',
                      color: _profile.noShowRate > 20 ? NeumorphicColors.error : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Scrollable Clinical Content
              Expanded(
                child: ListView(
                  children: [
                    // Clinical & Medical Flags Section
                    if (_profile.medicalFlags.isNotEmpty) ...[
                      Text(
                        'Medical & Clinical Flags',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _profile.medicalFlags.map((flag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: NeumorphicColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: NeumorphicColors.error.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 14, color: NeumorphicColors.error),
                                const SizedBox(width: 5),
                                Text(
                                  flag,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: NeumorphicColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Internal Clinical Notes Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Staff & Clinical Notes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showAddNoteDialog,
                          icon: const Icon(Icons.add_comment_outlined, size: 15),
                          label: const Text('Add Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_profile.internalStaffNotes.isEmpty)
                      Text(
                        'No internal notes recorded for this patient.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                      )
                    else
                      ..._profile.internalStaffNotes.map((note) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            note,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 18),

                    // Chronological Visit History
                    Text(
                      'Appointment & Visit History (${_profile.appointmentHistory.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_profile.appointmentHistory.isEmpty)
                      Text(
                        'No appointments recorded.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                      )
                    else
                      ..._profile.appointmentHistory.map((appt) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2330) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.calendar_today_rounded, size: 16, color: accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appt.serviceName ?? 'General Appointment',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${appt.formattedSchedule} • Specialist: ${appt.staffName ?? 'Staff'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                                      ),
                                    ),
                                    if (appt.clientNotes != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Note: ${appt.clientNotes}',
                                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.white38 : Colors.black45),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${appt.totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent),
                                  ),
                                  const SizedBox(height: 4),
                                  StatusBadge(status: appt.status),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NeumorphicButton(
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: const Text('Close Dossier'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTagPill extends StatelessWidget {
  final String tag;
  const _StatusTagPill({required this.tag});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _KpiMiniTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _KpiMiniTile({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
