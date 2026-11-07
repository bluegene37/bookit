// Gene - Nov, 03, 2026: Business, Services, and Staff repository service and providers
// Gene - Nov, 04, 2026: Added category & template queries and transactional business onboarding
// Gene - Nov, 05, 2026: Added foundation import for debugPrint logging
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../models/business_staff.dart';
import '../models/service_item.dart';
import '../models/business_category.dart';
import '../models/business_template.dart';
// Gene - Nov, 04, 2026: Added Review import for reviews synchronization
import '../models/review.dart';
import 'supabase_service.dart';
// Gene - Nov 07, 2026: Added PaginatedResult and AppErrorLogger imports for high-scale discovery pagination and telemetry
import '../core/utils/paginated_result.dart';
import '../core/utils/app_error_logger.dart';

class BusinessService {
  /*
  // Gene - Nov, 04, 2026: Smart semantic category and template matching across 6 sweet-spot industries without empty-table fallback
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

    return SupabaseService.mockBusinesses.where((b) {
      final matchesCategory = category == null || _matchesCategory(b, category);
      final matchesQuery = query == null ||
          query.trim().isEmpty ||
          b.name.toLowerCase().contains(query.toLowerCase()) ||
          (b.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
      return matchesCategory && matchesQuery;
    }).toList();
  }
  */

  /*
  // Gene - Nov, 05, 2026: Resilient getBusinesses combining remote data with local mock fallback and newly registered practices
  Future<List<Business>> getBusinesses({String? category, String? query}) async {
    final client = SupabaseService.client;
    List<Business> remoteList = [];
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
        remoteList = (data as List).map((json) => Business.fromJson(json)).toList();
      } catch (_) {}
    }

    // Filter local mock businesses against category and query criteria
    final filteredMock = SupabaseService.mockBusinesses.where((b) {
      final matchesCategory = category == null || _matchesCategory(b, category);
      final matchesQuery = query == null ||
          query.trim().isEmpty ||
          b.name.toLowerCase().contains(query.toLowerCase()) ||
          (b.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
      return matchesCategory && matchesQuery;
    }).toList();

    if (remoteList.isNotEmpty) {
      // Merge any newly registered local businesses not yet present in remote
      final remoteIds = remoteList.map((b) => b.id).toSet();
      final localOnly = filteredMock.where((b) => !remoteIds.contains(b.id)).toList();
      return [...localOnly, ...remoteList];
    }

    // If remote table is empty or unseeded, fall back to rich demo & newly registered businesses
    return filteredMock;
  }
  */

