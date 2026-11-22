// Gene - Nov, 22, 2026: PlatformConfigService loading dynamic global configuration from `public.platform_settings`
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/app_error_logger.dart';
import '../models/platform_config.dart';
import 'supabase_service.dart';

class PlatformConfigService {
  Future<PlatformConfig> getPlatformConfig() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final rows = await client.from('platform_settings').select('key, value');
        final parsedRows = (rows as List)
            .whereType<Map>()
            .map((r) => Map<String, dynamic>.from(r))
            .toList();
        if (parsedRows.isNotEmpty) {
          return PlatformConfig.fromSettingsRows(parsedRows);
        }
      } catch (e, st) {
        AppErrorLogger.report(
          service: 'PlatformConfigService',
          operation: 'getPlatformConfig',
          error: e,
          stackTrace: st,
        );
      }
    }
    return PlatformConfig.defaults();
  }
}

final platformConfigServiceProvider = Provider<PlatformConfigService>((ref) => PlatformConfigService());

final platformConfigProvider = FutureProvider<PlatformConfig>((ref) async {
  final service = ref.watch(platformConfigServiceProvider);
  return service.getPlatformConfig();
});

final activePlatformConfigProvider = Provider<PlatformConfig>((ref) {
  return ref.watch(platformConfigProvider).valueOrNull ?? PlatformConfig.defaults();
});
