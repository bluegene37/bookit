// Gene - Nov, 04, 2026: Admin Onboarding Wizard for business registration & template inheritance
// Gene - Nov, 14, 2026: Added dart:math for text-scaled responsive grid extent calculations
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/widgets/neumorphic_text_field.dart';
import '../../../../core/widgets/neumorphic_chip.dart';
import '../../../../models/business.dart';
// Gene - Nov, 04, 2026: Removed unused direct category model import; managed via providers
// import '../../../../models/business_category.dart';
import '../../../../models/business_template.dart';
import '../../../../models/service_item.dart';
import '../../../../models/business_staff.dart';
import '../../../../services/business_service.dart';
import '../../../../services/auth_service.dart';
// Gene - Nov, 05, 2026: Added Uuid import for PostgreSQL UUID compliant IDs
import 'package:uuid/uuid.dart';
// Gene - Nov 06, 2026: Added location geocoding service and interactive map pin-picker widget
import 'dart:async';
import '../../../../services/location_geocoding_service.dart';
import 'location_pin_picker.dart';

class AdminOnboardingWizard extends ConsumerStatefulWidget {
  final VoidCallback? onCompleted;

  const AdminOnboardingWizard({super.key, this.onCompleted});

  @override
  ConsumerState<AdminOnboardingWizard> createState() => _AdminOnboardingWizardState();
}

class _AdminOnboardingWizardState extends ConsumerState<AdminOnboardingWizard> {
  int _currentStep = 0;

  // Step 0: Selected Template
  String? _selectedCategoryId;
  BusinessTemplate? _selectedTemplate;

