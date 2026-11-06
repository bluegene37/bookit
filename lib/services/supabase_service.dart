// Gene - Nov, 03, 2026: Supabase Service wrapper with seamless offline/mock fallback for immediate local testing
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_config.dart';
import '../models/business.dart';
import '../models/business_staff.dart';
import '../models/service_item.dart';
import '../models/booking.dart';
import '../models/user_profile.dart';
import '../models/payment.dart';
// Gene - Nov, 04, 2026: Added notification_item import for mockNotifications
import '../models/notification_item.dart';
// Gene - Nov, 04, 2026: Added BusinessCategory and BusinessTemplate imports for template mock data
import '../models/business_category.dart';
import '../models/business_template.dart';
// Gene - Nov, 05, 2026: Added demo_data and review imports for dynamic seeding and reset
import '../core/constants/demo_data.dart';
import '../models/review.dart';

class SupabaseService {
  static SupabaseClient? get client {
    if (SupabaseConfig.isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> initialize() async {
    if (SupabaseConfig.isConfigured) {
      try {
        // Gene - Nov, 03, 2026: Updated to use publishableKey per latest supabase_flutter 2.18+
        await Supabase.initialize(
          url: SupabaseConfig.supabaseUrl,
          publishableKey: SupabaseConfig.supabaseAnonKey,
        );
        debugPrint('Supabase successfully initialized');
      } catch (e) {
        debugPrint('Supabase initialization failed, falling back to local mock data: $e');
      }
    } else {
      debugPrint('Supabase keys not yet configured. Running in Local Mock Demo Mode.');
    }
  }

  // Gene - Nov, 05, 2026: Connected centralized DemoData datasets across all 6 business sweet spots with reset capability
  static final List<Business> mockBusinesses = List.from(DemoData.freshBusinesses);
  static final List<BusinessStaff> mockStaff = List.from(DemoData.freshStaff);
  static final List<ServiceItem> mockServices = List.from(DemoData.freshServices);
  static final List<Booking> mockBookings = List.from(DemoData.freshBookings);
  static UserProfile mockCurrentUser = DemoData.demoAdmin;
  static final List<Payment> mockPayments = List.from(DemoData.freshPayments);
  static final List<NotificationItem> mockNotifications = List.from(DemoData.freshNotifications);
  static final List<Review> mockReviews = List.from(DemoData.freshReviews);

  // Gene - Nov, 05, 2026: Reset all in-memory mock datasets to clean fresh seed state
  static void resetToDefaultData() {
    mockBusinesses.clear();
    mockBusinesses.addAll(DemoData.freshBusinesses);

    mockStaff.clear();
    mockStaff.addAll(DemoData.freshStaff);

    mockServices.clear();
    mockServices.addAll(DemoData.freshServices);

    mockBookings.clear();
    mockBookings.addAll(DemoData.freshBookings);

    mockPayments.clear();
    mockPayments.addAll(DemoData.freshPayments);

    mockNotifications.clear();
    mockNotifications.addAll(DemoData.freshNotifications);

    mockReviews.clear();
    mockReviews.addAll(DemoData.freshReviews);

    mockCurrentUser = DemoData.demoAdmin;
  }

  /*
  // Gene - Nov, 03, 2026: Initial hardcoded static mock lists preserved for history
  static final List<Business> _initialMockBusinesses = [
    Business(
      id: '11111111-1111-1111-1111-111111111111',
      ownerId: '00000000-0000-0000-0000-000000000001',
      name: 'Apex Dental & Orthodontic Care',
      slug: 'apex-dental-orthodontic',
      category: 'Dental',
      bookingModel: BookingModelType.slotBased,
      description: 'Gentle cosmetic dentistry, precision orthodontics, and restorative oral care in a state-of-the-art facility.',
      address: '742 Evergreen Medical Suites, Suite 300',
      city: 'San Francisco',
      contactPhone: '+1 (555) 456-7890',
      contactEmail: 'contact@apexdental.com',
      ratingAvg: 4.92,
      ratingCount: 48,
      bannerUrl: 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=1200&q=80',
      settings: {
        'slot_interval_minutes': 30,
        'buffer_minutes': 10,
        'requires_approval': false,
        'working_hours': {
          'monday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'tuesday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'wednesday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'thursday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'friday': {'open': '09:00', 'close': '17:00', 'is_open': true},
          'saturday': {'open': '10:00', 'close': '15:00', 'is_open': true},
          'sunday': {'open': '00:00', 'close': '00:00', 'is_open': false},
        },
      },
    ),
    Business(
      id: '22222222-2222-2222-2222-222222222222',
      ownerId: '00000000-0000-0000-0000-000000000002',
      name: 'Serenity Post-Op Recovery & Wellness Suites',
      slug: 'serenity-wellness-suites',
      category: 'Recovery Stay',
      bookingModel: BookingModelType.dateRange,
      description: 'Luxury recovery retreat offering 24/7 nursing supervision, rehabilitation therapy, and nutritious dietary plans.',
      address: '1200 Coastal Bay Road',
      city: 'Monterey',
      contactPhone: '+1 (555) 321-9876',
      contactEmail: 'reservations@serenitystay.com',
      ratingAvg: 4.85,
      ratingCount: 24,
      bannerUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=80',
      settings: {
        'checkin_time': '14:00',
        'checkout_time': '11:00',
        'min_days': 2,
        'requires_approval': true,
      },
    ),
    Business(
      id: '33333333-3333-3333-3333-333333333333',
      ownerId: '00000000-0000-0000-0000-000000000001',
      name: 'Lumina Aesthetic & Dermatology Center',
      slug: 'lumina-dermatology',
      category: 'Medical',
      bookingModel: BookingModelType.slotBased,
      description: 'Board-certified dermatologists specializing in medical skin health, clinical laser therapy, and treatments.',
      address: '88 Sutter St, Floor 4',
      city: 'San Francisco',
      contactPhone: '+1 (555) 789-0123',
      contactEmail: 'hello@luminaderm.com',
      ratingAvg: 4.78,
      ratingCount: 36,
      bannerUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=1200&q=80',
      settings: {
        'slot_interval_minutes': 45,
        'buffer_minutes': 15,
        'requires_approval': false,
      },
    ),
  ];

  static final List<BusinessStaff> _initialMockStaff = [
    const BusinessStaff(
      id: '44444444-4444-4444-4444-444444444441',
      businessId: '11111111-1111-1111-1111-111111111111',
      name: 'Dr. Alexander Vance, DDS',
      specialty: 'Orthodontics & Smile Design',
      bio: '14+ years specializing in clear aligners, Invisalign, and smile makeovers.',
      avatarUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=400&q=80',
    ),
    const BusinessStaff(
      id: '44444444-4444-4444-4444-444444444442',
      businessId: '11111111-1111-1111-1111-111111111111',
      name: 'Dr. Sophia Martinez, DMD',
      specialty: 'Periodontics & Implants',
      bio: 'Harvard Dental alumnus with expertise in implantology and restorative therapy.',
      avatarUrl: 'https://images.unsplash.com/photo-1594824813637-b9560f1ad922?auto=format&fit=crop&w=400&q=80',
    ),
    const BusinessStaff(
      id: '44444444-4444-4444-4444-444444444443',
      businessId: '11111111-1111-1111-1111-111111111111',
      name: 'Sarah Lin, RDH',
      specialty: 'Lead Dental Hygienist',
      bio: 'Gentle preventative cleaning, scaling, and deep root planing specialist.',
      avatarUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  static final List<ServiceItem> _initialMockServices = [
    const ServiceItem(
      id: '55555555-5555-5555-5555-555555555551',
      businessId: '11111111-1111-1111-1111-111111111111',
      name: 'Comprehensive Dental Exam & Cleaning',
      description: 'Panoramic X-ray, gum evaluation, gentle scaling, and high-shine polish.',
      durationMinutes: 45,
      price: 120.00,
    ),
    const ServiceItem(
      id: '55555555-5555-5555-5555-555555555552',
      businessId: '11111111-1111-1111-1111-111111111111',
      name: 'Laser Teeth Whitening (Zoom!)',
      description: 'In-office accelerated whitening achieving up to 8 shades brighter in 60 mins.',
      durationMinutes: 60,
      price: 350.00,
    ),
    const ServiceItem(
      id: '55555555-5555-5555-5555-555555555553',
      businessId: '11111111-1111-1111-1111-111111111111',
      name: 'Invisalign & Clear Aligner Consultation',
      description: '3D intraoral iTero scan, digital bite simulation, and treatment roadmap.',
      durationMinutes: 30,
      price: 75.00,
    ),
    const ServiceItem(
      id: '66666666-6666-6666-6666-666666666661',
      businessId: '22222222-2222-2222-2222-222222222222',
      name: 'Private Recovery Suite (Per Night)',
      description: 'Ocean-view terrace room with 24/7 nursing supervision and organic meals.',
      durationMinutes: 1440,
      price: 450.00,
    ),
  ];

  static final List<Booking> _initialMockBookings = [
    Booking(
      id: 'bk-sample-1',
      businessId: '11111111-1111-1111-1111-111111111111',
      clientId: '00000000-0000-0000-0000-000000000003',
      serviceId: '55555555-5555-5555-5555-555555555551',
      staffId: '44444444-4444-4444-4444-444444444441',
      bookingModel: 'slot_based',
      startTime: DateTime.now().add(const Duration(days: 2, hours: 2)),
      endTime: DateTime.now().add(const Duration(days: 2, hours: 2, minutes: 45)),
      status: 'confirmed',
      totalPrice: 120.00,
      businessName: 'Apex Dental & Orthodontic Care',
      serviceName: 'Comprehensive Dental Exam & Cleaning',
      staffName: 'Dr. Alexander Vance, DDS',
      clientName: 'Michael Chen',
      clientNotes: 'Regular routine checkup and cleaning.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Booking(
      id: 'bk-sample-2',
      businessId: '22222222-2222-2222-2222-222222222222',
      clientId: '00000000-0000-0000-0000-000000000003',
      serviceId: '66666666-6666-6666-6666-666666666661',
      bookingModel: 'date_range',
      dateFrom: DateTime.now().add(const Duration(days: 7)),
      dateTo: DateTime.now().add(const Duration(days: 10)),
      status: 'pending',
      totalPrice: 1350.00,
      businessName: 'Serenity Post-Op Recovery & Wellness Suites',
      serviceName: 'Private Recovery Suite (Per Night)',
      clientName: 'Michael Chen',
      clientNotes: 'Post-rhinoplasty rehabilitation stay.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  static UserProfile _initialMockCurrentUser = UserProfile(
    id: '00000000-0000-0000-0000-000000000001',
    email: 'admin@bookit.dev',
    fullName: 'Dr. Alexander Vance',
    role: 'business_owner',
    phone: '+1 (555) 234-5678',
    createdAt: DateTime.now(),
  );

  static final List<Payment> _initialMockPayments = [
    Payment(
      id: 'pay-sample-1',
      bookingId: 'bk-sample-1',
      businessId: '11111111-1111-1111-1111-111111111111',
      clientId: '00000000-0000-0000-0000-000000000003',
      stripeSessionId: 'cs_test_mock_1',
      stripePaymentIntentId: 'pi_test_mock_1',
      grossAmount: 120.00,
      applicationFeeAmount: 3.30,
      stripeFeeAmount: 3.78,
      netAmount: 112.92,
      currency: 'usd',
      paymentStatus: 'succeeded',
      receiptUrl: 'https://pay.stripe.com/receipts/mock-1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<NotificationItem> _initialMockNotifications = [];
  */

  // Gene - Nov, 04, 2026: Seed mock business categories across the 6 sweet spots
  static final List<BusinessCategory> mockCategories = [
    const BusinessCategory(
      id: 'c0000001-0000-0000-0000-000000000001',
      name: 'Healthcare & Clinics',
      slug: 'healthcare-clinics',
      description: 'Dental practices, medical specialists, physical therapy, and clinical care.',
      icon: 'medical_services_rounded',
      displayOrder: 1,
    ),
    const BusinessCategory(
      id: 'c0000002-0000-0000-0000-000000000002',
      name: 'Wellness & Therapy',
      slug: 'wellness-therapy',
      description: 'Mental health counseling, specialized post-op recovery retreats, and nutrition.',
      icon: 'spa_rounded',
      displayOrder: 2,
    ),
    const BusinessCategory(
      id: 'c0000003-0000-0000-0000-000000000003',
      name: 'Beauty & Personal Care',
      slug: 'beauty-personal-care',
      description: 'Hair salons, barbershops, esthetics, medical spas, and nail care.',
      icon: 'content_cut_rounded',
      displayOrder: 3,
    ),
    const BusinessCategory(
      id: 'c0000004-0000-0000-0000-000000000004',
      name: 'Fitness & Coaching',
      slug: 'fitness-coaching',
      description: '1-on-1 personal training, golf/tennis instruction, and specialized private coaching.',
      icon: 'fitness_center_rounded',
      displayOrder: 4,
    ),
    const BusinessCategory(
      id: 'c0000005-0000-0000-0000-000000000005',
      name: 'Professional Consulting',
      slug: 'professional-consulting',
      description: 'Legal counsel, certified tax/accounting, financial advising, and architecture review.',
      icon: 'gavel_rounded',
      displayOrder: 5,
    ),
    const BusinessCategory(
      id: 'c0000006-0000-0000-0000-000000000006',
      name: 'Studios & Space Rentals',
      slug: 'studios-space-rentals',
      description: 'Photography cycloramas, podcast/audio booths, and private production suites.',
      icon: 'meeting_room_rounded',
      displayOrder: 6,
    ),
  ];

  // Gene - Nov, 04, 2026: Seed mock business templates with default settings, ui_config, and starter services
  // Gene - Nov, 04, 2026: Updated template mock IDs from t0000001 to b0000001 for valid UUID compliance
  static final List<BusinessTemplate> mockTemplates = [
    BusinessTemplate(
      // id: 't0000001-0000-0000-0000-000000000001',
      id: 'b0000001-0000-0000-0000-000000000001',
      categoryId: 'c0000001-0000-0000-0000-000000000001',
      name: 'Dental Care Clinic',
      slug: 'dental-clinic',
      description: 'Perfect for general dentists, orthodontists, periodontists, and oral surgeons.',
      icon: 'medical_information_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 30,
        'buffer_minutes': 10,
        'requires_approval': false,
        'working_hours': {
          'monday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'tuesday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'wednesday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'thursday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'friday': {'open': '09:00', 'close': '17:00', 'is_open': true},
          'saturday': {'open': '10:00', 'close': '15:00', 'is_open': true},
          'sunday': {'open': '00:00', 'close': '00:00', 'is_open': false},
        },
      },
      uiConfig: const {
        'resource_type': 'person',
        'resource_label': 'Dentist / Specialist',
        'service_label': 'Dental Treatment',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'dental_insurance', 'label': 'Do you have dental insurance?', 'type': 'boolean', 'required': false},
          {'id': 'insurance_carrier', 'label': 'Insurance Provider / Member ID', 'type': 'text', 'placeholder': 'e.g. Delta Dental / Cigna', 'required': false},
          {'id': 'anesthesia_allergies', 'label': 'Allergies to local anesthesia, latex, or antibiotics?', 'type': 'text', 'placeholder': 'None or specify', 'required': false},
          {'id': 'chief_complaint', 'label': 'Primary reason for visit / symptoms', 'type': 'textarea', 'placeholder': 'Checkup, tooth sensitivity, toothache...', 'required': true},
        ],
      },
      starterServices: const [
        {'name': 'Comprehensive Exam & Digital X-Ray', 'description': 'Full mouth exam, digital radiography, and preventive gum scoring.', 'duration_minutes': 45, 'price': 120.00, 'payment_policy': 'deposit_required', 'deposit_amount': 30.00},
        {'name': 'Preventive Teeth Cleaning (Prophylaxis)', 'description': 'Ultrasonic scaling, stain removal, and fluoride polish.', 'duration_minutes': 45, 'price': 95.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'In-Office Teeth Whitening', 'description': 'Professional 60-minute accelerated light-activated whitening treatment.', 'duration_minutes': 60, 'price': 350.00, 'payment_policy': 'deposit_required', 'deposit_amount': 50.00},
        {'name': 'Orthodontic & Invisalign Consultation', 'description': '3D intraoral digital scan and smile simulation.', 'duration_minutes': 30, 'price': 50.00, 'payment_policy': 'full_upfront'},
      ],
      starterStaffRoles: const ['General Dentist', 'Lead Orthodontist', 'Dental Hygienist', 'Oral Surgeon'],
      displayOrder: 1,
    ),
    /*
    // Gene - Nov, 04, 2026: Original Medical Specialist & Dermatology template
    BusinessTemplate(
      // id: 't0000001-0000-0000-0000-000000000002',
      id: 'b0000001-0000-0000-0000-000000000002',
      categoryId: 'c0000001-0000-0000-0000-000000000001',
      name: 'Medical Specialist & Dermatology',
      slug: 'medical-dermatology',
      description: 'Ideal for dermatologists, pediatricians, cardiologists, and outpatient clinical consultations.',
      icon: 'health_and_safety_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 45,
        'buffer_minutes': 15,
        'requires_approval': false,
        'working_hours': {
          'monday': {'open': '08:30', 'close': '17:30', 'is_open': true},
          'tuesday': {'open': '08:30', 'close': '17:30', 'is_open': true},
          'wednesday': {'open': '08:30', 'close': '17:30', 'is_open': true},
          'thursday': {'open': '08:30', 'close': '17:30', 'is_open': true},
          'friday': {'open': '08:30', 'close': '16:00', 'is_open': true},
          'saturday': {'open': '00:00', 'close': '00:00', 'is_open': false},
          'sunday': {'open': '00:00', 'close': '00:00', 'is_open': false},
        },
      },
      uiConfig: const {
        'resource_type': 'person',
        'resource_label': 'Physician / Doctor',
        'service_label': 'Consultation / Procedure',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'medical_history', 'label': 'Relevant past medical conditions or surgeries', 'type': 'textarea', 'placeholder': 'None or list conditions', 'required': false},
          {'id': 'current_medications', 'label': 'Current daily medications / dosages', 'type': 'text', 'placeholder': 'e.g. Lisinopril 10mg', 'required': false},
          {'id': 'referral_doctor', 'label': 'Referring Doctor (if applicable)', 'type': 'text', 'placeholder': 'Doctor name or clinic', 'required': false},
        ],
      },
      starterServices: const [
        {'name': 'New Patient Clinical Consultation', 'description': 'Comprehensive physical evaluation and diagnostics review.', 'duration_minutes': 45, 'price': 180.00, 'payment_policy': 'deposit_required', 'deposit_amount': 50.00},
        {'name': 'Targeted Follow-up & Treatment Review', 'description': 'Ongoing care monitoring and prescription adjustment.', 'duration_minutes': 30, 'price': 95.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Clinical Skin Check & Biopsy Review', 'description': 'Full-body dermatoscope inspection of moles and lesions.', 'duration_minutes': 45, 'price': 220.00, 'payment_policy': 'deposit_required', 'deposit_amount': 50.00},
      ],
      starterStaffRoles: const ['Board Certified Dermatologist', 'Attending Physician', 'Clinical Nurse Specialist'],
      displayOrder: 2,
    ),
    */

