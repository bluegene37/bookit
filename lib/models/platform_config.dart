// Gene - Nov, 22, 2026: Database-driven platform configuration models loaded from `public.platform_settings`

class CurrencyOption {
  final String code;
  final String symbol;
  final String name;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
  });

  factory CurrencyOption.fromJson(Map<String, dynamic> json) {
    return CurrencyOption(
      code: (json['code'] as String? ?? 'USD').toUpperCase(),
      symbol: json['symbol'] as String? ?? '\$',
      name: json['name'] as String? ?? 'US Dollar',
    );
  }
}

class BookingModelOption {
  final String id;
  final String title;
  final String shortLabel;
  final String description;
  final String icon;

  const BookingModelOption({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.description,
    required this.icon,
  });

  factory BookingModelOption.fromJson(Map<String, dynamic> json) {
    return BookingModelOption(
      id: json['id'] as String? ?? 'slot_based',
      title: json['title'] as String? ?? 'Time Slot Appointments',
      shortLabel: json['short_label'] as String? ?? 'Time Slot Appointment',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'calendar_today',
    );
  }
}

class PaymentChannelOption {
  final String id;
  final String label;
  final String channelTitle;
  final String subtitle;
  final bool requiresReference;
  final String referenceLabel;
  final String referenceHint;
  final String senderLabel;
  final String senderHint;

  const PaymentChannelOption({
    required this.id,
    required this.label,
    required this.channelTitle,
    required this.subtitle,
    required this.requiresReference,
    this.referenceLabel = 'Transaction Reference No.',
    this.referenceHint = 'Enter transaction reference number',
    this.senderLabel = 'Sending Account / Name',
    this.senderHint = 'Enter sender name or account',
  });

  factory PaymentChannelOption.fromJson(Map<String, dynamic> json) {
    return PaymentChannelOption(
      id: json['id'] as String? ?? 'stripe_card',
      label: json['label'] as String? ?? 'Card',
      channelTitle: json['channel_title'] as String? ?? 'Card Payment',
      subtitle: json['subtitle'] as String? ?? '',
      requiresReference: json['requires_reference'] as bool? ?? false,
      referenceLabel: json['reference_label'] as String? ?? 'Transaction Reference No.',
      referenceHint: json['reference_hint'] as String? ?? 'Enter transaction reference number',
      senderLabel: json['sender_label'] as String? ?? 'Sending Account / Name',
      senderHint: json['sender_hint'] as String? ?? 'Enter sender name or account',
    );
  }
}

class SchedulingPresets {
  final List<int> slotIntervals;
  final List<int> bufferOptions;
  final List<String> openTimes;
  final List<String> closeTimes;
  final int defaultAdvanceBookingDays;
  final int defaultMinNoticeHours;

  const SchedulingPresets({
    this.slotIntervals = const [15, 30, 45, 60],
    this.bufferOptions = const [0, 5, 10, 15, 30],
    this.openTimes = const ['06:00', '07:00', '08:00', '08:30', '09:00', '09:30', '10:00', '11:00', '12:00'],
    this.closeTimes = const ['14:00', '15:00', '16:00', '17:00', '17:30', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00'],
    this.defaultAdvanceBookingDays = 14,
    this.defaultMinNoticeHours = 0,
  });

  factory SchedulingPresets.fromJson(Map<String, dynamic> json) {
    List<int> parseInts(dynamic raw, List<int> fallback) {
      if (raw is List && raw.isNotEmpty) {
        return raw.map((e) => (e as num).toInt()).toList();
      }
      return fallback;
    }

    List<String> parseStrings(dynamic raw, List<String> fallback) {
      if (raw is List && raw.isNotEmpty) {
        return raw.map((e) => e.toString()).toList();
      }
      return fallback;
    }

    const def = SchedulingPresets();
    return SchedulingPresets(
      slotIntervals: parseInts(json['slot_intervals'], def.slotIntervals),
      bufferOptions: parseInts(json['buffer_options'], def.bufferOptions),
      openTimes: parseStrings(json['open_times'], def.openTimes),
      closeTimes: parseStrings(json['close_times'], def.closeTimes),
      defaultAdvanceBookingDays: (json['default_advance_booking_days'] as num?)?.toInt() ?? 14,
      defaultMinNoticeHours: (json['default_min_notice_hours'] as num?)?.toInt() ?? 0,
    );
  }
}

class CrmConfig {
  final double vipSpendThreshold;
  final int vipVisitsThreshold;
  final int regularVisitsThreshold;
  final int lapsedDays;
  final Map<String, List<String>> flagPresetsByCategory;

