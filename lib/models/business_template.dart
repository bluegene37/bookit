// Gene - Nov, 04, 2026: Business template model with default settings, starter services, and modular UI config
import 'business.dart';

class BusinessTemplate {
  final String id;
  final String categoryId;
  final String name;
  final String slug;
  final String? description;
  final String icon;
  final BookingModelType bookingModel;
  final Map<String, dynamic> defaultSettings;
  final Map<String, dynamic> uiConfig;
  final List<Map<String, dynamic>> starterServices;
  final List<String> starterStaffRoles;
  final int displayOrder;
  final bool isActive;

  const BusinessTemplate({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description,
    this.icon = 'business',
    required this.bookingModel,
    this.defaultSettings = const {},
    this.uiConfig = const {},
    this.starterServices = const [],
    this.starterStaffRoles = const [],
    this.displayOrder = 0,
    this.isActive = true,
  });

  String get resourceType => (uiConfig['resource_type'] as String?) ?? 'person';
  String get resourceLabel => (uiConfig['resource_label'] as String?) ?? 'Specialist';
  String get serviceLabel => (uiConfig['service_label'] as String?) ?? 'Service';
  bool get showStaffSelection => (uiConfig['show_staff_selection'] as bool?) ?? true;
  List<Map<String, dynamic>> get intakeFields {
    final fields = uiConfig['intake_fields'];
    if (fields is List) {
      return fields.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  factory BusinessTemplate.fromJson(Map<String, dynamic> json) {
    return BusinessTemplate(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'business',
      bookingModel: BookingModelType.fromString(json['booking_model'] as String? ?? 'slot_based'),
      defaultSettings: json['default_settings'] != null
          ? Map<String, dynamic>.from(json['default_settings'] as Map)
          : const {},
      uiConfig: json['ui_config'] != null
          ? Map<String, dynamic>.from(json['ui_config'] as Map)
          : const {},
      starterServices: json['starter_services'] != null
          ? (json['starter_services'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : const [],
      starterStaffRoles: json['starter_staff_roles'] != null
          ? (json['starter_staff_roles'] as List).map((e) => e.toString()).toList()
          : const [],
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'booking_model': bookingModel.toDbString(),
      'default_settings': defaultSettings,
      'ui_config': uiConfig,
      'starter_services': starterServices,
      'starter_staff_roles': starterStaffRoles,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}