  // Step 1: Business Details
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Gene - Nov 06, 2026: Coordinates and debouncer for interactive map pin-picker
  double? _latitude = 37.7749;
  double? _longitude = -122.4194;
  final GlobalKey<LocationPinPickerState> _pinPickerKey = GlobalKey<LocationPinPickerState>();
  Timer? _addressDebounce;

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
    _cityController.addListener(_onAddressChanged);
  }

  void _onAddressChanged() {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 600), () async {
      final query = '${_addressController.text.trim()}, ${_cityController.text.trim()}'.trim();
      if (query.length > 5) {
        final geocoder = ref.read(locationGeocodingServiceProvider);
        final results = await geocoder.searchAddress(query);
        if (results.isNotEmpty && mounted) {
          final loc = results.first;
          setState(() {
            _latitude = loc.latitude;
            _longitude = loc.longitude;
          });
          _pinPickerKey.currentState?.moveToLocation(loc.latitude, loc.longitude, addressLabel: loc.formattedAddress);
        }
      }
    });
  }

  // Step 2: Starter Catalog & Staff
  final List<Map<String, dynamic>> _customServices = [];
  final List<String> _customStaff = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _addressController.removeListener(_onAddressChanged);
    _cityController.removeListener(_onAddressChanged);
    _nameController.dispose();
    _slugController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onTemplateSelected(BusinessTemplate template) {
    setState(() {
      _selectedTemplate = template;
      // Pre-fill starter services
      _customServices.clear();
      for (final srv in template.starterServices) {
        _customServices.add({
          'name': srv['name'],
          'description': srv['description'] ?? '',
          'duration_minutes': srv['duration_minutes'] ?? 45,
          'price': (srv['price'] as num?)?.toDouble() ?? 50.0,
          'payment_policy': srv['payment_policy'] ?? 'pay_at_venue',
          'deposit_amount': (srv['deposit_amount'] as num?)?.toDouble() ?? 0.0,
          'is_included': true,
        });
      }

      // Pre-fill starter staff
      _customStaff.clear();
      _customStaff.addAll(template.starterStaffRoles);
    });
  }

  void _generateSlug(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    _slugController.text = slug;
  }

  Future<void> _handleCreateBusiness() async {
    if (_selectedTemplate == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a business name.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authProvider).user;
      /*
      // Gene - Nov, 04, 2026: Non-UUID timestamp keys that cause PostgreSQL syntax errors
      final ownerId = user?.id ?? '00000000-0000-0000-0000-000000000001';
      final businessId = 'biz-${DateTime.now().millisecondsSinceEpoch}';
      final slug = _slugController.text.trim().isNotEmpty
          ? _slugController.text.trim()
          : 'biz-${DateTime.now().millisecondsSinceEpoch}';
      */

      // Gene - Nov, 05, 2026: Generate valid RFC 4122 UUID v4 identifiers for business, services, and staff
      const uuidGen = Uuid();
      final ownerId = user?.id ?? '00000000-0000-0000-0000-000000000001';
      final businessId = uuidGen.v4();
      final slug = _slugController.text.trim().isNotEmpty
          ? _slugController.text.trim()
          : 'biz-${DateTime.now().millisecondsSinceEpoch}';

      /*
      // Original newBusiness without coordinates
      final newBusiness = Business(
        id: businessId,
        ownerId: ownerId,
        templateId: _selectedTemplate!.id,
        name: name,
        slug: slug,
        category: _selectedTemplate!.slug,
        bookingModel: _selectedTemplate!.bookingModel,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : _selectedTemplate!.description,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        contactPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        contactEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        settings: _selectedTemplate!.defaultSettings,
        uiConfig: _selectedTemplate!.uiConfig,
      );
      */
      // Gene - Nov 06, 2026: Included latitude and longitude captured from interactive LocationPinPicker
      final newBusiness = Business(
        id: businessId,
        ownerId: ownerId,
        templateId: _selectedTemplate!.id,
        name: name,
        slug: slug,
        category: _selectedTemplate!.slug,
        bookingModel: _selectedTemplate!.bookingModel,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : _selectedTemplate!.description,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        latitude: _latitude,
        longitude: _longitude,
        contactPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        contactEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        settings: _selectedTemplate!.defaultSettings,
        uiConfig: _selectedTemplate!.uiConfig,
      );

      /*
      // Gene - Nov, 04, 2026: Non-UUID service IDs
      final servicesToInsert = <ServiceItem>[];
      for (int i = 0; i < _customServices.length; i++) {
        final s = _customServices[i];
        if (s['is_included'] == true) {
          servicesToInsert.add(
            ServiceItem(
              id: 'srv-${DateTime.now().millisecondsSinceEpoch}-$i',
              businessId: businessId,
              name: s['name'] as String,
              description: s['description'] as String?,
              durationMinutes: s['duration_minutes'] as int,
              price: (s['price'] as num).toDouble(),
              paymentPolicy: s['payment_policy'] as String? ?? 'pay_at_venue',
              depositAmount: (s['deposit_amount'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
      }
      */

      // Gene - Nov, 05, 2026: Generate UUID v4 for each provisioned service
      final servicesToInsert = <ServiceItem>[];
      for (int i = 0; i < _customServices.length; i++) {
        final s = _customServices[i];
        if (s['is_included'] == true) {
          servicesToInsert.add(
            ServiceItem(
              id: uuidGen.v4(),
              businessId: businessId,
              name: s['name'] as String,
              description: s['description'] as String?,
              durationMinutes: s['duration_minutes'] as int,
              price: (s['price'] as num).toDouble(),
              paymentPolicy: s['payment_policy'] as String? ?? 'pay_at_venue',
              depositAmount: (s['deposit_amount'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
      }

      /*
      // Gene - Nov, 04, 2026: Non-UUID staff IDs
      final staffToInsert = <BusinessStaff>[];
      for (int i = 0; i < _customStaff.length; i++) {
        staffToInsert.add(
          BusinessStaff(
            id: 'stf-${DateTime.now().millisecondsSinceEpoch}-$i',
            businessId: businessId,
            name: '${_customStaff[i]} 1',
            specialty: _customStaff[i],
          ),
        );
      }
      */

      // Gene - Nov, 05, 2026: Generate UUID v4 for each provisioned staff member
      final staffToInsert = <BusinessStaff>[];
      for (int i = 0; i < _customStaff.length; i++) {
        staffToInsert.add(
          BusinessStaff(
            id: uuidGen.v4(),
            businessId: businessId,
            name: '${_customStaff[i]} 1',
            specialty: _customStaff[i],
          ),
        );
      }

      // Provision via business service
      await ref.read(businessServiceProvider).createBusiness(
        business: newBusiness,
        services: servicesToInsert,
        staff: staffToInsert,
      );

      // Invalidate list provider so admin dashboard refreshes
      ref.invalidate(businessListProvider);

      if (mounted) {
        Navigator.of(context).pop(newBusiness.id);
        widget.onCompleted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newBusiness.name} registered successfully!'),
            backgroundColor: NeumorphicColors.tealPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register business: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  IconData _resolveIcon(String icon) {
    switch (icon) {
      case 'medical_services_rounded':
      case 'medical_information_rounded':
        return Icons.medical_services_rounded;
      case 'health_and_safety_rounded':
        return Icons.health_and_safety_rounded;
      case 'hotel_rounded':
        return Icons.hotel_rounded;
      case 'psychology_rounded':
        return Icons.psychology_rounded;
      case 'brush_rounded':
      case 'content_cut_rounded':
        return Icons.content_cut_rounded;
      case 'spa_rounded':
      case 'self_improvement_rounded':
        return Icons.spa_rounded;
      case 'fitness_center_rounded':
      case 'sports_gymnastics_rounded':
        return Icons.fitness_center_rounded;
      case 'gavel_rounded':
      case 'balance_rounded':
        return Icons.balance_rounded;
      case 'meeting_room_rounded':
      case 'camera_indoor_rounded':
        return Icons.meeting_room_rounded;
      // Gene - Nov 06, 2026: Added car wash and automotive icons support
      case 'local_car_wash_rounded':
      case 'directions_car_rounded':
        return Icons.local_car_wash_rounded;
      default:
        return Icons.business_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    // Gene - Nov, 14, 2026: Compact modal insets/padding, Expanded header, Close tooltip, and responsive action footer
    final isNarrowViewport = MediaQuery.sizeOf(context).width < 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    // Gene - Nov, 14, 2026: Detect compact vertical heights (e.g. 320x568 @ 1.5x) to tighten chrome and preserve body height
    final screenHeight = MediaQuery.sizeOf(context).height;
    // final isShortViewport = screenHeight < 680 || (screenHeight / textScale) < 520;
    // Gene - Nov, 14, 2026: Tighten short-viewport threshold so 800x600 MediaQuery test surfaces keep standard layout
    final isShortViewport = screenHeight < 580 || (screenHeight / textScale) < 480;

    return Dialog(
      backgroundColor: Colors.transparent,
      /*
      insetPadding: isNarrowViewport
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      */
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrowViewport ? 12 : 20,
        vertical: isShortViewport ? 8 : (isNarrowViewport ? 16 : 24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: NeumorphicContainer(
          borderRadius: 20,
          // padding: EdgeInsets.all(isNarrowViewport ? 16 : 24),
          padding: EdgeInsets.all(isShortViewport ? 12 : (isNarrowViewport ? 16 : 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        NeumorphicContainer(
                          isCircle: true,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.storefront_rounded, color: accent, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Business Onboarding & Setup',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Step ${_currentStep + 1} of 4: ${_getStepTitle()}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: isShortViewport ? 8 : 16),

              // Progress Nodes
              _buildProgressNodes(isDark, accent, isCompactVertical: isShortViewport),
              SizedBox(height: isShortViewport ? 8 : 16),
              const Divider(height: 1),
              SizedBox(height: isShortViewport ? 8 : 16),

              // Body content
              Expanded(
                child: _buildCurrentStepView(isDark, accent),
              ),

              SizedBox(height: isShortViewport ? 8 : 16),
              const Divider(height: 1),
              SizedBox(height: isShortViewport ? 8 : 16),

              // Action Buttons
              LayoutBuilder(
                builder: (context, constraints) {
                  final backBtn = _currentStep > 0
                      ? NeumorphicButton(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          onPressed: () => setState(() => _currentStep--),
                          child: const Text('Back'),
                        )
                      : null;
                  final nextBtn = NeumorphicButton(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (_currentStep == 0) {
                              if (_selectedTemplate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select an industry template to continue.')),
                                );
                                return;
                              }
                              setState(() => _currentStep = 1);
                            } else if (_currentStep == 1) {
                              if (_nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter your business name.')),
                                );
                                return;
                              }
                              setState(() => _currentStep = 2);
                            } else if (_currentStep == 2) {
                              setState(() => _currentStep = 3);
                            } else {
                              _handleCreateBusiness();
                            }
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == 3 ? 'Launch Business' : 'Continue',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  );

                  if (constraints.maxWidth < 300 * textScale) {
                    return Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runAlignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ?backBtn,
                        nextBtn,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      backBtn ?? const SizedBox.shrink(),
                      nextBtn,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Choose Industry Template';
      case 1:
        return 'Business Information';
      case 2:
        return 'Review Starter Catalog';
      case 3:
      default:
        return 'Schedule & Launch';
    }
  }

  // Gene - Nov, 14, 2026: Responsive Wrap progress nodes when modal width/scale is narrow and accessible dot contrast
  Widget _buildProgressNodes(bool isDark, Color accent, {bool isCompactVertical = false}) {
    if (isCompactVertical) {
      // // Gene - Nov, 14, 2026: Previous horizontal SingleChildScrollView caused multiple Scrollable ambiguity in scrollUntilVisible tests
      // return SingleChildScrollView(
      //   scrollDirection: Axis.horizontal,
      //   child: Row(
      //     children: [
      //       _buildProgressDot(0, 'Template', isDark, accent),
      //       _buildProgressDot(1, 'Profile', isDark, accent),
      //       _buildProgressDot(2, 'Catalog', isDark, accent),
      //       _buildProgressDot(3, 'Launch', isDark, accent),
      //     ],
      //   ),
      // );
      // Gene - Nov, 14, 2026: Use non-scrollable FittedBox instead of SingleChildScrollView so scrollUntilVisible sees only the active step Scrollable
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressDot(0, 'Template', isDark, accent),
            _buildProgressDot(1, 'Profile', isDark, accent),
            _buildProgressDot(2, 'Catalog', isDark, accent),
            _buildProgressDot(3, 'Launch', isDark, accent),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        if (constraints.maxWidth < 480 * textScale) {
          return Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildProgressDot(0, 'Template', isDark, accent),
              _buildProgressDot(1, 'Profile', isDark, accent),
              _buildProgressDot(2, 'Catalog', isDark, accent),
              _buildProgressDot(3, 'Launch', isDark, accent),
            ],
          );
        }
        return Row(
          children: [
            _buildProgressDot(0, 'Template', isDark, accent),
            Expanded(child: Container(height: 2, color: _currentStep > 0 ? accent : Colors.grey.withValues(alpha: 0.3))),
            _buildProgressDot(1, 'Profile', isDark, accent),
            Expanded(child: Container(height: 2, color: _currentStep > 1 ? accent : Colors.grey.withValues(alpha: 0.3))),
            _buildProgressDot(2, 'Catalog', isDark, accent),
            Expanded(child: Container(height: 2, color: _currentStep > 2 ? accent : Colors.grey.withValues(alpha: 0.3))),
            _buildProgressDot(3, 'Launch', isDark, accent),
          ],
        );
      },
    );
  }

  Widget _buildProgressDot(int step, String label, bool isDark, Color accent) {
    final isDone = _currentStep > step;
    final isCurrent = _currentStep == step;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent || isDone ? NeumorphicColors.tealPrimary : (isDark ? Colors.grey[800] : Colors.grey[300]),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? Colors.white
                          : (isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent
                ? accent
                : (isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildCurrentStepView(bool isDark, Color accent) {
    switch (_currentStep) {
      case 0:
        return _buildTemplateSelectionStep(isDark, accent);
      case 1:
        return _buildBusinessProfileStep(isDark, accent);
      case 2:
        return _buildCatalogReviewStep(isDark, accent);
      case 3:
      default:
        return _buildScheduleLaunchStep(isDark, accent);
    }
  }

  // --- Step 0: Template Selection ---
  Widget _buildTemplateSelectionStep(bool isDark, Color accent) {
    final categoriesAsync = ref.watch(businessCategoriesProvider);
    final templatesAsync = ref.watch(businessTemplatesProvider);

    /*
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your business vertical to automatically configure your client booking UI, scheduling engine, intake form, and starter catalog.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 14),

        // Category Filter Chips
        categoriesAsync.when(
          loading: () => const SizedBox(height: 36, child: LinearProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (categories) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  NeumorphicChip(
                    label: 'All Verticals',
                    isSelected: _selectedCategoryId == null,
                    onTap: () {
                      setState(() => _selectedCategoryId = null);
                      ref.read(selectedTemplateCategoryIdProvider.notifier).state = null;
                    },
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((cat) {
                    final isSelected = _selectedCategoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: NeumorphicChip(
                        label: cat.name,
                        icon: _resolveIcon(cat.icon),
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedCategoryId = cat.id);
                          ref.read(selectedTemplateCategoryIdProvider.notifier).state = cat.id;
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Templates Grid
        // Gene - Nov, 14, 2026: Responsive 1/2-column grid with scaled mainAxisExtent, Semantics button state, and WCAG muted tokens
        Expanded(
          child: templatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading templates: $e')),
            data: (templates) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                  final isSingleCol = constraints.maxWidth < 560;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSingleCol ? 1 : 2,
                      mainAxisExtent: (isSingleCol ? 124.0 : 130.0) * math.max(1.0, textScale * 0.95),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      final isSelected = _selectedTemplate?.id == template.id;

                      return Semantics(
                        button: true,
                        selected: isSelected,
                        label: template.name,
                        child: GestureDetector(
                          onTap: () => _onTemplateSelected(template),
                          child: NeumorphicContainer(
                            borderRadius: 14,
                            border: isSelected ? Border.all(color: accent, width: 2) : null,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                NeumorphicContainer(
                                  isCircle: true,
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    _resolveIcon(template.icon),
                                    color: isSelected
                                        ? accent
                                        : (isDark
                                            ? NeumorphicColors.darkTextSecondary
                                            : NeumorphicColors.lightTextSecondary),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              template.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? accent
                                                    : (isDark
                                                        ? NeumorphicColors.darkTextPrimary
                                                        : NeumorphicColors.lightTextPrimary),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            flex: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: accent.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                template.bookingModel.name.toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: accent,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Expanded(
                                        child: Text(
                                          template.description ?? '',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? NeumorphicColors.darkTextSecondary
                                                : NeumorphicColors.lightTextSecondary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            template.showStaffSelection ? Icons.person_rounded : Icons.home_work_rounded,
                                            size: 13,
                                            color: isDark
                                                ? NeumorphicColors.darkTextMuted
                                                : NeumorphicColors.lightTextMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              template.resourceLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? NeumorphicColors.darkTextMuted
                                                    : NeumorphicColors.lightTextMuted,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${template.starterServices.length} Services',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
    */
    // Gene - Nov, 14, 2026: Switch Step 0 template picker to a full-step SingleChildScrollView when available height < 340dp (e.g. 320x568 @ 1.5x)
    return LayoutBuilder(
      builder: (context, stepConstraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final isShortStep = stepConstraints.maxHeight < 340;
        final isSingleCol = stepConstraints.maxWidth < 560;

        final description = Text(
          'Select your business vertical to automatically configure your client booking UI, scheduling engine, intake form, and starter catalog.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
          ),
        );

        final categoryStrip = categoriesAsync.when(
          loading: () => const SizedBox(height: 36, child: LinearProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (categories) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  NeumorphicChip(
                    label: 'All Verticals',
                    isSelected: _selectedCategoryId == null,
                    onTap: () {
                      setState(() => _selectedCategoryId = null);
                      ref.read(selectedTemplateCategoryIdProvider.notifier).state = null;
                    },
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((cat) {
                    final isSelected = _selectedCategoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: NeumorphicChip(
                        label: cat.name,
                        icon: _resolveIcon(cat.icon),
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedCategoryId = cat.id);
                          ref.read(selectedTemplateCategoryIdProvider.notifier).state = cat.id;
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );

        final templatesGrid = templatesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading templates: $e')),
          data: (templates) {
            return GridView.builder(
              shrinkWrap: isShortStep,
              physics: isShortStep ? const NeverScrollableScrollPhysics() : null,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSingleCol ? 1 : 2,
                mainAxisExtent: (isSingleCol ? 124.0 : 130.0) * math.max(1.0, textScale * 0.95),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final isSelected = _selectedTemplate?.id == template.id;

                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: template.name,
                  child: GestureDetector(
                    onTap: () => _onTemplateSelected(template),
                    child: NeumorphicContainer(
                      borderRadius: 14,
                      border: isSelected ? Border.all(color: accent, width: 2) : null,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NeumorphicContainer(
                            isCircle: true,
                            width: 44,
                            height: 44,
                            child: Icon(
                              _resolveIcon(template.icon),
                              color: isSelected
                                  ? accent
                                  : (isDark
                                      ? NeumorphicColors.darkTextSecondary
                                      : NeumorphicColors.lightTextSecondary),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        template.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? accent
                                              : (isDark
                                                  ? NeumorphicColors.darkTextPrimary
                                                  : NeumorphicColors.lightTextPrimary),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      flex: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          template.bookingModel.name.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    template.description ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? NeumorphicColors.darkTextSecondary
                                          : NeumorphicColors.lightTextSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      template.showStaffSelection ? Icons.person_rounded : Icons.home_work_rounded,
                                      size: 13,
                                      color: isDark
                                          ? NeumorphicColors.darkTextMuted
                                          : NeumorphicColors.lightTextMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        template.resourceLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? NeumorphicColors.darkTextMuted
                                              : NeumorphicColors.lightTextMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${template.starterServices.length} Services',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );

        if (isShortStep) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                description,
                const SizedBox(height: 12),
                categoryStrip,
                const SizedBox(height: 14),
                templatesGrid,
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            description,
            const SizedBox(height: 14),
            categoryStrip,
            const SizedBox(height: 16),
            Expanded(child: templatesGrid),
          ],
        );
      },
    );
  }

  // --- Step 1: Business Profile ---
  // Gene - Nov, 14, 2026: Stack 2-column form rows vertically when narrow (< 520px) to prevent modal overflows
  Widget _buildBusinessProfileStep(bool isDark, Color accent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final nameField = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            NeumorphicTextField(
              controller: _nameController,
              hintText: 'e.g. Skyline Orthodontics & Dental Studio',
              onChanged: _generateSlug,
            ),
          ],
        );
        final slugField = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Slug (URL Handle)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            NeumorphicTextField(
              controller: _slugController,
              hintText: 'skyline-orthodontics',
            ),
          ],
        );
        final phoneField = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Phone', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            NeumorphicTextField(
              controller: _phoneController,
              hintText: '+1 (555) 000-0000',
            ),
          ],
        );
        final emailField = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Email', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            NeumorphicTextField(
              controller: _emailController,
              hintText: 'contact@business.com',
            ),
          ],
        );
        final addressField = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Street Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            NeumorphicTextField(
              controller: _addressController,
              hintText: '100 Medical Center Parkway, Suite 400',
            ),
          ],
        );
        final cityField = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('City / Region', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            NeumorphicTextField(
              controller: _cityController,
              hintText: 'San Francisco',
            ),
          ],
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNarrow) ...[
                nameField,
                const SizedBox(height: 12),
                slugField,
              ] else
                Row(
                  children: [
                    Expanded(flex: 3, child: nameField),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: slugField),
                  ],
                ),
              const SizedBox(height: 16),

              if (isNarrow) ...[
                phoneField,
                const SizedBox(height: 12),
                emailField,
              ] else
                Row(
                  children: [
                    Expanded(child: phoneField),
                    const SizedBox(width: 14),
                    Expanded(child: emailField),
                  ],
                ),
              const SizedBox(height: 16),

              if (isNarrow) ...[
                addressField,
                const SizedBox(height: 12),
                cityField,
              ] else
                Row(
                  children: [
                    Expanded(flex: 3, child: addressField),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: cityField),
                  ],
                ),
              // Gene - Nov 06, 2026: Embedded interactive LocationPinPicker with bidirectional sync
              const SizedBox(height: 16),
              LocationPinPicker(
                key: _pinPickerKey,
                initialLatitude: _latitude ?? 37.7749,
                initialLongitude: _longitude ?? -122.4194,
                height: 200,
                label: 'Clinic Map Location (Drag or tap map to set pin)',
                onLocationChanged: (loc) {
                  setState(() {
                    _latitude = loc.latitude;
                    _longitude = loc.longitude;
                    _addressController.removeListener(_onAddressChanged);
                    _cityController.removeListener(_onAddressChanged);
                    _addressController.text = loc.formattedAddress;
                    if (loc.city != null) _cityController.text = loc.city!;
                    _addressController.addListener(_onAddressChanged);
                    _cityController.addListener(_onAddressChanged);
                  });
                },
              ),
              const SizedBox(height: 16),

              const Text('Short Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              NeumorphicTextField(
                controller: _descriptionController,
                hintText: 'Tell your clients about your facilities, specialties, and customer philosophy...',
                maxLines: 3,
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Step 2: Catalog Review ---
  Widget _buildCatalogReviewStep(bool isDark, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /*
        // Gene - Nov, 04, 2026: Previous unconstrained Row causing RenderFlex overflow on narrow dialogs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Starter Service Catalog & Resource Roles',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pre-filled from "${_selectedTemplate?.name}". Toggle or adjust pricing before launch.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        */
        // Gene - Nov, 04, 2026: Wrapped catalog header in Expanded to eliminate RenderFlex overflow on responsive dialogs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Starter Service Catalog & Resource Roles',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pre-filled from "${_selectedTemplate?.name}". Toggle or adjust pricing before launch.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Services list
        // Gene - Nov, 14, 2026: Wrap catalog row badges under < 520px and upgrade muted colors to WCAG AA tokens
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              return ListView.builder(
                itemCount: _customServices.length,
                itemBuilder: (context, index) {
                  final srv = _customServices[index];
                  final isIncluded = srv['is_included'] as bool;
                  final durationBadge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${srv['duration_minutes']} min',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  );
                  final policyBadge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      srv['payment_policy'] == 'deposit_required'
                          ? 'Deposit \$${srv['deposit_amount']}'
                          : (srv['payment_policy'] == 'full_upfront' ? 'Full Upfront' : 'Pay at Venue'),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent),
                    ),
                  );
                  final priceText = Text(
                    '\$${(srv['price'] as num).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary,
                    ),
                  );
                  final checkboxAndTitle = Row(
                    children: [
                      Checkbox(
                        value: isIncluded,
                        activeColor: accent,
                        onChanged: (val) {
                          setState(() {
                            srv['is_included'] = val ?? true;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              srv['name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isIncluded
                                    ? (isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary)
                                    : (isDark ? NeumorphicColors.darkTextMuted : NeumorphicColors.lightTextMuted),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              srv['description'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? NeumorphicColors.darkTextMuted : NeumorphicColors.lightTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NeumorphicContainer(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: isNarrow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                checkboxAndTitle,
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      durationBadge,
                                      policyBadge,
                                      priceText,
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: checkboxAndTitle),
                                const SizedBox(width: 14),
                                durationBadge,
                                const SizedBox(width: 12),
                                policyBadge,
                                const SizedBox(width: 12),
                                priceText,
                              ],
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 10),
        // Staff roles preview
        Text(
          'Starter ${_selectedTemplate?.resourceLabel} Titles: ${_customStaff.join(', ')}',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  // --- Step 3: Schedule & Launch ---
  Widget _buildScheduleLaunchStep(bool isDark, Color accent) {
    final settings = _selectedTemplate?.defaultSettings ?? {};
    final uiConfig = _selectedTemplate?.uiConfig ?? {};
    final intakeFields = _selectedTemplate?.intakeFields ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeumorphicContainer(
            borderRadius: 14,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gene - Nov, 14, 2026: Wrap Ready to Launch heading in Expanded to prevent narrow/scaled modal overflow
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: accent, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ready to Launch ${_nameController.text.trim()}!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Settings Breakdown
                _buildSummaryRow('Chosen Template', _selectedTemplate?.name ?? 'Generic'),
                _buildSummaryRow('Booking Model', _selectedTemplate?.bookingModel.displayName ?? ''),
                _buildSummaryRow('Resource Archetype', '${uiConfig['resource_type']} (${uiConfig['resource_label']})'),
                _buildSummaryRow('Time Slot Interval', '${settings['slot_interval_minutes'] ?? 30} minutes'),
                _buildSummaryRow('Buffer Interval', '${settings['buffer_minutes'] ?? 10} minutes'),
                _buildSummaryRow('Services to Provision', '${_customServices.where((s) => s['is_included'] == true).length} active services'),
                _buildSummaryRow('Dynamic Intake Fields', '${intakeFields.length} custom intake questions'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'What happens next?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildNextStepItem(
            Icons.tune_rounded,
            'Client Booking Engine Instantly Configured',
            'Your clients will immediately see the optimized booking flow tailored specifically for your industry.',
            isDark,
            accent,
          ),
          const SizedBox(height: 8),
          _buildNextStepItem(
            Icons.point_of_sale_rounded,
            'Manage Services & Payments Anytime',
            'You can add more services, edit staff members, and connect your Stripe account in your Admin Settings.',
            isDark,
            accent,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    /*
    // Gene - Nov, 04, 2026: Rigid Row causing RenderFlex overflow for multi-resource archetypes
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
    */
    // Gene - Nov 06, 2026: Wrapped summary row value in Flexible to prevent RenderFlex overflow for multi-resource archetypes
    // Gene - Nov, 14, 2026: Use WCAG AA secondary text colors on summary rows and next-step descriptions
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(IconData icon, String title, String subtitle, bool isDark, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
