// Gene - Nov, 03, 2026: Supabase configuration with environment overrides and demo-mode readiness
class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder-anon-key',
  );

  static bool get isConfigured =>
      supabaseUrl != 'https://placeholder-project.supabase.co' &&
      supabaseAnonKey != 'placeholder-anon-key';
}