  const CrmConfig({
    this.vipSpendThreshold = 350.0,
    this.vipVisitsThreshold = 3,
    this.regularVisitsThreshold = 2,
    this.lapsedDays = 90,
    this.flagPresetsByCategory = _defaultPresetsByCategory,
  });

  static const Map<String, List<String>> _defaultPresetsByCategory = {
    'healthcare': [
      'Penicillin Allergy',
      'Latex Sensitivity',
      'Blood Thinners',
      'High Anxiety',
      'Lidocaine Sensitivity',
      'Pregnancy / Nursing',
    ],
    'wellness': [
      'Essential Oil Sensitivity',
      'Pregnancy / Prenatal',
      'Deep Pressure Contraindication',
      'Mobility Assistance',
      'Dietary Allergy',
    ],
    'beauty': [
      'Sensitive Scalp / Skin',
      'Color / Bleach History',
      'Keratin / Chemical Treated',
      'Adhesive / Latex Sensitivity',
    ],
    'fitness': [
      'Knee / Joint Limitation',
      'Lower Back Sensitivity',
      'Asthma / Cardio Note',
      'Post-Rehab Clearance',
    ],
    'automotive': [
      'Matte Paint / Vinyl Wrap',
      'Ceramic Coated',
      'Oversize / Over 7ft',
      'Heavy Pet Hair',
    ],
    'default': [
      'VIP Preference',
      'Accessibility Needs',
      'Special Preparation',
      'Repeat Scheduling Preference',
    ],
  };

  factory CrmConfig.fromJson(Map<String, dynamic> json) {
    final rawMap = json['flag_presets_by_category'];
    final parsedPresets = <String, List<String>>{};
    if (rawMap is Map) {
      rawMap.forEach((k, v) {
        if (v is List) {
          parsedPresets[k.toString().toLowerCase()] = v.map((e) => e.toString()).toList();
        }
      });
    }
    return CrmConfig(
      vipSpendThreshold: (json['vip_spend_threshold'] as num?)?.toDouble() ?? 350.0,
      vipVisitsThreshold: (json['vip_visits_threshold'] as num?)?.toInt() ?? 3,
      regularVisitsThreshold: (json['regular_visits_threshold'] as num?)?.toInt() ?? 2,
      lapsedDays: (json['lapsed_days'] as num?)?.toInt() ?? 90,
      flagPresetsByCategory: parsedPresets.isNotEmpty ? parsedPresets : _defaultPresetsByCategory,
    );
  }

  List<String> presetsForCategory(String? category) {
    final lower = (category ?? '').toLowerCase();
    if (lower.contains('health') || lower.contains('dental') || lower.contains('medical') || lower.contains('clinic')) {
      return flagPresetsByCategory['healthcare'] ?? _defaultPresetsByCategory['healthcare']!;
    }
    if (lower.contains('wellness') || lower.contains('spa') || lower.contains('therapy') || lower.contains('recovery')) {
      return flagPresetsByCategory['wellness'] ?? _defaultPresetsByCategory['wellness']!;
    }
    if (lower.contains('beauty') || lower.contains('salon') || lower.contains('barber')) {
      return flagPresetsByCategory['beauty'] ?? _defaultPresetsByCategory['beauty']!;
    }
    if (lower.contains('fitness') || lower.contains('yoga') || lower.contains('pilates') || lower.contains('train')) {
      return flagPresetsByCategory['fitness'] ?? _defaultPresetsByCategory['fitness']!;
    }
    if (lower.contains('auto') || lower.contains('car') || lower.contains('wash') || lower.contains('detail')) {
      return flagPresetsByCategory['automotive'] ?? _defaultPresetsByCategory['automotive']!;
    }
    return flagPresetsByCategory['default'] ?? _defaultPresetsByCategory['default']!;
  }
}

class StandeePresets {
  final String publicBaseUrl;
  final List<String> headlines;

  const StandeePresets({
    this.publicBaseUrl = 'https://bookit.app',
    this.headlines = const [
      'Scan to Book in 30 Seconds',
      "Walk-Ins Welcome — Check Today's Openings",
      'Reserve Your Spot Now',
    ],
  });

