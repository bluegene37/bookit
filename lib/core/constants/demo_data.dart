// Gene - Nov, 05, 2026: Comprehensive Data-Driven Demo Store with rich seed datasets across all 6 business sweet spots, multiple demo personas, and defensive fallback defaults
import '../../models/business.dart';
import '../../models/business_staff.dart';
import '../../models/service_item.dart';
import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../models/review.dart';
import '../../models/notification_item.dart';
import '../../models/user_profile.dart';

class DemoData {
  // --- Demo Personas ---
  static const String adminOwnerId = '00000000-0000-0000-0000-000000000001';
  static const String retreatOwnerId = '00000000-0000-0000-0000-000000000002';
  static const String staffUserId = '00000000-0000-0000-0000-000000000004';
  static const String clientUserId = '00000000-0000-0000-0000-000000000003';

  static final UserProfile demoAdmin = UserProfile(
    id: adminOwnerId,
    email: 'admin@bookit.dev',
    fullName: 'Dr. Alexander Vance',
    role: 'business_owner',
    phone: '+1 (555) 234-5678',
    avatarUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=400&q=80',
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
  );

  static final UserProfile demoRetreatOwner = UserProfile(
    id: retreatOwnerId,
    email: 'retreat@bookit.dev',
    fullName: 'Elena Rostova',
    role: 'business_owner',
    phone: '+1 (555) 987-6543',
    avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
  );

  static final UserProfile demoStaff = UserProfile(
    id: staffUserId,
    email: 'staff@bookit.dev',
    fullName: 'Dr. Sophia Martinez, DMD',
    role: 'staff',
    phone: '+1 (555) 789-4321',
    // avatarUrl: 'https://images.unsplash.com/photo-1594824813637-b9560f1ad922?auto=format&fit=crop&w=400&q=80',
    // Gene - Nov, 7, 2026: Replaced broken 404 Unsplash avatar URL with verified working portrait URL
    avatarUrl: 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?auto=format&fit=crop&w=400&q=80',
    createdAt: DateTime.now().subtract(const Duration(days: 45)),
  );