    // Gene - Nov 06, 2026: Upgraded to comprehensive Aesthetic & Dermatology Clinic template (Injectables, Laser, Morpheus8, Fitzpatrick, Accutane screening)
    BusinessTemplate(
      id: 'b0000001-0000-0000-0000-000000000002',
      categoryId: 'c0000001-0000-0000-0000-000000000001',
      name: 'Aesthetic & Dermatology Clinic',
      slug: 'aesthetic-dermatology',
      description: 'Medical aesthetics, laser dermatology, Botox/fillers, Morpheus8 RF, and clinical peels.',
      icon: 'health_and_safety_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 15,
        'buffer_minutes': 15,
        'numbing_buffer_minutes': 20,
        'requires_approval': true,
        'deposit_percent': 30.0,
        'cancellation_window_hours': 48,
        'advance_booking_days': 60,
        'min_notice_hours': 6,
        'working_hours': {
          'monday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'tuesday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'wednesday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'thursday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'friday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'saturday': {'open': '10:00', 'close': '16:00', 'is_open': true},
          'sunday': {'open': '00:00', 'close': '00:00', 'is_open': false},
        },
      },
      uiConfig: const {
        'resource_type': 'person_and_room_and_device',
        'resource_label': 'Medical Practitioner',
        'service_label': 'Aesthetic Treatment',
        'show_staff_selection': true,
        'intake_fields': [
          {
            'id': 'fitzpatrick_scale',
            'label': 'Fitzpatrick Skin Type',
            'type': 'select',
            'required': true,
            'options': [
              'Type I - Always burns, never tans',
              'Type II - Usually burns, tans with difficulty',
              'Type III - Sometimes mild burn, gradually tans',
              'Type IV - Rarely burns, tans with ease',
              'Type V - Very rarely burns, tans very easily',
              'Type VI - Never burns, deeply pigmented'
            ]
          },
          {
            'id': 'accutane_history',
            'label': 'Used oral Isotretinoin (Accutane) within the past 6 months?',
            'type': 'boolean',
            'required': true,
            'blocking_condition': true,
            'blocking_message': 'Laser, RF microneedling, and chemical peels cannot be administered within 6 months of Accutane therapy due to scarring risks.'
          },
          {
            'id': 'blood_thinners_nsaids',
            'label': 'Currently taking blood thinners, Aspirin, Ibuprofen, or high-dose Fish Oil?',
            'type': 'boolean',
            'required': true,
            'helper_text': 'May increase injection-site bruising.'
          },
          {
            'id': 'pregnancy_lactation',
            'label': 'Currently pregnant, planning pregnancy, or breastfeeding?',
            'type': 'boolean',
            'required': true,
            'blocking_condition': true,
            'blocking_message': 'Cosmetic injectables and laser treatments are contraindicated during pregnancy and breastfeeding.'
          },
          {
            'id': 'hsv_cold_sores',
            'label': 'History of oral facial cold sores (HSV-1)?',
            'type': 'boolean',
            'required': false,
            'helper_text': 'If having lip filler or perioral laser, prophylactic antiviral medication is recommended.'
          },
          {
            'id': 'clinical_photo_consent',
            'label': 'I consent to pre- and post-treatment photographic documentation for my clinical record',
            'type': 'boolean',
            'required': true
          }
        ],
      },
      starterServices: const [
        {'name': 'Botox / Dysport Wrinkle Relaxer', 'description': 'Precision neuromodulator injections for forehead lines, crow\'s feet, and frown lines.', 'duration_minutes': 30, 'price': 320.00, 'payment_policy': 'deposit_required', 'deposit_amount': 96.00},
        {'name': 'Juvederm / Restylane Dermal Filler', 'description': 'Hyaluronic acid contouring for midface volume, cheekbones, and jawline definition.', 'duration_minutes': 45, 'price': 650.00, 'payment_policy': 'deposit_required', 'deposit_amount': 195.00},
        {'name': 'Lip Augmentation & Volumizing', 'description': 'Bespoke lip shaping, hydration enhancement, and natural vermilion border definition.', 'duration_minutes': 45, 'price': 550.00, 'payment_policy': 'deposit_required', 'deposit_amount': 165.00},
        {'name': 'Candela GentleMax Pro Laser Hair (Full Legs)', 'description': 'Medical-grade dual-wavelength alexandrite/Nd:YAG permanent hair reduction.', 'duration_minutes': 45, 'price': 280.00, 'payment_policy': 'deposit_required', 'deposit_amount': 84.00},
        {'name': 'PicoWay Pigmentation & Melasma Removal', 'description': 'Picosecond acoustic laser targeting sun damage, age spots, and stubborn melasma.', 'duration_minutes': 45, 'price': 400.00, 'payment_policy': 'deposit_required', 'deposit_amount': 120.00},
        {'name': 'Morpheus8 RF Microneedling (Face & Neck)', 'description': 'Fractional radiofrequency subdermal adipose remodeling for skin tightening.', 'duration_minutes': 75, 'price': 950.00, 'payment_policy': 'deposit_required', 'deposit_amount': 285.00},
        {'name': 'Deluxe Medical Hydrafacial with Booster', 'description': 'Vortex-fusion deep pore cleansing, exfoliation, painless extraction, and antioxidant infusion.', 'duration_minutes': 60, 'price': 275.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'TCA Jessner Medium Skin Rejuvenation Peel', 'description': 'Clinical chemical exfoliation targeting cellular turnover, hyperpigmentation, and texture.', 'duration_minutes': 45, 'price': 220.00, 'payment_policy': 'deposit_required', 'deposit_amount': 66.00},
      ],
      starterStaffRoles: const [
        'Dr. Alexander Vance, MD (Board-Certified Dermatologist)',
        'Sarah Jenkins, RN, CANS (Lead Aesthetic Nurse Injector)',
        'Elena Rostova (Senior Certified Laser Specialist)',
      ],
      displayOrder: 2,
    ),
    BusinessTemplate(
      // id: 't0000001-0000-0000-0000-000000000003',
      id: 'b0000001-0000-0000-0000-000000000003',
      categoryId: 'c0000002-0000-0000-0000-000000000002',
      name: 'Post-Op Recovery & Wellness Suites',
      slug: 'recovery-suites',
      description: 'Specialized multi-day post-operative clinical suites with nursing supervision and rehabilitation support.',
      icon: 'hotel_rounded',
      bookingModel: BookingModelType.dateRange,
      defaultSettings: const {
        'checkin_time': '14:00',
        'checkout_time': '11:00',
        'min_days': 2,
        'max_days': 30,
        'requires_approval': true,
      },
      uiConfig: const {
        'resource_type': 'facility',
        'resource_label': 'Care Suite / Room',
        'service_label': 'Recovery Tier',
        'show_staff_selection': false,
        'intake_fields': [
          {'id': 'surgery_type', 'label': 'Surgical procedure type & hospital', 'type': 'text', 'placeholder': 'e.g. Orthopedic knee replacement at UCSF', 'required': true},
          {'id': 'surgery_date', 'label': 'Surgery discharge date', 'type': 'text', 'placeholder': 'MM/DD/YYYY', 'required': true},
          {'id': 'mobility_level', 'label': 'Assistance needed (Wheelchair, Walker, Bedbound)', 'type': 'text', 'placeholder': 'Describe mobility needs', 'required': true},
          {'id': 'dietary_restrictions', 'label': 'Nutritional restrictions / allergies', 'type': 'text', 'placeholder': 'e.g. Low sodium, Diabetic, Gluten-free', 'required': false},
        ],
      },
      starterServices: const [
        {'name': 'Private Clinical Recovery Suite (Per Night)', 'description': 'Private suite with 24/7 dedicated RN monitoring, physical therapy access, and chef-curated meals.', 'duration_minutes': 1440, 'price': 450.00, 'payment_policy': 'deposit_required', 'deposit_amount': 100.00},
        {'name': 'Executive Care Suite & Companion Bed (Per Night)', 'description': 'Expanded double suite accommodating patient and accompanying family member.', 'duration_minutes': 1440, 'price': 650.00, 'payment_policy': 'deposit_required', 'deposit_amount': 150.00},
      ],
      starterStaffRoles: const ['Lead Registered Nurse (RN)', 'Physical Therapist', 'Nutritional Coordinator'],
      displayOrder: 3,
    ),
    BusinessTemplate(
      // id: 't0000001-0000-0000-0000-000000000004',
      id: 'b0000001-0000-0000-0000-000000000004',
      categoryId: 'c0000002-0000-0000-0000-000000000002',
      name: 'Mental Health & Therapy Practice',
      slug: 'mental-health-therapy',
      description: 'Designed for licensed psychologists, counselors, psychotherapists, and family therapists.',
      icon: 'psychology_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 50,
        'buffer_minutes': 10,
        'requires_approval': false,
        'working_hours': {
          'monday': {'open': '09:00', 'close': '19:00', 'is_open': true},
          'tuesday': {'open': '09:00', 'close': '19:00', 'is_open': true},
          'wednesday': {'open': '09:00', 'close': '19:00', 'is_open': true},
          'thursday': {'open': '09:00', 'close': '19:00', 'is_open': true},
          'friday': {'open': '09:00', 'close': '17:00', 'is_open': true},
          'saturday': {'open': '10:00', 'close': '14:00', 'is_open': true},
          'sunday': {'open': '00:00', 'close': '00:00', 'is_open': false},
        },
      },
      uiConfig: const {
        'resource_type': 'person',
        'resource_label': 'Therapist / Counselor',
        'service_label': 'Session Type',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'preferred_format', 'label': 'Session Format', 'type': 'text', 'placeholder': 'In-Person or Secure Video Call', 'required': true},
          {'id': 'prior_therapy', 'label': 'Have you worked with a counselor before?', 'type': 'boolean', 'required': false},
          {'id': 'primary_goals', 'label': 'What are your primary goals for therapy?', 'type': 'textarea', 'placeholder': 'Anxiety management, life transition, relationship...', 'required': true},
        ],
      },
      starterServices: const [
        {'name': 'Individual Psychotherapy Session (50 min)', 'description': 'Confidential one-on-one evidence-based therapy session.', 'duration_minutes': 50, 'price': 160.00, 'payment_policy': 'full_upfront'},
        {'name': 'Couples & Family Counseling (75 min)', 'description': 'Systemic counseling focusing on communication and relationship dynamics.', 'duration_minutes': 75, 'price': 230.00, 'payment_policy': 'full_upfront'},
        {'name': 'Initial Consultation & Intake Assessment (60 min)', 'description': 'Diagnostic evaluation and personalized treatment roadmap design.', 'duration_minutes': 60, 'price': 190.00, 'payment_policy': 'full_upfront'},
      ],
      starterStaffRoles: const ['Licensed Clinical Psychologist (PsyD)', 'Licensed Marriage & Family Therapist (LMFT)', 'Clinical Social Worker (LCSW)'],
      displayOrder: 4,
    ),
    BusinessTemplate(
      // id: 't0000001-0000-0000-0000-000000000005',
      id: 'b0000001-0000-0000-0000-000000000005',
      categoryId: 'c0000003-0000-0000-0000-000000000003',
      name: 'Hair Salon & Barbershop',
      slug: 'hair-salon-barber',
      description: 'Built for hair stylists, barbers, colorists, and grooming studios.',
      icon: 'brush_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 45,
        'buffer_minutes': 10,
        'requires_approval': false,
        'working_hours': {
          'monday': {'open': '00:00', 'close': '00:00', 'is_open': false},
          'tuesday': {'open': '10:00', 'close': '20:00', 'is_open': true},
          'wednesday': {'open': '10:00', 'close': '20:00', 'is_open': true},
          'thursday': {'open': '10:00', 'close': '20:00', 'is_open': true},
          'friday': {'open': '10:00', 'close': '20:00', 'is_open': true},
          'saturday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'sunday': {'open': '10:00', 'close': '17:00', 'is_open': true},
        },
      },
      uiConfig: const {
        'resource_type': 'person',
        'resource_label': 'Stylist / Barber',
        'service_label': 'Service',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'hair_length', 'label': 'Current Hair Length (Short / Medium / Long)', 'type': 'text', 'placeholder': 'e.g. Medium (past shoulders)', 'required': false},
          {'id': 'color_history', 'label': 'Recent color or chemical treatments in last 6 months?', 'type': 'text', 'placeholder': 'e.g. Bleach blonde 2 months ago, none', 'required': false},
        ],
      },
      starterServices: const [
        {'name': 'Precision Haircut & Blowout', 'description': 'Customized hair architecture, clarifying wash, and signature blowout.', 'duration_minutes': 60, 'price': 85.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Full Balayage & Gloss Toner', 'description': 'Hand-painted sun-kissed lightening with custom gloss finish.', 'duration_minutes': 150, 'price': 260.00, 'payment_policy': 'deposit_required', 'deposit_amount': 50.00},
        {'name': 'Classic Gentleman Barber Cut & Hot Towel Shave', 'description': 'Scissor-over-comb fade, straight-razor neck shave, and eucalyptus towel.', 'duration_minutes': 45, 'price': 55.00, 'payment_policy': 'pay_at_venue'},
      ],
      starterStaffRoles: const ['Master Stylist', 'Color Specialist', 'Senior Barber'],
      displayOrder: 5,
    ),
    BusinessTemplate(
      // id: 't0000001-0000-0000-0000-000000000006',
      id: 'b0000001-0000-0000-0000-000000000006',
      categoryId: 'c0000003-0000-0000-0000-000000000003',
      name: 'Luxury Day Spa & Esthetics',
      slug: 'day-spa-esthetics',
      description: 'Tailored for day spas, massage therapists, estheticians, and holistic bodywork centers.',
      icon: 'self_improvement_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 60,
        'buffer_minutes': 15,
        'requires_approval': false,
        'working_hours': {
          'monday': {'open': '10:00', 'close': '19:00', 'is_open': true},
          'tuesday': {'open': '10:00', 'close': '19:00', 'is_open': true},
          'wednesday': {'open': '10:00', 'close': '19:00', 'is_open': true},
          'thursday': {'open': '10:00', 'close': '19:00', 'is_open': true},
          'friday': {'open': '10:00', 'close': '20:00', 'is_open': true},
          'saturday': {'open': '09:00', 'close': '19:00', 'is_open': true},
          'sunday': {'open': '10:00', 'close': '18:00', 'is_open': true},
        },
      },
      uiConfig: const {
        'resource_type': 'person',
        'resource_label': 'Therapist / Esthetician',
        'service_label': 'Spa Treatment',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'massage_pressure', 'label': 'Preferred Pressure (Light / Medium / Firm / Deep)', 'type': 'text', 'placeholder': 'Medium to Deep', 'required': false},
          {'id': 'skin_allergies', 'label': 'Skin allergies or essential oil sensitivities', 'type': 'text', 'placeholder': 'None or list allergies', 'required': false},
        ],
      },
      starterServices: const [
        {'name': 'Deep Tissue Therapeutic Massage (60 min)', 'description': 'Targeted myofascial release relieving chronic tension and muscle knots.', 'duration_minutes': 60, 'price': 130.00, 'payment_policy': 'deposit_required', 'deposit_amount': 30.00},
        {'name': 'Organic Botanical Hydrating Facial', 'description': 'Double cleanse, enzymatic exfoliation, custom serum infusion, and cryo-globe massage.', 'duration_minutes': 60, 'price': 145.00, 'payment_policy': 'deposit_required', 'deposit_amount': 30.00},
      ],
      starterStaffRoles: const ['Licensed Massage Therapist', 'Master Esthetician', 'Aromatherapy Specialist'],
      displayOrder: 6,
    ),
    BusinessTemplate(
      // id: 't0000001-0000-0000-0000-000000000007',
      id: 'b0000001-0000-0000-0000-000000000007',
      categoryId: 'c0000004-0000-0000-0000-000000000004',
      name: 'Personal Training & Fitness Studio',
      slug: 'personal-training',
      description: 'For private fitness trainers, sports performance coaches, and boutique studios.',
      icon: 'sports_gymnastics_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 60,
        'buffer_minutes': 10,
        'requires_approval': false,
        'working_hours': {
          'monday': {'open': '06:00', 'close': '20:00', 'is_open': true},
          'tuesday': {'open': '06:00', 'close': '20:00', 'is_open': true},
          'wednesday': {'open': '06:00', 'close': '20:00', 'is_open': true},
          'thursday': {'open': '06:00', 'close': '20:00', 'is_open': true},
          'friday': {'open': '06:00', 'close': '19:00', 'is_open': true},
          'saturday': {'open': '07:00', 'close': '14:00', 'is_open': true},
          'sunday': {'open': '08:00', 'close': '12:00', 'is_open': true},
        },
      },
      uiConfig: const {
        'resource_type': 'person',
        'resource_label': 'Coach / Trainer',
        'service_label': 'Training Program',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'fitness_goal', 'label': 'Primary Fitness Goal (Strength, Fat Loss, Endurance)', 'type': 'text', 'placeholder': 'e.g. Strength building & functional mobility', 'required': true},
          {'id': 'injuries', 'label': 'Any joint injuries or physical limitations?', 'type': 'textarea', 'placeholder': 'Lower back tightness, shoulder impingement...', 'required': false},
        ],
      },
      starterServices: const [
        {'name': '1-on-1 Functional Strength Session (60 min)', 'description': 'Personalized biomechanics assessment, progressive overload, and movement coaching.', 'duration_minutes': 60, 'price': 95.00, 'payment_policy': 'full_upfront'},
        {'name': 'Athletic Movement & Speed Assessment', 'description': 'Kinematic movement screen identifying kinetic imbalances and power output.', 'duration_minutes': 60, 'price': 120.00, 'payment_policy': 'full_upfront'},
      ],
      starterStaffRoles: const ['Certified Strength & Conditioning Specialist (CSCS)', 'Performance Coach', 'Kinesiologist'],
      displayOrder: 7,
    ),
    BusinessTemplate(
      // id: 't0000001-0000-0000-0000-000000000008',
      id: 'b0000001-0000-0000-0000-000000000008',
      categoryId: 'c0000005-0000-0000-0000-000000000005',
      name: 'Legal & Financial Advisory',
      slug: 'legal-financial-advisory',
      description: 'Built for attorneys, CPA tax advisors, financial planners, and corporate consultants.',
      icon: 'balance_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 60,
        'buffer_minutes': 15,
        'requires_approval': true,
        'working_hours': {
          'monday': {'open': '09:00', 'close': '17:00', 'is_open': true},
          'tuesday': {'open': '09:00', 'close': '17:00', 'is_open': true},
          'wednesday': {'open': '09:00', 'close': '17:00', 'is_open': true},
          'thursday': {'open': '09:00', 'close': '17:00', 'is_open': true},
          'friday': {'open': '09:00', 'close': '16:00', 'is_open': true},
          'saturday': {'open': '00:00', 'close': '00:00', 'is_open': false},
          'sunday': {'open': '00:00', 'close': '00:00', 'is_open': false},
        },
      },
      uiConfig: const {
        'resource_type': 'person',
        'resource_label': 'Consultant / Attorney',
        'service_label': 'Advisory Engagement',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'legal_matter', 'label': 'Matter Type (Contract, Corporate, IP, Estate, Tax)', 'type': 'text', 'placeholder': 'e.g. Commercial Contract Review', 'required': true},
          {'id': 'opposing_party', 'label': 'Adverse / Opposing Party Name (for Conflict Check)', 'type': 'text', 'placeholder': 'Party or company name', 'required': true},
          {'id': 'brief_summary', 'label': 'Brief overview of question or matter', 'type': 'textarea', 'placeholder': 'Summarize key issues...', 'required': true},
        ],
      },
      starterServices: const [
        {'name': 'Initial Legal Strategy Consultation (60 min)', 'description': 'Structured legal risk analysis, issue spotting, and engagement roadmap.', 'duration_minutes': 60, 'price': 350.00, 'payment_policy': 'full_upfront'},
        {'name': 'CPA Tax Planning & Entity Structure Review', 'description': 'Tax mitigation optimization for business owners and high earners.', 'duration_minutes': 60, 'price': 275.00, 'payment_policy': 'full_upfront'},
      ],
      starterStaffRoles: const ['Managing Partner / Attorney', 'Senior Tax CPA', 'Corporate Counsel'],
      displayOrder: 8,
    ),
    BusinessTemplate(
      // id: 't0000001-0000-0000-0000-000000000009',
      id: 'b0000001-0000-0000-0000-000000000009',
      categoryId: 'c0000006-0000-0000-0000-000000000006',
      name: 'Photography & Podcast Studio',
      slug: 'photo-podcast-studio',
      description: 'Designed for rentable production spaces, white cycloramas, and broadcast-ready podcast rooms.',
      icon: 'camera_indoor_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 60,
        'buffer_minutes': 30,
        'requires_approval': false,
        'working_hours': {
          'monday': {'open': '08:00', 'close': '22:00', 'is_open': true},
          'tuesday': {'open': '08:00', 'close': '22:00', 'is_open': true},
          'wednesday': {'open': '08:00', 'close': '22:00', 'is_open': true},
          'thursday': {'open': '08:00', 'close': '22:00', 'is_open': true},
          'friday': {'open': '08:00', 'close': '23:00', 'is_open': true},
          'saturday': {'open': '08:00', 'close': '23:00', 'is_open': true},
          'sunday': {'open': '09:00', 'close': '21:00', 'is_open': true},
        },
      },
      uiConfig: const {
        'resource_type': 'facility',
        'resource_label': 'Studio Bay / Room',
        'service_label': 'Space Rental',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'crew_size', 'label': 'Estimated Crew / Cast Size', 'type': 'text', 'placeholder': 'e.g. 5 people', 'required': true},
          {'id': 'equipment_needs', 'label': 'Special equipment requested (Strobes, Microphones, C-Stands)', 'type': 'text', 'placeholder': 'e.g. 4x Shure SM7B, Aputure 600d', 'required': false},
          {'id': 'production_type', 'label': 'Production Type (Fashion, Interview, Commercial)', 'type': 'text', 'placeholder': 'e.g. Video podcast recording', 'required': true},
        ],
      },
      starterServices: const [
        {'name': 'Soundproof 4-Mic Podcast Suite (Per Hour)', 'description': 'Equipped with Shure SM7B mics, Rodecaster Pro II, Blackmagic 4K cameras, and studio headphones.', 'duration_minutes': 60, 'price': 95.00, 'payment_policy': 'deposit_required', 'deposit_amount': 30.00},
        {'name': 'White Cyclorama Photo & Video Bay (Per Hour)', 'description': 'Corner infinity cove cyclorama with pre-rigged RGB ceiling grid and 200A power distribution.', 'duration_minutes': 60, 'price': 140.00, 'payment_policy': 'deposit_required', 'deposit_amount': 50.00},
      ],
      starterStaffRoles: const ['Studio A (Cyclorama Cove)', 'Studio B (Podcast Suite)', 'Sound Stage C'],
      displayOrder: 9,
    ),
  ];
}

// Gene - Nov, 04, 2026: Added supabaseClientProvider for Riverpod dependency injection
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  final client = SupabaseService.client;
  if (client != null) {
    return client;
  }
  return SupabaseClient(
    SupabaseConfig.supabaseUrl,
    SupabaseConfig.supabaseAnonKey,
  );
});
