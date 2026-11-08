// Gene - Nov, 04, 2026: Imported conditional test environment detector
import 'test_environment.dart';

// Gene - Nov, 03, 2026: Configured Supabase project ref xjivgzyfewvdhiceaned with environment override support
class SupabaseConfig {
  SupabaseConfig._();

  static const String projectRef = 'xjivgzyfewvdhiceaned';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xjivgzyfewvdhiceaned.supabase.co',
  );

  /*
  // Gene - Nov, 03, 2026: Placeholder anon key for initial scaffold
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder-anon-key',
  );
  */
  // Gene - Nov, 04, 2026: Live Supabase anon publishable key for project xjivgzyfewvdhiceaned
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhqaXZnenlmZXd2ZGhpY2VhbmVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM3MDU0MTksImV4cCI6MjEwOTI4MTQxOX0.uRZjRV3R58KstQkZaeo2UakN4Ylb-qjw4FhLrdjGNw0',
  );

  /*
  // Gene - Nov, 03, 2026: Basic isConfigured check without test environment guard
  static bool get isConfigured =>
      supabaseAnonKey != 'placeholder-anon-key' &&
      supabaseAnonKey.isNotEmpty;
  */
  /*
  // Gene - Nov, 04, 2026: Added FLUTTER_TEST environment guard so unit/widget tests run offline with mock fixtures while real app connects to live Supabase
  static bool get isConfigured =>
      !const bool.fromEnvironment('FLUTTER_TEST') &&
      supabaseAnonKey != 'placeholder-anon-key' &&
      supabaseAnonKey.isNotEmpty;
  */

  // Gene - Nov, 04, 2026: Optional override flag for tests or forced offline mode
  static bool? overrideConfigured;

  /*
  // Gene - Nov, 04, 2026: Uses cross-platform isFlutterTestRunning conditional check so unit/widget tests use mock fixtures without live socket heartbeats, while Flutter web and mobile connect live
  static bool get isConfigured {
    if (overrideConfigured != null) return overrideConfigured!;
    return !isFlutterTestRunning() &&
        supabaseAnonKey != 'placeholder-anon-key' &&
        supabaseAnonKey.isNotEmpty;
  }
  */

  // Gene - Nov, 08, 2026: Added FORCE_MOCK_MODE build flag and HTTPS/localhost transport security validation (CWE-319) for Vercel Web deployments
  static const bool forceMockMode = bool.fromEnvironment(
    'FORCE_MOCK_MODE',
    defaultValue: false,
  );

  static bool get isSecureUrl =>
      supabaseUrl.startsWith('https://') ||
      supabaseUrl.startsWith('http://localhost') ||
      supabaseUrl.startsWith('http://127.0.0.1');

  static bool get isConfigured {
    if (overrideConfigured != null) return overrideConfigured!;
    if (forceMockMode) return false;
    return !isFlutterTestRunning() &&
        isSecureUrl &&
        supabaseAnonKey != 'placeholder-anon-key' &&
        supabaseAnonKey.isNotEmpty;
  }
}
