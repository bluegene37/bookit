// Gene - Nov, 03, 2026: Business, Services, and Staff repository service and providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../models/business_staff.dart';
import '../models/service_item.dart';
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
