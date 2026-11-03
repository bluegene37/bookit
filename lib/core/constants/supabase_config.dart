// Gene - Nov, 03, 2026: Configured Supabase project ref xjivgzyfewvdhiceaned with environment override support
class SupabaseConfig {
  SupabaseConfig._();

  static const String projectRef = 'xjivgzyfewvdhiceaned';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xjivgzyfewvdhiceaned.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder-anon-key',
  );

  static bool get isConfigured =>
      supabaseAnonKey != 'placeholder-anon-key' &&
      supabaseAnonKey.isNotEmpty;
}