  static final UserProfile demoClient = UserProfile(
    id: clientUserId,
    email: 'client@bookit.dev',
    fullName: 'Michael Chen',
    role: 'client',
    phone: '+1 (555) 345-6789',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  static final List<UserProfile> allDemoUsers = [
    demoAdmin,
    demoRetreatOwner,
    demoStaff,
    demoClient,
  ];

  // --- Fresh Seed Generators ---
  static List<Business> get freshBusinesses => [
    // 1. Dental Care (Slot Based)
    const Business(
      id: '11111111-1111-1111-1111-111111111111',
      ownerId: adminOwnerId,
      name: 'Apex Dental & Orthodontic Care',
      slug: 'apex-dental-orthodontic',
      category: 'Healthcare & Clinics',
      bookingModel: BookingModelType.slotBased,
      description: 'Gentle cosmetic dentistry, precision orthodontics, and restorative oral care in a state-of-the-art facility.',
      address: '742 Evergreen Medical Suites, Suite 300',
      city: 'San Francisco',
      contactPhone: '+1 (555) 456-7890',
      contactEmail: 'contact@apexdental.com',
      ratingAvg: 4.92,
      ratingCount: 48,
      bannerUrl: 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=1200&q=80',
      templateId: 'b0000001-0000-0000-0000-000000000001',
      uiConfig: {
        'resource_type': 'person',
        'resource_label': 'Specialist',
        'service_label': 'Service',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'dental_insurance', 'label': 'Do you have dental insurance?', 'type': 'boolean', 'required': false},
          {'id': 'insurance_carrier', 'label': 'Insurance Provider / Member ID', 'type': 'text', 'placeholder': 'e.g. Delta Dental / Cigna', 'required': false},
          {'id': 'chief_complaint', 'label': 'Primary reason for visit / symptoms', 'type': 'textarea', 'placeholder': 'Checkup, tooth sensitivity, whitening...', 'required': true},
        ],
      },
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

    // 2. Recovery Stays (Date Range)
    const Business(
      id: '22222222-2222-2222-2222-222222222222',
      ownerId: retreatOwnerId,
      name: 'Serenity Post-Op Recovery & Wellness Suites',
      slug: 'serenity-wellness-suites',
      category: 'Wellness & Therapy',
      bookingModel: BookingModelType.dateRange,
      description: 'Luxury recovery retreat offering 24/7 nursing supervision, rehabilitation therapy, and nutritious dietary plans.',
      address: '1200 Coastal Bay Road',
      city: 'Monterey',
      contactPhone: '+1 (555) 321-9876',
      contactEmail: 'reservations@serenitystay.com',
      ratingAvg: 4.88,
      ratingCount: 32,
      bannerUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=80',
      templateId: 'b0000001-0000-0000-0000-000000000003',
      uiConfig: {
        'resource_type': 'facility',
        'resource_label': 'Care Suite / Room',
        'service_label': 'Service',
        'show_staff_selection': false,
        'intake_fields': [
          {'id': 'surgery_type', 'label': 'Surgical procedure type & hospital', 'type': 'text', 'placeholder': 'e.g. Knee replacement at UCSF', 'required': true},
          {'id': 'mobility_level', 'label': 'Assistance needed (Wheelchair, Walker, Bedbound)', 'type': 'text', 'placeholder': 'Describe mobility needs', 'required': true},
        ],
      },
      settings: {
        'checkin_time': '14:00',
        'checkout_time': '11:00',
        'min_days': 2,
        'max_days': 30,
        'requires_approval': true,
      },
    ),

    // 3. Medical & Dermatology (Slot Based)
    const Business(
      id: '33333333-3333-3333-3333-333333333333',
      ownerId: adminOwnerId,
      name: 'Lumina Aesthetic & Dermatology Center',
      slug: 'lumina-dermatology',
      category: 'Healthcare & Clinics',
      bookingModel: BookingModelType.slotBased,
      description: 'Board-certified dermatologists specializing in medical skin health, clinical laser therapy, and advanced procedures.',
      address: '88 Sutter St, Floor 4',
      city: 'San Francisco',
      contactPhone: '+1 (555) 789-0123',
      contactEmail: 'hello@luminaderm.com',
      ratingAvg: 4.82,
      ratingCount: 40,
      bannerUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=1200&q=80',
      templateId: 'b0000001-0000-0000-0000-000000000002',
      uiConfig: {
        'resource_type': 'person',
        'resource_label': 'Physician / Doctor',
        'service_label': 'Procedure / Consultation',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'skin_concerns', 'label': 'Primary skin concerns or condition', 'type': 'textarea', 'placeholder': 'Acne, mole check, pigmentation...', 'required': true},
        ],
      },
      settings: {
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
    ),

