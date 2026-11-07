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
      // avatarUrl: 'https://images.unsplash.com/photo-1594824813637-b9560f1ad922?auto=format&fit=crop&w=400&q=80',
      // Gene - Nov, 7, 2026: Replaced broken 404 Unsplash avatar URL with verified working portrait URL
      avatarUrl: 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?auto=format&fit=crop&w=400&q=80',
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
    // Gene - Nov 06, 2026: Added Automotive & Detailing category
    const BusinessCategory(
      id: 'c0000007-0000-0000-0000-000000000007',
      name: 'Automotive & Detailing',
      slug: 'automotive-detailing',
      description: 'Car wash, ceramic coatings, interior steam sanitization, and mobile detailing fleets.',
      icon: 'local_car_wash_rounded',
      displayOrder: 7,
    ),
  ];

  // Gene - Nov, 04, 2026: Seed mock business templates with default settings, ui_config, and starter services
  // Gene - Nov, 04, 2026: Updated template mock IDs from t0000001 to b0000001 for valid UUID compliance
  static final List<BusinessTemplate> mockTemplates = [
    /*
    // Gene - Nov, 04, 2026: Original basic Dental Care Clinic template
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
    */

    // Gene - Nov 06, 2026: Upgraded Dental Care Clinic to full Dental Practice template (CEREC crowns, Zoom! whitening, Invisalign, antibiotic pre-med, anxiety screening)
    BusinessTemplate(
      id: 'b0000001-0000-0000-0000-000000000001',
      categoryId: 'c0000001-0000-0000-0000-000000000001',
      name: 'Dental Care Clinic',
      slug: 'dental-clinic',
      description: 'Comprehensive family dentistry, CEREC single-visit crowns, Zoom! whitening, and 3D digital orthodontic scans.',
      icon: 'medical_services_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 15,
        'buffer_minutes': 10,
        'requires_approval': false,
        'deposit_percent': 0.0,
        'cancellation_window_hours': 24,
        'advance_booking_days': 180,
        'min_notice_hours': 4,
        'working_hours': {
          'monday': {'open': '08:00', 'close': '17:00', 'is_open': true},
          'tuesday': {'open': '08:00', 'close': '17:00', 'is_open': true},
          'wednesday': {'open': '08:00', 'close': '17:00', 'is_open': true},
          'thursday': {'open': '08:00', 'close': '17:00', 'is_open': true},
          'friday': {'open': '08:00', 'close': '16:00', 'is_open': true},
          'saturday': {'open': '09:00', 'close': '14:00', 'is_open': true},
          'sunday': {'open': '00:00', 'close': '00:00', 'is_open': false},
        },
      },
      uiConfig: const {
        'resource_type': 'dentist_hygienist_and_operatory',
        'resource_label': 'Dentist / Dental Hygienist',
        'service_label': 'Dental Treatment',
        'show_staff_selection': true,
        'intake_fields': [
          {
            'id': 'dental_insurance_info',
            'label': 'Do you have dental insurance coverage?',
            'type': 'boolean',
            'required': true,
          },
          {
            'id': 'insurance_details',
            'label': 'Insurance Provider Name, Policy ID & Group Number',
            'type': 'text',
            'required': false,
            'placeholder': 'e.g. Delta Dental Premier, Member ID: W1234567, Group: 98765',
          },
          {
            'id': 'medical_premed_conditions',
            'label': 'Artificial heart valves, joint replacements, or require antibiotic pre-medication?',
            'type': 'select',
            'required': true,
            'options': [
              'No - None',
              'Yes - Artificial Heart Valve (Requires Amoxicillin / Clindamycin Pre-med)',
              'Yes - Total Joint Replacement within past 2 years',
              'Yes - History of Infective Endocarditis'
            ],
          },
          {
            'id': 'blood_thinners_bisphosphonates',
            'label': 'Taking blood thinners (Warfarin/Eliquis) or bone density meds (Fosamax)?',
            'type': 'boolean',
            'required': true,
            'helper_text': 'Crucial for oral surgery, extractions, and deep periodontal scaling safety.',
          },
          {
            'id': 'dental_anxiety_score',
            'label': 'How would you rate your level of dental anxiety?',
            'type': 'select',
            'required': true,
            'options': [
              '1 - Completely relaxed and comfortable',
              '2 - Mild nervousness',
              '3 - Moderate anxiety (prefer detailed explanations before each step)',
              '4 - High anxiety (request numbing gel / stress ball)',
              '5 - Severe phobia (interested in Nitrous Oxide laughing gas sedation)'
            ],
          },
          {
            'id': 'chief_dental_complaint',
            'label': 'Primary reason for your visit today',
            'type': 'textarea',
            'required': true,
            'placeholder': 'Routine 6-month checkup, cold sensitivity, throbbing pain in upper molar, smile cosmetic consult...',
          },
        ],
      },
      starterServices: const [
        {'name': 'Comprehensive Exam & Digital 3D X-Rays', 'description': 'Full intraoral exam, digital bitewings, gum charting, and oral cancer check.', 'duration_minutes': 60, 'price': 180.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Adult Dental Prophylaxis (Cleaning & Polish)', 'description': 'Ultrasonic calculus removal, stain elimination, and fluoride enamel polish.', 'duration_minutes': 45, 'price': 110.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Periodontal Deep Scaling & Root Planing', 'description': 'Deep subgingival cleaning per quadrant to halt periodontal bone loss.', 'duration_minutes': 60, 'price': 275.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Pediatric Exam, Cleaning & Cavity Sealants', 'description': 'Gentle youth prophylaxis, fluoride treatment, and preventative molar sealants.', 'duration_minutes': 45, 'price': 125.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Tooth-Colored Composite Resin Filling', 'description': 'Seamless aesthetic restoration matching natural enamel shade.', 'duration_minutes': 45, 'price': 190.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Same-Day CEREC Digital Porcelain Crown', 'description': 'Precision 3D CAD/CAM milled ceramic crown crafted in a single appointment.', 'duration_minutes': 90, 'price': 1250.00, 'payment_policy': 'deposit_required', 'deposit_amount': 200.00},
        {'name': 'In-Office Philips Zoom! Teeth Whitening', 'description': 'Professional light-activated whitening lifting enamel up to 8 shades in 75 min.', 'duration_minutes': 75, 'price': 450.00, 'payment_policy': 'deposit_required', 'deposit_amount': 100.00},
        {'name': 'Invisalign Clear Aligner iTero 3D Scan & Consult', 'description': 'High-definition digital impression with immediate real-time smile simulation.', 'duration_minutes': 30, 'price': 0.00, 'payment_policy': 'free_consultation'},
        {'name': 'Custom Nightguard for Bruxism & Jaw Grinding', 'description': 'Custom lab-fabricated protective appliance preventing TMJ wear and dental erosion.', 'duration_minutes': 30, 'price': 420.00, 'payment_policy': 'deposit_required', 'deposit_amount': 100.00},
      ],
      starterStaffRoles: const [
        'Dr. Arthur Brooks, DDS (Lead Restorative & Implant Dentist)',
        'Dr. Emily Chen, DMD (Orthodontics & Cosmetic Specialist)',
        'Rachel Adams, RDH (Senior Dental Hygienist)',
      ],
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
    /*
    // Gene - Nov, 04, 2026: Original basic salon, spa, and fitness templates
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
    */

    // Gene - Nov 06, 2026: Upgraded Hair & Beauty Salon template (Lived-in balayage, keratin, lashes, multiselect chemical history, PPD allergy patch test)
    BusinessTemplate(
      id: 'b0000001-0000-0000-0000-000000000005',
      categoryId: 'c0000003-0000-0000-0000-000000000003',
      name: 'Hair & Beauty Salon',
      slug: 'hair-beauty-salon',
      description: 'Lived-in balayage, precision cuts, Brazilian keratin smoothing, Russian volume lashes, and brow sculpt.',
      icon: 'content_cut_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 15,
        'buffer_minutes': 10,
        'requires_approval': false,
        'deposit_percent': 25.0,
        'cancellation_window_hours': 48,
        'advance_booking_days': 60,
        'min_notice_hours': 4,
        'working_hours': {
          'monday': {'open': '00:00', 'close': '00:00', 'is_open': false},
          'tuesday': {'open': '09:00', 'close': '19:00', 'is_open': true},
          'wednesday': {'open': '09:00', 'close': '19:00', 'is_open': true},
          'thursday': {'open': '09:00', 'close': '20:00', 'is_open': true},
          'friday': {'open': '09:00', 'close': '20:00', 'is_open': true},
          'saturday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'sunday': {'open': '10:00', 'close': '17:00', 'is_open': true},
        },
      },
      uiConfig: const {
        'resource_type': 'stylist_chair_and_wash_basin',
        'resource_label': 'Master Stylist / Colorist',
        'service_label': 'Salon Service',
        'show_staff_selection': true,
        'intake_fields': [
          {
            'id': 'hair_chemical_history',
            'label': 'Chemical & Color History (Past 24 Months)',
            'type': 'multiselect',
            'required': true,
            'options': [
              'Virgin Hair (No color or chemicals ever)',
              'Professional Salon Bleach / Highlights',
              'At-Home Drugstore Box Dye / Black Color',
              'Henna or Vegetable Dyes',
              'Keratin Treatment / Brazilian Blowout',
              'Chemical Perm or Relaxer'
            ],
          },
          {
            'id': 'current_hair_length',
            'label': 'Current Hair Length',
            'type': 'select',
            'required': true,
            'options': [
              'Pixie / Above Ears',
              'Bob / Chin Length',
              'Shoulder Length',
              'Mid-Back Length',
              'Waist Length or Longer (Requires extra time)'
            ],
          },
          {
            'id': 'ppd_allergy',
            'label': 'Have you ever experienced an allergic reaction or burning from hair dye (PPD)?',
            'type': 'boolean',
            'required': true,
            'helper_text': 'If yes, a 48-hour strand patch test is required prior to your chemical appointment.',
          },
          {
            'id': 'lash_contact_lenses',
            'label': 'Wearing contact lenses during lash appointments?',
            'type': 'boolean',
            'required': false,
            'helper_text': 'Please bring lens case or wear glasses to avoid eye irritation.',
          },
        ],
      },
      starterServices: const [
        {'name': 'Lived-In Signature Balayage & Glaze', 'description': 'Hand-painted multidimensional blonde with custom gloss tone and signature blowout.', 'duration_minutes': 180, 'price': 320.00, 'payment_policy': 'deposit_required', 'deposit_amount': 75.00},
        {'name': 'Full Platinum Foil Bleach Retouch', 'description': 'Precision micro-slice on-scalp lightening with bond-building toner.', 'duration_minutes': 150, 'price': 260.00, 'payment_policy': 'deposit_required', 'deposit_amount': 75.00},
        {'name': 'All-Over Single Process & Gloss', 'description': 'Lustrous root-to-end rich color enrichment, shampoo basin wash, and sleek style.', 'duration_minutes': 105, 'price': 165.00, 'payment_policy': 'deposit_required', 'deposit_amount': 50.00},
        {'name': 'Master Stylist Precision Cut & Blowout', 'description': 'Bespoke structural shear architecture, wash, and voluminous round-brush finish.', 'duration_minutes': 60, 'price': 110.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Signature Bouncy Blowout & Iron Wave', 'description': 'Clarifying scalp wash, tension blowout, and long-lasting thermal barrel waves.', 'duration_minutes': 45, 'price': 65.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Brazilian Keratin Smoothing Complex', 'description': 'Formaldehyde-free intensive amino smoothing eliminating 95% of frizz for 12 weeks.', 'duration_minutes': 150, 'price': 350.00, 'payment_policy': 'deposit_required', 'deposit_amount': 100.00},
        {'name': 'Full Set Russian Volume Lash Extensions', 'description': 'Handmade lightweight 3D-6D volume fans delivering full, dark, fluffy lash drama.', 'duration_minutes': 120, 'price': 220.00, 'payment_policy': 'deposit_required', 'deposit_amount': 50.00},
        {'name': 'Brow Lamination, Sculpt & Hybrid Dye', 'description': 'Fluffy brushed-up brow setting with custom pigmented dye and thread clean-up.', 'duration_minutes': 45, 'price': 85.00, 'payment_policy': 'pay_at_venue'},
      ],
      starterStaffRoles: const [
        'Julian Voss (Creative Director & Master Balayage Specialist)',
        'Mia Sterling (Senior Colorist & Keratin Expert)',
        'Kira Patel (Certified Lash Master & Brow Sculptor)',
      ],
      displayOrder: 5,
    ),

    // Gene - Nov 06, 2026: Upgraded Day Spa & Massage Center template (Couples duet suites, hot stones, pressure map, multiselect focus areas, soundscapes)
    BusinessTemplate(
      id: 'b0000001-0000-0000-0000-000000000006',
      categoryId: 'c0000003-0000-0000-0000-000000000003',
      name: 'Day Spa & Massage Center',
      slug: 'day-spa-massage',
      description: 'Therapeutic massage, basalt hot stones, infrared thermal suites, and couples romance duet rituals.',
      icon: 'spa_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 15,
        'buffer_minutes': 15,
        'early_arrival_minutes': 15,
        'requires_approval': false,
        'deposit_percent': 25.0,
        'cancellation_window_hours': 24,
        'advance_booking_days': 90,
        'min_notice_hours': 2,
        'working_hours': {
          'monday': {'open': '10:00', 'close': '20:00', 'is_open': true},
          'tuesday': {'open': '10:00', 'close': '20:00', 'is_open': true},
          'wednesday': {'open': '10:00', 'close': '20:00', 'is_open': true},
          'thursday': {'open': '10:00', 'close': '20:00', 'is_open': true},
          'friday': {'open': '10:00', 'close': '21:00', 'is_open': true},
          'saturday': {'open': '09:00', 'close': '20:00', 'is_open': true},
          'sunday': {'open': '10:00', 'close': '18:00', 'is_open': true},
        },
      },
      uiConfig: const {
        'resource_type': 'massage_therapist_and_treatment_room',
        'resource_label': 'Licensed Massage Therapist (LMT)',
        'service_label': 'Spa Ritual & Bodywork',
        'show_staff_selection': true,
        'intake_fields': [
          {
            'id': 'desired_pressure',
            'label': 'Preferred Massage Pressure',
            'type': 'select',
            'required': true,
            'options': [
              'Light - Gentle flowing relaxation',
              'Medium - Balanced stress relief and tension release',
              'Firm - Deep muscle focus without sharp pain',
              'Deep Tissue - Intense trigger point focus and myofascial release'
            ],
          },
          {
            'id': 'focus_and_avoid_areas',
            'label': 'Primary Focus Areas (Select all that apply)',
            'type': 'multiselect',
            'required': true,
            'options': [
              'Neck & Cervical Spine',
              'Upper Shoulders & Trapezius',
              'Lower Lumbar Back',
              'Glutes & Sciatic Nerve',
              'Legs & Hamstrings',
              'Feet & Reflexology',
              'Scalp & Temples',
              'Avoid Glutes',
              'Avoid Feet'
            ],
          },
          {
            'id': 'oil_scent_allergies',
            'label': 'Tree nut (almond carrier oil), iodine, or essential oil allergies?',
            'type': 'text',
            'required': false,
            'placeholder': 'None or specify allergies (e.g. Sweet Almond, Nutmeg, Lavender)',
          },
          {
            'id': 'pregnancy_status',
            'label': 'Are you currently pregnant?',
            'type': 'select',
            'required': true,
            'options': [
              'No',
              'Yes - 1st Trimester (Under 12 weeks: contraindicated)',
              'Yes - 2nd Trimester (13-27 weeks)',
              'Yes - 3rd Trimester (28+ weeks)'
            ],
          },
          {
            'id': 'soundscape_ambience',
            'label': 'Treatment Room Soundscape Preference',
            'type': 'select',
            'required': false,
            'options': [
              'Gentle Ocean Waves & Rainfall',
              'Tibetan Singing Bowls & Meditation',
              'Soft Acoustic Piano & Cello',
              'Complete Silence'
            ],
          },
        ],
      },
      starterServices: const [
        {'name': 'Deep Tissue Neuromuscular Massage (60 min)', 'description': 'Targeted myofascial release relieving chronic tension and muscle knots.', 'duration_minutes': 60, 'price': 130.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Deep Tissue Neuromuscular Massage (90 min)', 'description': 'Extended full-body therapeutic release with trigger-point therapy.', 'duration_minutes': 90, 'price': 185.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Swedish Aromatherapy Serenity Ritual (60 min)', 'description': 'Long flowing effleurage strokes with warm organic botanical essential oils.', 'duration_minutes': 60, 'price': 115.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Swedish Aromatherapy Serenity Ritual (90 min)', 'description': 'Complete head-to-toe relaxation with customized aromatherapy blend.', 'duration_minutes': 90, 'price': 165.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Basalt Heated Stone Full Body Therapy (75 min)', 'description': 'Smooth volcanic river stones gliding deep heat into tired muscular tissues.', 'duration_minutes': 75, 'price': 170.00, 'payment_policy': 'deposit_required', 'deposit_amount': 42.50},
        {'name': 'Prenatal Gentle Nurturing Massage (60 min)', 'description': 'Safe side-lying pregnancy comfort relieving pelvic tension and swollen legs.', 'duration_minutes': 60, 'price': 135.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Private Infrared Sauna & Cold Plunge Circuit (45 min)', 'description': 'Private thermal sanctuary: full-spectrum infrared sauna and cold plunge bath.', 'duration_minutes': 45, 'price': 65.00, 'payment_policy': 'full_upfront'},
        {'name': 'Turkish Herbal Eucalyptus Steam Ritual (45 min)', 'description': 'Aromatherapeutic warm eucalyptus steam room with private cooling shower.', 'duration_minutes': 45, 'price': 75.00, 'payment_policy': 'full_upfront'},
        {'name': 'Presidential Romance Duet Couples Massage (75 min)', 'description': 'Side-by-side couples massage in our luxury fireplace suite with champagne.', 'duration_minutes': 75, 'price': 320.00, 'payment_policy': 'deposit_required', 'deposit_amount': 160.00},
      ],
      starterStaffRoles: const [
        'Maya Lin, LMT (Master Deep Tissue & Heated Stone Specialist)',
        'David Thorne, LMT (Sports Recovery & Myofascial Therapist)',
        'Chloe Dupont, LMT (Holistic Aromatherapy & Prenatal Practitioner)',
      ],
      displayOrder: 6,
    ),

    // Gene - Nov 06, 2026: Upgraded Boutique Fitness Studio & Yoga template (Reformer Pilates, Heated Yoga, 1-on-1 private, multiselect PAR-Q, grip socks toggle, waiver signature)
    BusinessTemplate(
      id: 'b0000001-0000-0000-0000-000000000007',
      categoryId: 'c0000004-0000-0000-0000-000000000004',
      name: 'Boutique Fitness Studio & Yoga',
      slug: 'fitness-pilates-yoga',
      description: 'Reformer Pilates, 95° Infrared Vinyasa Yoga, 1-on-1 private movement analysis, and class credits.',
      icon: 'fitness_center_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 60,
        'buffer_minutes': 10,
        'requires_approval': false,
        'deposit_percent': 100.0,
        'cancellation_window_hours': 12,
        'advance_booking_days': 14,
        'min_notice_hours': 1,
        'working_hours': {
          'monday': {'open': '06:00', 'close': '20:00', 'is_open': true},
          'tuesday': {'open': '06:00', 'close': '20:00', 'is_open': true},
          'wednesday': {'open': '06:00', 'close': '20:00', 'is_open': true},
          'thursday': {'open': '06:00', 'close': '20:00', 'is_open': true},
          'friday': {'open': '06:00', 'close': '19:00', 'is_open': true},
          'saturday': {'open': '07:00', 'close': '16:00', 'is_open': true},
          'sunday': {'open': '08:00', 'close': '14:00', 'is_open': true},
        },
      },
      uiConfig: const {
        'resource_type': 'instructor_and_studio_sanctuary',
        'resource_label': 'Certified Instructor',
        'service_label': 'Class / Private Session',
        'show_staff_selection': true,
        'intake_fields': [
          {
            'id': 'fitness_experience_level',
            'label': 'Pilates / Yoga Experience Level',
            'type': 'select',
            'required': true,
            'options': [
              'First Timer (Never been on a Reformer before)',
              'Beginner (1 - 5 classes completed)',
              'Intermediate (Regular practitioner)',
              'Advanced / Instructor'
            ],
          },
          {
            'id': 'injury_movement_limitations',
            'label': 'Current Injuries, Limitations or Surgeries (Select all that apply)',
            'type': 'multiselect',
            'required': true,
            'options': [
              'None - Healthy & Full Mobility',
              'Lower Back Pain / Disc Herniation',
              'Knee Pain / Meniscus / ACL',
              'Neck / Cervical Spine',
              'Shoulder / Rotator Cuff',
              'Carpal Tunnel / Wrist Sensitivity',
              'Diastasis Recti / Postpartum',
              'Currently Pregnant'
            ],
          },
          {
            'id': 'grip_socks_acknowledgment',
            'label': 'Mandatory Grip Socks Policy Acknowledgment',
            'type': 'boolean',
            'required': true,
            'helper_text': 'Grip socks are strictly required for all Reformer classes for hygiene and traction.',
          },
          {
            'id': 'studio_liability_waiver',
            'label': 'Physical Activity Liability Release Waiver',
            'type': 'signature',
            'required': true,
            'disclaimer': 'I voluntarily participate in physical exercise at the studio and assume all risks of injury. I agree to inform the instructor of any pain or modifications needed.',
          },
          {
            'id': 'emergency_contact',
            'label': 'Emergency Contact (Name & Phone Number)',
            'type': 'text',
            'required': true,
            'placeholder': 'e.g. Alex Morgan - (555) 019-9988',
          },
        ],
      },
      starterServices: const [
        {'name': 'Signature Reformer Flow (All Levels)', 'description': 'Full-body core integration, spinal articulation, and muscle endurance on Allegro 2 reformer.', 'duration_minutes': 50, 'price': 36.00, 'payment_policy': 'full_upfront'},
        {'name': 'Athletic Jumpboard Cardio HIIT Reformer', 'description': 'High-energy low-impact plyometric jumping intervals boosting cardiovascular stamina.', 'duration_minutes': 50, 'price': 38.00, 'payment_policy': 'full_upfront'},
        {'name': 'Restorative Stretch & Release Reformer', 'description': 'Deep supported stretching using reformer spring assistance to release tight hips and hamstrings.', 'duration_minutes': 50, 'price': 36.00, 'payment_policy': 'full_upfront'},
        {'name': '95° Infrared Candlelight Vinyasa Yoga', 'description': 'Therapeutic infrared heat promoting detoxifying sweat and deeper muscle flexibility.', 'duration_minutes': 60, 'price': 28.00, 'payment_policy': 'full_upfront'},
        {'name': 'Yin Yoga & Sound Bowl Meditation', 'description': 'Long-held passive poses stimulating connective fascia paired with Tibetan singing bowls.', 'duration_minutes': 75, 'price': 32.00, 'payment_policy': 'full_upfront'},
        {'name': '1-on-1 Private Reformer & Movement Analysis', 'description': 'Personalized kinetic biomechanics screen and tailored reformer workout.', 'duration_minutes': 55, 'price': 115.00, 'payment_policy': 'full_upfront'},
        {'name': 'Duet Private Reformer (2 Persons)', 'description': 'Semi-private training for two clients with dedicated master instructor coaching.', 'duration_minutes': 55, 'price': 160.00, 'payment_policy': 'full_upfront'},
      ],
      starterStaffRoles: const [
        'Maya Sterling (Lead Comprehensive Pilates Master Trainer)',
        'Leo Rossi (Senior Yoga Acharya & Sound Healer)',
        'Samira Khan (Functional Movement & Mobility Coach)',
      ],
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
    // Gene - Nov 06, 2026: Added Auto Detailing & Car Wash template preset
    BusinessTemplate(
      id: 'b0000001-0000-0000-0000-000000000010',
      categoryId: 'c0000007-0000-0000-0000-000000000007',
      name: 'Auto Detailing & Car Wash',
      slug: 'auto-detailing-car-wash',
      description: 'Hand foam washes, interior steam extraction, 1-step machine polish, and multi-year ceramic paint coatings.',
      icon: 'local_car_wash_rounded',
      bookingModel: BookingModelType.slotBased,
      defaultSettings: const {
        'slot_interval_minutes': 30,
        'buffer_minutes': 10,
        'requires_approval': false,
        'deposit_percent': 25.0,
        'cancellation_window_hours': 24,
        'advance_booking_days': 30,
        'min_notice_hours': 2,
        'working_hours': {
          'monday': {'open': '08:00', 'close': '18:00', 'is_open': true},
          'tuesday': {'open': '08:00', 'close': '18:00', 'is_open': true},
          'wednesday': {'open': '08:00', 'close': '18:00', 'is_open': true},
          'thursday': {'open': '08:00', 'close': '18:00', 'is_open': true},
          'friday': {'open': '08:00', 'close': '18:00', 'is_open': true},
          'saturday': {'open': '08:00', 'close': '18:00', 'is_open': true},
          'sunday': {'open': '09:00', 'close': '16:00', 'is_open': true},
        },
      },
      uiConfig: const {
        'resource_type': 'bay_and_technician',
        'resource_label': 'Detailing Bay & Specialist',
        'service_label': 'Auto Detailing Package',
        'show_staff_selection': true,
        'intake_fields': [
          {
            'id': 'vehicle_type',
            'label': 'Vehicle Size & Class',
            'type': 'select',
            'required': true,
            'options': [
              'Sedan / Hatchback',
              'Mid-Size SUV / Crossover',
              'Full-Size SUV / Pickup Truck',
              'Minivan / Commercial Van'
            ],
          },
          {
            'id': 'vehicle_make_model_year',
            'label': 'Vehicle Year, Make & Model',
            'type': 'text',
            'required': true,
            'placeholder': 'e.g. 2024 Porsche Macan, Chalk White',
          },
          {
            'id': 'license_plate',
            'label': 'License Plate # & State',
            'type': 'text',
            'required': true,
            'placeholder': 'e.g. 7XYZ123 (CA)',
          },
          {
            'id': 'heavy_soiling_pet_hair',
            'label': 'Excessive pet hair, interior mold, or heavy caked mud?',
            'type': 'boolean',
            'required': true,
            'helper_text': 'Additional manual steam extraction surcharge (\$30–\$50) may apply at intake inspection.',
          },
          {
            'id': 'ceramic_matte_paint',
            'label': 'Vehicle has existing ceramic coating, matte paint, or protective vinyl wrap?',
            'type': 'boolean',
            'required': false,
            'helper_text': 'Ensures pH-neutral foam wash and contact-free drying towels.',
          },
          {
            'id': 'special_requests',
            'label': 'Interior focus areas or special requests',
            'type': 'textarea',
            'required': false,
            'placeholder': 'Cup holder stains, engine bay wipe, child car seat sanitized...',
          },
        ],
      },
      starterServices: const [
        {'name': 'Signature Hand Wash & Wheel Decon', 'description': 'Touchless pre-foam, 2-bucket hand wash, iron wheel decontamination, and tire dressing.', 'duration_minutes': 45, 'price': 55.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Executive Interior Steam & Leather Care', 'description': 'Deep dry steam extraction, vents sanitized, leather conditioned, and carpet shampoo.', 'duration_minutes': 90, 'price': 165.00, 'payment_policy': 'deposit_required', 'deposit_amount': 40.00},
        {'name': 'Complete Diamond Detail (In & Out)', 'description': 'Full exterior clay bar decontamination, 1-month sealant, and intensive interior steam sanitize.', 'duration_minutes': 150, 'price': 280.00, 'payment_policy': 'deposit_required', 'deposit_amount': 70.00},
        {'name': '1-Step Paint Correction & Machine Polish', 'description': 'Swirl mark and light scratch elimination restoring gloss and optical depth.', 'duration_minutes': 180, 'price': 380.00, 'payment_policy': 'deposit_required', 'deposit_amount': 95.00},
        {'name': '3-Year Pro Ceramic Coating Package', 'description': 'Full paint decontamination, multi-stage prep, and 9H SiO2 ceramic liquid glass application.', 'duration_minutes': 240, 'price': 850.00, 'payment_policy': 'deposit_required', 'deposit_amount': 200.00},
        {'name': 'Engine Bay Steam Clean & Dressing', 'description': 'Safe low-moisture steam degreasing of plastics and hoses with satin UV protectant.', 'duration_minutes': 45, 'price': 75.00, 'payment_policy': 'pay_at_venue'},
        {'name': 'Headlight Restoration & UV Sealant', 'description': 'Wet-sanding yellowed foggy polycarbonate headlights with clear ceramic cure.', 'duration_minutes': 45, 'price': 90.00, 'payment_policy': 'pay_at_venue'},
      ],
      starterStaffRoles: const [
        'Bay 1: Master Certified Detailer & Paint Corrector',
        'Bay 2: Senior Interior Steam Specialist',
        'Bay 3: Ceramic Coating Technician',
      ],
      displayOrder: 10,
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