  factory StandeePresets.fromJson(Map<String, dynamic> json) {
    final rawHeadlines = json['headlines'];
    return StandeePresets(
      publicBaseUrl: json['public_base_url'] as String? ?? 'https://bookit.app',
      headlines: rawHeadlines is List && rawHeadlines.isNotEmpty
          ? rawHeadlines.map((e) => e.toString()).toList()
          : const StandeePresets().headlines,
    );
  }
}

class BrandingConfig {
  final String appName;
  final String discoverySubtitle;
  final String searchPlaceholder;
  final double defaultLatitude;
  final double defaultLongitude;

  const BrandingConfig({
    this.appName = 'BookIt',
    this.discoverySubtitle = 'Discover businesses, specialists & services',
    this.searchPlaceholder = 'Search businesses, services, or specialists...',
    this.defaultLatitude = 37.7749,
    this.defaultLongitude = -122.4194,
  });

  factory BrandingConfig.fromJson(Map<String, dynamic> json) {
    return BrandingConfig(
      appName: json['app_name'] as String? ?? 'BookIt',
      discoverySubtitle: json['discovery_subtitle'] as String? ?? 'Discover businesses, specialists & services',
      searchPlaceholder: json['search_placeholder'] as String? ?? 'Search businesses, services, or specialists...',
      defaultLatitude: (json['default_latitude'] as num?)?.toDouble() ?? 37.7749,
      defaultLongitude: (json['default_longitude'] as num?)?.toDouble() ?? -122.4194,
    );
  }
}

class PlatformConfig {
  final List<CurrencyOption> supportedCurrencies;
  final List<BookingModelOption> bookingModels;
  final SchedulingPresets schedulingPresets;
  final List<PaymentChannelOption> paymentChannels;
  final CrmConfig crmConfig;
  final StandeePresets standeePresets;
  final BrandingConfig branding;

  const PlatformConfig({
    required this.supportedCurrencies,
    required this.bookingModels,
    required this.schedulingPresets,
    required this.paymentChannels,
    required this.crmConfig,
    required this.standeePresets,
    required this.branding,
  });

  static const Map<String, String> _knownCurrencySymbols = {
    'USD': '\$',
    'PHP': '₱',
    'EUR': '€',
    'GBP': '£',
    'SGD': 'S\$',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'JPY': '¥',
  };

  static String symbolFor(String? currencyCode, {List<CurrencyOption>? currencies}) {
    final normalized = (currencyCode ?? 'USD').trim().toUpperCase();
    if (currencies != null) {
      for (final c in currencies) {
        if (c.code.toUpperCase() == normalized) return c.symbol;
      }
    }
    return _knownCurrencySymbols[normalized] ?? '\$';
  }

  static String formatCurrency(
    double amount, {
    String? currencyCode,
    int decimals = 2,
    List<CurrencyOption>? currencies,
  }) {
    final symbol = symbolFor(currencyCode, currencies: currencies);
    return '$symbol${amount.toStringAsFixed(decimals)}';
  }

  String formatAmount(double amount, {String? currencyCode, int decimals = 2}) {
    return formatCurrency(
      amount,
      currencyCode: currencyCode,
      decimals: decimals,
      currencies: supportedCurrencies,
    );
  }

  String symbolForCode(String? currencyCode) {
    return symbolFor(currencyCode, currencies: supportedCurrencies);
  }

  List<String> crmFlagPresetsForCategory(String? category) {
    return crmConfig.presetsForCategory(category);
  }