    // 4. Mental Health & Therapy Practice
    const Business(
      id: '44444444-1111-1111-1111-111111111111',
      ownerId: retreatOwnerId,
      name: 'Mindful Horizon Psychotherapy & Counseling',
      slug: 'mindful-horizon-psychotherapy',
      category: 'Wellness & Therapy',
      bookingModel: BookingModelType.slotBased,
      description: 'Licensed clinical psychologists providing evidence-based individual therapy, cognitive behavioral therapy, and family counseling.',
      address: '220 Montgomery St, Suite 820',
      city: 'San Francisco',
      contactPhone: '+1 (555) 654-3210',
      contactEmail: 'care@mindfulhorizon.com',
      ratingAvg: 4.95,
      ratingCount: 29,
      bannerUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=1200&q=80',
      templateId: 'b0000001-0000-0000-0000-000000000004',
      uiConfig: {
        'resource_type': 'person',
        'resource_label': 'Therapist / Counselor',
        'service_label': 'Session Type',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'session_format', 'label': 'Preferred Format (In-Person or Video)', 'type': 'text', 'placeholder': 'In-Person or Video', 'required': true},
          {'id': 'primary_goals', 'label': 'Primary goals for counseling', 'type': 'textarea', 'placeholder': 'Stress reduction, relationship dynamics...', 'required': true},
        ],
      },
      settings: {
        'slot_interval_minutes': 50,
        'buffer_minutes': 10,
        'requires_approval': false,
        'working_hours': {
          'monday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'tuesday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'wednesday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'thursday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'friday': {'open': '09:00', 'close': '16:00', 'is_open': true},
          'saturday': {'open': '10:00', 'close': '14:00', 'is_open': true},
          'sunday': {'open': '00:00', 'close': '00:00', 'is_open': false},
        },
      },
    ),

    // 5. Hair Salon & Grooming
    const Business(
      id: '55555555-1111-1111-1111-111111111111',
      ownerId: adminOwnerId,
      name: 'Crown & Razor Grooming Studio',
      slug: 'crown-and-razor',
      category: 'Beauty & Personal Care',
      bookingModel: BookingModelType.slotBased,
      description: 'Artisanal haircuts, custom color balayage, hot-towel straight razor shaves, and grooming treatments.',
      address: '512 Valencia Street',
      city: 'San Francisco',
      contactPhone: '+1 (555) 443-2211',
      contactEmail: 'appointments@crownandrazor.com',
      ratingAvg: 4.89,
      ratingCount: 54,
      bannerUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=1200&q=80',
      templateId: 'b0000001-0000-0000-0000-000000000005',
      uiConfig: {
        'resource_type': 'person',
        'resource_label': 'Stylist / Barber',
        'service_label': 'Hair & Grooming Service',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'hair_length', 'label': 'Current hair length', 'type': 'text', 'placeholder': 'Short, medium, long', 'required': false},
        ],
      },
      settings: {
        'slot_interval_minutes': 45,
        'buffer_minutes': 10,
        'requires_approval': false,
        'working_hours': {
          'monday': {'open': '10:00', 'close': '19:00', 'is_open': true},
          'tuesday': {'open': '10:00', 'close': '19:00', 'is_open': true},
          'wednesday': {'open': '10:00', 'close': '19:00', 'is_open': true},
          'thursday': {'open': '10:00', 'close': '20:00', 'is_open': true},
          'friday': {'open': '09:00', 'close': '20:00', 'is_open': true},
          'saturday': {'open': '09:00', 'close': '18:00', 'is_open': true},
          'sunday': {'open': '11:00', 'close': '17:00', 'is_open': true},
        },
      },
    ),

    // 6. Fitness & Athletic Coaching
    const Business(
      id: '66666666-1111-1111-1111-111111111111',
      ownerId: adminOwnerId,
      name: 'Kinetic Edge Athletic Conditioning',
      slug: 'kinetic-edge-fitness',
      category: 'Fitness & Coaching',
      bookingModel: BookingModelType.slotBased,
      description: 'Private 1-on-1 sports performance coaching, functional strength training, and kinetic movement diagnostics.',
      address: '350 Townsend St, Unit 100',
      city: 'San Francisco',
      contactPhone: '+1 (555) 912-3847',
      contactEmail: 'train@kineticedge.com',
      ratingAvg: 4.96,
      ratingCount: 38,
      bannerUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=1200&q=80',
      templateId: 'b0000001-0000-0000-0000-000000000007',
      uiConfig: {
        'resource_type': 'person',
        'resource_label': 'Coach / Trainer',
        'service_label': 'Training Program',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'fitness_goal', 'label': 'Primary Fitness Goal', 'type': 'text', 'placeholder': 'Strength, fat loss, mobility...', 'required': true},
        ],
      },
      settings: {
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
          'sunday': {'open': '00:00', 'close': '00:00', 'is_open': false},
        },
      },
    ),

    // 7. Legal & Professional Advisory
    const Business(
      id: '77777777-1111-1111-1111-111111111111',
      ownerId: adminOwnerId,
      name: 'Vanguard Legal & Strategic Counsel',
      slug: 'vanguard-legal-counsel',
      category: 'Professional Consulting',
      bookingModel: BookingModelType.slotBased,
      description: 'Corporate law advisory, intellectual property protection, tax planning, and venture financing consultations.',
      address: '555 California St, Suite 2800',
      city: 'San Francisco',
      contactPhone: '+1 (555) 880-9911',
      contactEmail: 'advisory@vanguardlegal.com',
      ratingAvg: 4.91,
      ratingCount: 22,
      bannerUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
      templateId: 'b0000001-0000-0000-0000-000000000008',
      uiConfig: {
        'resource_type': 'person',
        'resource_label': 'Attorney / Partner',
        'service_label': 'Counsel Engagement',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'matter_type', 'label': 'Type of Legal Matter', 'type': 'text', 'placeholder': 'Corporate, IP, Contract, Tax', 'required': true},
          {'id': 'brief_summary', 'label': 'Brief overview of question or matter', 'type': 'textarea', 'placeholder': 'Summary...', 'required': true},
        ],
      },
      settings: {
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
    ),

    // 8. Studios & Creative Spaces
    const Business(
      id: '88888888-1111-1111-1111-111111111111',
      ownerId: retreatOwnerId,
      name: 'Aura Sound & Visual Stage Lab',
      slug: 'aura-sound-stage',
      category: 'Studios & Space Rentals',
      bookingModel: BookingModelType.slotBased,
      description: 'Broadcast-quality 4-mic podcast studio, corner infinity white cyclorama bay, and 4K cinema livestream facility.',
      address: '1045 Sansome St, Studio 12',
      city: 'San Francisco',
      contactPhone: '+1 (555) 774-2100',
      contactEmail: 'bookings@aurastages.com',
      ratingAvg: 4.94,
      ratingCount: 31,
      bannerUrl: 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&w=1200&q=80',
      templateId: 'b0000001-0000-0000-0000-000000000009',
      uiConfig: {
        'resource_type': 'facility',
        'resource_label': 'Studio Room / Bay',
        'service_label': 'Rental Session',
        'show_staff_selection': true,
        'intake_fields': [
          {'id': 'crew_size', 'label': 'Estimated Crew / Cast Size', 'type': 'text', 'placeholder': 'e.g. 4 people', 'required': true},
          {'id': 'equipment_needs', 'label': 'Special equipment requested', 'type': 'text', 'placeholder': 'Microphones, lights, switcher...', 'required': false},
        ],
      },
      settings: {
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
    ),
  ];

  static List<BusinessStaff> get freshStaff => [
    // Apex Dental Staff
    const BusinessStaff(
      id: '44444444-4444-4444-4444-444444444441',
      businessId: '11111111-1111-1111-1111-111111111111',
      name: 'Dr. Alexander Vance, DDS',
      specialty: 'Orthodontics & Smile Design',
      bio: '14+ years specializing in clear aligners, Invisalign, and aesthetic smile architecture.',
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

    // Serenity Retreat Staff
    const BusinessStaff(
      id: '44444444-4444-4444-4444-444444444451',
      businessId: '22222222-2222-2222-2222-222222222222',
      name: 'Elena Rostova, RN, BSN',
      specialty: 'Clinical Nurse Director',
      bio: 'Over 16 years of ICU and post-surgical rehabilitation patient care leadership.',
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    ),
    const BusinessStaff(
      id: '44444444-4444-4444-4444-444444444452',
      businessId: '22222222-2222-2222-2222-222222222222',
      name: 'Marcus Bell, DPT',
      specialty: 'Physical Rehabilitation',
      bio: 'Gentle mobility recovery, lymphatic drainage, and joint rehabilitation therapy.',
      avatarUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=400&q=80',
    ),

    // Lumina Dermatology Staff
    const BusinessStaff(
      id: '44444444-4444-4444-4444-444444444461',
      businessId: '33333333-3333-3333-3333-333333333333',
      name: 'Dr. Claire Laurent, MD',
      specialty: 'Board-Certified Dermatologist',
      bio: 'Stanford Medical graduate focusing on dermatologic oncology, laser rejuvenation, and skin health.',
      avatarUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=400&q=80',
    ),

    // Crown & Razor Staff
    const BusinessStaff(
      id: '44444444-4444-4444-4444-444444444471',
      businessId: '55555555-1111-1111-1111-111111111111',
      name: 'Julian Vance',
      specialty: 'Master Barber & Colorist',
      bio: 'Precision scissor architect and traditional straight-razor shave artisan.',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    ),

    // Kinetic Edge Staff
    const BusinessStaff(
      id: '44444444-4444-4444-4444-444444444481',
      businessId: '66666666-1111-1111-1111-111111111111',
      name: 'Coach David Thorne, CSCS',
      specialty: 'Head Performance Coach',
      bio: 'Specialist in functional biomechanics, Olympic weightlifting, and mobility restoration.',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    ),

    // Vanguard Legal Staff
    const BusinessStaff(
      id: '44444444-4444-4444-4444-444444444491',
      businessId: '77777777-1111-1111-1111-111111111111',
      name: 'Arthur Sterling, Esq.',
      specialty: 'Managing Partner',
      bio: 'Specialized corporate transaction, venture financing, and IP licensing counsel.',
      avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
    ),

    // Aura Sound Staff
    const BusinessStaff(
      id: '44444444-4444-4444-4444-444444444495',
      businessId: '88888888-1111-1111-1111-111111111111',
      name: 'Studio Bay A (Cyclorama Cove)',
      specialty: 'Infinity White Photo & Video Bay',
      bio: 'Pre-lit RGB ceiling grid, 200A power distribution, and sound dampening curtains.',
      avatarUrl: 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  static List<ServiceItem> get freshServices => [
    // Apex Dental Services
    const ServiceItem(
      id: '55555555-5555-5555-5555-555555555551',
      businessId: '11111111-1111-1111-1111-111111111111',
      name: 'Comprehensive Dental Exam & Cleaning',
      description: 'Panoramic X-ray, gum evaluation, gentle ultrasonic scaling, and high-shine polish.',
      durationMinutes: 45,
      price: 120.00,
      paymentPolicy: 'deposit_required',
      depositType: 'fixed',
      depositAmount: 30.00,
    ),
    const ServiceItem(
      id: '55555555-5555-5555-5555-555555555552',
      businessId: '11111111-1111-1111-1111-111111111111',
      name: 'Laser Teeth Whitening (Zoom!)',
      description: 'In-office accelerated whitening achieving up to 8 shades brighter in 60 mins.',
      durationMinutes: 60,
      price: 350.00,
      paymentPolicy: 'deposit_required',
      depositType: 'fixed',
      depositAmount: 50.00,
    ),
    const ServiceItem(
      id: '55555555-5555-5555-5555-555555555553',
      businessId: '11111111-1111-1111-1111-111111111111',
      name: 'Invisalign & Clear Aligner Consultation',
      description: '3D intraoral iTero scan, digital bite simulation, and orthodontic treatment roadmap.',
      durationMinutes: 30,
      price: 75.00,
      paymentPolicy: 'pay_at_venue',
      depositAmount: 0.0,
    ),

    // Serenity Stays Services
    const ServiceItem(
      id: '66666666-6666-6666-6666-666666666661',
      businessId: '22222222-2222-2222-2222-222222222222',
      name: 'Private Recovery Suite (Per Night)',
      description: 'Ocean-view terrace suite with 24/7 dedicated RN monitoring, physical therapy access, and organic meals.',
      durationMinutes: 1440,
      price: 450.00,
      paymentPolicy: 'deposit_required',
      depositType: 'fixed',
      depositAmount: 100.00,
    ),
    const ServiceItem(
      id: '66666666-6666-6666-6666-666666666662',
      businessId: '22222222-2222-2222-2222-222222222222',
      name: 'Executive Care Suite & Companion Bed (Per Night)',
      description: 'Expanded dual-room suite accommodating patient and accompanying family member or caregiver.',
      durationMinutes: 1440,
      price: 650.00,
      paymentPolicy: 'deposit_required',
      depositType: 'fixed',
      depositAmount: 150.00,
    ),

    // Lumina Dermatology Services
    const ServiceItem(
      id: '77777777-7777-7777-7777-777777777771',
      businessId: '33333333-3333-3333-3333-333333333333',
      name: 'Full-Body Skin Check & Dermatoscope Exam',
      description: 'Head-to-toe clinical evaluation of suspicious moles, lesions, and preventive scoring.',
      durationMinutes: 45,
      price: 220.00,
      paymentPolicy: 'deposit_required',
      depositType: 'fixed',
      depositAmount: 50.00,
    ),
    const ServiceItem(
      id: '77777777-7777-7777-7777-777777777772',
      businessId: '33333333-3333-3333-3333-333333333333',
      name: 'Clinical Laser Rejuvenation & Resurfacing',
      description: 'Fractional non-ablative laser treatment stimulating collagen and addressing fine lines.',
      durationMinutes: 60,
      price: 450.00,
      paymentPolicy: 'deposit_required',
      depositType: 'percentage',
      depositAmount: 20.00,
    ),

    // Crown & Razor Services
    const ServiceItem(
      id: '88888888-8888-8888-8888-888888888881',
      businessId: '55555555-1111-1111-1111-111111111111',
      name: 'Signature Haircut & Eucalyptus Hot Towel Shave',
      description: 'Precision scissor blend, neck taper, hot lather, straight-razor shave, and organic balm.',
      durationMinutes: 50,
      price: 65.00,
      paymentPolicy: 'pay_at_venue',
      depositAmount: 0.0,
    ),

    // Kinetic Edge Services
    const ServiceItem(
      id: '99999999-9999-9999-9999-999999999991',
      businessId: '66666666-1111-1111-1111-111111111111',
      name: '1-on-1 Functional Strength & Mobility Session',
      description: 'Personalized biomechanics assessment, progressive movement load, and recovery tracking.',
      durationMinutes: 60,
      price: 110.00,
      paymentPolicy: 'full_upfront',
      depositAmount: 110.00,
    ),

    // Vanguard Legal Services
    const ServiceItem(
      id: '10101010-1010-1010-1010-101010101010',
      businessId: '77777777-1111-1111-1111-111111111111',
      name: 'Initial Corporate & Financing Strategy Consultation',
      description: 'Structured risk review, venture formation overview, and agreement architecture analysis.',
      durationMinutes: 60,
      price: 350.00,
      paymentPolicy: 'full_upfront',
      depositAmount: 350.00,
    ),

    // Aura Sound Services
    const ServiceItem(
      id: '12121212-1212-1212-1212-121212121212',
      businessId: '88888888-1111-1111-1111-111111111111',
      name: 'Soundproof 4-Mic Podcast Suite (Per Hour)',
      description: 'Equipped with Shure SM7B mics, Rodecaster Pro II, Blackmagic 4K cameras, and studio headphones.',
      durationMinutes: 60,
      price: 95.00,
      paymentPolicy: 'deposit_required',
      depositType: 'fixed',
      depositAmount: 30.00,
    ),
  ];

  static List<Booking> get freshBookings => [
    // Booking 1: Confirmed upcoming slot
    Booking(
      id: 'bk-demo-1',
      businessId: '11111111-1111-1111-1111-111111111111',
      clientId: clientUserId,
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
      clientNotes: 'Routine cleaning and checkup. Slight cold sensitivity in upper molar.',
      paymentStatus: 'deposit_paid',
      amountPaid: 30.00,
      amountDue: 90.00,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),

    // Booking 2: Pending date range stay (requires approval)
    Booking(
      id: 'bk-demo-2',
      businessId: '22222222-2222-2222-2222-222222222222',
      clientId: clientUserId,
      serviceId: '66666666-6666-6666-6666-666666666661',
      bookingModel: 'date_range',
      dateFrom: DateTime.now().add(const Duration(days: 7)),
      dateTo: DateTime.now().add(const Duration(days: 10)),
      status: 'pending',
      totalPrice: 1350.00,
      businessName: 'Serenity Post-Op Recovery & Wellness Suites',
      serviceName: 'Private Recovery Suite (Per Night)',
      clientName: 'Michael Chen',
      clientNotes: 'Post-rhinoplasty rehabilitation stay. Low sodium meals requested.',
      paymentStatus: 'unpaid',
      amountPaid: 0.0,
      amountDue: 1350.00,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),

    // Booking 3: Completed booking eligible for client review
    Booking(
      id: 'bk-demo-3',
      businessId: '11111111-1111-1111-1111-111111111111',
      clientId: clientUserId,
      serviceId: '55555555-5555-5555-5555-555555555552',
      staffId: '44444444-4444-4444-4444-444444444442',
      bookingModel: 'slot_based',
      startTime: DateTime.now().subtract(const Duration(days: 5, hours: 3)),
      endTime: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
      status: 'completed',
      totalPrice: 350.00,
      businessName: 'Apex Dental & Orthodontic Care',
      serviceName: 'Laser Teeth Whitening (Zoom!)',
      staffName: 'Dr. Sophia Martinez, DMD',
      clientName: 'Michael Chen',
      clientNotes: 'Zoom whitening session.',
      paymentStatus: 'paid_in_full',
      amountPaid: 350.00,
      amountDue: 0.0,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),

    // Booking 4: Cancelled booking with refund status
    Booking(
      id: 'bk-demo-4',
      businessId: '33333333-3333-3333-3333-333333333333',
      clientId: clientUserId,
      serviceId: '77777777-7777-7777-7777-777777777771',
      bookingModel: 'slot_based',
      startTime: DateTime.now().subtract(const Duration(days: 2)),
      endTime: DateTime.now().subtract(const Duration(days: 2, minutes: -45)),
      status: 'cancelled',
      totalPrice: 220.00,
      businessName: 'Lumina Aesthetic & Dermatology Center',
      serviceName: 'Full-Body Skin Check & Dermatoscope Exam',
      clientName: 'Michael Chen',
      cancellationReason: 'Client work travel schedule conflict.',
      paymentStatus: 'refunded',
      amountPaid: 0.0,
      amountDue: 0.0,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  static List<Payment> get freshPayments => [
    Payment(
      id: 'pay-demo-1',
      bookingId: 'bk-demo-1',
      businessId: '11111111-1111-1111-1111-111111111111',
      clientId: clientUserId,
      stripeSessionId: 'cs_test_demo_01',
      stripePaymentIntentId: 'pi_test_demo_01',
      grossAmount: 30.00,
      applicationFeeAmount: 1.05,
      stripeFeeAmount: 1.17,
      netAmount: 27.78,
      currency: 'usd',
      paymentStatus: 'succeeded',
      receiptUrl: 'https://pay.stripe.com/receipts/demo-1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Payment(
      id: 'pay-demo-3',
      bookingId: 'bk-demo-3',
      businessId: '11111111-1111-1111-1111-111111111111',
      clientId: clientUserId,
      stripeSessionId: 'cs_test_demo_03',
      stripePaymentIntentId: 'pi_test_demo_03',
      grossAmount: 350.00,
      applicationFeeAmount: 9.05,
      stripeFeeAmount: 10.45,
      netAmount: 330.50,
      currency: 'usd',
      paymentStatus: 'succeeded',
      receiptUrl: 'https://pay.stripe.com/receipts/demo-3',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static List<Review> get freshReviews => [
    Review(
      id: 'rev-demo-1',
      businessId: '11111111-1111-1111-1111-111111111111',
      clientId: clientUserId,
      /*
      bookingId: 'bk-demo-3',
      */
      // Gene - Nov 07, 2026: Keep bk-demo-3 unreviewed initially so it remains eligible for 'Leave a Review' in ClientBookingsScreen
      bookingId: 'bk-historical-100',
      rating: 5,
      comment: 'Dr. Alexander Vance and Dr. Martinez made the teeth whitening process completely painless. The results exceeded my expectations!',
      clientName: 'Michael Chen',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Review(
      id: 'rev-demo-2',
      businessId: '11111111-1111-1111-1111-111111111111',
      clientId: '00000000-0000-0000-0000-000000000099',
      bookingId: 'bk-historical-99',
      rating: 5,
      comment: 'Top-tier dental practice in San Francisco. State of the art scans and gentle cleaning by Sarah.',
      clientName: 'Jessica Wu',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    Review(
      id: 'rev-demo-3',
      businessId: '22222222-2222-2222-2222-222222222222',
      clientId: '00000000-0000-0000-0000-000000000098',
      bookingId: 'bk-historical-98',
      rating: 5,
      comment: 'Elena and the nursing staff at Serenity Suites provided miraculous care following my surgery. Truly a restorative sanctuary.',
      clientName: 'David Sterling',
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
  ];

  static List<NotificationItem> get freshNotifications => [
    NotificationItem(
      id: 'notif-demo-1',
      userId: clientUserId,
      businessId: '11111111-1111-1111-1111-111111111111',
      bookingId: 'bk-demo-1',
      title: 'Appointment Confirmed',
      body: 'Your dental cleaning with Dr. Alexander Vance is confirmed for 2 days from now.',
      type: 'booking_confirmed',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationItem(
      id: 'notif-demo-2',
      userId: adminOwnerId,
      businessId: '11111111-1111-1111-1111-111111111111',
      bookingId: 'bk-demo-1',
      title: 'New Booking Received',
      body: 'Michael Chen booked Comprehensive Dental Exam & Cleaning (\$30 deposit received).',
      type: 'payment_succeeded',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationItem(
      id: 'notif-demo-3',
      userId: retreatOwnerId,
      businessId: '22222222-2222-2222-2222-222222222222',
      bookingId: 'bk-demo-2',
      title: 'Pending Stay Request',
      body: 'Michael Chen requested a 3-night post-op recovery stay awaiting your approval.',
      type: 'booking_pending',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];
}
