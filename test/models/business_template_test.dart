// Gene - Nov, 04, 2026: Unit tests for BusinessCategory and BusinessTemplate models & UI helpers
import 'package:flutter_test/flutter_test.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/models/business_category.dart';
import 'package:bookit/models/business_template.dart';

void main() {
  group('BusinessCategory Model Tests', () {
    test('BusinessCategory serializes to and from JSON properly', () {
      final json = {
        'id': 'cat-1',
        'name': 'Healthcare & Clinics',
        'slug': 'healthcare-clinics',
        'description': 'Medical and dental practices',
        'icon': 'medical_services_rounded',
        'display_order': 1,
        'is_active': true,
      };

      final cat = BusinessCategory.fromJson(json);
      expect(cat.id, 'cat-1');
      expect(cat.name, 'Healthcare & Clinics');
      expect(cat.slug, 'healthcare-clinics');
      expect(cat.icon, 'medical_services_rounded');
      expect(cat.displayOrder, 1);
      expect(cat.isActive, isTrue);

      final serialized = cat.toJson();
      expect(serialized['id'], 'cat-1');
      expect(serialized['name'], 'Healthcare & Clinics');
      expect(serialized['slug'], 'healthcare-clinics');
    });
  });

  group('BusinessTemplate Model Tests', () {
    test('BusinessTemplate parses fields and dynamic UI helpers correctly', () {
      final json = {
        'id': 'tpl-1',
        'category_id': 'cat-1',
        'name': 'Dental Care Clinic',
        'slug': 'dental-clinic',
        'description': 'Full dental care setup',
        'icon': 'medical_information_rounded',
        'booking_model': 'slot_based',
        'default_settings': {
          'slot_interval_minutes': 30,
          'buffer_minutes': 10,
        },
        'ui_config': {
          'resource_type': 'person',
          'resource_label': 'Dentist / Specialist',
          'service_label': 'Dental Procedure',
          'show_staff_selection': true,
          'intake_fields': [
            {'id': 'insurance', 'label': 'Dental Insurance?', 'type': 'boolean', 'required': false},
            {'id': 'complaint', 'label': 'Symptoms', 'type': 'textarea', 'required': true},
          ],
        },
        'starter_services': [
          {'name': 'Teeth Cleaning', 'price': 95.0, 'duration_minutes': 45},
        ],
        'starter_staff_roles': ['General Dentist', 'Hygienist'],
        'display_order': 1,
        'is_active': true,
      };

      final tpl = BusinessTemplate.fromJson(json);
      expect(tpl.id, 'tpl-1');
      expect(tpl.categoryId, 'cat-1');
      expect(tpl.name, 'Dental Care Clinic');
      expect(tpl.bookingModel, BookingModelType.slotBased);
      expect(tpl.resourceType, 'person');
      expect(tpl.resourceLabel, 'Dentist / Specialist');
      expect(tpl.serviceLabel, 'Dental Procedure');
      expect(tpl.showStaffSelection, isTrue);
      expect(tpl.intakeFields.length, 2);
      expect(tpl.intakeFields[0]['type'], 'boolean');
      expect(tpl.starterServices.length, 1);
      expect(tpl.starterStaffRoles, contains('General Dentist'));

      final serialized = tpl.toJson();
      expect(serialized['name'], 'Dental Care Clinic');
      expect(serialized['booking_model'], 'slot_based');
    });

    test('Business template inheritance into Business model', () {
      final biz = Business(
        id: 'biz-1',
        ownerId: 'owner-1',
        templateId: 'tpl-1',
        name: 'Smile Design Dental',
        slug: 'smile-design',
        category: 'dental-clinic',
        bookingModel: BookingModelType.slotBased,
        uiConfig: {
          'resource_type': 'person',
          'resource_label': 'Lead Dentist',
          'service_label': 'Treatment',
          'show_staff_selection': true,
          'intake_fields': [
            {'id': 'allergies', 'label': 'Allergies', 'type': 'text', 'required': false},
          ],
        },
      );

      expect(biz.templateId, 'tpl-1');
      expect(biz.resourceLabel, 'Lead Dentist');
      expect(biz.serviceLabel, 'Treatment');
      expect(biz.showStaffSelection, isTrue);
      expect(biz.intakeFields.length, 1);
      expect(biz.intakeFields[0]['id'], 'allergies');

      final json = biz.toJson();
      expect(json['template_id'], 'tpl-1');
      expect(json['ui_config']['resource_label'], 'Lead Dentist');

      final restored = Business.fromJson(json);
      expect(restored.templateId, 'tpl-1');
      expect(restored.resourceLabel, 'Lead Dentist');
    });
  });
}