  factory PlatformConfig.defaults() {
    return const PlatformConfig(
      supportedCurrencies: [
        CurrencyOption(code: 'USD', symbol: '\$', name: 'US Dollar'),
        CurrencyOption(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
        CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro'),
        CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound'),
        CurrencyOption(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
        CurrencyOption(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
        CurrencyOption(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
        CurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
      ],
      bookingModels: [
        BookingModelOption(
          id: 'slot_based',
          title: '1. Time Slot Appointments',
          shortLabel: 'Time Slot Appointment',
          description: 'Clients choose a service, select a provider or resource, and book discrete time slots.',
          icon: 'calendar_today',
        ),
        BookingModelOption(
          id: 'date_range',
          title: '2. Date Range Booking (Stays & Rentals)',
          shortLabel: 'Date Range Booking',
          description: 'Clients pick arrival and departure dates with automatic multi-day or nightly rate calculation.',
          icon: 'date_range',
        ),
        BookingModelOption(
          id: 'daily',
          title: '3. Daily Session (Day Pass & Capacity)',
          shortLabel: 'Daily Session',
          description: 'Clients reserve full-day sessions or day passes on available open dates.',
          icon: 'view_day',
        ),
      ],
      schedulingPresets: SchedulingPresets(),
      paymentChannels: [
        PaymentChannelOption(
          id: 'stripe_card',
          label: 'Card (Stripe)',
          channelTitle: 'Credit / Debit Card (Stripe)',
          subtitle: 'Online card checkout via Stripe Express',
          requiresReference: false,
        ),
        PaymentChannelOption(
          id: 'gcash',
          label: 'GCash',
          channelTitle: 'GCash Express / QR Ph',
          subtitle: 'Clients scan QR or transfer to your GCash number and input their 13-digit Reference No.',
          requiresReference: true,
          referenceLabel: '13-Digit GCash Reference No.',
          referenceHint: 'e.g. 9018472615243',
          senderLabel: 'Your GCash Name / Mobile No.',
          senderHint: 'e.g. Alex Reyes (0917-XXX-XXXX)',
        ),
        PaymentChannelOption(
          id: 'maya',
          label: 'Maya',
          channelTitle: 'Maya Digital Wallet',
          subtitle: 'Direct transfer via Maya mobile number or QR Ph',
          requiresReference: true,
          referenceLabel: 'Maya Reference ID',
          referenceHint: 'Enter transaction reference number',
          senderLabel: 'Your Maya Name / Mobile No.',
          senderHint: 'e.g. Alex Reyes (0918-XXX-XXXX)',
        ),
        PaymentChannelOption(
          id: 'bank_transfer',
          label: 'Bank Transfer',
          channelTitle: 'Bank Transfer (InstaPay / PESONet)',
          subtitle: 'Clients transfer to your business bank account',
          requiresReference: true,
          referenceLabel: 'Bank Transfer Reference No.',
          referenceHint: 'Enter transaction reference number',
          senderLabel: 'Your Sending Bank & Account Name',
          senderHint: 'e.g. BPI Savings / Alex Reyes',
        ),
      ],
      crmConfig: CrmConfig(),
      standeePresets: StandeePresets(),
      branding: BrandingConfig(),
    );
  }

  factory PlatformConfig.fromSettingsRows(List<Map<String, dynamic>> rows) {
    final defaults = PlatformConfig.defaults();
    if (rows.isEmpty) return defaults;

    final map = <String, dynamic>{};
    for (final row in rows) {
      final k = row['key']?.toString();
      if (k != null && row['value'] != null) {
        map[k] = row['value'];
      }
    }

    List<CurrencyOption> currencies = defaults.supportedCurrencies;
    if (map['supported_currencies'] is List && (map['supported_currencies'] as List).isNotEmpty) {
      currencies = (map['supported_currencies'] as List)
          .whereType<Map>()
          .map((e) => CurrencyOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<BookingModelOption> bookingModels = defaults.bookingModels;
    if (map['booking_models'] is List && (map['booking_models'] as List).isNotEmpty) {
      bookingModels = (map['booking_models'] as List)
          .whereType<Map>()
          .map((e) => BookingModelOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<PaymentChannelOption> paymentChannels = defaults.paymentChannels;
    if (map['payment_channels'] is List && (map['payment_channels'] as List).isNotEmpty) {
      paymentChannels = (map['payment_channels'] as List)
          .whereType<Map>()
          .map((e) => PaymentChannelOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return PlatformConfig(
      supportedCurrencies: currencies,
      bookingModels: bookingModels,
      schedulingPresets: map['scheduling_presets'] is Map
          ? SchedulingPresets.fromJson(Map<String, dynamic>.from(map['scheduling_presets'] as Map))
          : defaults.schedulingPresets,
      paymentChannels: paymentChannels,
      crmConfig: map['crm_config'] is Map
          ? CrmConfig.fromJson(Map<String, dynamic>.from(map['crm_config'] as Map))
          : defaults.crmConfig,
      standeePresets: map['standee_presets'] is Map
          ? StandeePresets.fromJson(Map<String, dynamic>.from(map['standee_presets'] as Map))
          : defaults.standeePresets,
      branding: map['branding'] is Map
          ? BrandingConfig.fromJson(Map<String, dynamic>.from(map['branding'] as Map))
          : defaults.branding,
    );
  }
}