  // Gene - Nov 07, 2026: Upgraded getBusinesses with optional range pagination, structured error telemetry, and getBusinessesPaginated
  Future<List<Business>> getBusinesses({
    String? category,
    String? query,
    int? page,
    int? pageSize,
  }) async {
    final client = SupabaseService.client;
    List<Business> remoteList = [];
    if (client != null) {
      try {
        var queryBuilder = client.from('businesses').select().eq('is_active', true);
        if (category != null && category != 'All') {
          queryBuilder = queryBuilder.ilike('category', '%$category%');
        }
        if (query != null && query.trim().isNotEmpty) {
          queryBuilder = queryBuilder.ilike('name', '%$query%');
        }
        final dynamic data;
        if (page != null && pageSize != null && page >= 0 && pageSize > 0) {
          final from = page * pageSize;
          final to = from + pageSize - 1;
          data = await queryBuilder.order('rating_avg', ascending: false).range(from, to);
        } else {
          data = await queryBuilder;
        }
        remoteList = (data as List).map((json) => Business.fromJson(json)).toList();
      } catch (e, st) {
        AppErrorLogger.report(
          service: 'BusinessService',
          operation: 'getBusinesses',
          error: e,
          stackTrace: st,
        );
      }
    }

    // Filter local mock businesses against category and query criteria
    final filteredMock = SupabaseService.mockBusinesses.where((b) {
      final matchesCategory = category == null || _matchesCategory(b, category);
      final matchesQuery = query == null ||
          query.trim().isEmpty ||
          b.name.toLowerCase().contains(query.toLowerCase()) ||
          (b.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
      return matchesCategory && matchesQuery;
    }).toList();

    List<Business> merged;
    if (remoteList.isNotEmpty) {
      final remoteIds = remoteList.map((b) => b.id).toSet();
      final localOnly = filteredMock.where((b) => !remoteIds.contains(b.id)).toList();
      merged = [...localOnly, ...remoteList];
    } else {
      merged = filteredMock;
    }

    if (page != null && pageSize != null && page >= 0 && pageSize > 0) {
      return PaginatedResult.fromFullList(
        fullList: merged,
        page: page,
        pageSize: pageSize,
      ).items;
    }

    return merged;
  }

  // Gene - Nov 07, 2026: Paginated discovery query returning PaginatedResult<Business> metadata (items, hasMore, totalCount)
  Future<PaginatedResult<Business>> getBusinessesPaginated({
    String? category,
    String? query,
    required int page,
    int pageSize = 20,
  }) async {
    final fullMatching = await getBusinesses(category: category, query: query);
    return PaginatedResult.fromFullList(
      fullList: fullMatching,
      page: page,
      pageSize: pageSize,
    );
  }

  // Gene - Nov, 04, 2026: Helper matching business against industry category & template links
  bool _matchesCategory(Business b, String category) {
    if (category == 'All') return true;
    final catLower = category.toLowerCase();
    final bCat = b.category.toLowerCase();
    if (bCat.contains(catLower) || catLower.contains(bCat)) return true;

    // Check template link
    if (b.templateId != null) {
      final tpl = SupabaseService.mockTemplates.firstWhere(
        (t) => t.id == b.templateId,
        orElse: () => SupabaseService.mockTemplates.first,
      );
      if (tpl.slug.contains(catLower) || tpl.name.toLowerCase().contains(catLower)) return true;
      final parentCat = SupabaseService.mockCategories.firstWhere(
        (c) => c.id == tpl.categoryId,
        orElse: () => SupabaseService.mockCategories.first,
      );
      if (parentCat.name.toLowerCase() == catLower || parentCat.slug.contains(catLower)) return true;
    }

    // Semantic sweet spot aliases
    if (catLower.contains('health') && (bCat.contains('dental') || bCat.contains('medical') || bCat.contains('clinic'))) return true;
    if (catLower.contains('wellness') && (bCat.contains('recovery') || bCat.contains('stay') || bCat.contains('therapy') || bCat.contains('wellness'))) return true;
    if (catLower.contains('beauty') && (bCat.contains('salon') || bCat.contains('barber') || bCat.contains('spa') || bCat.contains('esthetics'))) return true;
    if (catLower.contains('fitness') && (bCat.contains('train') || bCat.contains('gym') || bCat.contains('fitness'))) return true;
    if (catLower.contains('consult') && (bCat.contains('legal') || bCat.contains('tax') || bCat.contains('advis'))) return true;
    if (catLower.contains('studio') && (bCat.contains('photo') || bCat.contains('podcast') || bCat.contains('space') || bCat.contains('rent'))) return true;

    return false;
  }

  /*
  // Gene - Nov, 03, 2026: Original getBusinessById
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
  */

  // Gene - Nov, 05, 2026: Defensive getBusinessById with safe fallback to prevent StateError on empty collections
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
      orElse: () => SupabaseService.mockBusinesses.isNotEmpty
          ? SupabaseService.mockBusinesses.first
          : Business.fallback(id: id),
    );
  }

  /*
  // Gene - Nov, 03, 2026: Previous getServices returning empty remote list on unseeded tables
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
  */

  /*
  // Gene - Nov, 05, 2026: Defensive getServices falling back to mock services when remote table has 0 rows for business
  Future<List<ServiceItem>> getServices(String businessId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('services').select().eq('business_id', businessId).eq('is_active', true);
        final list = (data as List).map((json) => ServiceItem.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return SupabaseService.mockServices.where((s) => s.businessId == businessId).toList();
  }
  */

  // Gene - Nov 07, 2026: Filter getServices to active-only for Client views and add getAdminServices returning all items for Admin catalog
  Future<List<ServiceItem>> getServices(String businessId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('services').select().eq('business_id', businessId).eq('is_active', true);
        final list = (data as List).map((json) => ServiceItem.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return SupabaseService.mockServices.where((s) => s.businessId == businessId && s.isActive).toList();
  }

  Future<List<ServiceItem>> getAdminServices(String businessId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('services').select().eq('business_id', businessId);
        final list = (data as List).map((json) => ServiceItem.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return SupabaseService.mockServices.where((s) => s.businessId == businessId).toList();
  }

  /*
  // Gene - Nov, 03, 2026: Previous getStaff returning empty remote list on unseeded tables
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
  */

  /*
  // Gene - Nov, 05, 2026: Defensive getStaff falling back to mock staff when remote table has 0 rows for business
  Future<List<BusinessStaff>> getStaff(String businessId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('business_staff').select().eq('business_id', businessId).eq('is_active', true);
        final list = (data as List).map((json) => BusinessStaff.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return SupabaseService.mockStaff.where((st) => st.businessId == businessId).toList();
  }
  */

  // Gene - Nov 07, 2026: Filter getStaff to active-only for Client views and add getAdminStaff returning all practitioners for Admin roster
  Future<List<BusinessStaff>> getStaff(String businessId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('business_staff').select().eq('business_id', businessId).eq('is_active', true);
        final list = (data as List).map((json) => BusinessStaff.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return SupabaseService.mockStaff.where((st) => st.businessId == businessId && st.isActive).toList();
  }

  Future<List<BusinessStaff>> getAdminStaff(String businessId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('business_staff').select().eq('business_id', businessId);
        final list = (data as List).map((json) => BusinessStaff.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
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

  /*
  // Gene - Nov, 04, 2026: Original createBusiness implementation
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
  */

  // Gene - Nov, 05, 2026: Resilient createBusiness ensuring local memory persistence alongside Supabase remote sync
  Future<Business> createBusiness({
    required Business business,
    required List<ServiceItem> services,
    required List<BusinessStaff> staff,
  }) async {
    // 1. Always ensure local mock state reflects newly registered business immediately
    final existingIdx = SupabaseService.mockBusinesses.indexWhere((b) => b.id == business.id);
    if (existingIdx != -1) {
      SupabaseService.mockBusinesses[existingIdx] = business;
    } else {
      SupabaseService.mockBusinesses.insert(0, business);
    }
    for (final srv in services) {
      if (!SupabaseService.mockServices.any((s) => s.id == srv.id)) {
        SupabaseService.mockServices.add(srv);
      }
    }
    for (final st in staff) {
      if (!SupabaseService.mockStaff.any((s) => s.id == st.id)) {
        SupabaseService.mockStaff.add(st);
      }
    }

    // 2. Attempt remote Supabase synchronization if client is configured
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final bizData = await client.from('businesses').insert(business.toJson()).select().single();
        final createdBusiness = Business.fromJson(bizData);

        if (services.isNotEmpty) {
          final srvJsonList = services.map((s) => s.toJson()).toList();
          await client.from('services').insert(srvJsonList);
        }

        if (staff.isNotEmpty) {
          final staffJsonList = staff.map((st) => st.toJson()).toList();
          await client.from('business_staff').insert(staffJsonList);
        }

        return createdBusiness;
      } catch (e) {
        debugPrint('Remote Supabase business sync note (using local state): $e');
      }
    }

    return business;
  }

  // Gene - Nov 06, 2026: Update business details including latitude, longitude, and address
  Future<Business> updateBusiness(Business business) async {
    final existingIdx = SupabaseService.mockBusinesses.indexWhere((b) => b.id == business.id);
    if (existingIdx != -1) {
      SupabaseService.mockBusinesses[existingIdx] = business;
    } else {
      SupabaseService.mockBusinesses.insert(0, business);
    }

    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('businesses').update(business.toJson()).eq('id', business.id).select().single();
        return Business.fromJson(data);
      } catch (e) {
        debugPrint('[BusinessService] updateBusiness remote error: $e');
      }
    }
    return business;
  }

  // Gene - Nov 06, 2026: Update staff member details, shift hours, and lunch breaks
  Future<BusinessStaff> updateStaff(BusinessStaff staff) async {
    final existingIdx = SupabaseService.mockStaff.indexWhere((st) => st.id == staff.id);
    if (existingIdx != -1) {
      SupabaseService.mockStaff[existingIdx] = staff;
    } else {
      SupabaseService.mockStaff.add(staff);
    }

    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('business_staff').update(staff.toJson()).eq('id', staff.id).select().single();
        return BusinessStaff.fromJson(data);
      } catch (e) {
        debugPrint('[BusinessService] updateStaff remote sync note (using memory state): $e');
      }
    }
    return staff;
  }

  // Gene - Nov 07, 2026: Added addStaff, addService, and updateService for full Admin catalog & practitioner CRUD
  Future<BusinessStaff> addStaff(BusinessStaff staff) async {
    final existingIdx = SupabaseService.mockStaff.indexWhere((st) => st.id == staff.id);
    if (existingIdx != -1) {
      SupabaseService.mockStaff[existingIdx] = staff;
    } else {
      SupabaseService.mockStaff.add(staff);
    }

    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('business_staff').insert(staff.toJson()).select().single();
        return BusinessStaff.fromJson(data);
      } catch (e) {
        debugPrint('[BusinessService] addStaff remote sync note (using memory state): $e');
      }
    }
    return staff;
  }

  Future<ServiceItem> addService(ServiceItem service) async {
    final existingIdx = SupabaseService.mockServices.indexWhere((s) => s.id == service.id);
    if (existingIdx != -1) {
      SupabaseService.mockServices[existingIdx] = service;
    } else {
      SupabaseService.mockServices.add(service);
    }

    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('services').insert(service.toJson()).select().single();
        return ServiceItem.fromJson(data);
      } catch (e) {
        debugPrint('[BusinessService] addService remote sync note (using memory state): $e');
      }
    }
    return service;
  }

  Future<ServiceItem> updateService(ServiceItem service) async {
    final existingIdx = SupabaseService.mockServices.indexWhere((s) => s.id == service.id);
    if (existingIdx != -1) {
      SupabaseService.mockServices[existingIdx] = service;
    } else {
      SupabaseService.mockServices.add(service);
    }

    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client.from('services').update(service.toJson()).eq('id', service.id).select().single();
        return ServiceItem.fromJson(data);
      } catch (e) {
        debugPrint('[BusinessService] updateService remote sync note (using memory state): $e');
      }
    }
    return service;
  }

  /*
  // Gene - Nov, 04, 2026: Synchronize customer reviews from Supabase reviews table
  Future<List<Review>> getReviews(String businessId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client
            .from('reviews')
            .select('*, profiles:client_id (full_name)')
            .eq('business_id', businessId)
            .order('created_at', ascending: false);
        return (data as List).map((r) => Review.fromJson(r)).toList();
      } catch (_) {}
    }
    return [];
  }

  // Gene - Nov, 04, 2026: Create and submit customer review to Supabase reviews table
  Future<bool> createReview(Review review) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('reviews').insert(review.toJson());
        return true;
      } catch (_) {}
    }
    return false;
  }
  */

  /*
  // Gene - Nov, 05, 2026: Customer reviews with dynamic in-memory store fallback and rating recalculation
  Future<List<Review>> getReviews(String businessId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client
            .from('reviews')
            .select('*, profiles:client_id (full_name)')
            .eq('business_id', businessId)
            .order('created_at', ascending: false);
        return (data as List).map((r) => Review.fromJson(r)).toList();
      } catch (_) {}
    }
    return SupabaseService.mockReviews.where((r) => r.businessId == businessId).toList();
  }

  // Gene - Nov, 05, 2026: Submit customer review and immediately recalculate rating_avg and rating_count
  Future<bool> createReview(Review review) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('reviews').insert(review.toJson());
        return true;
      } catch (_) {}
    }

    // In-Memory store update
    SupabaseService.mockReviews.insert(0, review);
  */

  // Gene - Nov 07, 2026: Ensure getReviews falls back to mockReviews when remote table is unseeded, and createReview always updates local memory + ratingAvg
  Future<List<Review>> getReviews(String businessId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client
            .from('reviews')
            .select('*, profiles:client_id (full_name)')
            .eq('business_id', businessId)
            .order('created_at', ascending: false);
        final list = (data as List).map((r) => Review.fromJson(r)).toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return SupabaseService.mockReviews.where((r) => r.businessId == businessId).toList();
  }

  Future<bool> createReview(Review review) async {
    // 1. Always update in-memory store immediately
    SupabaseService.mockReviews.insert(0, review);

    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('reviews').insert(review.toJson());
      } catch (_) {}
    }

    // Dynamic rating recalculation on targeted business
    final bizIndex = SupabaseService.mockBusinesses.indexWhere((b) => b.id == review.businessId);
    if (bizIndex != -1) {
      final biz = SupabaseService.mockBusinesses[bizIndex];
      final currentTotal = biz.ratingAvg * biz.ratingCount;
      final newCount = biz.ratingCount + 1;
      final newAvg = double.parse(((currentTotal + review.rating) / newCount).toStringAsFixed(2));
      SupabaseService.mockBusinesses[bizIndex] = Business(
        id: biz.id,
        ownerId: biz.ownerId,
        name: biz.name,
        slug: biz.slug,
        category: biz.category,
        bookingModel: biz.bookingModel,
        description: biz.description,
        address: biz.address,
        city: biz.city,
        latitude: biz.latitude,
        longitude: biz.longitude,
        contactPhone: biz.contactPhone,
        contactEmail: biz.contactEmail,
        bannerUrl: biz.bannerUrl,
        logoUrl: biz.logoUrl,
        settings: biz.settings,
        ratingAvg: newAvg,
        ratingCount: newCount,
        isActive: biz.isActive,
        stripeAccountId: biz.stripeAccountId,
        stripeChargesEnabled: biz.stripeChargesEnabled,
        platformFeePercent: biz.platformFeePercent,
        platformFeeFixed: biz.platformFeeFixed,
        templateId: biz.templateId,
        uiConfig: biz.uiConfig,
      );
    }
    return true;
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

// Gene - Nov 07, 2026: Added admin-specific providers returning both active and archived/inactive services and staff
final adminBusinessServicesProvider = FutureProvider.family<List<ServiceItem>, String>((ref, businessId) async {
  final service = ref.watch(businessServiceProvider);
  return service.getAdminServices(businessId);
});

final adminBusinessStaffProvider = FutureProvider.family<List<BusinessStaff>, String>((ref, businessId) async {
  final service = ref.watch(businessServiceProvider);
  return service.getAdminStaff(businessId);
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

// Gene - Nov, 04, 2026: Provider for business customer reviews
final businessReviewsProvider = FutureProvider.family<List<Review>, String>((ref, businessId) async {
  final service = ref.watch(businessServiceProvider);
  return service.getReviews(businessId);
});
