// Gene - Nov, 03, 2026: Supabase Service wrapper with seamless offline/mock fallback for immediate local testing
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_config.dart';
import '../models/business.dart';
import '../models/business_staff.dart';
import '../models/service_item.dart';
import '../models/booking.dart';
import '../models/user_profile.dart';

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

  // --- Seed Mock Data for Local Testing ---
  static final List<Business> mockBusinesses = [
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

  static final List<BusinessStaff> mockStaff = [
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

  static final List<ServiceItem> mockServices = [
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

  static final List<Booking> mockBookings = [
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

  static UserProfile mockCurrentUser = UserProfile(
    id: '00000000-0000-0000-0000-000000000001',
    email: 'admin@bookit.dev',
    fullName: 'Dr. Alexander Vance',
    role: 'business_owner',
    phone: '+1 (555) 234-5678',
    createdAt: DateTime.now(),
  );
}
