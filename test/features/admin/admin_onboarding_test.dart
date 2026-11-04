// Gene - Nov, 04, 2026: Tests for BusinessService template retrieval, creation, and onboarding wizard
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/models/business_staff.dart';
import 'package:bookit/services/business_service.dart';
import 'package:bookit/features/admin/presentation/widgets/admin_onboarding_wizard.dart';

void main() {
  group('BusinessService Template & Category Tests', () {
    test('getCategories returns 6 sweet-spot categories in offline fallback', () async {
      final service = BusinessService();
      final categories = await service.getCategories();
      expect(categories.length, greaterThanOrEqualTo(6));
      expect(categories.any((c) => c.name.contains('Healthcare')), isTrue);
      expect(categories.any((c) => c.name.contains('Wellness')), isTrue);
      expect(categories.any((c) => c.name.contains('Beauty')), isTrue);
      expect(categories.any((c) => c.name.contains('Fitness')), isTrue);
      expect(categories.any((c) => c.name.contains('Professional Consulting')), isTrue);
      expect(categories.any((c) => c.name.contains('Studios & Space')), isTrue);
    });

    test('getTemplates returns sweet-spot templates with starter services and intake fields', () async {
      final service = BusinessService();
      final templates = await service.getTemplates();
      expect(templates.length, greaterThanOrEqualTo(8));

      final dentalTpl = templates.firstWhere((t) => t.slug == 'dental-clinic');
      expect(dentalTpl.bookingModel, BookingModelType.slotBased);
      expect(dentalTpl.showStaffSelection, isTrue);
      expect(dentalTpl.starterServices.isNotEmpty, isTrue);
      expect(dentalTpl.starterStaffRoles.isNotEmpty, isTrue);
      expect(dentalTpl.intakeFields.isNotEmpty, isTrue);

      final recoveryTpl = templates.firstWhere((t) => t.slug == 'recovery-suites');
      expect(recoveryTpl.bookingModel, BookingModelType.dateRange);
      expect(recoveryTpl.showStaffSelection, isFalse);
    });

    test('createBusiness stores new business and provisions starter services and staff', () async {
      final service = BusinessService();
      final newBiz = Business(
        id: 'test-biz-onboard-1',
        ownerId: 'owner-test',
        name: 'Test Onboard Clinic',
        slug: 'test-onboard-clinic',
        category: 'dental-clinic',
        bookingModel: BookingModelType.slotBased,
        settings: const {'slot_interval_minutes': 30},
        uiConfig: const {
          'resource_type': 'person',
          'resource_label': 'Dentist',
          'show_staff_selection': true,
        },
      );

      final services = [
        ServiceItem(
          id: 'srv-test-1',
          businessId: 'test-biz-onboard-1',
          name: 'Consultation',
          durationMinutes: 30,
          price: 100.0,
          paymentPolicy: 'full_upfront',
        ),
      ];

      final staff = [
        BusinessStaff(
          id: 'stf-test-1',
          businessId: 'test-biz-onboard-1',
          name: 'Dr. Jane Smith',
          specialty: 'Lead Dentist',
        ),
      ];

      final created = await service.createBusiness(
        business: newBiz,
        services: services,
        staff: staff,
      );

      expect(created.id, 'test-biz-onboard-1');
      expect(created.name, 'Test Onboard Clinic');

      // Verify services and staff are retrievable
      final fetchedServices = await service.getServices('test-biz-onboard-1');
      expect(fetchedServices.any((s) => s.id == 'srv-test-1'), isTrue);

      final fetchedStaff = await service.getStaff('test-biz-onboard-1');
      expect(fetchedStaff.any((st) => st.id == 'stf-test-1'), isTrue);
    });
  });

  group('AdminOnboardingWizard Widget Tests', () {
    testWidgets('AdminOnboardingWizard renders category chips and template cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AdminOnboardingWizard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and step 1 title
      expect(find.text('Business Onboarding & Setup'), findsOneWidget);
      expect(find.text('Step 1 of 4: Choose Industry Template'), findsOneWidget);

      // Verify category chips render
      expect(find.text('All Verticals'), findsOneWidget);
      expect(find.text('Healthcare & Clinics'), findsOneWidget);

      // Verify template card exists
      expect(find.text('Dental Care Clinic'), findsOneWidget);

      // Tap on template card to select it
      await tester.tap(find.text('Dental Care Clinic'));
      await tester.pumpAndSettle();

      // Tap continue to go to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Business Profile
      expect(find.text('Step 2 of 4: Business Information'), findsOneWidget);
      expect(find.text('Business Name *'), findsOneWidget);
      expect(find.text('Slug (URL Handle)'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });
  });
}
