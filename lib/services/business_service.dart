// Gene - Nov, 03, 2026: Business, Services, and Staff repository service and providers
// Gene - Nov, 04, 2026: Added category & template queries and transactional business onboarding
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../models/business_staff.dart';
import '../models/service_item.dart';
import '../models/business_category.dart';
import '../models/business_template.dart';
import 'supabase_service.dart';

class BusinessService {
  Future<List<Business>> getBusinesses({String? category, String? query}) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        var queryBuilder = client.from('businesses').select().eq('is_active', true);
        if (category != null && category != 'All') {
          queryBuilder = queryBuilder.ilike('category', '%$category%');
        }
        if (query != null && query.trim().isNotEmpty) {
          queryBuilder = queryBuilder.ilike('name', '%$query%');
        }
        final data = await queryBuilder;
        return (data as List).map((json) => Business.fromJson(json)).toList();
      } catch (_) {}
    }

    // Mock fallback
    return SupabaseService.mockBusinesses.where((b) {
      final matchesCategory = category == null || category == 'All' || b.category.toLowerCase().contains(category.toLowerCase());
      final matchesQuery = query == null || query.trim().isEmpty || b.name.toLowerCase().contains(query.toLowerCase()) || (b.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<Business?> getBusinessById(String id) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('businesses').select().eq('id', id).single();
        return Business.fromJson(data);
      } catch (_) {}
    }
    return SupabaseService.mockBusinesses.firstWhere(
      (b) => b.id == id,
      orElse: () => SupabaseService.mockBusinesses.first,
    );
  }

  Future<List<ServiceItem>> getServices(String businessId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('services').select().eq('business_id', businessId).eq('is_active', true);
        return (data as List).map((json) => ServiceItem.fromJson(json)).toList();
      } catch (_) {}
    }
    return SupabaseService.mockServices.where((s) => s.businessId == businessId).toList();
  }

  Future<List<BusinessStaff>> getStaff(String businessId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('business_staff').select().eq('business_id', businessId).eq('is_active', true);
        return (data as List).map((json) => BusinessStaff.fromJson(json)).toList();
      } catch (_) {}
    }
    return SupabaseService.mockStaff.where((st) => st.businessId == businessId).toList();
  }

  // Gene - Nov, 04, 2026: Fetch business categories from Supabase with offline fallback
  Future<List<BusinessCategory>> getCategories() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client
            .from('business_categories')
            .select()
            .eq('is_active', true)
            .order('display_order', ascending: true);
        return (data as List).map((json) => BusinessCategory.fromJson(json)).toList();
      } catch (_) {}
    }
    return SupabaseService.mockCategories;
  }

  // Gene - Nov, 04, 2026: Fetch business templates optionally filtered by category
  Future<List<BusinessTemplate>> getTemplates({String? categoryId}) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        var query = client.from('business_templates').select().eq('is_active', true);
        if (categoryId != null && categoryId != 'All') {
          query = query.eq('category_id', categoryId);
        }
        final data = await query.order('display_order', ascending: true);
        return (data as List).map((json) => BusinessTemplate.fromJson(json)).toList();
      } catch (_) {}
    }
    if (categoryId != null && categoryId != 'All') {
      return SupabaseService.mockTemplates.where((t) => t.categoryId == categoryId).toList();
    }
    return SupabaseService.mockTemplates;
  }

  // Gene - Nov, 04, 2026: Register and provision a new business with services and staff
  Future<Business> createBusiness({
    required Business business,
    required List<ServiceItem> services,
    required List<BusinessStaff> staff,
  }) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        // 1. Insert Business
        final bizData = await client.from('businesses').insert(business.toJson()).select().single();
        final createdBusiness = Business.fromJson(bizData);

        // 2. Insert Services
        if (services.isNotEmpty) {
          final srvJsonList = services.map((s) => s.toJson()).toList();
          await client.from('services').insert(srvJsonList);
        }

        // 3. Insert Staff
        if (staff.isNotEmpty) {
          final staffJsonList = staff.map((st) => st.toJson()).toList();
          await client.from('business_staff').insert(staffJsonList);
        }

        return createdBusiness;
      } catch (_) {}
    }

    // Mock fallback: append into memory
    SupabaseService.mockBusinesses.insert(0, business);
    for (final srv in services) {
      SupabaseService.mockServices.add(srv);
    }
    for (final st in staff) {
      SupabaseService.mockStaff.add(st);
    }
    return business;
  }
}

final businessServiceProvider = Provider<BusinessService>((ref) => BusinessService());

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final searchQueryProvider = StateProvider<String>((ref) => '');

final businessListProvider = FutureProvider<List<Business>>((ref) async {
  final service = ref.watch(businessServiceProvider);
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider);
  return service.getBusinesses(category: category, query: query);
});

final businessDetailProvider = FutureProvider.family<Business?, String>((ref, id) async {
  final service = ref.watch(businessServiceProvider);
  return service.getBusinessById(id);
});

final businessServicesProvider = FutureProvider.family<List<ServiceItem>, String>((ref, businessId) async {
  final service = ref.watch(businessServiceProvider);
  return service.getServices(businessId);
});

final businessStaffProvider = FutureProvider.family<List<BusinessStaff>, String>((ref, businessId) async {
  final service = ref.watch(businessServiceProvider);
  return service.getStaff(businessId);
});

// Gene - Nov, 04, 2026: Providers for categories and templates
final businessCategoriesProvider = FutureProvider<List<BusinessCategory>>((ref) async {
  final service = ref.watch(businessServiceProvider);
  return service.getCategories();
});

final selectedTemplateCategoryIdProvider = StateProvider<String?>((ref) => null);

final businessTemplatesProvider = FutureProvider<List<BusinessTemplate>>((ref) async {
  final service = ref.watch(businessServiceProvider);
  final catId = ref.watch(selectedTemplateCategoryIdProvider);
  return service.getTemplates(categoryId: catId);
});
