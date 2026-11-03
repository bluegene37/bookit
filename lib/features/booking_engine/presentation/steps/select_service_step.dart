// Gene - Nov, 03, 2026: Step 1 - Service & Procedure selection step
import 'package:flutter/material.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../models/service_item.dart';

class SelectServiceStep extends StatelessWidget {
  final List<ServiceItem> services;
  final ServiceItem? selectedService;
  final ValueChanged<ServiceItem> onSelect;

  const SelectServiceStep({
    super.key,
    required this.services,
    required this.selectedService,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    if (services.isEmpty) {
      return const Center(child: Text('No services currently listed.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: services.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final service = services[index];
        final isSelected = selectedService?.id == service.id;

        return NeumorphicContainer(
          borderRadius: 18.0,
          isInset: isSelected,
          onTap: () => onSelect(service),
          padding: const EdgeInsets.all(18),
          border: isSelected ? Border.all(color: accent, width: 2) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? accent.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  color: isSelected ? accent : (isDark ? Colors.white70 : Colors.black54),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? accent : (isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary),
                      ),
                    ),
                    if (service.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                        const SizedBox(width: 4),
                        Text(
                          service.formattedDuration,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                service.formattedPrice,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
