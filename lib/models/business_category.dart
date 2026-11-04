// Gene - Nov, 04, 2026: Business category model representing high-level industry groupings

class BusinessCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String icon;
  final int displayOrder;
  final bool isActive;

  const BusinessCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon = 'category',
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'category',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}
