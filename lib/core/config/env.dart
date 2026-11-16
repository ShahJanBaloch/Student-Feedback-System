/// Reads Supabase settings from compile-time Dart defines.
///
/// The anon key is a client key. It is still not hardcoded in Dart source.
/// Use `tool/flutter-with-env.ps1` to load the local KEY=VALUE `.env` file.
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String? get configurationError {
    if (supabaseUrl.isEmpty) {
      return 'SUPABASE_URL is missing. Run with tool/flutter-with-env.ps1.';
    }
    if (supabaseAnonKey.isEmpty) {
      return 'SUPABASE_ANON_KEY is missing. Copy .env.example to .env, add '
          'the anon key, and run with tool/flutter-with-env.ps1.';
    }
    return null;
  }
}
